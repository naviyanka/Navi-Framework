#!/bin/bash

# Navi Framework - Recon & Vulnerability Scanning
# Version: 2.0

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# Global Variables
DOMAIN=""
VERBOSE=false
BASE_DIR="./results"
WORDLIST_DIR="./wordlists"
TARGET_DIR=""
SESSION_FILE=""
SKIP_TOOL=false
SKIP_FUNCTION=false

# Default Configuration
CONFIG_FILE="config.conf"
DEFAULT_THREADS=10
DEFAULT_TIMEOUT=30
DEFAULT_RETRIES=3

# Load Configuration
function load_configuration() {
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${CYAN}[INFO] Loading configuration from $CONFIG_FILE${NC}"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        echo -e "${YELLOW}[WARNING] Configuration file not found, using defaults${NC}"
        cat > "$CONFIG_FILE" <<EOL
# Navi Framework Configuration
THREADS=$DEFAULT_THREADS
TIMEOUT=$DEFAULT_TIMEOUT
RETRIES=$DEFAULT_RETRIES
WORDLIST_DIR="./wordlists"
BASE_DIR="./results"
EOL
    fi
}

# ASCII Art Banner
function show_banner() {
    clear
    echo -e "${CYAN}"
    echo -e "███╗   ██╗ █████╗ ██╗   ██╗██╗"
    echo -e "████╗  ██║██╔══██╗██║   ██║██║"
    echo -e "██╔██╗ ██║███████║██║   ██║██║"
    echo -e "██║╚██╗██║██╔══██║╚██╗ ██╔╝██║"
    echo -e "██║ ╚████║██║  ██║ ╚████╔╝ ██║"
    echo -e "╚═╝  ╚═══╝╚═╝  ╚═╝  ╚═══╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${CYAN}Navi Framework - Recon & Vulnerability Scanning${NC}\n"
}

# Usage Instructions
function show_usage() {
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  naviconsole.sh [-d target.tld] [-v] [--help]"
    echo -e "\nOptions:"
    echo -e "  -d, --domain      Target domain (e.g., example.com)"
    echo -e "  -v, --verbose     Enable verbose mode"
    echo -e "  -h, --help        Show this help message"
    echo -e ""
}

# Initialize Session
function initialize_session() {
    TARGET_DIR="${BASE_DIR}/${DOMAIN}"
    SESSION_FILE="${TARGET_DIR}/session_state.txt"
    mkdir -p "$TARGET_DIR"

    # Initialize session state if not already present
    if [ ! -f "$SESSION_FILE" ]; then
        echo "subdomain_enumeration=false" >"$SESSION_FILE"
        echo "web_probing=false" >>"$SESSION_FILE"
        echo "crawling=false" >>"$SESSION_FILE"
        echo "vulnerability_scanning=false" >>"$SESSION_FILE"
        echo "directory_fuzzing=false" >>"$SESSION_FILE"
    fi
}

# Update Session State
function update_session() {
    local step="$1"
    sed -i "s/^${step}=false/${step}=true/" "$SESSION_FILE"
}

# Check if Step is Completed
function is_step_completed() {
    local step="$1"
    grep "^${step}=true" "$SESSION_FILE" &>/dev/null
}

# Ctrl+C Handling
function ctrl_c() {
    echo -e "\n\n${YELLOW}[!] Detected keyboard interruption.${NC}"
    read -rp "Skip current tool, skip current function, or quit? (tool/function/quit): " choice
    case $choice in
        tool)
            echo -e "${CYAN}[INFO] Skipping current tool...${NC}"
            SKIP_TOOL=true
            kill -9 "$CURRENT_TOOL_PID" 2>/dev/null  # Terminate the current tool process
            ;;
        function)
            echo -e "${CYAN}[INFO] Skipping current function...${NC}"
            SKIP_FUNCTION=true ;;
        quit)
            echo -e "${RED}[INFO] Quitting the framework...${NC}"
            exit 1 ;;
        *)
            echo -e "${RED}[INFO] Invalid choice. Continuing...${NC}" ;;
    esac
}

# Trap Ctrl+C
trap ctrl_c INT

# Enhanced Run Tool Function
function run_tool() {
    local cmd="$1"
    local tool_name="$2"
    local log_file="${TARGET_DIR}/logs/${tool_name}.log"
    
    mkdir -p "${TARGET_DIR}/logs"
    
    echo -e "${CYAN}[INFO] Running $tool_name...${NC}"
    
    if $VERBOSE; then
        eval "$cmd" 2>&1 | tee -a "$log_file" &
    else
        eval "$cmd" > "$log_file" 2>&1 &
    fi
    
    CURRENT_TOOL_PID=$!
    
    # Show spinner while tool is running
    local spin='-\|/'
    local i=0
    while kill -0 $CURRENT_TOOL_PID 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${YELLOW}[RUNNING] %s ${spin:$i:1}${NC}" "$tool_name"
        sleep .1
    done
    
    wait $CURRENT_TOOL_PID
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "\r${RED}[ERROR] $tool_name failed. Check logs at: $log_file${NC}"
        if $SKIP_TOOL; then
            SKIP_TOOL=false
            return 1
        fi
        return $exit_code
    fi
    
    echo -e "\r${GREEN}[SUCCESS] $tool_name completed successfully${NC}"
    return 0
}

# Check Required Tools
function check_required_tools() {
    local tools=("subfinder" "amass" "ffuf" "gobuster" "nuclei" "httpx" "dnsx" "gospider" "waybackurls" "gau" "jq" "anew")
    local missing_tools=()
    
    echo -e "${CYAN}[INFO] Checking required tools...${NC}"
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}[ERROR] Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Please install the missing tools before running the script.${NC}"
        exit 1
    fi
    echo -e "${GREEN}[SUCCESS] All required tools are installed.${NC}"
}

# Subdomain Enumeration
function subdomain_enumeration() {
    if is_step_completed "subdomain_enumeration"; then
        echo -e "${CYAN}[INFO] Subdomain enumeration already completed. Skipping.${NC}"
        return
    fi

    echo -e "${CYAN}Starting subdomain enumeration for: ${DOMAIN}${NC}"

    # Temporary directory for intermediate files
    TMP_DIR="${TARGET_DIR}/.tmp"
    mkdir -p "$TMP_DIR"

    # Passive Subdomain Enumeration with rate limiting and retry logic
    echo -e "${GREEN}[INFO] Performing passive subdomain enumeration...${NC}"
    
    # Add delay between API calls to prevent rate limiting
    local API_DELAY=2
    
    # crt.sh with retry logic
    for i in $(seq 1 $DEFAULT_RETRIES); do
        if run_tool "curl -s --max-time $DEFAULT_TIMEOUT 'https://crt.sh/?q=%25.$DOMAIN&output=json' | jq -r '.[].name_value' | sed 's/\\*\\.//g' | anew -q $TMP_DIR/crtsh.txt" "crt.sh"; then
            break
        fi
        echo -e "${YELLOW}[WARNING] Retry $i for crt.sh...${NC}"
        sleep $API_DELAY
    done
    
    sleep $API_DELAY
    
    # HackerTarget with retry logic
    for i in $(seq 1 $DEFAULT_RETRIES); do
        if run_tool "curl -s --max-time $DEFAULT_TIMEOUT 'https://api.hackertarget.com/hostsearch/?q=$DOMAIN' | awk -F, '{print \$1}' | anew -q $TMP_DIR/hackertarget.txt" "hackertarget"; then
            break
        fi
        echo -e "${YELLOW}[WARNING] Retry $i for hackertarget...${NC}"
        sleep $API_DELAY
    done

    # Active tools with parallel processing and timeout
    echo -e "${GREEN}[INFO] Performing active subdomain enumeration...${NC}"
    
    # Run multiple tools in parallel with proper resource management
    {
        run_tool "subfinder -d $DOMAIN -t $DEFAULT_THREADS -timeout $DEFAULT_TIMEOUT -silent -o $TMP_DIR/subfinder.txt" "subfinder"
    } &
    
    {
        run_tool "amass enum -passive -d $DOMAIN -timeout $DEFAULT_TIMEOUT -o $TMP_DIR/amass_passive.txt" "amass_passive"
    } &
    
    # Wait for parallel processes to complete
    wait

    # Merge results with duplicate removal and validation
    FINAL_OUTPUT="${TARGET_DIR}/${DOMAIN}_subdomains.txt"
    echo -e "${CYAN}[INFO] Merging and validating results...${NC}"
    
    # Merge all results and validate domains
    run_tool "cat $TMP_DIR/*.txt | grep -v '*' | sed '/@\\|<BR>\\|\\_/d' | grep -P '^[a-zA-Z0-9][a-zA-Z0-9.-]*\\.${DOMAIN}$' | sort -u | anew -q $FINAL_OUTPUT" "merge_results"

    # Validate final output
    if [ ! -f "$FINAL_OUTPUT" ] || [ ! -s "$FINAL_OUTPUT" ]; then
        echo -e "${RED}[ERROR] No valid subdomains found or enumeration failed${NC}"
        return 1
    fi

    echo -e "${GREEN}[SUCCESS] Found $(wc -l < "$FINAL_OUTPUT") unique subdomains${NC}"
    update_session "subdomain_enumeration"
}

# Web Probing
function web_probing_filtering() {
    local input_file="$1"

    if is_step_completed "web_probing"; then
        echo -e "${CYAN}[INFO] Web probing already completed. Skipping.${NC}"
        return
    fi

    # Validate input file
    if [ ! -f "$input_file" ] || [ ! -s "$input_file" ]; then
        echo -e "${RED}[ERROR] Invalid or empty input file: $input_file${NC}"
        return 1
    fi

    echo -e "${CYAN}Starting web probing for: ${DOMAIN}${NC}"
    
    local tmp_dir="${TARGET_DIR}/.tmp/probing"
    mkdir -p "$tmp_dir"
    
    FINAL_LIVE_FILE="${TARGET_DIR}/${DOMAIN}_livesubdomains.txt"

    # DNS resolution with retry logic
    echo -e "${GREEN}[INFO] Performing DNS resolution...${NC}"
    if ! run_tool "dnsx -l $input_file -retry $DEFAULT_RETRIES -t $DEFAULT_THREADS \
        -r ${WORDLIST_DIR}/resolvers.txt \
        -silent -a -aaaa -cname -ns \
        -o $tmp_dir/dns_resolved.txt" "dnsx"; then
        echo -e "${RED}[ERROR] DNS resolution failed${NC}"
        return 1
    fi

    # HTTP probing with advanced options
    echo -e "${GREEN}[INFO] Performing HTTP/HTTPS probing...${NC}"
    if ! run_tool "httpx -l $tmp_dir/dns_resolved.txt \
        -threads $DEFAULT_THREADS \
        -timeout $DEFAULT_TIMEOUT \
        -retry $DEFAULT_RETRIES \
        -silent \
        -title -status-code -tech-detect \
        -o $tmp_dir/http_probed.txt" "httpx"; then
        echo -e "${RED}[ERROR] HTTP probing failed${NC}"
        return 1
    fi

    # Extract live domains with status code 200
    echo -e "${CYAN}[INFO] Filtering live domains...${NC}"
    awk '$2 == 200 {print $1}' "$tmp_dir/http_probed.txt" | sort -u > "$FINAL_LIVE_FILE"

    # Validate results
    if [ ! -s "$FINAL_LIVE_FILE" ]; then
        echo -e "${RED}[ERROR] No live subdomains found${NC}"
        return 1
    fi

    echo -e "${GREEN}[SUCCESS] Found $(wc -l < "$FINAL_LIVE_FILE") live subdomains${NC}"
    update_session "web_probing"
}

# Crawling
function crawling() {
    if is_step_completed "crawling"; then
        echo -e "${CYAN}[INFO] Crawling already completed. Skipping.${NC}"
        return
    fi

    echo -e "${CYAN}Starting crawling for: ${DOMAIN}${NC}"
    INPUT_FILE="${TARGET_DIR}/${DOMAIN}_livesubdomains.txt"
    FINAL_OUTPUT="${TARGET_DIR}/${DOMAIN}_urls.txt"

    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}[ERROR] Input file not found: ${INPUT_FILE}${NC}"
        exit 1
    fi

    run_tool "gospider -S $INPUT_FILE -o ${TARGET_DIR}/gospider_output" "gospider"
    run_tool "xargs -a $INPUT_FILE waybackurls > ${TARGET_DIR}/waybackurls.txt" "xargs"
    run_tool "xargs -a $INPUT_FILE gau > ${TARGET_DIR}/gau.txt" "xargs"

    cat "${TARGET_DIR}/gospider_output" "${TARGET_DIR}/waybackurls.txt" "${TARGET_DIR}/gau.txt" | sort -u >"$FINAL_OUTPUT"
    echo -e "${GREEN}[SUCCESS] Crawling completed. Results saved to: ${FINAL_OUTPUT}${NC}"

    update_session "crawling"
}

# Vulnerability Scanning
function vulnerability_scanning() {
    if is_step_completed "vulnerability_scanning"; then
        echo -e "${CYAN}[INFO] Vulnerability scanning already completed. Skipping.${NC}"
        return
    fi

    echo -e "${CYAN}Starting vulnerability scanning for: ${DOMAIN}${NC}"
    INPUT_FILE="${TARGET_DIR}/${DOMAIN}_urls.txt"
    FINAL_OUTPUT="${TARGET_DIR}/vulnerabilities"

    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}[ERROR] Input file not found: ${INPUT_FILE}${NC}"
        exit 1
    fi

    mkdir -p "$FINAL_OUTPUT"
    run_tool "nuclei -l $INPUT_FILE -o ${FINAL_OUTPUT}/nuclei_results.txt" "nuclei"
    echo -e "${GREEN}[SUCCESS] Vulnerability scanning completed.${NC}"

    update_session "vulnerability_scanning"
}

# Cleanup Function
function cleanup() {
    local target_dir="$1"
    echo -e "${CYAN}[INFO] Cleaning up temporary files...${NC}"
    if [ -d "${target_dir}/.tmp" ]; then
        rm -rf "${target_dir}/.tmp"
    fi
}

# Error Handler
function error_handler() {
    local exit_code=$?
    local line_number=$1
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}[ERROR] Failed at line $line_number with exit code $exit_code${NC}"
        cleanup "${TARGET_DIR}"
        exit $exit_code
    fi
}

# Add error handling to script
trap 'error_handler ${LINENO}' ERR

# Main Function
function main() {
    show_banner
    
    if [ -z "$DOMAIN" ]; then
        show_usage
        exit 1
    fi
    
    # Load configuration and check tools
    load_configuration
    check_required_tools
    
    # Create results directory
    initialize_session
    
    # Main workflow
    subdomain_enumeration
    web_probing_filtering "${TARGET_DIR}/${DOMAIN}_subdomains.txt"
    crawling
    vulnerability_scanning
    
    # Cleanup
    cleanup "${TARGET_DIR}"
    
    echo -e "${GREEN}[SUCCESS] All tasks completed for: ${DOMAIN}${NC}"
    echo -e "${CYAN}[INFO] Results are available in: ${TARGET_DIR}${NC}"
}

# Parse Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--domain) DOMAIN="$2"; shift ;;
        -v|--verbose) VERBOSE=true ;;
        -h|--help) show_banner; show_usage; exit 0 ;;
        *) echo -e "${RED}[ERROR] Unknown argument: $1${NC}"; show_usage; exit 1 ;;
    esac
    shift
done

# Execute main function
main