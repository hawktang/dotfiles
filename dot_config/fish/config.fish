if status is-interactive
    # Commands to run in interactive sessions can go here
end

set PATH /Users/hawktang/micromamba/condabin /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin /opt/homebrew/bin/ /opt/homebrew/sbin/ /opt/homebrew/bin /opt/homebrew/sbin /usr/local/bin /System/Cryptexes/App/usr/bin /usr/bin /bin /usr/sbin /sbin /var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin /var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin /var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin /opt/X11/bin /Library/TeX/texbin /Users/hawktang/.fig/bin /Users/hawktang/.local/bin

alias ls='lsd'
alias l='lsd -l'
alias ll='lsd -lh'

alias conda='micromamba'

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
set -gx MAMBA_EXE "/opt/homebrew/bin/micromamba"
set -gx MAMBA_ROOT_PREFIX "$HOME/micromamba"
$MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
# <<< mamba initialize <<<

atuin init fish | source
starship init fish | source
