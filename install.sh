#!/bin/bash

# Detect OS type
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  OS_TYPE="macos"
elif [[ "$(uname)" == "Linux" ]]; then
  # Linux
  OS_TYPE="linux"
else
  echo "Unsupported operating system"
  exit 1
fi

# Install Homebrew
install_homebrew() {
  echo '🍺  Installing Homebrew'
  /bin/bash -c "$(curl -fsSLk https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH based on the system
  if [[ "$OS_TYPE" == "macos" ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
      # For Apple Silicon Macs
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      # For Intel Macs
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  elif [[ "$OS_TYPE" == "linux" ]]; then
    # For Linux
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  
  echo "Homebrew has been installed and added to PATH"
}

# Install chezmoi using the appropriate method for the OS
install_chezmoi() {
  echo '👊  Installing chezmoi'
  
  if [[ "$OS_TYPE" == "macos" ]] || command -v brew >/dev/null 2>&1; then
    # Use Homebrew if available
    brew install chezmoi
  elif [[ "$OS_TYPE" == "linux" ]]; then
    # Alternative installation method for Linux if Homebrew isn't available
    if ! command -v brew >/dev/null 2>&1; then
      # Binary install as fallback on Linux
      bin_dir="$HOME/.local/bin"
      mkdir -p "$bin_dir"
      sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin_dir"
      export PATH="$bin_dir:$PATH"
    fi
  fi
}

# Check and install Homebrew if needed
if ! command -v brew >/dev/null 2>&1; then
  install_homebrew
fi

# Check and install chezmoi if needed
if ! command -v chezmoi >/dev/null 2>&1; then
  install_chezmoi
fi

# Apply dotfiles with chezmoi
echo "Applying dotfiles with chezmoi..."
chezmoi init --apply hawktang

echo ""
echo "Done."
