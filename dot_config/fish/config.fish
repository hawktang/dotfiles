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

#$PATH

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


atuin init fish | source
starship init fish | source
zoxide init fish | source
