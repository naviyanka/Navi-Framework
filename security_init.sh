#!/bin/bash

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Enhanced security initialization
function init_enhanced_security() {
    echo -e "${CYAN}[INFO] Initializing enhanced security measures...${NC}"
    
    # Create secure temporary directory
    if [ "${SECURE_TEMP_DIR}" != "" ]; then
        mkdir -p "${SECURE_TEMP_DIR}"
        chmod 700 "${SECURE_TEMP_DIR}"
        echo -e "${GREEN}[+] Secure temporary directory created${NC}"
    fi
    
    # Initialize audit logging
    if [ "${ENABLE_AUDIT}" = "true" ]; then
        mkdir -p ./logs/audit
        chmod 700 ./logs/audit
        touch ./logs/audit/commands.log
        chmod 600 ./logs/audit/commands.log
        echo -e "${GREEN}[+] Audit logging initialized${NC}"
    fi
    
    # Setup process isolation
    if [ "${PROCESS_ISOLATION}" = "true" ]; then
        mkdir -p ./isolated
        chmod 700 ./isolated
        echo -e "${GREEN}[+] Process isolation directory created${NC}"
    fi
    
    # Initialize integrity database
    if [ "${FILE_INTEGRITY_CHECK}" = "true" ]; then
        mkdir -p ./security/integrity
        touch ./security/integrity/checksums.db
        chmod 600 ./security/integrity/checksums.db
        echo -e "${GREEN}[+] File integrity database initialized${NC}"
    fi
    
    echo -e "${GREEN}[SUCCESS] Enhanced security initialization completed${NC}"
}

# Enhanced security validation
function validate_enhanced_security() {
    local errors=0
    
    # Check for root privileges if needed
    if [ "${ENABLE_CHROOT}" = "true" ] && [ "$(id -u)" != "0" ]; then
        echo -e "${RED}[ERROR] Root privileges required for chroot${NC}"
        ((errors++))
    fi
    
    # Validate secure directories
    for dir in ./logs/audit ./security/integrity ./isolated "${SECURE_TEMP_DIR}"; do
        if [ -d "$dir" ] && [ "$(stat -c %a $dir)" != "700" ]; then
            echo -e "${RED}[ERROR] Insecure permissions on $dir${NC}"
            ((errors++))
        fi
    done
    
    # Check system security requirements
    if [ "${ENABLE_SECCOMP}" = "true" ] && ! command -v seccomp-tools &>/dev/null; then
        echo -e "${YELLOW}[WARNING] seccomp-tools not installed${NC}"
    fi
    
    # Verify network security
    if [ "${ENABLE_DNS_SEC}" = "true" ] && ! command -v dig &>/dev/null; then
        echo -e "${YELLOW}[WARNING] dig not installed for DNSSEC validation${NC}"
    fi
    
    return $errors
}

# Main execution
echo -e "${CYAN}[INFO] Starting enhanced security initialization...${NC}"
init_enhanced_security
validate_enhanced_security

if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Enhanced security validation failed${NC}"
    exit 1
else
    echo -e "${GREEN}[SUCCESS] All security measures are in place${NC}"
fi 