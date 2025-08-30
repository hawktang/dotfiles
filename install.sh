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

# Check if running as root on Linux (which is not recommended for Homebrew)
check_not_root() {
  if [[ "$OS_TYPE" == "linux" && "$EUID" -eq 0 ]]; then
    echo "Warning: Running as root is not recommended for Homebrew."
    echo "Consider running this script as a non-root user."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
}

# Create user local directories if they don't exist
ensure_user_dirs() {
  local_bin="$HOME/.local/bin"
  if [[ ! -d "$local_bin" ]]; then
    echo "Creating $local_bin directory"
    mkdir -p "$local_bin"
  fi
  
  # Add to PATH if not already present
  if [[ ":$PATH:" != *":$local_bin:"* ]]; then
    export PATH="$local_bin:$PATH"
    echo "Added $local_bin to PATH"
  fi
}

# Configure passwordless sudo for current user
configure_passwordless_sudo() {
  local username=$(whoami)
  local sudoers_file="/etc/sudoers.d/99-nopasswd-${username}"
  
  echo "Configuring passwordless sudo for user: ${username}"
  
  # Create sudoers drop-in file with proper syntax validation
  echo "${username} ALL=(ALL) NOPASSWD:ALL" | sudo tee "${sudoers_file}" > /dev/null
  
  # Set correct permissions for sudoers file
  sudo chmod 440 "${sudoers_file}"
  
  echo "Passwordless sudo configured successfully."
}

# Install prerequisites for Amazon Linux 2023
install_amazon_linux_prerequisites() {
  echo "Installing prerequisites for Amazon Linux 2023..."
  
  # Configure passwordless sudo first to avoid password prompts
  configure_passwordless_sudo
  
  # Install Development Tools group
  sudo dnf groupinstall -y "Development Tools"
  
  # Install additional required packages
  sudo dnf install -y procps-ng curl file git
  
  echo "Prerequisites installed successfully."
}

# Install Homebrew
install_homebrew() {
  echo '🍺  Installing Homebrew'
  
  # Check if running on Amazon Linux 2023 and install prerequisites
  if [[ "$OS_TYPE" == "linux" ]]; then
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      if [[ "$ID" == "amzn" && "$VERSION_ID" == "2023" ]]; then
        echo "Detected Amazon Linux 2023"
        install_amazon_linux_prerequisites
      fi
    fi
  fi
  
  # Check for necessary tools
  if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed."
    exit 1
  fi
  
  # First try the official installer
  echo "Attempting standard Homebrew installation..."
  if /bin/bash -c "$(curl -fsSLk https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>/dev/null; then
    echo "Standard Homebrew installation successful."
  else
    echo "Standard installation failed. Trying manual installation method..."
    
    # Manual installation as fallback for non-root users
    HOMEBREW_DIR="$HOME/.homebrew"
    
    if [[ -d "$HOMEBREW_DIR" ]]; then
      echo "Removing existing directory at $HOMEBREW_DIR"
      rm -rf "$HOMEBREW_DIR"
    fi
    
    mkdir -p "$HOMEBREW_DIR"
    echo "Downloading and extracting Homebrew to $HOMEBREW_DIR..."
    
    if curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOMEBREW_DIR"; then
      echo "Manual Homebrew installation successful."
      
      # Add to PATH
      export PATH="$HOMEBREW_DIR/bin:$PATH"
      
      # Create a shell initialization script
      BREW_RC="$HOME/.brewrc"
      echo '# Homebrew setup for non-root installation' > "$BREW_RC"
      echo "export PATH=\"$HOMEBREW_DIR/bin:\$PATH\"" >> "$BREW_RC"
      echo "export HOMEBREW_PREFIX=\"$HOMEBREW_DIR\"" >> "$BREW_RC"
      echo "export HOMEBREW_CELLAR=\"$HOMEBREW_DIR/Cellar\"" >> "$BREW_RC"
      echo "export HOMEBREW_REPOSITORY=\"$HOMEBREW_DIR\"" >> "$BREW_RC"
      
      # Suggest adding source to shell config
      echo ""
      echo "Add the following line to your shell configuration file (.bashrc, .zshrc, etc.):"
      echo "source $BREW_RC"
      echo ""
      
      # Source it for this session
      source "$BREW_RC"
    else
      echo "Failed to install Homebrew manually."
      exit 1
    fi
  fi
  
  # Add Homebrew to PATH based on the system (if using standard installation)
  if [[ "$OS_TYPE" == "macos" ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
      # For Apple Silicon Macs
      [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      # For Intel Macs
      [[ -f /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
    fi
  elif [[ "$OS_TYPE" == "linux" ]]; then
    # For Linux
    if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      
      # Add Homebrew to .bashrc for persistent PATH
      if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q '/home/linuxbrew/.linuxbrew/bin/brew shellenv' "$HOME/.bashrc"; then
          echo "" >> "$HOME/.bashrc"
          echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
          echo "Added Homebrew to .bashrc for persistent PATH configuration"
        fi
      fi
    elif [[ -f ~/.linuxbrew/bin/brew ]]; then
      eval "$(~/.linuxbrew/bin/brew shellenv)"
    elif [[ -f /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
  
  # Verify Homebrew installation
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew has been installed and added to PATH"
  else
    echo "Homebrew was installed but isn't in PATH. You may need to restart your terminal or shell session."
    exit 1
  fi
}

# Install chezmoi using the appropriate method for the OS
install_chezmoi() {
  echo '👊  Installing chezmoi'
  
  if command -v brew >/dev/null 2>&1; then
    # Use Homebrew if available
    brew install chezmoi
  else
    # Binary install as fallback
    bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$bin_dir" || {
      echo "Failed to install chezmoi binary. Please check your internet connection."
      exit 1
    }
    
    # Make sure bin_dir is in PATH
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
      export PATH="$bin_dir:$PATH"
    fi
  fi
  
  # Verify chezmoi installation
  if ! command -v chezmoi >/dev/null 2>&1; then
    echo "Failed to install chezmoi or add it to PATH."
    exit 1
  fi
}

# Apply dotfiles with chezmoi
apply_dotfiles() {
  echo "Applying dotfiles with chezmoi..."
  
  # Check if we can write to the home directory 
  if [[ ! -w "$HOME" ]]; then
    echo "Warning: No write permission to $HOME"
    exit 1
  fi
  
  # Create and set temp directory to avoid permission issues
  mkdir -p "$HOME/.cache/tmp"
  export TMPDIR="$HOME/.cache/tmp"
  
  # Initialize and apply chezmoi configuration
  chezmoi init --apply hawktang || {
    echo "Failed to apply dotfiles with chezmoi."
    exit 1
  }
}

# Main execution flow
check_not_root
ensure_user_dirs

# Check and install Homebrew if needed
if ! command -v brew >/dev/null 2>&1; then
  install_homebrew
fi

# Check and install chezmoi if needed
if ! command -v chezmoi >/dev/null 2>&1; then
  install_chezmoi
fi

apply_dotfiles

echo ""
echo "✅ Setup completed successfully."
