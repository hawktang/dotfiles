#!/bin/bash

brew bundle --no-lock --file=/dev/stdin <<EOF
brew "git"
brew "midnight-commander"
brew "bat"
brew "exa"
brew "fd"
brew "ripgrep"
brew "fzf"
brew "awscli"
brew "chezmoi"
brew "thefuck"
brew "tldr"
brew "duf"
brew "ncdu"
EOF
