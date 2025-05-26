#!/bin/bash

##################################
# README
##################################
# This script generates a Slack-ready changelog prompt from Git commit messages.
# You provide two Git tags or branches. The script fetches commit logs, formats
# them for AI input (e.g., ChatGPT), and copies the result to your clipboard.
#
# Usage:
#   generate-release-prompt-slack <older_tag> [latest_tag] [version] [--debug|-v]
#
# Parameters:
#   <older_tag>: The tag or branch to start the log from.
#   [latest_tag]: (default 'main' or 'master') The tag or branch to end the log at.
#   [version]: (optional) The version number for the release. If not provided, defaults to the value of latest_tag.
#
# Prerequisites:
# - The script must be run inside a Git repository.
# - 'pbcopy' must be available on the system (macOS default clipboard utility).
#
# Example:
#   generate-release-prompt-slack v1.2.0 v1.3.0 1.0.0
#   generate-release-prompt-slack v1.2.0 v1.3.0    # uses v1.3.0 as version
#   generate-release-prompt-slack v1.2.0    # defaults to main, uses main as version
##################################

set -e
set -o pipefail
IFS=$'\n'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEBUG=false

for arg in "$@"; do
    case $arg in
        --debug|-v)
            DEBUG=true
            ;;
    esac
done

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

if $DEBUG; then
    trap error_trace ERR
fi

check_git() {
    git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
        echo -e "${RED}Not a Git repo.${NC}"
        exit 1
    }
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

# Get CLI input
if [ "$#" -lt 1 ]; then
    echo -e "${YELLOW}Usage: $0 <older_tag> [optional: latest_tag] [optional: version (defaults to latest_tag)] [--debug|-v]${NC}"
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
check_tag_or_branch_exists "$older_tag"

# Check if version is provided as third parameter
if [ "$#" -ge 3 ] && [[ "$3" != --* ]] && [[ "$3" != -* ]]; then
    versie=$3
else
  read -p "Welke versie wordt er released? (bijv. 13.0.0): " versie
fi

# Prompt for release day
read -p "Welke dag komt deze release live? (bijv. Woensdag): " releasedag

echo -e "${YELLOW}Release dag: ${releasedag}${NC}"
# Prompt base
slack_prompt="Zet onderstaande changelog om in een Slack update voor collega's van ons WMS-systeem.

Gebruik dit format:
- Start met: \`@here ${releasedag} komt er weer een update richting het WMS versie ${versie}!\`
- Gebruik deze secties:
  :rocket: *Nieuwe Functionaliteiten*
  :wrench: *Verbeteringen*
  :arrows_counterclockwise: *Overige Updates*
- Schrijf begrijpelijk voor operationele teams zoals magazijn of support.
- Wees kort, noem eventueel waarom iets belangrijk is.

Changelog (commit messages):
\`\`\`
"

echo -e "${YELLOW}Generating changelog from ${older_tag} to ${latest_tag}${NC}"
# Save the current 'set -e' state and temporarily disable it
set +e
git_log=$(git --no-pager log --pretty=format:"- %B" ${older_tag}..${latest_tag} 2>/dev/null)
git_exit_code=$?
# Restore the previous 'set -e' state
set -e

if [ $git_exit_code -ne 0 ]; then
    echo -e "${RED}Error: Failed to get git log from ${older_tag} to ${latest_tag}.${NC}"
    echo -e "${RED}Make sure both ${older_tag} and ${latest_tag} exist and are valid references.${NC}"
    exit 1
fi

if [ -z "$git_log" ]; then
    echo -e "${YELLOW}Warning: No commits found between ${older_tag} and ${latest_tag}.${NC}"
    slack_prompt+="No commits found between ${older_tag} and ${latest_tag}."
else
    slack_prompt+=$(echo "$git_log" | grep -v "Merge branch")
fi
slack_prompt+="\`\`\`"

echo -e "${YELLOW}Generated Slack prompt:${NC}"
echo "$slack_prompt"
# Copy the release notes to clipboard
if command -v pbcopy >/dev/null 2>&1; then
    echo "$slack_prompt" | pbcopy
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to copy the AI prompt to the clipboard.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Slack prompt copied to clipboard!${NC}"
else
    echo "$slack_prompt" > slack_prompt.txt
    echo -e "${YELLOW}pbcopy not found. Prompt saved to slack_prompt.txt${NC}"
fi
