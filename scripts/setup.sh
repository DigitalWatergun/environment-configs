#!/bin/bash

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the repo directory (works whether run from repo root or scripts/)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If script is in scripts/ directory, go up one level to get repo root
if [[ "$SCRIPT_DIR" == */scripts ]]; then
    REPO_DIR="$(dirname "$SCRIPT_DIR")"
else
    # Script was moved or run from repo root, use current directory
    REPO_DIR="$SCRIPT_DIR"
fi

echo -e "${GREEN}Starting environment setup...${NC}\n"

# Update Oh My Zsh local copy if possible (whether installed or not)
echo -e "${YELLOW}Attempting to update Oh My Zsh local copy...${NC}"
if git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$REPO_DIR/ohmyzsh/ohmyzsh.tmp" 2>/dev/null; then
    echo -e "${GREEN}Successfully cloned latest Oh My Zsh, updating local copy...${NC}"
    rm -rf "$REPO_DIR/ohmyzsh/ohmyzsh.tmp/.git"
    rm -rf "$REPO_DIR/ohmyzsh/ohmyzsh"
    mv "$REPO_DIR/ohmyzsh/ohmyzsh.tmp" "$REPO_DIR/ohmyzsh/ohmyzsh"
else
    echo -e "${YELLOW}Could not clone Oh My Zsh (using existing local copy)${NC}"
fi

# Install Oh My Zsh if it doesn't exist
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${YELLOW}Oh My Zsh already installed, skipping installation...${NC}\n"
else
    echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
    if [ -d "$REPO_DIR/ohmyzsh/ohmyzsh" ]; then
        cp -r "$REPO_DIR/ohmyzsh/ohmyzsh" "$HOME/.oh-my-zsh"
        echo -e "${GREEN}Oh My Zsh installed from local repository${NC}\n"
    else
        echo -e "${RED}ERROR: Local Oh My Zsh copy not found!${NC}\n"
        exit 1
    fi
fi

# Update Powerlevel10k local copy if possible (whether installed or not)
echo -e "${YELLOW}Attempting to update Powerlevel10k local copy...${NC}"
if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$REPO_DIR/p10k/powerlevel10k.tmp" 2>/dev/null; then
    echo -e "${GREEN}Successfully cloned latest Powerlevel10k, updating local copy...${NC}"
    rm -rf "$REPO_DIR/p10k/powerlevel10k.tmp/.git"
    rm -rf "$REPO_DIR/p10k/powerlevel10k"
    mv "$REPO_DIR/p10k/powerlevel10k.tmp" "$REPO_DIR/p10k/powerlevel10k"
else
    echo -e "${YELLOW}Could not clone Powerlevel10k (using existing local copy)${NC}"
fi

# Install Powerlevel10k if it doesn't exist
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if [ -d "$P10K_DIR" ]; then
    echo -e "${YELLOW}Powerlevel10k already installed, skipping installation...${NC}\n"
else
    echo -e "${YELLOW}Installing Powerlevel10k...${NC}"
    if [ -d "$REPO_DIR/p10k/powerlevel10k" ]; then
        mkdir -p "$(dirname "$P10K_DIR")"
        cp -r "$REPO_DIR/p10k/powerlevel10k" "$P10K_DIR"
        echo -e "${GREEN}Powerlevel10k installed from local repository${NC}\n"
    else
        echo -e "${RED}ERROR: Local Powerlevel10k copy not found!${NC}\n"
        exit 1
    fi
fi

# Copy Zsh configuration
echo -e "${YELLOW}Setting up Zsh configuration...${NC}"
cp "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
echo -e "${GREEN}Zsh configuration copied${NC}\n"

# Copy Powerlevel10k configuration
echo -e "${YELLOW}Setting up Powerlevel10k configuration...${NC}"
cp "$REPO_DIR/p10k/p10k.zsh" "$HOME/.p10k.zsh"
echo -e "${GREEN}Powerlevel10k configuration copied${NC}\n"

# Copy Tmux configuration
echo -e "${YELLOW}Setting up Tmux configuration...${NC}"
cp "$REPO_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
echo -e "${GREEN}Tmux configuration copied${NC}\n"

# Copy Neovim configuration
echo -e "${YELLOW}Setting up Neovim configuration...${NC}"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
mkdir -p "$NVIM_CONFIG_DIR"
cp "$REPO_DIR/nvim/init.lua" "$NVIM_CONFIG_DIR/init.lua"
echo -e "${GREEN}Neovim configuration copied${NC}\n"

# Copy Alacritty configuration
echo -e "${YELLOW}Setting up Alacritty configuration...${NC}"
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"
cp "$REPO_DIR/alacritty/alacritty.toml" "$ALACRITTY_CONFIG_DIR/alacritty.toml"
echo -e "${GREEN}Alacritty configuration copied${NC}\n"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Restart your terminal or run: ${GREEN}source ~/.zshrc${NC}"
echo -e "2. Install Tmux manually if not already installed"
echo -e "3. Install Neovim manually if not already installed"
echo -e "4. Install Alacritty manually if not already installed"
