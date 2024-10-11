#!/bin/bash
set -e
IFS=$'\n'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# show warning if the script is run as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}This script should not be run as root.${NC}"
    exit 1
fi

# script should copy all bin scripts to the bin directory: /usr/local/bin/ and remove the .sh part
for file in bin/*.sh; do
    echo "$BLUE Copying $YELLOW$file$BLUE to $YELLOW/usr/local/bin/$(basename "$file" .sh)$NC"
    cp "$file" "/usr/local/bin/$(basename "$file" .sh)"
done

echo "${GREEN}All scripts have been copied to the /usr/local/bin/ directory.${NC}"