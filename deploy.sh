#!/bin/bash

# show warning if the script is run as root
if [ "$EUID" -eq 0 ]; then
    echo "This script should not be run as root."
    exit 1
fi

# script should copy all bin scripts to the bin directory: /usr/local/bin/ and remove the .sh part
for file in bin/*.sh; do
    cp "$file" "/usr/local/bin/$(basename "$file" .sh)"
done