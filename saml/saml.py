import base64
import configparser
import getpass
import json
import os
import re
import shlex
import subprocess
from pathlib import Path
from urllib.parse import quote
from urllib.parse import urlparse
import boto3
import pandas as pd
import psutil
import requests
import urllib3
import xml.etree.ElementTree as ET
from bs4 import BeautifulSoup
from pandarallel import pandarallel
from rich import print
from rich.console import Console
from rich.table import Table
from rich.text import Text
import boto3
from botocore.exceptions import ClientError, ProfileNotFound

import fabric

# import asyncssh
# import asyncio

# Initialize pandarallel
pandarallel.initialize(progress_bar=False, verbose=0, nb_workers=5)

# Disable urllib3 warnings
urllib3.disable_warnings()

# Set pandas display options
pd.set_option("display.max_colwidth", 200)
pd.set_option("display.width", 200)

# Set no_proxy environment variable
os.environ['no_proxy'] = 'sqauthprod.sq.com.sg'

# Constants
REGION = 'ap-southeast-1'
OUTPUT_FORMAT = 'json'
CREDENTIALS_PATH = Path.home() / '.aws' / 'credentials'
DEFAULT_PROFILE = 'default'
SSL_VERIFICATION = False
REQUEST_TIMEOUT = 20
IDP_ENTRY_URL = 'https://sqauthprod.sq.com.sg/affwebservices/public/saml2sso?SPID=urn:amazon:webservices'
DURATION_SECONDS = 28800

# Set up directories and paths
ssh_dir = Path.home() / '.ssh'
ssh_dir.mkdir(parents=True, exist_ok=True)
path_password = ssh_dir / 'w2k.json'
path_token = ssh_dir / 'token.json'

console = Console()

base_profile_dir = Path.home() / "Library/Application Support/Firefox/Profiles"
base_profile_dir.mkdir(parents=True, exist_ok=True)



def probe_aws_profile(s3_uri, profile_name):
    try:
        # Parse the S3 URI
        parsed_uri = urlparse(s3_uri)
        bucket_name = parsed_uri.netloc
        prefix = parsed_uri.path.lstrip('/')

        # Create a session using the specified profile
        session = boto3.Session(profile_name=profile_name)
        
        # Create an S3 client using the session
        s3_client = session.client('s3')
        
        # Attempt to list objects in the bucket
        response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
        
        # If we get here, the profile is valid and not timed out
        # print(f"Profile '{profile_name}' is valid and not timed out.")
        return True
    
    except ClientError as e:
        if e.response['Error']['Code'] == 'ExpiredToken':
            print(f"Profile '{profile_name}' has timed out. Please refresh your credentials.")
        else:
            print(f"An error occurred: {e}")
        return False
    
    except ProfileNotFound:
        print(f"No credentials found for profile '{profile_name}'. Please check your AWS configuration.")
        return False
    
    except ValueError:
        print(f"Invalid S3 URI: {s3_uri}")
        return False

def start_browser_instances(df):
    """
    Start Firefox browser instances for each row in the dataframe.
    
    Args:
    df (pd.DataFrame): Dataframe containing 'profile' and 'url' columns.
    """
    def launch_firefox(profile, url=None):
        profile_path = Path.home() / "Library/Application Support/Firefox/Profiles" / profile
        profile_path.mkdir(parents=True, exist_ok=True)
        
        command = f'firefox -new-tab -profile "{profile_path}" "{url}"'
        args = shlex.split(command)
        
        try:
            process = subprocess.Popen(args, 
                                       start_new_session=True, 
                                       stdout=subprocess.DEVNULL, 
                                       stderr=subprocess.DEVNULL)
            print(f"Firefox launched with profile: {profile}")
            return process
        except Exception as e:
            print(f"An error occurred: {e}")
            return None

    df.apply(lambda row: launch_firefox(row['profile'], row['url']), axis=1)

def df_to_table(pandas_dataframe, rich_table, show_index=True, index_name=None, url_column='url'):
    """
    Convert a pandas DataFrame to a rich Table.
    
    Args:
    pandas_dataframe (pd.DataFrame): The DataFrame to convert.
    rich_table (rich.table.Table): The rich Table to populate.
    show_index (bool): Whether to show the index column.
    index_name (str): Name for the index column.
    url_column (str): Name of the column containing URLs.
    
    Returns:
    rich.table.Table: The populated rich Table.
    """
    if show_index:
        rich_table.add_column(str(index_name) if index_name else "")

    for column in pandas_dataframe.columns:
        #if column != url_column:
        rich_table.add_column(str(column))

    for index, row in pandas_dataframe.iterrows():
        table_row = [str(index)] if show_index else []
        for column, value in row.items():
            if column != url_column:
                cell = str(value)
            elif url_column and url_column in row:
                cell = Text('url', style=f"link {row[url_column]}")
            table_row.append(cell)
        rich_table.add_row(*table_row)

    return rich_table

def get_aws_console_url(token):
    """
    Get the AWS console URL for a given token.
    
    Args:
    token (dict): The AWS token containing credentials.
    
    Returns:
    str: The AWS console URL.
    """
    session_json = json.dumps({
        'sessionId': token['Credentials']['AccessKeyId'],
        'sessionKey': token['Credentials']['SecretAccessKey'],
        'sessionToken': token['Credentials']['SessionToken']
    })

    signin_token_url = f"https://signin.aws.amazon.com/federation?Action=getSigninToken&SessionDuration={DURATION_SECONDS}&Session={quote(session_json)}"
    signin_token_response = requests.get(signin_token_url)
    signin_token = json.loads(signin_token_response.text)['SigninToken']

    return f"https://signin.aws.amazon.com/federation?Action=login&Destination={quote('https://console.aws.amazon.com/')}&SigninToken={signin_token}"

def get_login_payload(formsoup, creds):
    """
    Extract login payload from form soup and credentials.
    
    Args:
    formsoup (BeautifulSoup): The parsed HTML form.
    creds (tuple): Username and password.
    
    Returns:
    dict: The login payload.
    """
    payload = {}
    for inputtag in formsoup.find_all(re.compile('(INPUT|input)')):
        name = inputtag.get('name', '')
        value = inputtag.get('value', '')
        if 'user' in name.lower() or 'email' in name.lower():
            payload[name] = creds[0]
        elif 'password' in name.lower():
            payload[name] = creds[1]
        else:
            payload[name] = value
    return payload

def extract_saml_assertion(response):
    """
    Extract SAML assertion from response.
    
    Args:
    response (requests.Response): The response containing SAML assertion.
    
    Returns:
    str: The SAML assertion.
    
    Raises:
    Exception: If no valid SAML assertion is found.
    """
    soup = BeautifulSoup(response.text, 'html.parser')
    for inputtag in soup.find_all('input'):
        if inputtag.get('name') == 'SAMLResponse':
            return inputtag.get('value')
    raise Exception('Response did not contain a valid SAML assertion')

def get_token(awsrole, assertion):
    """
    Get AWS token for a given role and SAML assertion.
    
    Args:
    awsrole (pd.Series): AWS role information.
    assertion (str): SAML assertion.
    
    Returns:
    dict: The AWS token, or None if an error occurs.
    """
    try:
        return boto3.Session(profile_name=DEFAULT_PROFILE).client('sts', region_name=REGION).assume_role_with_saml(
            RoleArn=awsrole['role_arn'],
            PrincipalArn=awsrole['principal_arn'],
            SAMLAssertion=assertion,
            DurationSeconds=DURATION_SECONDS)
    except Exception as e:
        print(f'{awsrole.role} failed')
        print(e)
        return None

def process_saml_assertion(assertion):
    """
    Process SAML assertion and generate AWS roles.
    
    Args:
    assertion (str): SAML assertion.
    
    Returns:
    pd.DataFrame: Processed AWS roles.
    """
    awsroles = []
    root = ET.fromstring(base64.b64decode(assertion))
    for saml2attribute in root.iter('{urn:oasis:names:tc:SAML:2.0:assertion}Attribute'):
        if saml2attribute.get('Name') == 'https://aws.amazon.com/SAML/Attributes/Role':
            for saml2attributevalue in saml2attribute.iter('{urn:oasis:names:tc:SAML:2.0:assertion}AttributeValue'):
                principal_arn, role_arn = saml2attributevalue.text.split(',')
                awsroles.append({
                    'role_arn': role_arn,
                    'principal_arn': principal_arn,
                })

    awsroles = pd.DataFrame(awsroles)
    awsroles[['account_number', 'role']] = awsroles.role_arn.str.lower().str.extract(r'arn:aws:iam::(\d+):role/(.*)')
    awsroles['account_name'] = awsroles.account_number.replace({
        '817929577935':'devops',
        '378888410647':'uat',
        '335723636949':'poc4',
        '654782598114':'prod',
        '442687725725':'poc2',
        '473563362768':'semiauto_prod',
        '759387151437':'semiauto_uat',
    })
    
    awsroles['account'] = awsroles.account_name + '(' + awsroles.account_number + ')'
    awsroles['profile'] = awsroles.role + '_' + awsroles.account_name
    awsroles['profile'] = awsroles.profile.replace(regex={
        'de_devops_devops':'default',
        'ds_admin_':'',
    })
    awsroles = awsroles.loc[lambda df: ~df.account.str.contains('semiauto')]
    awsroles = awsroles.loc[lambda df: ~df.role.str.contains('ce_adapt|de_readonly|ce_voc|ce_cipsearch|de_gpt|de_datamart')]
    awsroles = awsroles.sort_values('account_name').dropna()

    awsroles['token'] = awsroles.parallel_apply(lambda r: get_token(r, assertion), axis=1)
    awsroles = awsroles.dropna()
    
    awsroles['url'] = awsroles.token.parallel_apply(get_aws_console_url)
    awsroles.to_json(path_token, orient='records')
    
    # role_table = Table(title="Current Profiles", title_style='bold orange1', style='green')
    # role_table = df_to_table(awsroles[['profile','role', 'account','url']], role_table, show_index=False)
    # console.print(role_table)

    print(f'Writing SAML token to {CREDENTIALS_PATH}')
    config = configparser.RawConfigParser()
    config.read(CREDENTIALS_PATH)
    
    def add_profile(profile, token):
        if not config.has_section(profile):
            config.add_section(profile)
        config.set(profile, 'output', OUTPUT_FORMAT)
        config.set(profile, 'region', REGION)
        config.set(profile, 'aws_access_key_id', token['Credentials']['AccessKeyId'])
        config.set(profile, 'aws_secret_access_key', token['Credentials']['SecretAccessKey'])
        config.set(profile, 'aws_session_token', token['Credentials']['SessionToken'])

    with CREDENTIALS_PATH.open('w+') as configfile:
        awsroles.apply(lambda awsrole: add_profile(awsrole.profile, awsrole.token), axis=1)
        config.write(configfile)

    return awsroles

def get_saml_token(username, password):
    """
    Get SAML token for given username and password.
    
    Args:
    username (str): The username.
    password (str): The password.
    
    Returns:
    pd.DataFrame: Processed AWS roles.
    """
    session = requests.Session()
    session.trust_env = True

    formresponse = session.get(IDP_ENTRY_URL, verify=SSL_VERIFICATION, timeout=REQUEST_TIMEOUT)
    formsoup = BeautifulSoup(formresponse.text, 'html.parser')

    payload = get_login_payload(formsoup, (username, password))
    idpauthformsubmiturl = "https://sqauthprod.sq.com.sg/affwebservices/public/processlogin.jsp"

    response = session.post(idpauthformsubmiturl, data=payload, verify=SSL_VERIFICATION, timeout=REQUEST_TIMEOUT)

    print('Extracting data from SAML assertion...')
    assertion = extract_saml_assertion(response)

    print('Processing SAML into ARNs...')
    return process_saml_assertion(assertion)

# async def credential_to_dgx():
#     try:
#         async with asyncssh.connect('dgx') as conn:
#             await asyncssh.scp(str(Path('~/.aws/credentials').expanduser()), 'dgx:~/.aws/credentials')
#             print("AWS credential file has been transferred to DGX")
#     except Exception as e:
#         print(f'Connection failed: {str(e)}')

def sync_credentials_to_dgx():
    try:
        with fabric.Connection('dgx') as c:
            c.put(str(Path('~/.aws/credentials').expanduser()), '.aws/credentials')
            print("AWS credential file has been successfully transferred to DGX")
    except Exception as e:
        print(f'Connection failed: {str(e)}')

def process_aws_roles():
    """
    Perform main operations with AWS roles.
    """
    awsroles = pd.read_json(path_token)
    role_table = Table(title="Current Profiles", title_style='bold orange1', style='green')
    role_table = df_to_table(awsroles[['profile','role', 'account','url']], role_table, show_index=False)
    console.print(role_table)
    awsroles['url'] = awsroles.token.parallel_apply(get_aws_console_url)
    awsroles.to_json(path_token, orient='records')
    # awsroles = awsroles.loc[lambda df: ~df.profile.str.contains('ce_adapt|de_readonly|ce_voc|ce_cipsearch|de_gpt|de_datamart|poc4|ce_cip')]
    # sort firefox profile as you like
    awsroles = awsroles.set_index("profile").reindex(['default', 'uat', 'prod', 'admin_poc2']).reset_index()
    start_browser_instances(awsroles)
    # asyncio.run(credential_to_dgx())
    sync_credentials_to_dgx()



def check_ip_patterns(patterns):
    interfaces = psutil.net_if_addrs()
    
    for interface, addrs in interfaces.items():
        for addr in addrs:
            if addr.family == 2:  # IPv4
                ip = addr.address
                for pattern in patterns:
                    if re.match(pattern, ip):
                        return True  # Return True as soon as a match is found
    
    return False

def perform_saml_authentication(ip_pattern):
    if not path_password.exists():
        username = getpass.getpass(prompt="username: ")
        password = getpass.getpass(prompt="w2k password: ")
        pd.Series({'username': username, 'w2k': password}).to_json(path_password)

    df = pd.read_json(path_password, typ='series')
    username = df['username']
    w2k = df['w2k']
    print(f'username and w2k password were saved to {path_password}, click to change')

    if check_ip_patterns([ip_pattern]):
        try:
            get_saml_token(username, w2k)
            return
        except Exception:
            pass

    passcode = getpass.getpass(prompt="passcode with 6 fixed digital and 6 dynamic digital:")
    get_saml_token(username, passcode)

if __name__ == '__main__':
    if probe_aws_profile('s3://de-data-dev-ds-projects/probe', 'uat'):
        process_aws_roles()
    else:
        perform_saml_authentication(ip_pattern= r"10\.\d{1,3}\.\d{1,3}\.\d{1,3}")
        process_aws_roles()
