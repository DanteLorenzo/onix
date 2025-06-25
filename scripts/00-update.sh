#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Detecting system type...${NC}"

if [ -f /etc/debian_version ]; then
    echo -e "${GREEN}Debian-based system detected${NC}"
    echo -e "${GREEN}Updating package list...${NC}"
    sudo apt update
    echo -e "${GREEN}Upgrading installed packages...${NC}"
    sudo apt upgrade -y
    echo -e "${GREEN}Performing full system upgrade...${NC}"
    sudo apt full-upgrade -y
    echo -e "${GREEN}Removing unused packages...${NC}"
    sudo apt autoremove -y
    echo -e "${GREEN}Cleaning up cache...${NC}"
    sudo apt clean
elif [ -f /etc/arch-release ]; then
    echo -e "${GREEN}Arch Linux-based system detected${NC}"
    echo -e "${GREEN}Updating system and all packages...${NC}"
    sudo pacman -Syu --noconfirm
    echo -e "${GREEN}Cleaning up package cache...${NC}"
    sudo pacman -Sc --noconfirm
else
    echo -e "${RED}Could not detect system type. This script supports only Debian/Ubuntu and Arch Linux!${NC}"
    exit 1
fi

echo -e "${GREEN}System update complete!${NC}"
exit 0 