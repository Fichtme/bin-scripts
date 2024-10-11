#!/bin/bash
set -e
IFS=$'\n'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory where the scripts are located
SCRIPT_DIR="$(dirname "$0")/bin"

# User bin directory
USER_BIN_DIR="/usr/local/bin"

# Create bin directory if it doesn't exist
mkdir -p "$USER_BIN_DIR"

# Function to print colored messages
print_colored_message() {
  local color_code=$1
  local message=$2
  echo -e "${color_code}${message}${NC}"
}

# Copy all scripts to bin directory and remove '.sh' extension
for script in "$SCRIPT_DIR"/*.sh; do
  script_name=$(basename "$script" .sh)
  target_path="$USER_BIN_DIR/$script_name"
  cp "$script" "$target_path"
  chmod +x "$target_path"
  print_colored_message "$BLUE" "Copying ${YELLOW}$script${BLUE} to ${YELLOW}$target_path${NC}"
done

print_colored_message "$GREEN" "All scripts have been copied to the $USER_BIN_DIR directory."