if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
atuin init fish | source
starship init fish | source
