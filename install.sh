#!/bin/bash

# Navi Framework - Tool Checker and Installer
# Author: EthicalHackerGPT
# Version: 1.1

# Define the list of required tools
REQUIRED_TOOLS=(
    "subfinder"
    "amass"
    "sublist3r"
    "assetfinder"
    "crobat"
    "httpx"
    "dnsx"
    "nuclei"
    "dalfox"
    "kxss"
    "gf"
    "crlfuzz"
    "ffuf"
    "gospider"
    "waybackurls"
    "gau"
    "gauplus"
    "hakrawler"
    "unfurl"
    "scripthunter"
    "notify"
)

# Set Go binary path
GO_BIN_PATH="/root/go-workspace/bin"
export PATH="$GO_BIN_PATH:$PATH"

# Check if a tool is installed
function check_tool() {
    local tool="$1"
    if command -v "$tool" &>/dev/null; then
        echo -e "✔️  $tool is installed."
        return 0
    else
        echo -e "❌ $tool is missing."
        return 1
    fi
}

# Install a Go-based tool
function install_go_tool() {
    local tool_name="$1"
    local install_command="$2"
    echo -e "Installing $tool_name..."
    eval "$install_command"
    if command -v "$tool_name" &>/dev/null; then
        echo -e "✔️  $tool_name installed successfully."
    else
        echo -e "❌ Failed to install $tool_name. Check your setup."
    fi
}

# Install tools function
function install_tools() {
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            case $tool in
                "subfinder")
                    install_go_tool "subfinder" "GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" ;;
                "amass")
                    install_go_tool "amass" "GO111MODULE=on go install -v github.com/owasp-amass/amass/v3/...@latest" ;;
                "assetfinder")
                    install_go_tool "assetfinder" "go install github.com/tomnomnom/assetfinder@latest" ;;
                "crobat")
                    install_go_tool "crobat" "go install github.com/cgboal/sonarsearch/cmd/crobat@latest" ;;
                "httpx")
                    install_go_tool "httpx" "GO111MODULE=on go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest" ;;
                "dnsx")
                    install_go_tool "dnsx" "GO111MODULE=on go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest" ;;
                "nuclei")
                    install_go_tool "nuclei" "GO111MODULE=on go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest" ;;
                "dalfox")
                    install_go_tool "dalfox" "GO111MODULE=on go install -v github.com/hahwul/dalfox/v2@latest" ;;
                "kxss")
                    install_go_tool "kxss" "go install github.com/Emoe/kxss@latest" ;;
                "gf")
                    install_go_tool "gf" "go install github.com/tomnomnom/gf@latest && cp -r /root/go/pkg/mod/github.com/tomnomnom/gf*/examples ~/.gf" ;;
                "crlfuzz")
                    install_go_tool "crlfuzz" "go install github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest" ;;
                "ffuf")
                    install_go_tool "ffuf" "GO111MODULE=on go install -v github.com/ffuf/ffuf@latest" ;;
                "gospider")
                    install_go_tool "gospider" "GO111MODULE=on go install github.com/jaeles-project/gospider@latest" ;;
                "waybackurls")
                    install_go_tool "waybackurls" "go install github.com/tomnomnom/waybackurls@latest" ;;
                "gau")
                    install_go_tool "gau" "GO111MODULE=on go install github.com/lc/gau/v2/cmd/gau@latest" ;;
                "gauplus")
                    install_go_tool "gauplus" "GO111MODULE=on go install github.com/bp0lr/gauplus@latest" ;;
                "hakrawler")
                    install_go_tool "hakrawler" "GO111MODULE=on go install github.com/hakluke/hakrawler@latest" ;;
                "unfurl")
                    install_go_tool "unfurl" "go install github.com/tomnomnom/unfurl@latest" ;;
                "scripthunter")
                    install_go_tool "scripthunter" "git clone https://github.com/robre/scripthunter.git && cd scripthunter && go build && mv scripthunter $GO_BIN_PATH" ;;
                "notify")
                    install_go_tool "notify" "GO111MODULE=on go install -v github.com/projectdiscovery/notify/cmd/notify@latest" ;;
                *)
                    echo -e "⚠️  Installation command not defined for $tool."
                    ;;
            esac
        fi
    done
}

# Main script
function main() {
    echo -e "\nChecking for required tools...\n"

    # Check all tools
    missing_tools=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! check_tool "$tool"; then
            missing_tools+=("$tool")
        fi
    done

    # Prompt to install missing tools
    if [ "${#missing_tools[@]}" -eq 0 ]; then
        echo -e "\nAll required tools are already installed. 🎉"
    else
        echo -e "\nThe following tools are missing:"
        for tool in "${missing_tools[@]}"; do
            echo -e "  - $tool"
        done

        read -rp "Would you like to install the missing tools? [y/N]: " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            install_tools
        else
            echo -e "Skipping tool installation. Some functionality may not work."
        fi
    fi
}
# Download wordlists
function wordlistsd() {
    local target_dir="$1/wordlists"
    mkdir -p "$target_dir"
    echo -e "\n${BK}DOWNLOADING ALL THE WORDLISTS${RT}"
    cd "$target_dir" || exit
    
    echo -e "\n- Downloading subdomains wordlists"
    wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/deepmagic.com-prefixes-top50000.txt -O subdomains.txt
    if [ -s subdomains.txt ]; then
        echo -e "${GR}SUCCESS${RT}"
    else
        echo -e "${YW}FAILED${RT}"
    fi
    
    echo -e "\n- Downloading resolvers wordlists"
    wget -q https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -O resolvers.txt
    if [ -s resolvers.txt ]; then
        echo -e "${GR}SUCCESS${RT}"
    else
        echo -e "${YW}FAILED${RT}"
    fi
    
    echo -e "\n- Downloading fuzz wordlists"
    wget -q https://raw.githubusercontent.com/Bo0oM/fuzz.txt/master/fuzz.txt -O fuzz.txt
    if [ -s fuzz.txt ]; then
        echo -e "${GR}SUCCESS${RT}"
    else
        echo -e "${YW}FAILED${RT}"
    fi
}

# Example usage of wordlistsd function
TARGET_DIR="/root/navi"
wordlistsd "$TARGET_DIR"
main
