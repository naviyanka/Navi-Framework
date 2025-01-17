#!/bin/bash

# Colors for output
RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Test directory
TEST_DIR="./test_results"
WORDLIST_DIR="./wordlists"

# Create necessary directories
function setup_environment() {
    echo -e "${CYAN}[INFO] Setting up test environment...${NC}"
    mkdir -p "$TEST_DIR"
    mkdir -p "$WORDLIST_DIR"
    
    # Create basic resolvers.txt
    echo "8.8.8.8
8.8.4.4
1.1.1.1
1.0.0.1" > "${WORDLIST_DIR}/resolvers.txt"
}

# Test basic script functionality
function test_basic_functionality() {
    echo -e "\n${CYAN}[TEST] Testing basic functionality...${NC}"
    
    # Test syntax first
    echo -e "${CYAN}[INFO] Checking script syntax...${NC}"
    bash -n naviconsole.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[PASS] Script syntax is valid${NC}"
    else
        echo -e "${RED}[FAIL] Script has syntax errors${NC}"
        # Show the problematic section
        echo -e "${YELLOW}[DEBUG] Showing lines around the error:${NC}"
        sed -n '392,402p' naviconsole.sh
        return 1
    fi
    
    # Test help menu
    echo -e "${CYAN}[INFO] Testing help menu...${NC}"
    ./naviconsole.sh --help
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[PASS] Help menu works${NC}"
    else
        echo -e "${RED}[FAIL] Help menu failed${NC}"
    fi
    
    # Test invalid argument
    echo -e "${CYAN}[INFO] Testing invalid argument handling...${NC}"
    ./naviconsole.sh -x 2>/dev/null
    if [ $? -eq 1 ]; then
        echo -e "${GREEN}[PASS] Invalid argument handling works${NC}"
    else
        echo -e "${RED}[FAIL] Invalid argument handling failed${NC}"
    fi
}

# Test tool availability
function test_tool_availability() {
    echo -e "\n${CYAN}[TEST] Checking required tools...${NC}"
    local tools=("subfinder" "amass" "ffuf" "gobuster" "nuclei" "httpx" "dnsx" "gospider" "waybackurls" "gau" "jq" "anew")
    local missing=0
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo -e "${RED}[MISSING] $tool is not installed${NC}"
            missing=$((missing + 1))
        else
            echo -e "${GREEN}[FOUND] $tool is installed${NC}"
        fi
    done
    
    return $missing
}

# Test with a real domain
function test_real_domain() {
    echo -e "\n${CYAN}[TEST] Testing with example.com...${NC}"
    
    # Test with verbose mode
    ./naviconsole.sh -d example.com -v
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[PASS] Verbose mode test completed${NC}"
    else
        echo -e "${RED}[FAIL] Verbose mode test failed${NC}"
    fi
}

# Main test execution
echo -e "${CYAN}Starting Navi Framework Test Suite${NC}"
echo -e "${YELLOW}================================${NC}\n"

# Make script executable
chmod +x naviconsole.sh

# Run tests
setup_environment
test_basic_functionality
test_tool_availability
if [ $? -eq 0 ]; then
    test_real_domain
else
    echo -e "${RED}[ERROR] Missing required tools. Please install them before running the main script.${NC}"
    exit 1
fi 