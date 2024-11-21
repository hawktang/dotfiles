if status is-interactive
    # Commands to run in interactive sessions can go here
end
# curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
# fisher update 

set PATH \
/home/linuxbrew/.linuxbrew/bin \
/home/linuxbrew/.linuxbrew/sbin \
/opt/homebrew/bin/ \
/opt/homebrew/sbin/ \
/opt/homebrew/bin \
/opt/homebrew/sbin \
$PATH

fish_config theme choose "Tomorrow Night"

alias ls='lsd'
alias l='lsd --long --sort time --reverse'
alias ll='lsd --long --tree'

alias conda='micromamba'

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
# set -gx MAMBA_EXE "/opt/homebrew/bin/micromamba"
# set -gx MAMBA_ROOT_PREFIX "$HOME/micromamba"
# $MAMBA_EXE shell hook --shell fish | source
# <<< mamba initialize <<<
# --root-prefix $MAMBA_ROOT_PREFIX

function fish_greeting
    fastfetch
end

function __tabby_working_directory_reporting --on-event fish_prompt
    echo -en "\e]1337;CurrentDir=$PWD\x7"
end

atuin init fish | source
starship init fish | source
zoxide init fish | source

# function y() {
#	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
#	yazi "$@" --cwd-file="$tmp"
#	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
#		builtin cd -- "$cwd"
#	fi
#	rm -f -- "$tmp"
# }

if set -q ZELLIJ
else
  zellij
end
