if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias ls='lsd'
alias l='lsd -l'
alias ll='lsd -lh'

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
set -gx MAMBA_EXE "/opt/homebrew/bin/micromamba"
set -gx MAMBA_ROOT_PREFIX "/Users/hawktang/micromamba"
$MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
# <<< mamba initialize <<<

atuin init fish | source
starship init fish | source
