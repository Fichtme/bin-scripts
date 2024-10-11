#!/bin/bash

##################################
# README
##################################
# This script helps to generate AI-based release notes for a Git repository.
# It fetches the Git log between two tags or branches, formats the log for AI processing,
# and copies the formatted log to the clipboard. The AI prompt includes:
# - New Features
# - Improvements
# - Other Changes
#
# Usage:
#   generate_release_notes <older_tag> [optional: latest_tag]
#
# Parameters:
#   <older_tag>: The tag or branch to start the log from.
#   [optional: latest_tag]: (default 'main' or 'master') The tag or branch to end the log at.
#
# Prerequisites:
# - The script must be run inside a Git repository.
# - 'pbcopy' must be available on the system (macOS default clipboard utility).
#
# Example:
#   generate_release_notes v1.0.0 v1.1.0
#   generate_release_notes v1.0.0
#
# The prompt for AI will be prepared and copied to the clipboard for further processing.
# Note: The script handles color codes for output messages.
##################################

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
check_branch_exists() {
    if ! git show-ref --verify --quiet "refs/heads/$1"; then
        echo -e "${RED}Error: Branch '$1' does not exist.${NC}"
        exit 1
    fi
}

if [ "$#" -lt 1 ]; then
    echo -e "${YELLOW}Usage: $0 <older_tag> [optional: latest_tag]${NC}"
    exit 1
fi

older_tag=$1

if [ "$#" -eq 2 ]; then
    latest_tag=$2
    check_tag_exists "$latest_tag" || check_branch_exists "$latest_tag"
else
    # Default to 'main' or 'master' if not provided
    if git show-ref --quiet --verify "refs/heads/main"; then
        latest_tag="main"
    elif git show-ref --quiet --verify "refs/heads/master"; then
        latest_tag="master"
    else
        echo -e "${RED}Error: Neither 'main' nor 'master' branch exist.${NC}"
        exit 1
    fi
fi

check_git
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
echo "$gpt_prompt" | pbcopy

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to copy the AI prompt to the clipboard.${NC}"
    exit 1
fi
echo -e "${GREEN}AI prompt with information has been copied to the clipboard.${NC}"
