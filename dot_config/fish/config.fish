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

function ecr_push
    set ECR "817929577935.dkr.ecr.ap-southeast-1.amazonaws.com/de-kariba-docker"
    docker tag $argv[1] $ECR:$argv[1]; and docker push $ECR:$argv[1]
end

atuin init fish | source
starship init fish | source
zoxide init fish | source
fzf --fish | source


# set -gx http_proxy "http://127.0.0.1:6152"
# set -gx https_proxy "http://127.0.0.1:6152"
# set -gx no_proxy "localhost,127.0.0.1,.local,::1,!*.sq.com.sg"


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
