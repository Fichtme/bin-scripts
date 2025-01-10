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
set -o pipefail  # Exit immediately if any command in a pipeline fails
IFS=$'\n'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Debug flag
DEBUG=false

# Parse input arguments for --debug or -v
for arg in "$@"; do
    case $arg in
        --debug|-v)
            DEBUG=true
            ;;
    esac
done

# Error handling - print the trace on error
error_trace() {
    local cmd="$BASH_COMMAND" # Capture the failed command
    if $DEBUG; then
        echo -e "${RED}Error: Command '${cmd}' failed.${NC}" >&2
        echo -e "${RED}Traceback (most recent calls):${NC}" >&2
        local i=0
        while caller $i; do
            ((i++))
        done
    else
        echo -e "${RED}An error occurred. Use --debug or -v for more details.${NC}" >&2
    fi
    exit 1
}

# Attach the error_trace function to ERR signal only if DEBUG is enabled
if $DEBUG; then
    trap error_trace ERR
fi

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

# Check if the tag or branch exists
check_tag_or_branch_exists() {
    if git rev-parse --quiet --verify "refs/tags/$1" >/dev/null 2>&1; then
        return 0  # It's a tag
    elif git show-ref --verify --quiet "refs/heads/$1"; then
        return 0  # It's a branch
    else
        echo -e "${RED}Error: Neither tag nor branch '$1' exists.${NC}"
        return 1  # Not found as tag or branch
    fi
}

if [ "$#" -lt 1 ]; then
    echo -e "${YELLOW}Usage: $0 <older_tag> [optional: latest_tag] [--debug|-v]${NC}"
    exit 1
fi

older_tag=$1

if [ "$#" -ge 2 ]; then
    latest_tag=$2
    check_tag_or_branch_exists "$latest_tag"
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
gpt_prompt="Generate detailed release notes in Markdown format based on the following Git log.
The release notes must have the following **three sections** in this order:
1. **New Features**
2. **Improvements**
3. **Other Changes**

Markdown formatting rules:
- Use proper headings (`####`) for each section.
- Each change should be listed as a bullet point starting with a **bold title**, followed by a short description.
- If there are no items for a section, include the section with the text 'No changes in this category.'

Example output:
#### New Features
- **Mail Branding** - Mail service has been updated to support brand color customization.

#### Improvements
- **Performance Optimization** - Reduced database query times to improve response latency.

#### Other Changes
- **Typo Fixes** - Corrected typos in user-visible error messages.

Below are the Git commit messages between the tags ${older_tag} and ${latest_tag}, excluding merge commits:
"

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
