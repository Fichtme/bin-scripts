#!/bin/bash
set -e
IFS=$'\n'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_git() {
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${RED}This script should be run inside a Git repository.${NC}"
        exit 1
    fi
}

check_tag_exists() {
    if ! git rev-parse --quiet --verify "refs/tags/$1" >/dev/null 2>&1; then
        echo -e "${RED}Error: Tag '$1' does not exist.${NC}"
        exit 1
    fi
}

if [ "$#" -ne 2 ]; then
    echo -e "${YELLOW}Usage: $0 <latest_tag> <older_tag>${NC}"
    exit 1
fi
latest_tag=$1
older_tag=$2
check_git

check_tag_exists "$latest_tag"
check_tag_exists "$older_tag"
# Build the release notes content
gpt_prompt="Can you generate release notes based on the following git log? It's generated using: git log --pretty=format:\"- %B\" ${older_tag}..${latest_tag}
I need it in markdown format, so I can paste it into the release notes
It should have 3 sections: New Features, Improvements, and Other Changes
Please make sure to add the appropriate bullet points under each section
Each bullet point should start with a title
This is an example bullet point: **Mail Branding** - Mail service has seen an update with the addition of brand coloring.
We should not show the actual merge commits
Below are the changes between the tags ${older_tag} and ${latest_tag}:"

# Add the git log to release notes, excluding merge commits
gpt_prompt+=$'\n'
gpt_prompt+=$(git --no-pager log --pretty=format:"- %B" ${older_tag}..${latest_tag} | grep -v "Merge branch")

# Copy the release notes to clipboard
echo "gpt_prompt" | pbcopy

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to copy the AI prompt to the clipboard.${NC}"
    exit 1
fi
echo -e "${GREEN}AI prompt with information has been copied to the clipboard.${NC}"
