#!/bin/bash

set -eufo pipefail

echo ""
echo "🤚  The script will setup .dotfiles for you."
read -n 1 -r -s -p $'    Press any key to continue or Ctrl+C to abort...\n\n'


# Install Homebrew
command -v brew >/dev/null 2>&1 || \
  (echo '🍺  Installing Homebrew' && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")

# Install chezmoi
command -v chezmoi >/dev/null 2>&1 || \
  (echo '👊  Installing chezmoi' && brew install chezmoi)

if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
  echo "🚸  chezmoi already initialized"
  echo "    Reinitialize with: 'chezmoi init --apply hawktang'" &&  && /bin/bash -c "$(chezmoi init --apply hawktang)"
else
  echo "🚀  Initialize dotfiles with:"
  echo "    chezmoi init --apply hawktang" &&  && /bin/bash -c "$(chezmoi init --apply hawktang)"
fi

echo ""
echo "Done."
