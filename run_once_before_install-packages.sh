#!/bin/bash

set -eufo pipefail

formulae=(
  midnight-commander
  bat
  lsd
  fd
  ripgrep
  fzf
  starship
  tldr
  duf
  ncdu
  byobu
  zoxide
  rsync
  aria2
  httpie
  w3m
  git
  poetry
  p7zip
  atuin
  awscli
  mitmproxy
  docker
)

brew update

brew install ${formulae[@]}

casks=(
    google-chrome
    iterm2
    visual-studio-code
    stats
    secure-pipes
)

brew install --cask ${casks[@]} -f

brew tap homebrew/cask-fonts
brew search '/font-.*-nerd-font/' | awk '{ print $1 }' | xargs -I{} brew install --cask {} || true

brew cleanup

git config --global http."https://git-codecommit.ap-southeast-1.amazonaws.com".sslVerify false
git config --global credential."https://git-codecommit.ap-southeast-1.amazonaws.com".UseHttpPath true

git config --global --unset-all credential."https://git-codecommit.ap-southeast-1.amazonaws.com/v1/repos/ce-cipsearch".helper '!aws --profile ce_cipsearch_devops_devops codecommit credential-helper $@'
git config --global --unset-all credential."https://git-codecommit.ap-southeast-1.amazonaws.com".helper '!aws --profile default codecommit credential-helper $@'
git config --global credential."https://git-codecommit.ap-southeast-1.amazonaws.com/v1/repos/ce-cipsearch".helper '!aws --profile ce_cipsearch_devops_devops codecommit credential-helper $@'
git config --global credential."https://git-codecommit.ap-southeast-1.amazonaws.com".helper '!aws --profile default codecommit credential-helper $@'


