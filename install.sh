#!/usr/bin/env bash

set -e

INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ask"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ask"
REPO_URL="https://raw.githubusercontent.com/elias-ba/ask/main/ask"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
cat <<'EOF'
            _    
   __ _ ___| | __
  / _` / __| |/ /
 | (_| \__ \   < 
  \__,_|___/_|\_\
  
ask - ai powered shell assistant
EOF
echo -e "${NC}"

if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
    echo -e "${YELLOW}Installing system-wide to $INSTALL_DIR${NC}"
else
    if [ -w "/usr/local/bin" ]; then
        INSTALL_DIR="/usr/local/bin"
        echo -e "${GREEN}Installing to $INSTALL_DIR${NC}"
    else
        INSTALL_DIR="$HOME/.local/bin"
        echo -e "${YELLOW}No write access to /usr/local/bin${NC}"
        echo -e "${GREEN}Installing to $INSTALL_DIR${NC}"
        mkdir -p "$INSTALL_DIR"
    fi
fi

echo -e "\n${CYAN}Checking dependencies...${NC}"
missing_deps=()

for cmd in curl jq; do
    if ! command -v "$cmd" &> /dev/null; then
        missing_deps+=("$cmd")
    else
        echo -e "  ${GREEN}✓${NC} $cmd"
    fi
done

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo -e "\n${RED}Missing dependencies: ${missing_deps[*]}${NC}"
    echo -e "\nInstall them with:"
    echo -e "  ${YELLOW}Ubuntu/Debian:${NC} sudo apt-get install ${missing_deps[*]}"
    echo -e "  ${YELLOW}macOS:${NC}        brew install ${missing_deps[*]}"
    echo -e "  ${YELLOW}Fedora:${NC}       sudo dnf install ${missing_deps[*]}"
    echo -e "  ${YELLOW}Arch:${NC}         sudo pacman -S ${missing_deps[*]}"
    exit 1
fi

echo -e "\n${CYAN}Downloading ask...${NC}"
if curl -fsSL "$REPO_URL" -o "$INSTALL_DIR/ask"; then
    echo -e "${GREEN}✓ Downloaded successfully${NC}"
else
    echo -e "${RED}✗ Download failed${NC}"
    exit 1
fi

chmod +x "$INSTALL_DIR/ask"
echo -e "${GREEN}✓ Made executable${NC}"

echo -e "\n${CYAN}Setting up configuration...${NC}"
mkdir -p "$CONFIG_DIR" "$CACHE_DIR"
echo -e "${GREEN}✓ Created config directories${NC}"

cat > "$CONFIG_DIR/functions.sh" <<'EOF'
# ask generated functions
# Source this file: source ~/.config/ask/functions.sh
# Or add to your ~/.bashrc: source ~/.config/ask/functions.sh

EOF
echo -e "${GREEN}✓ Created functions file${NC}"

echo -e "\n${CYAN}Checking PATH...${NC}"
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo -e "${YELLOW}Warning: $INSTALL_DIR is not in your PATH${NC}"
    echo -e "\nAdd this to your ~/.bashrc or ~/.zshrc:"
    echo -e "  ${CYAN}export PATH=\"$INSTALL_DIR:\$PATH\"${NC}"
else
    echo -e "${GREEN}✓ $INSTALL_DIR is in PATH${NC}"
fi

echo -e "\n${CYAN}Verifying installation...${NC}"
if "$INSTALL_DIR/ask" --version &> /dev/null; then
    echo -e "${GREEN}✓ ask installed successfully!${NC}"
else
    echo -e "${RED}✗ Installation verification failed${NC}"
    exit 1
fi

echo -e "\n${CYAN}Checking API keys...${NC}"
keys_found=false

if [ -n "$ANTHROPIC_API_KEY" ]; then
    echo -e "${GREEN}✓ ANTHROPIC_API_KEY is set${NC}"
    keys_found=true
fi

if [ -n "$OPENAI_API_KEY" ]; then
    echo -e "${GREEN}✓ OPENAI_API_KEY is set${NC}"
    keys_found=true
fi

if [ -n "$OPENROUTER_API_KEY" ]; then
    echo -e "${GREEN}✓ OPENROUTER_API_KEY is set${NC}"
    keys_found=true
fi

if [ "$keys_found" = false ]; then
    echo -e "${YELLOW}⚠ No API keys found${NC}"
    echo -e "\n${BOLD}Set up your API key:${NC}"
    echo -e "  ${CYAN}ask keys set anthropic${NC}     # For Anthropic Claude"
    echo -e "  ${CYAN}ask keys set openai${NC}        # For OpenAI GPT"
    echo -e "  ${CYAN}ask keys set openrouter${NC}    # For OpenRouter"
    echo -e "\n${DIM}Get API keys:${NC}"
    echo -e "  ${DIM}Anthropic:  https://console.anthropic.com/${NC}"
    echo -e "  ${DIM}OpenAI:     https://platform.openai.com/api-keys${NC}"
    echo -e "  ${DIM}OpenRouter: https://openrouter.ai/keys${NC}"
fi

echo -e "\n${GREEN}${BOLD}🎉 Installation complete!${NC}\n"
echo -e "${BOLD}Next steps:${NC}"
echo -e "  1. Set up your API key:"
echo -e "     ${CYAN}ask keys set anthropic${NC}"
echo -e ""
echo -e "  2. Try your first query:"
echo -e "     ${CYAN}ask \"your question\"${NC}"
echo -e ""
echo -e "${BOLD}Quick examples:${NC}"
echo -e "  ${CYAN}ask \"how do I find large files?\"${NC}"
echo -e "  ${CYAN}git diff | ask \"explain changes\"${NC}"
echo -e "  ${CYAN}ask --agent \"optimize PNGs in ./images\"${NC}"
echo -e "  ${CYAN}ask commit${NC}                 # Generate git commit message"
echo -e ""
echo -e "${BOLD}Get help:${NC}"
echo -e "  ${CYAN}ask --help${NC}                 # Show all options"
echo -e "  ${CYAN}ask keys list${NC}              # View configured keys"
echo -e "\n${BOLD}don't grep. don't awk. just ask${NC}\n"