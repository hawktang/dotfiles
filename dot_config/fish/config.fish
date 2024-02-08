if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias ls='lsd'
alias ll='lsd -l'
alias ll='lsd -lh'

atuin init fish | source
starship init fish | source
