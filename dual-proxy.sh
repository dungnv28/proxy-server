#!/bin/bash

# Dual Proxy Manager v3.0
# HTTP Proxy (Squid) + SOCKS5 Proxy (Dante)
# Full CRUD operations for proxy pairs
# Author: Enhanced by AI Assistant

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration files
PROXY_DB="/etc/proxy-manager/proxy_users.db"
CONFIG_DIR="/etc/proxy-manager"
HTTP_PORT=3128
SOCKS_PORT=1080
SERVER_IP=""
INTERFACE=""

# Functions
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "══════════════════════════════════════════════════════════════"
    echo "    DUAL PROXY MANAGER v3.0 - CRUD Operations"
    echo "    HTTP Proxy (Squid) + SOCKS5 Proxy (Dante)"
    echo "    Format: IP:PORT:USER:PASS for both HTTP and SOCKS5"
    echo "══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check shell type
check_shell() {
    if readlink /proc/$$/exe | grep -qs "dash"; then
        log_error "This script needs to be run with bash, not sh"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -e /etc/debian_version ]]; then
        OS_TYPE="deb"
        OS_NAME="Debian/Ubuntu"
    elif [[ -e /etc/centos-release ]] || [[ -e /etc/redhat-release ]]; then
        OS_TYPE="centos"
        OS_NAME="CentOS/RHEL"
    else
        log_error "Unsupported OS. This script only works on Debian/Ubuntu/CentOS/RHEL"
        exit 1
    fi
    log_info "Detected OS: $OS_NAME"
}

# Get network info
get_network_info() {
    INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')
    
    if [[ -z "$INTERFACE" ]]; then
        log_error "Cannot detect network interface"
        exit 1
    fi
    
    if [[ -z "$SERVER_IP" ]]; then
        log_error "Cannot detect server IP"
        exit 1
    fi
    
    log_info "Network interface: $INTERFACE"
    log_info "Server IP: $SERVER_IP"
}

# Initialize database
init_database() {
    mkdir -p "$CONFIG_DIR"
    
    if [[ ! -f "$PROXY_DB" ]]; then
        cat > "$PROXY_DB" << 'EOF'
# Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS
# This file is automatically managed by the proxy manager
EOF
        log_info "Database initialized"
    fi
}

# Generate unique username
generate_unique_username() {
    local username
    local attempts=0
    local max_attempts=100
    
    while [[ $attempts -lt $max_attempts ]]; do
        # Generate random username with prefix
        local random_part=$(openssl rand -hex 4)
        username="proxy_${random_part}"
        
        # Check if username already exists in system and database
        if ! getent passwd "$username" >/dev/null 2>&1 && ! grep -q "^$username:" "$PROXY_DB" 2>/dev/null; then
            echo "$username"
            return 0
        fi
        
        ((attempts++))
    done
    
    log_error "Failed to generate unique username after $max_attempts attempts"
    return 1
}

# Generate unique password
generate_unique_password() {
    local password
    local attempts=0
    local max_attempts=100
    
    while [[ $attempts -lt $max_attempts ]]; do
        # Generate strong random password
        password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)
        
        # Check if password already exists in database
        if ! grep -q ":$password:" "$PROXY_DB" 2>/dev/null; then
            echo "$password"
            return 0
        fi
        
        ((attempts++))
    done
    
    log_error "Failed to generate unique password after $max_attempts attempts"
    return 1
}

# Install packages
install_packages() {
    log_info "Installing required packages..."
    
    if [[ "$OS_TYPE" = "deb" ]]; then
        apt-get update -y
        apt-get install -y squid apache2-utils curl wget openssl make gcc zip jq
    else
        yum update -y
        yum install -y epel-release
        yum install -y squid httpd-tools curl wget openssl make gcc zip jq
    fi
    
    log_success "Packages installed successfully"
}

# Configure Squid (HTTP Proxy)
configure_squid() {
    log_info "Configuring Squid HTTP proxy..."
    
    # Backup original config
    [[ -f /etc/squid/squid.conf ]] && cp /etc/squid/squid.conf /etc/squid/squid.conf.backup
    
    # Create Squid configuration
    cat > /etc/squid/squid.conf << EOF
# HTTP Proxy Configuration - Dual Proxy Manager
http_port ${HTTP_PORT}

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm "HTTP Proxy Authentication Required"
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED

# Access control
http_access allow authenticated
http_access deny all

# Network settings
visible_hostname dual-proxy-server
dns_v4_first on

# Performance settings
cache_mem 256 MB
maximum_object_size 128 MB
pipeline_prefetch on

# Logging
access_log /var/log/squid/access.log combined
cache_log /var/log/squid/cache.log
pid_filename /var/run/squid.pid

# DNS servers
dns_nameservers 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1

# Privacy settings
forwarded_for off
via off

# Timeout settings
connect_timeout 1 minute
peer_connect_timeout 30 seconds
read_timeout 5 minutes
request_timeout 5 minutes

# Security headers
request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all

# Block some headers for privacy
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
EOF

    # Create password file for Squid
    touch /etc/squid/passwd
    chown squid:squid /etc/squid/passwd 2>/dev/null || chown proxy:proxy /etc/squid/passwd
    chmod 644 /etc/squid/passwd
    
    log_success "Squid configuration completed"
}

# Install and configure Dante (SOCKS5 Proxy)
install_dante() {
    log_info "Installing Dante SOCKS5 proxy..."
    
    # Check if Dante is already installed
    if command -v sockd >/dev/null 2>&1; then
        log_info "Dante is already installed"
        return 0
    fi
    
    # Download and compile Dante
    cd /tmp
    wget -q https://www.inet.no/dante/files/dante-1.4.3.tar.gz
    tar xzf dante-1.4.3.tar.gz
    cd dante-1.4.3
    
    # Configure and compile
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-client \
        --without-libwrap \
        --without-bsdauth \
        --without-gssapi \
        --without-krb5 \
        --without-upnp \
        --without-pam >/dev/null 2>&1
    
    make >/dev/null 2>&1 && make install >/dev/null 2>&1
    
    log_success "Dante compiled and installed"
}

# Configure Dante
configure_dante() {
    log_info "Configuring Dante SOCKS5 proxy..."
    
    # Create Dante configuration
    cat > /etc/sockd.conf << EOF
# SOCKS5 Proxy Configuration - Dual Proxy Manager
internal: $INTERFACE port = $SOCKS_PORT
external: $INTERFACE
user.privileged: root
user.unprivileged: nobody
socksmethod: username
logoutput: /var/log/sockd.log

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
    socksmethod: username
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: error
    socksmethod: username
}
EOF

    # Create systemd service for Dante
    cat > /etc/systemd/system/sockd.service << 'EOF'
[Unit]
Description=Dante Socks Proxy v1.4.3 - Dual Proxy Manager
After=network.target

[Service]
Type=forking
PIDFile=/var/run/sockd.pid
ExecStart=/usr/sbin/sockd -D -f /etc/sockd.conf
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    
    log_success "Dante configuration completed"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    # UFW (Ubuntu/Debian)
    if command -v ufw >/dev/null 2>&1; then
        ufw allow ${HTTP_PORT}/tcp >/dev/null 2>&1
        ufw allow ${SOCKS_PORT}/tcp >/dev/null 2>&1
        log_info "UFW rules added"
    fi
    
    # Firewalld (CentOS/RHEL)
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${HTTP_PORT}/tcp >/dev/null 2>&1
        firewall-cmd --permanent --add-port=${SOCKS_PORT}/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
        log_info "Firewalld rules added"
    fi
    
    # Iptables
    if command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport $HTTP_PORT -j ACCEPT 2>/dev/null
        iptables -I INPUT -p tcp --dport $SOCKS_PORT -j ACCEPT 2>/dev/null
        
        # Save iptables rules
        if [[ "$OS_TYPE" = "deb" ]]; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null
        else
            service iptables save 2>/dev/null
        fi
        log_info "Iptables rules added"
    fi
    
    log_success "Firewall configured"
}

# Start services
start_services() {
    log_info "Starting proxy services..."
    
    # Start Squid
    systemctl enable squid >/dev/null 2>&1
    systemctl restart squid
    
    # Start Dante
    systemctl enable sockd >/dev/null 2>&1
    systemctl restart sockd
    
    # Check service status
    sleep 3
    
    if systemctl is-active --quiet squid; then
        log_success "Squid HTTP proxy started successfully"
    else
        log_error "Failed to start Squid"
        return 1
    fi
    
    if systemctl is-active --quiet sockd; then
        log_success "Dante SOCKS5 proxy started successfully"
    else
        log_error "Failed to start Dante"
        return 1
    fi
}

# CRUD Operations

# CREATE - Add single proxy pair
create_proxy_pair() {
    log_info "Creating new proxy pair..."
    
    local username=$(generate_unique_username)
    local password=$(generate_unique_password)
    
    if [[ -z "$username" || -z "$password" ]]; then
        log_error "Failed to generate unique credentials"
        return 1
    fi
    
    # Create system user
    useradd -M -s /usr/sbin/nologin "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    # Add to Squid
    htpasswd -b /etc/squid/passwd "$username" "$password" >/dev/null 2>&1
    
    # Add to database
    echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active" >> "$PROXY_DB"
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    echo -e "${GREEN}✓ Proxy pair created successfully!${NC}"
    echo -e "${YELLOW}HTTP Proxy:${NC}   $SERVER_IP:$HTTP_PORT:$username:$password"
    echo -e "${YELLOW}SOCKS5 Proxy:${NC} $SERVER_IP:$SOCKS_PORT:$username:$password"
    
    log_success "Proxy pair created: $username"
    return 0
}

# CREATE - Add multiple proxy pairs
create_multiple_proxy_pairs() {
    local num_pairs
    
    while true; do
        read -p "Enter number of proxy pairs to create: " num_pairs
        if [[ "$num_pairs" =~ ^[0-9]+$ ]] && [[ "$num_pairs" -ge 1 ]] && [[ "$num_pairs" -le 100 ]]; then
            break
        else
            log_error "Please enter a valid number (1-100)"
        fi
    done
    
    log_info "Creating $num_pairs proxy pairs..."
    
    local success_count=0
    local proxy_list=""
    
    for ((i=1; i<=num_pairs; i++)); do
        local username=$(generate_unique_username)
        local password=$(generate_unique_password)
        
        if [[ -n "$username" && -n "$password" ]]; then
            # Create system user
            useradd -M -s /usr/sbin/nologin "$username" 2>/dev/null
            echo "$username:$password" | chpasswd
            
            # Add to Squid
            htpasswd -b /etc/squid/passwd "$username" "$password" >/dev/null 2>&1
            
            # Add to database
            echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active" >> "$PROXY_DB"
            
            # Add to proxy list
            proxy_list+="HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password\n"
            proxy_list+="SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password\n\n"
            
            ((success_count++))
            echo -ne "\rProgress: $i/$num_pairs"
        fi
    done
    
    echo
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    echo -e "\n${GREEN}✓ Created $success_count proxy pairs successfully!${NC}\n"
    echo -e "${CYAN}Proxy List:${NC}"
    echo -e "$proxy_list"
    
    # Save to file
    echo -e "$proxy_list" > "/tmp/proxy_pairs_$(date +%Y%m%d_%H%M%S).txt"
    log_success "Proxy list saved to /tmp/proxy_pairs_$(date +%Y%m%d_%H%M%S).txt"
    
    # Upload to file.io
    upload_proxy_list "$proxy_list"
}

# READ - List all proxy pairs
read_proxy_pairs() {
    echo -e "${CYAN}Current Proxy Pairs:${NC}\n"
    
    if [[ ! -f "$PROXY_DB" ]] || [[ ! -s "$PROXY_DB" ]]; then
        log_warning "No proxy pairs found"
        return 0
    fi
    
    local count=0
    echo -e "${YELLOW}Format: HTTP and SOCKS5 pairs${NC}"
    echo -e "${YELLOW}Server IP: $SERVER_IP${NC}\n"
    
    while IFS=':' read -r username password created_date status; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        ((count++))
        echo -e "${PURPLE}[$count]${NC} User: ${GREEN}$username${NC}"
        echo -e "    HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password"
        echo -e "    SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password"
        echo -e "    Created: $created_date | Status: $status"
        echo
    done < "$PROXY_DB"
    
    if [[ $count -eq 0 ]]; then
        log_warning "No active proxy pairs found"
    else
        log_info "Total proxy pairs: $count"
    fi
}

# UPDATE - Update proxy password
update_proxy_pair() {
    echo -e "${CYAN}Update Proxy Pair Password${NC}\n"
    
    # List current users
    read_proxy_pairs
    
    read -p "Enter username to update: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$PROXY_DB" 2>/dev/null; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Generate new password
    local new_password=$(generate_unique_password)
    
    if [[ -z "$new_password" ]]; then
        log_error "Failed to generate new password"
        return 1
    fi
    
    # Update system user password
    echo "$username:$new_password" | chpasswd
    
    # Update Squid password
    htpasswd -b /etc/squid/passwd "$username" "$new_password" >/dev/null 2>&1
    
    # Update database
    sed -i "s/^$username:[^:]*:/$username:$new_password:/" "$PROXY_DB"
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    echo -e "${GREEN}✓ Password updated successfully!${NC}"
    echo -e "${YELLOW}HTTP Proxy:${NC}   $SERVER_IP:$HTTP_PORT:$username:$new_password"
    echo -e "${YELLOW}SOCKS5 Proxy:${NC} $SERVER_IP:$SOCKS_PORT:$username:$new_password"
    
    log_success "Password updated for user: $username"
}

# DELETE - Delete single proxy pair
delete_proxy_pair() {
    echo -e "${CYAN}Delete Proxy Pair${NC}\n"
    
    # List current users
    read_proxy_pairs
    
    read -p "Enter username to delete: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$PROXY_DB" 2>/dev/null; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Confirm deletion
    read -p "Are you sure you want to delete user '$username'? [y/N]: " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Deletion cancelled"
        return 0
    fi
    
    # Delete system user
    userdel "$username" 2>/dev/null
    
    # Remove from Squid
    htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1
    
    # Remove from database
    sed -i "/^$username:/d" "$PROXY_DB"
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    log_success "Proxy pair deleted: $username"
}

# DELETE - Delete all proxy pairs
delete_all_proxy_pairs() {
    echo -e "${RED}Delete All Proxy Pairs${NC}\n"
    
    # Count current users
    local user_count=$(grep -v '^#' "$PROXY_DB" 2>/dev/null | grep -c '^[^[:space:]]*:' || echo "0")
    
    if [[ $user_count -eq 0 ]]; then
        log_warning "No proxy pairs to delete"
        return 0
    fi
    
    echo -e "${YELLOW}This will delete all $user_count proxy pairs!${NC}"
    read -p "Are you absolutely sure? Type 'DELETE ALL' to confirm: " confirm
    
    if [[ "$confirm" != "DELETE ALL" ]]; then
        log_info "Deletion cancelled"
        return 0
    fi
    
    log_info "Deleting all proxy pairs..."
    
    # Delete all users from database
    while IFS=':' read -r username password created_date status; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        # Delete system user
        userdel "$username" 2>/dev/null
        
        # Remove from Squid
        htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1
    done < "$PROXY_DB"
    
    # Clear database (keep header)
    cat > "$PROXY_DB" << 'EOF'
# Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS
# This file is automatically managed by the proxy manager
EOF
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    log_success "All proxy pairs deleted"
}

# Upload proxy list to file.io
upload_proxy_list() {
    local proxy_content="$1"
    
    if [[ -z "$proxy_content" ]]; then
        return 1
    fi
    
    log_info "Uploading proxy list..."
    
    # Create temporary file
    local temp_file="/tmp/proxy_list_$(date +%Y%m%d_%H%M%S).txt"
    echo -e "$proxy_content" > "$temp_file"
    
    # Create password-protected zip
    local password=$(openssl rand -base64 12)
    local zip_file="/tmp/proxy_list_$(date +%Y%m%d_%H%M%S).zip"
    
    if command -v zip >/dev/null 2>&1; then
        zip -P "$password" "$zip_file" "$temp_file" >/dev/null 2>&1
        
        # Upload to file.io
        local json=$(curl -s -F "file=@$zip_file" https://file.io 2>/dev/null)
        local url=$(echo "$json" | jq -r '.link' 2>/dev/null)
        
        if [[ "$url" != "null" && -n "$url" ]]; then
            echo -e "\n${GREEN}✓ Proxy list uploaded successfully!${NC}"
            echo -e "${YELLOW}Download URL:${NC} $url"
            echo -e "${YELLOW}Archive Password:${NC} $password"
        else
            log_warning "Failed to upload to file.io"
        fi
        
        # Cleanup
        rm -f "$temp_file" "$zip_file"
    else
        log_warning "zip command not available for upload"
        rm -f "$temp_file"
    fi
}

# Export proxy pairs to file
export_proxy_pairs() {
    local export_file="/tmp/proxy_export_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "# Dual Proxy Export - $(date)" > "$export_file"
    echo "# Server: $SERVER_IP" >> "$export_file"
    echo "# HTTP Port: $HTTP_PORT | SOCKS5 Port: $SOCKS_PORT" >> "$export_file"
    echo "# Format: TYPE:IP:PORT:USERNAME:PASSWORD" >> "$export_file"
    echo "" >> "$export_file"
    
    local count=0
    while IFS=':' read -r username password created_date status; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        echo "HTTP:$SERVER_IP:$HTTP_PORT:$username:$password" >> "$export_file"
        echo "SOCKS5:$SERVER_IP:$SOCKS_PORT:$username:$password" >> "$export_file"
        ((count++))
    done < "$PROXY_DB"
    
    if [[ $count -gt 0 ]]; then
        log_success "Exported $count proxy pairs to: $export_file"
        
        # Upload to file.io
        local proxy_content=$(cat "$export_file")
        upload_proxy_list "$proxy_content"
    else
        log_warning "No proxy pairs to export"
        rm -f "$export_file"
    fi
}

# Service management
restart_services() {
    log_info "Restarting proxy services..."
    systemctl restart squid
    systemctl restart sockd
    sleep 2
    
    if systemctl is-active --quiet squid && systemctl is-active --quiet sockd; then
        log_success "Services restarted successfully"
    else
        log_error "Failed to restart one or more services"
    fi
}

show_service_status() {
    echo -e "${CYAN}Service Status:${NC}"
    echo -n "Squid (HTTP):   "
    if systemctl is-active --quiet squid; then
        echo -e "${GREEN}Running${NC}"
    else
        echo -e "${RED}Stopped${NC}"
    fi
    
    echo -n "Dante (SOCKS5): "
    if systemctl is-active --quiet sockd; then
        echo -e "${GREEN}Running${NC}"
    else
        echo -e "${RED}Stopped${NC}"
    fi
    
    echo -e "\n${YELLOW}Port Status:${NC}"
    echo "HTTP Port $HTTP_PORT:   $(netstat -ln | grep ":$HTTP_PORT " >/dev/null && echo -e "${GREEN}Open${NC}" || echo -e "${RED}Closed${NC}")"
    echo "SOCKS5 Port $SOCKS_PORT: $(netstat -ln | grep ":$SOCKS_PORT " >/dev/null && echo -e "${GREEN}Open${NC}" || echo -e "${RED}Closed${NC}")"
}

# Test proxy functionality
test_proxy_pair() {
    echo -e "${CYAN}Test Proxy Pair${NC}\n"
    
    # List current users
    read_proxy_pairs
    
    read -p "Enter username to test: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    
    # Get password from database
    local password=$(grep "^$username:" "$PROXY_DB" 2>/dev/null | cut -d':' -f2)
    
    if [[ -z "$password" ]]; then
        log_error "User '$username' not found"
        return 1
    fi
    
    log_info "Testing proxy pair for user: $username"
    
    # Test HTTP proxy
    echo -e "\n${YELLOW}Testing HTTP Proxy...${NC}"
    local http_result=$(curl -s --max-time 10 -x "$username:$password@$SERVER_IP:$HTTP_PORT" http://ifconfig.me 2>/dev/null)
    
    if [[ -n "$http_result" ]]; then
        echo -e "${GREEN}✓ HTTP Proxy working - External IP: $http_result${NC}"
    else
        echo -e "${RED}✗ HTTP Proxy failed${NC}"
    fi
    
    # Test SOCKS5 proxy
    echo -e "\n${YELLOW}Testing SOCKS5 Proxy...${NC}"
    local socks_result=$(curl -s --max-time 10 --socks5 "$username:$password@$SERVER_IP:$SOCKS_PORT" http://ifconfig.me 2>/dev/null)
    
    if [[ -n "$socks_result" ]]; then
        echo -e "${GREEN}✓ SOCKS5 Proxy working - External IP: $socks_result${NC}"
    else
        echo -e "${RED}✗ SOCKS5 Proxy failed${NC}"
    fi
}

# Main menu
show_main_menu() {
    while true; do
        print_banner
        echo -e "\n${YELLOW}Proxy Management Menu${NC}"
        echo -e "${YELLOW}Server: $SERVER_IP | HTTP: $HTTP_PORT | SOCKS5: $SOCKS_PORT${NC}"
        echo
        echo -e "${CYAN}CRUD Operations:${NC}"
        echo -e "${GREEN}1)${NC} Create Single Proxy Pair"
        echo -e "${GREEN}2)${NC} Create Multiple Proxy Pairs"
        echo -e "${GREEN}3)${NC} Read/List All Proxy Pairs"
        echo -e "${GREEN}4)${NC} Update Proxy Password"
        echo -e "${GREEN}5)${NC} Delete Single Proxy Pair"
        echo -e "${GREEN}6)${NC} Delete All Proxy Pairs"
        echo
        echo -e "${CYAN}Management:${NC}"
        echo -e "${BLUE}7)${NC} Export Proxy Pairs"
        echo -e "${BLUE}8)${NC} Test Proxy Pair"
        echo -e "${BLUE}9)${NC} Service Status"
        echo -e "${BLUE}10)${NC} Restart Services"
        echo -e "${BLUE}11)${NC} View Logs"
        echo
        echo -e "${RED}0)${NC} Exit"
        echo

        read -p "Select an option [0-11]: " choice

        case $choice in
            1) create_proxy_pair ;;
            2) create_multiple_proxy_pairs ;;
            3) read_proxy_pairs ;;
            4) update_proxy_pair ;;
            5) delete_proxy_pair ;;
            6) delete_all_proxy_pairs ;;
            7) export_proxy_pairs ;;
            8) test_proxy_pair ;;
            9) show_service_status ;;
            10) restart_services ;;
            11) show_logs ;;
            0) echo "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac

        echo
        read -p "Press Enter to continue..."
    done
}

# Show logs
show_logs() {
    echo -e "${CYAN}Proxy Logs${NC}\n"
    echo -e "${YELLOW}1) HTTP Proxy Logs (last 20 lines)${NC}"
    echo -e "${YELLOW}2) SOCKS5 Proxy Logs (last 20 lines)${NC}"
    echo -e "${YELLOW}3) Both Logs${NC}"
    echo
    
    read -p "Select log to view [1-3]: " log_choice
    
    case $log_choice in
        1)
            echo -e "\n${CYAN}HTTP Proxy Access Log:${NC}"
            tail -20 /var/log/squid/access.log 2>/dev/null || log_warning "HTTP log not found"
            ;;
        2)
            echo -e "\n${CYAN}SOCKS5 Proxy Log:${NC}"
            tail -20 /var/log/sockd.log 2>/dev/null || log_warning "SOCKS5 log not found"
            ;;
        3)
            echo -e "\n${CYAN}HTTP Proxy Access Log:${NC}"
            tail -10 /var/log/squid/access.log 2>/dev/null || log_warning "HTTP log not found"
            echo -e "\n${CYAN}SOCKS5 Proxy Log:${NC}"
            tail -10 /var/log/sockd.log 2>/dev/null || log_warning "SOCKS5 log not found"
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac
}

# Check if already installed
check_existing_installation() {
    if [[ -f /etc/sockd.conf ]] && [[ -f /etc/squid/squid.conf ]] && systemctl is-active --quiet squid && systemctl is-active --quiet sockd; then
        log_info "Dual proxy system already installed. Entering management mode..."
        init_database
        show_main_menu
        exit 0
    fi
}

# Initial installation
install_dual_proxy() {
    print_banner
    
    log_info "Starting dual proxy installation..."
    
    # Get configuration
    echo -e "${YELLOW}Installation Configuration${NC}"
    
    while true; do
        read -p "Enter HTTP proxy port (default: 3128): " -e -i 3128 http_port
        if [[ "$http_port" =~ ^[0-9]+$ ]] && [[ "$http_port" -ge 1 ]] && [[ "$http_port" -le 65535 ]]; then
            HTTP_PORT="$http_port"
            break
        else
            log_error "Invalid port number"
        fi
    done
    
    while true; do
        read -p "Enter SOCKS5 proxy port (default: 1080): " -e -i 1080 socks_port
        if [[ "$socks_port" =~ ^[0-9]+$ ]] && [[ "$socks_port" -ge 1 ]] && [[ "$socks_port" -le 65535 ]]; then
            SOCKS_PORT="$socks_port"
            break
        else
            log_error "Invalid port number"
        fi
    done
    
    while true; do
        read -p "Create initial proxy pairs? [y/N]: " create_initial
        if [[ "$create_initial" =~ ^[yY]$ ]]; then
            while true; do
                read -p "Enter number of initial proxy pairs (1-50): " initial_count
                if [[ "$initial_count" =~ ^[0-9]+$ ]] && [[ "$initial_count" -ge 1 ]] && [[ "$initial_count" -le 50 ]]; then
                    break
                else
                    log_error "Please enter a valid number (1-50)"
                fi
            done
            break
        elif [[ "$create_initial" =~ ^[nN]$ ]] || [[ -z "$create_initial" ]]; then
            initial_count=0
            break
        else
            log_error "Please enter y or n"
        fi
    done
    
    # Installation process
    install_packages
    configure_squid
    install_dante
    configure_dante
    configure_firewall
    init_database
    start_services
    
    # Create initial proxy pairs if requested
    if [[ $initial_count -gt 0 ]]; then
        log_info "Creating $initial_count initial proxy pairs..."
        
        local proxy_list=""
        for ((i=1; i<=initial_count; i++)); do
            local username=$(generate_unique_username)
            local password=$(generate_unique_password)
            
            if [[ -n "$username" && -n "$password" ]]; then
                # Create system user
                useradd -M -s /usr/sbin/nologin "$username" 2>/dev/null
                echo "$username:$password" | chpasswd
                
                # Add to Squid
                htpasswd -b /etc/squid/passwd "$username" "$password" >/dev/null 2>&1
                
                # Add to database
                echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active" >> "$PROXY_DB"
                
                # Add to proxy list
                proxy_list+="HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password\n"
                proxy_list+="SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password\n\n"
            fi
        done
        
        # Restart Squid to reload users
        systemctl reload squid >/dev/null 2>&1
        
        echo -e "\n${GREEN}✓ Installation completed with $initial_count proxy pairs!${NC}\n"
        echo -e "${CYAN}Initial Proxy List:${NC}"
        echo -e "$proxy_list"
        
        # Upload proxy list
        upload_proxy_list "$proxy_list"
    else
        echo -e "\n${GREEN}✓ Installation completed!${NC}"
        log_info "Use the management menu to create proxy pairs"
    fi
    
    # Save installation info
    cat > /root/dual_proxy_info.txt << EOF
Dual Proxy Manager Installation
===============================
Installation Date: $(date)
Server IP: $SERVER_IP
HTTP Proxy Port: $HTTP_PORT
SOCKS5 Proxy Port: $SOCKS_PORT
Initial Proxy Pairs: $initial_count

Management:
- Run: bash $(realpath "$0")
- Config Directory: $CONFIG_DIR
- Database: $PROXY_DB

Service Commands:
- HTTP Proxy: systemctl {start|stop|restart|status} squid
- SOCKS5 Proxy: systemctl {start|stop|restart|status} sockd

Log Files:
- HTTP Proxy: /var/log/squid/access.log
- SOCKS5 Proxy: /var/log/sockd.log
EOF
    
    log_success "Installation information saved to /root/dual_proxy_info.txt"
    
    # Enter management mode
    echo
    read -p "Press Enter to enter management mode..."
    show_main_menu
}

# Main function
main() {
    # Pre-installation checks
    check_shell
    check_root
    detect_os
    get_network_info
    check_existing_installation
    
    # Start installation
    install_dual_proxy
}

# Handle command line arguments
case "${1:-}" in
    "menu")
        check_shell
        check_root
        get_network_info
        init_database
        show_main_menu
        ;;
    "info")
        [[ -f /root/dual_proxy_info.txt ]] && cat /root/dual_proxy_info.txt || log_error "Info file not found"
        ;;
    "status")
        check_root
        get_network_info
        show_service_status
        ;;
    *)
        main
        ;;
esac