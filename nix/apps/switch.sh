#!/bin/sh -e

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SYSTEM=$(uname -m)

case "$SYSTEM" in
  x86_64)
    FLAKE_TARGET="x86_64-linux"
    ;;
  aarch64)
    FLAKE_TARGET="aarch64-linux"
    ;;
  *)
    echo -e "${RED}Unsupported architecture: $SYSTEM${NC}"
    exit 1
    ;;
esac

echo -e "${YELLOW}Starting...${NC}"

# We pass SSH from user to root so root can download secrets from our private Github
sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK /run/current-system/sw/bin/nixos-rebuild switch --flake .#$FLAKE_TARGET $@

echo -e "${GREEN}Switch to new generation complete!${NC}"
