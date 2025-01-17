#!/bin/bash

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

# Report Configuration
REPORT_DIR="./reports/security"
REPORT_FILE="${REPORT_DIR}/security_report_$(date +%Y%m%d_%H%M%S).txt"
HTML_REPORT="${REPORT_DIR}/security_report_$(date +%Y%m%d_%H%M%S).html"

# Initialize Report Directory
mkdir -p "${REPORT_DIR}"
chmod 750 "${REPORT_DIR}"

# Generate Security Report
function generate_security_report() {
    {
        echo "=== Navi Framework Security Report ==="
        echo "Generated: $(date)"
        echo "================================================"
        
        # System Security Check
        echo -e "\n1. System Security Status:"
        echo "------------------------"
        check_system_security
        
        # File Permissions Check
        echo -e "\n2. File Permission Status:"
        echo "------------------------"
        check_file_permissions
        
        # Configuration Security
        echo -e "\n3. Configuration Security:"
        echo "------------------------"
        check_config_security
        
        # Network Security
        echo -e "\n4. Network Security Status:"
        echo "------------------------"
        check_network_security
        
        # Tool Security
        echo -e "\n5. Tool Security Status:"
        echo "------------------------"
        check_tool_security
        
        # Audit Log Analysis
        echo -e "\n6. Audit Log Analysis:"
        echo "------------------------"
        analyze_audit_logs
        
    } | tee "${REPORT_FILE}"
    
    # Generate HTML Report
    convert_to_html
}

# System Security Check
function check_system_security() {
    echo "[*] Checking process isolation..."
    ps -eo user,pid,ppid,cmd --forest
    
    echo "[*] Checking resource limits..."
    ulimit -a
    
    echo "[*] Checking mounted filesystems..."
    mount | grep -E "noexec|nosuid|nodev"
}

# File Permission Check
function check_file_permissions() {
    local critical_files=(
        "config.conf"
        "security_init.sh"
        "./logs/audit/commands.log"
        "./security/integrity/checksums.db"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            perms=$(stat -c "%a %U:%G" "$file")
            echo "[*] $file: $perms"
        else
            echo "[!] Missing file: $file"
        fi
    done
}

# Configuration Security Check
function check_config_security() {
    if [ -f "config.conf" ]; then
        echo "[*] Checking for sensitive data exposure..."
        grep -i "key\|password\|token" config.conf | grep -v "^#"
        
        echo "[*] Validating security settings..."
        source config.conf
        [[ "${SSL_VERIFY}" != "true" ]] && echo "[!] SSL verification is disabled"
        [[ "${ENCRYPT_RESULTS}" != "true" ]] && echo "[!] Result encryption is disabled"
    fi
}

# Network Security Check
function check_network_security() {
    echo "[*] Checking open ports..."
    netstat -tuln 2>/dev/null || ss -tuln
    
    echo "[*] Checking DNS security..."
    if command -v dig &>/dev/null; then
        dig +dnssec google.com | grep -i "DNSSEC"
    fi
}

# Tool Security Check
function check_tool_security() {
    local tools=("subfinder" "amass" "ffuf" "nuclei" "httpx")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "[*] $tool: $(which "$tool")"
            if [ -x "$(which "$tool")" ]; then
                sha256sum "$(which "$tool")"
            fi
        else
            echo "[!] $tool not found"
        fi
    done
}

# Audit Log Analysis
function analyze_audit_logs() {
    if [ -f "./logs/audit/commands.log" ]; then
        echo "[*] Recent command executions:"
        tail -n 10 "./logs/audit/commands.log"
        
        echo "[*] Failed operations:"
        grep -i "error\|failed\|failure" "./logs/audit/commands.log" | tail -n 5
    fi
}

# Convert to HTML Report
function convert_to_html() {
    {
        echo "<html><head><style>"
        echo "body { font-family: Arial, sans-serif; margin: 40px; }"
        echo "h1 { color: #2c3e50; }"
        echo ".section { margin: 20px 0; padding: 10px; background: #f8f9fa; }"
        echo ".warning { color: #e74c3c; }"
        echo ".success { color: #27ae60; }"
        echo "</style></head><body>"
        
        echo "<h1>Navi Framework Security Report</h1>"
        echo "<div class='section'>"
        
        # Convert the text report to HTML
        sed 's/\[!]/<span class="warning">[!]<\/span>/g' "${REPORT_FILE}" |
            sed 's/\[*]/<span class="success">[*]<\/span>/g' |
            sed 's/$/<br>/g'
        
        echo "</div></body></html>"
    } > "${HTML_REPORT}"
    
    echo -e "${GREEN}[SUCCESS] Reports generated:${NC}"
    echo -e "Text Report: ${REPORT_FILE}"
    echo -e "HTML Report: ${HTML_REPORT}"
}

# Execute Report Generation
generate_security_report 