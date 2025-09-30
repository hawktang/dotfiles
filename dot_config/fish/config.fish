if status is-interactive
    # Commands to run in interactive sessions can go here
end
# curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
# fisher update 

set PATH \
/home/linuxbrew/.linuxbrew/bin \
/home/linuxbrew/.linuxbrew/sbin \
/opt/homebrew/bin \
/opt/homebrew/sbin \
$HOME/.local/bin \
$PATH

fish_config theme choose "Tomorrow Night"

# Check if running on Amazon Linux 2023 and set proxy
if test -f /etc/os-release
    set os_info (cat /etc/os-release)
    if string match -q '*ID="amzn"*' $os_info; and string match -q '*VERSION_ID="2023"*' $os_info
        # Set proxy for Amazon Linux 2023
        set -gx http_proxy 'http://proxy.sin.services.nonprod.c0.sq.com.sg:3128'
        set -gx https_proxy 'http://proxy.sin.services.nonprod.c0.sq.com.sg:3128'
        set -gx HTTP_PROXY 'http://proxy.sin.services.nonprod.c0.sq.com.sg:3128'
        set -gx HTTPS_PROXY 'http://proxy.sin.services.nonprod.c0.sq.com.sg:3128'
        
        # Set no_proxy for both lowercase and uppercase
        set -gx no_proxy "api.nonprod.kariba-litellm.de.sin.auto2.nonprod.c0.sq.com.sg,10.119.112.43,10.119.114.49,127.0.0.1,localhost,169.254.169.253,169.254.169.254,.s3.ap-southeast-1.amazonaws.com,s3-ap-southeast-1.amazonaws.com,dynamodb.ap-southeast-1.amazonaws.com,.sq.com.sg,logs.ap-southeast-1.amazonaws.com,es.amazonaws.com"
        set -gx NO_PROXY "api.nonprod.kariba-litellm.de.sin.auto2.nonprod.c0.sq.com.sg,10.119.112.43,10.119.114.49,127.0.0.1,localhost,169.254.169.253,169.254.169.254,.s3.ap-southeast-1.amazonaws.com,s3-ap-southeast-1.amazonaws.com,dynamodb.ap-southeast-1.amazonaws.com,.sq.com.sg,logs.ap-southeast-1.amazonaws.com,es.amazonaws.com"
        
        # Enable Vertex AI integration
        set -gx CLAUDE_CODE_USE_VERTEX 1
        set -gx CLOUD_ML_REGION global
        set -gx ANTHROPIC_VERTEX_PROJECT_ID sia-data-team
        # Optional: Disable prompt caching if needed
        set -gx DISABLE_PROMPT_CACHING 0
        
        # When CLOUD_ML_REGION=global, override region for unsupported models
        set -gx VERTEX_REGION_CLAUDE_3_5_HAIKU us-east5
        
        # Optional: Override regions for other specific models
        set -gx VERTEX_REGION_CLAUDE_3_5_SONNET us-east5
        set -gx VERTEX_REGION_CLAUDE_3_7_SONNET us-east5
        set -gx VERTEX_REGION_CLAUDE_4_0_OPUS europe-west1
        set -gx VERTEX_REGION_CLAUDE_4_0_SONNET us-east5
        set -gx VERTEX_REGION_CLAUDE_4_1_OPUS europe-west1
        
        # Set Google Application Credentials
        set -gx GOOGLE_APPLICATION_CREDENTIALS "$HOME/gcloud.json"
    end
end

# git config --global http.sslVerify false
# git config --global credential."https://git-codecommit.ap-southeast-1.amazonaws.com".UseHttpPath true
# git config --global credential."https://git-codecommit.ap-southeast-1.amazonaws.com".helper '!aws --profile default codecommit credential-helper $@'

set -gx MAMBA_EXE (command -v micromamba)
if not set -q MAMBA_ROOT_PREFIX
    set -gx MAMBA_ROOT_PREFIX "$HOME/micromamba"
end
$MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
set -gx GIT_CONFIG_NOSYSTEM 1

# function fish_greeting
#    fastfetch
# end

function __tabby_working_directory_reporting --on-event fish_prompt
    echo -en "\e]1337;CurrentDir=$PWD\x7"
end

# function ecr_push
#    set ECR "817929577935.dkr.ecr.ap-southeast-1.amazonaws.com/de-kariba-docker"
#    docker tag $argv[1] $ECR:$argv[1]; and docker push $ECR:$argv[1]
# end

fzf --fish | source
starship init fish | source
zoxide init fish | source

atuin init fish --disable-up-arrow | source
# Bind up arrow to atuin search using new syntax
bind \e\[A _atuin_search



# set -gx http_proxy "http://127.0.0.1:6152"
# set -gx https_proxy "http://127.0.0.1:6152"
set -gx no_proxy "localhost,127.0.0.1,.local,::1,169.254.169.253,169.254.169.254"
# set -gx no_proxy "api.nonprod.kariba-litellm.de.sin.auto2.nonprod.c0.sq.com.sg,10.119.112.43,10.119.114.49,127.0.0.1,localhost,169.254.169.253,169.254.169.254,.s3.ap-southeast-1.amazonaws.com,s3-ap-southeast-1.amazonaws.com,dynamodb.ap-southeast-1.amazonaws.com,.sq.com.sg,logs.ap-southeast-1.amazonaws.com,es.amazonaws.com"
# 169.254.169.254 is where sia kriscloud get ec2 role.
# !*.sq.com.sg


alias http="http --verify=no -pb"
alias ls='lsd'
alias l='lsd --long --sort time --reverse'
alias ll='lsd --long --tree'

alias conda='micromamba'
# For Bash/Zsh
alias zellij='zellij attach --create'

# For Fish
alias zellij 'zellij attach --create'

# function y() {
#	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
#	yazi "$@" --cwd-file="$tmp"
#	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
#		builtin cd -- "$cwd"
#	fi
#	rm -f -- "$tmp"
# }

# if set -q ZELLIJ
# else
#  zellij
# end
