#!/bin/bash
set -e
IFS=$'\n'

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Stop and remove all Docker containers
docker stop $(docker ps -aq)

if [ $? -eq 0 ]; then
  echo -e "${GREEN}All Docker containers have been stopped${NC}"
else
  echo -e "${RED}Failed to stop some Docker containers${NC}"
fi