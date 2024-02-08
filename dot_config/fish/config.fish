if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias ls='lsd'
alias l='lsd -l'
alias la='lsd -a'
alias lla='lsd -la'
alias lt='lsd --tree'
atuin init fish | source
starship init fish | source
