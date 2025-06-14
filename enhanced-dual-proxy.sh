#!/bin/bash

# Enhanced Dual Proxy Manager v4.0
# HTTP Proxy (Squid) + SOCKS5 Proxy (Dante) + Bandwidth Management
# Full CRUD operations + Speed Limiting + Monthly Quota
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
BANDWIDTH_DB="/etc/proxy-manager/bandwidth_usage.db"
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
    echo "    ENHANCED DUAL PROXY MANAGER v4.0 - BANDWIDTH CONTROL"
    echo "    HTTP Proxy (Squid) + SOCKS5 Proxy (Dante)"
    echo "    Speed Limiting + Monthly Quota Management"
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

# Initialize databases
init_database() {
    mkdir -p "$CONFIG_DIR"
    
    if [[ ! -f "$PROXY_DB" ]]; then
        cat > "$PROXY_DB" << 'EOF'
# Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:MONTHLY_QUOTA_GB:QUOTA_RESET_DATE
# SPEED_LIMIT_MBPS: 0 = unlimited, >0 = limit in Mbps
# MONTHLY_QUOTA_GB: 0 = unlimited, >0 = limit in GB
EOF
        log_info "Proxy database initialized"
    fi
    
    if [[ ! -f "$BANDWIDTH_DB" ]]; then
        cat > "$BANDWIDTH_DB" << 'EOF'
# Bandwidth Usage Database
# Format: USERNAME:YEAR_MONTH:USED_BYTES:LAST_UPDATED
# YEAR_MONTH format: YYYY-MM (e.g., 2024-01)
EOF
        log_info "Bandwidth database initialized"
    fi
}

# Generate unique username
generate_unique_username() {
    local username
    local attempts=0
    local max_attempts=100
    
    while [[ $attempts -lt $max_attempts ]]; do
        local random_part=$(openssl rand -hex 4)
        username="proxy_${random_part}"
        
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
        password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)
        
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
        apt-get install -y squid apache2-utils curl wget openssl make gcc zip jq iproute2 iptables-persistent
    else
        yum update -y
        yum install -y epel-release
        yum install -y squid httpd-tools curl wget openssl make gcc zip jq iproute tc iptables-services
    fi
    
    log_success "Packages installed successfully"
}

# Configure Squid (HTTP Proxy)
configure_squid() {
    log_info "Configuring Squid HTTP proxy..."
    
    [[ -f /etc/squid/squid.conf ]] && cp /etc/squid/squid.conf /etc/squid/squid.conf.backup
    
    cat > /etc/squid/squid.conf << EOF
# Enhanced HTTP Proxy Configuration with Bandwidth Control
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
visible_hostname enhanced-proxy-server
dns_v4_first on

# Performance settings
cache_mem 256 MB
maximum_object_size 128 MB
pipeline_prefetch on

# Logging with detailed format for bandwidth tracking
access_log /var/log/squid/access.log combined
logformat combined %>a %[ui %[un [%tl] "%rm %ru HTTP/%rv" %>Hs %<st "%{Referer}>h" "%{User-Agent}>h" %ss:%Sh
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

# Bandwidth control preparation
delay_pools 1
delay_class 1 2
delay_parameters 1 -1/-1 -1/-1
delay_access 1 allow authenticated

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

    touch /etc/squid/passwd
    chown squid:squid /etc/squid/passwd 2>/dev/null || chown proxy:proxy /etc/squid/passwd
    chmod 644 /etc/squid/passwd
    
    log_success "Squid configuration completed"
}

# Install and configure Dante (SOCKS5 Proxy)
install_dante() {
    log_info "Installing Dante SOCKS5 proxy..."
    
    if command -v sockd >/dev/null 2>&1; then
        log_info "Dante is already installed"
        return 0
    fi
    
    cd /tmp
    wget -q https://www.inet.no/dante/files/dante-1.4.3.tar.gz
    tar xzf dante-1.4.3.tar.gz
    cd dante-1.4.3
    
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
    
    cat > /etc/sockd.conf << EOF
# Enhanced SOCKS5 Proxy Configuration
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

    cat > /etc/systemd/system/sockd.service << 'EOF'
[Unit]
Description=Enhanced Dante Socks Proxy v1.4.3 - Bandwidth Control
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
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow ${HTTP_PORT}/tcp >/dev/null 2>&1
        ufw allow ${SOCKS_PORT}/tcp >/dev/null 2>&1
        log_info "UFW rules added"
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${HTTP_PORT}/tcp >/dev/null 2>&1
        firewall-cmd --permanent --add-port=${SOCKS_PORT}/tcp >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
        log_info "Firewalld rules added"
    fi
    
    if command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport $HTTP_PORT -j ACCEPT 2>/dev/null
        iptables -I INPUT -p tcp --dport $SOCKS_PORT -j ACCEPT 2>/dev/null
        
        if [[ "$OS_TYPE" = "deb" ]]; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null
        else
            service iptables save 2>/dev/null
        fi
        log_info "Iptables rules added"
    fi
    
    log_success "Firewall configured"
}

# Apply bandwidth limit for user
apply_bandwidth_limit() {
    local username="$1"
    local speed_limit="$2"  # in Mbps
    
    if [[ -z "$username" || -z "$speed_limit" ]]; then
        log_error "Username and speed limit required"
        return 1
    fi
    
    # Get user UID
    local uid=$(id -u "$username" 2>/dev/null)
    if [[ -z "$uid" ]]; then
        log_error "User $username not found"
        return 1
    fi
    
    # Remove existing rules for this user
    remove_bandwidth_limit "$username"
    
    if [[ "$speed_limit" -eq 0 ]]; then
        log_info "Unlimited bandwidth set for user: $username"
        return 0
    fi
    
    # Convert Mbps to bytes per second (for tc)
    local rate_bps=$((speed_limit * 1024 * 1024 / 8))
    local burst=$((rate_bps * 2))
    
    # Create unique class ID based on UID
    local class_id=$((1000 + uid % 1000))
    
    # Setup traffic control if not exists
    if ! tc qdisc show dev "$INTERFACE" | grep -q "qdisc htb 1:"; then
        tc qdisc add dev "$INTERFACE" root handle 1: htb default 999
        tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate 1000mbit
    fi
    
    # Add class for this user
    tc class add dev "$INTERFACE" parent 1:1 classid 1:$class_id htb rate ${speed_limit}mbit ceil ${speed_limit}mbit burst ${burst}
    
    # Add filter for outgoing traffic (upload)
    tc filter add dev "$INTERFACE" protocol ip parent 1:0 prio 1 handle $uid fw flowid 1:$class_id
    
    # Mark packets with iptables
    iptables -t mangle -A OUTPUT -m owner --uid-owner $uid -j MARK --set-mark $uid
    
    # For incoming traffic (download) - use IFB interface
    if ! ip link show ifb0 >/dev/null 2>&1; then
        modprobe ifb
        ip link add ifb0 type ifb
        ip link set dev ifb0 up
        tc qdisc add dev ifb0 root handle 1: htb default 999
        tc class add dev ifb0 parent 1: classid 1:1 htb rate 1000mbit
        
        # Redirect ingress traffic to ifb0
        tc qdisc add dev "$INTERFACE" handle ffff: ingress
        tc filter add dev "$INTERFACE" parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb0
    fi
    
    # Add download limit on ifb0
    tc class add dev ifb0 parent 1:1 classid 1:$class_id htb rate ${speed_limit}mbit ceil ${speed_limit}mbit burst ${burst}
    tc filter add dev ifb0 protocol ip parent 1:0 prio 1 handle $uid fw flowid 1:$class_id
    
    # Mark incoming packets for this user (requires connection tracking)
    iptables -t mangle -A PREROUTING -m conntrack --ctstate ESTABLISHED -j CONNMARK --restore-mark
    iptables -t mangle -A OUTPUT -m owner --uid-owner $uid -j CONNMARK --set-mark $uid
    iptables -t mangle -A PREROUTING -m connmark --mark $uid -j MARK --set-mark $uid
    
    log_success "Bandwidth limit ${speed_limit}Mbps applied for user: $username"
}

# Remove bandwidth limit for user
remove_bandwidth_limit() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        return 1
    fi
    
    local uid=$(id -u "$username" 2>/dev/null)
    if [[ -z "$uid" ]]; then
        return 1
    fi
    
    local class_id=$((1000 + uid % 1000))
    
    # Remove tc rules
    tc filter del dev "$INTERFACE" protocol ip parent 1:0 prio 1 handle $uid fw 2>/dev/null
    tc class del dev "$INTERFACE" classid 1:$class_id 2>/dev/null
    
    # Remove ifb0 rules if exists
    if ip link show ifb0 >/dev/null 2>&1; then
        tc filter del dev ifb0 protocol ip parent 1:0 prio 1 handle $uid fw 2>/dev/null
        tc class del dev ifb0 classid 1:$class_id 2>/dev/null
    fi
    
    # Remove iptables rules
    iptables -t mangle -D OUTPUT -m owner --uid-owner $uid -j MARK --set-mark $uid 2>/dev/null
    iptables -t mangle -D OUTPUT -m owner --uid-owner $uid -j CONNMARK --set-mark $uid 2>/dev/null
    iptables -t mangle -D PREROUTING -m connmark --mark $uid -j MARK --set-mark $uid 2>/dev/null
}

# Check monthly quota for user
check_monthly_quota() {
    local username="$1"
    local quota_gb="$2"
    
    if [[ -z "$username" || "$quota_gb" -eq 0 ]]; then
        return 0  # Unlimited
    fi
    
    local current_month=$(date +%Y-%m)
    local used_bytes=$(grep "^$username:$current_month:" "$BANDWIDTH_DB" 2>/dev/null | cut -d':' -f3)
    
    if [[ -z "$used_bytes" ]]; then
        used_bytes=0
    fi
    
    local quota_bytes=$((quota_gb * 1024 * 1024 * 1024))
    
    if [[ $used_bytes -ge $quota_bytes ]]; then
        return 1  # Quota exceeded
    fi
    
    return 0  # Within quota
}

# Update bandwidth usage
update_bandwidth_usage() {
    local username="$1"
    local bytes_used="$2"
    
    if [[ -z "$username" || -z "$bytes_used" ]]; then
        return 1
    fi
    
    local current_month=$(date +%Y-%m)
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if entry exists for this user and month
    if grep -q "^$username:$current_month:" "$BANDWIDTH_DB" 2>/dev/null; then
        # Update existing entry
        local current_usage=$(grep "^$username:$current_month:" "$BANDWIDTH_DB" | cut -d':' -f3)
        local new_usage=$((current_usage + bytes_used))
        sed -i "s/^$username:$current_month:.*/$username:$current_month:$new_usage:$current_time/" "$BANDWIDTH_DB"
    else
        # Create new entry
        echo "$username:$current_month:$bytes_used:$current_time" >> "$BANDWIDTH_DB"
    fi
}

# Block user access (quota exceeded)
block_user_access() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        return 1
    fi
    
    local uid=$(id -u "$username" 2>/dev/null)
    if [[ -z "$uid" ]]; then
        return 1
    fi
    
    # Block user in iptables
    iptables -I OUTPUT -m owner --uid-owner $uid -j DROP
    
    # Update status in database
    sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_quota:/" "$PROXY_DB"
    
    log_warning "User $username blocked due to quota exceeded"
}

# Unblock user access
unblock_user_access() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        return 1
    fi
    
    local uid=$(id -u "$username" 2>/dev/null)
    if [[ -z "$uid" ]]; then
        return 1
    fi
    
    # Remove block rule
    iptables -D OUTPUT -m owner --uid-owner $uid -j DROP 2>/dev/null
    
    # Update status in database
    sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_quota:/$username:\1:\2:active:/" "$PROXY_DB"
    
    log_success "User $username unblocked"
}

# Start services
start_services() {
    log_info "Starting proxy services..."
    
    systemctl enable squid >/dev/null 2>&1
    systemctl restart squid
    
    systemctl enable sockd >/dev/null 2>&1
    systemctl restart sockd
    
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

# CRUD Operations with Bandwidth Control

# CREATE - Add single proxy pair with bandwidth options
create_proxy_pair() {
    log_info "Creating new proxy pair with bandwidth control..."
    
    local username=$(generate_unique_username)
    local password=$(generate_unique_password)
    
    if [[ -z "$username" || -z "$password" ]]; then
        log_error "Failed to generate unique credentials"
        return 1
    fi
    
    # Get bandwidth settings
    echo -e "\n${YELLOW}Bandwidth Configuration:${NC}"
    echo "1) Unlimited (default)"
    echo "2) Custom speed limit and monthly quota"
    read -p "Select option [1-2]: " bandwidth_option
    
    local speed_limit=0
    local monthly_quota=0
    
    if [[ "$bandwidth_option" == "2" ]]; then
        while true; do
            read -p "Enter speed limit in Mbps (e.g., 100): " speed_limit
            if [[ "$speed_limit" =~ ^[0-9]+$ ]] && [[ "$speed_limit" -gt 0 ]]; then
                break
            else
                log_error "Please enter a valid speed limit (positive number)"
            fi
        done
        
        while true; do
            read -p "Enter monthly quota in GB (0 for unlimited): " monthly_quota
            if [[ "$monthly_quota" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid quota (number)"
            fi
        done
    fi
    
    # Create system user
    useradd -M -s /usr/sbin/nologin "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    # Add to Squid
    htpasswd -b /etc/squid/passwd "$username" "$password" >/dev/null 2>&1
    
    # Add to database with bandwidth settings
    local quota_reset_date=$(date -d "next month" +%Y-%m-01)
    echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:$speed_limit:$monthly_quota:$quota_reset_date" >> "$PROXY_DB"
    
    # Apply bandwidth limit
    if [[ "$speed_limit" -gt 0 ]]; then
        apply_bandwidth_limit "$username" "$speed_limit"
    fi
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    echo -e "${GREEN}✓ Proxy pair created successfully!${NC}"
    echo -e "${YELLOW}HTTP Proxy:${NC}   $SERVER_IP:$HTTP_PORT:$username:$password"
    echo -e "${YELLOW}SOCKS5 Proxy:${NC} $SERVER_IP:$SOCKS_PORT:$username:$password"
    echo -e "${YELLOW}Speed Limit:${NC}  $([ $speed_limit -eq 0 ] && echo "Unlimited" || echo "${speed_limit}Mbps")"
    echo -e "${YELLOW}Monthly Quota:${NC} $([ $monthly_quota -eq 0 ] && echo "Unlimited" || echo "${monthly_quota}GB")"
    
    log_success "Proxy pair created: $username"
    return 0
}

# CREATE - Add multiple proxy pairs with same bandwidth settings
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
    
    # Get bandwidth settings for all proxies
    echo -e "\n${YELLOW}Bandwidth Configuration for all proxies:${NC}"
    echo "1) Unlimited (default)"
    echo "2) Custom speed limit and monthly quota"
    read -p "Select option [1-2]: " bandwidth_option
    
    local speed_limit=0
    local monthly_quota=0
    
    if [[ "$bandwidth_option" == "2" ]]; then
        while true; do
            read -p "Enter speed limit in Mbps (e.g., 100): " speed_limit
            if [[ "$speed_limit" =~ ^[0-9]+$ ]] && [[ "$speed_limit" -gt 0 ]]; then
                break
            else
                log_error "Please enter a valid speed limit (positive number)"
            fi
        done
        
        while true; do
            read -p "Enter monthly quota in GB (0 for unlimited): " monthly_quota
            if [[ "$monthly_quota" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid quota (number)"
            fi
        done
    fi
    
    log_info "Creating $num_pairs proxy pairs with bandwidth control..."
    
    local success_count=0
    local proxy_list=""
    local quota_reset_date=$(date -d "next month" +%Y-%m-01)
    
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
            echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:$speed_limit:$monthly_quota:$quota_reset_date" >> "$PROXY_DB"
            
            # Apply bandwidth limit
            if [[ "$speed_limit" -gt 0 ]]; then
                apply_bandwidth_limit "$username" "$speed_limit"
            fi
            
            # Add to proxy list
            proxy_list+="HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password"
            proxy_list+=" | Speed: $([ $speed_limit -eq 0 ] && echo "Unlimited" || echo "${speed_limit}Mbps")"
            proxy_list+=" | Quota: $([ $monthly_quota -eq 0 ] && echo "Unlimited" || echo "${monthly_quota}GB")\n"
            proxy_list+="SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password"
            proxy_list+=" | Speed: $([ $speed_limit -eq 0 ] && echo "Unlimited" || echo "${speed_limit}Mbps")"
            proxy_list+=" | Quota: $([ $monthly_quota -eq 0 ] && echo "Unlimited" || echo "${monthly_quota}GB")\n\n"
            
            ((success_count++))
            echo -ne "\rProgress: $i/$num_pairs"
        fi
    done
    
    echo
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    echo -e "\n${GREEN}✓ Created $success_count proxy pairs successfully!${NC}\n"
    echo -e "${CYAN}Proxy List with Bandwidth Settings:${NC}"
    echo -e "$proxy_list"
    
    # Save to file
    echo -e "$proxy_list" > "/tmp/proxy_pairs_$(date +%Y%m%d_%H%M%S).txt"
    log_success "Proxy list saved to /tmp/proxy_pairs_$(date +%Y%m%d_%H%M%S).txt"
    
    # Upload to file.io
    upload_proxy_list "$proxy_list"
}

# READ - List all proxy pairs with bandwidth info
read_proxy_pairs() {
    echo -e "${CYAN}Current Proxy Pairs with Bandwidth Control:${NC}\n"
    
    if [[ ! -f "$PROXY_DB" ]] || [[ ! -s "$PROXY_DB" ]]; then
        log_warning "No proxy pairs found"
        return 0
    fi
    
    local count=0
    echo -e "${YELLOW}Format: HTTP and SOCKS5 pairs with bandwidth limits${NC}"
    echo -e "${YELLOW}Server IP: $SERVER_IP${NC}\n"
    
    while IFS=':' read -r username password created_date status speed_limit monthly_quota quota_reset_date; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        ((count++))
        
        # Get current month usage
        local current_month=$(date +%Y-%m)
        local used_bytes=$(grep "^$username:$current_month:" "$BANDWIDTH_DB" 2>/dev/null | cut -d':' -f3 || echo "0")
        local used_gb=$((used_bytes / 1024 / 1024 / 1024))
        
        # Status color
        local status_color="${GREEN}"
        [[ "$status" == "blocked_quota" ]] && status_color="${RED}"
        [[ "$status" == "inactive" ]] && status_color="${YELLOW}"
        
        echo -e "${PURPLE}[$count]${NC} User: ${GREEN}$username${NC}"
        echo -e "    HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password"
        echo -e "    SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password"
        echo -e "    Created: $created_date | Status: ${status_color}$status${NC}"
        echo -e "    Speed Limit: $([ ${speed_limit:-0} -eq 0 ] && echo "${GREEN}Unlimited${NC}" || echo "${YELLOW}${speed_limit}Mbps${NC}")"
        echo -e "    Monthly Quota: $([ ${monthly_quota:-0} -eq 0 ] && echo "${GREEN}Unlimited${NC}" || echo "${YELLOW}${monthly_quota}GB${NC}")"
        echo -e "    Usage This Month: ${CYAN}${used_gb}GB${NC}"
        [[ ${monthly_quota:-0} -gt 0 ]] && echo -e "    Quota Reset: $quota_reset_date"
        echo
    done < "$PROXY_DB"
    
    if [[ $count -eq 0 ]]; then
        log_warning "No active proxy pairs found"
    else
        log_info "Total proxy pairs: $count"
    fi
}

# UPDATE - Update proxy bandwidth settings
update_proxy_bandwidth() {
    echo -e "${CYAN}Update Proxy Bandwidth Settings${NC}\n"
    
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
    
    echo -e "\n${YELLOW}Update Options:${NC}"
    echo "1) Update speed limit only"
    echo "2) Update monthly quota only"
    echo "3) Update both speed limit and quota"
    echo "4) Reset to unlimited"
    echo "5) Block/Unblock user"
    read -p "Select option [1-5]: " update_option
    
    case $update_option in
        1)
            read -p "Enter new speed limit in Mbps (0 for unlimited): " new_speed
            if [[ "$new_speed" =~ ^[0-9]+$ ]]; then
                # Update database
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):/$username:\1:\2:\3:$new_speed:/" "$PROXY_DB"
                
                # Apply bandwidth limit
                if [[ "$new_speed" -gt 0 ]]; then
                    apply_bandwidth_limit "$username" "$new_speed"
                else
                    remove_bandwidth_limit "$username"
                fi
                
                log_success "Speed limit updated to $([ $new_speed -eq 0 ] && echo "Unlimited" || echo "${new_speed}Mbps") for user: $username"
            else
                log_error "Invalid speed limit"
            fi
            ;;
        2)
            read -p "Enter new monthly quota in GB (0 for unlimited): " new_quota
            if [[ "$new_quota" =~ ^[0-9]+$ ]]; then
                # Update database
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):/$username:\1:\2:\3:\4:$new_quota:/" "$PROXY_DB"
                
                # Check if user should be unblocked
                if [[ "$new_quota" -eq 0 ]] || check_monthly_quota "$username" "$new_quota"; then
                    unblock_user_access "$username"
                fi
                
                log_success "Monthly quota updated to $([ $new_quota -eq 0 ] && echo "Unlimited" || echo "${new_quota}GB") for user: $username"
            else
                log_error "Invalid quota"
            fi
            ;;
        3)
            read -p "Enter new speed limit in Mbps (0 for unlimited): " new_speed
            read -p "Enter new monthly quota in GB (0 for unlimited): " new_quota
            
            if [[ "$new_speed" =~ ^[0-9]+$ ]] && [[ "$new_quota" =~ ^[0-9]+$ ]]; then
                # Update database
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:/$username:\1:\2:\3:$new_speed:$new_quota:/" "$PROXY_DB"
                
                # Apply bandwidth limit
                if [[ "$new_speed" -gt 0 ]]; then
                    apply_bandwidth_limit "$username" "$new_speed"
                else
                    remove_bandwidth_limit "$username"
                fi
                
                # Check quota
                if [[ "$new_quota" -eq 0 ]] || check_monthly_quota "$username" "$new_quota"; then
                    unblock_user_access "$username"
                fi
                
                log_success "Bandwidth settings updated for user: $username"
                echo "Speed: $([ $new_speed -eq 0 ] && echo "Unlimited" || echo "${new_speed}Mbps")"
                echo "Quota: $([ $new_quota -eq 0 ] && echo "Unlimited" || echo "${new_quota}GB")"
            else
                log_error "Invalid input"
            fi
            ;;
        4)
            # Reset to unlimited
            sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:/$username:\1:\2:\3:0:0:/" "$PROXY_DB"
            remove_bandwidth_limit "$username"
            unblock_user_access "$username"
            log_success "User $username reset to unlimited bandwidth"
            ;;
        5)
            # Block/Unblock user
            local current_status=$(grep "^$username:" "$PROXY_DB" | cut -d':' -f4)
            if [[ "$current_status" == "active" ]]; then
                sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:inactive:/" "$PROXY_DB"
                block_user_access "$username"
                log_success "User $username blocked"
            else
                sed -i "s/^$username:\([^:]*\):\([^:]*\):inactive:/$username:\1:\2:active:/" "$PROXY_DB"
                sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_quota:/$username:\1:\2:active:/" "$PROXY_DB"
                unblock_user_access "$username"
                log_success "User $username unblocked"
            fi
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac
}

# Bandwidth monitoring and quota enforcement
monitor_bandwidth_usage() {
    log_info "Starting bandwidth monitoring..."
    
    # Create monitoring script
    cat > /usr/local/bin/proxy-bandwidth-monitor.sh << 'EOF'
#!/bin/bash

PROXY_DB="/etc/proxy-manager/proxy_users.db"
BANDWIDTH_DB="/etc/proxy-manager/bandwidth_usage.db"
LOG_FILE="/var/log/proxy-bandwidth-monitor.log"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Parse Squid access log for bandwidth usage
parse_squid_logs() {
    local last_check_file="/tmp/squid_last_check"
    local current_time=$(date +%s)
    local last_check_time=0
    
    if [[ -f "$last_check_file" ]]; then
        last_check_time=$(cat "$last_check_file")
    fi
    
    # Parse access log for new entries
    awk -v start_time="$last_check_time" -v current_time="$current_time" '
    {
        # Parse Squid log format: timestamp username bytes_sent
        timestamp = $1
        username = $8
        bytes_sent = $5
        bytes_received = $6
        
        if (timestamp > start_time && username != "-") {
            total_bytes = bytes_sent + bytes_received
            user_usage[username] += total_bytes
        }
    }
    END {
        for (user in user_usage) {
            print user ":" user_usage[user]
        }
    }' /var/log/squid/access.log
    
    echo "$current_time" > "$last_check_file"
}

# Update bandwidth usage in database
while IFS=':' read -r username bytes_used; do
    if [[ -n "$username" && -n "$bytes_used" && "$bytes_used" -gt 0 ]]; then
        current_month=$(date +%Y-%m)
        current_time=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Update usage in database
        if grep -q "^$username:$current_month:" "$BANDWIDTH_DB" 2>/dev/null; then
            current_usage=$(grep "^$username:$current_month:" "$BANDWIDTH_DB" | cut -d':' -f3)
            new_usage=$((current_usage + bytes_used))
            sed -i "s/^$username:$current_month:.*/$username:$current_month:$new_usage:$current_time/" "$BANDWIDTH_DB"
        else
            echo "$username:$current_month:$bytes_used:$current_time" >> "$BANDWIDTH_DB"
            new_usage=$bytes_used
        fi
        
        # Check quota
        quota_gb=$(grep "^$username:" "$PROXY_DB" | cut -d':' -f6)
        if [[ -n "$quota_gb" && "$quota_gb" -gt 0 ]]; then
            quota_bytes=$((quota_gb * 1024 * 1024 * 1024))
            if [[ $new_usage -ge $quota_bytes ]]; then
                # Block user
                uid=$(id -u "$username" 2>/dev/null)
                if [[ -n "$uid" ]]; then
                    iptables -I OUTPUT -m owner --uid-owner $uid -j DROP 2>/dev/null
                    sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_quota:/" "$PROXY_DB"
                    log_message "User $username blocked due to quota exceeded ($new_usage bytes >= $quota_bytes bytes)"
                fi
            fi
        fi
    fi
done < <(parse_squid_logs)

log_message "Bandwidth monitoring completed"
EOF

    chmod +x /usr/local/bin/proxy-bandwidth-monitor.sh
    
    # Create cron job for monitoring
    cat > /etc/cron.d/proxy-bandwidth-monitor << 'EOF'
# Proxy bandwidth monitoring - runs every 5 minutes
*/5 * * * * root /usr/local/bin/proxy-bandwidth-monitor.sh
EOF

    log_success "Bandwidth monitoring configured"
}

# Monthly quota reset
setup_monthly_quota_reset() {
    log_info "Setting up monthly quota reset..."
    
    # Create quota reset script
    cat > /usr/local/bin/proxy-quota-reset.sh << 'EOF'
#!/bin/bash

PROXY_DB="/etc/proxy-manager/proxy_users.db"
BANDWIDTH_DB="/etc/proxy-manager/bandwidth_usage.db"
LOG_FILE="/var/log/proxy-quota-reset.log"

# Function to log with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_message "Starting monthly quota reset"

# Reset quota for all users
while IFS=':' read -r username password created_date status speed_limit monthly_quota quota_reset_date; do
    # Skip comments and empty lines
    [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
    
    # Check if quota reset date has passed
    current_date=$(date +%Y-%m-%d)
    if [[ "$current_date" >= "$quota_reset_date" ]]; then
        # Calculate next reset date
        next_reset_date=$(date -d "$(date -d "$quota_reset_date" +%Y-%m-01) +1 month" +%Y-%m-01)
        
        # Update quota reset date in database
        sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):$quota_reset_date/$username:\1:\2:\3:\4:\5:$next_reset_date/" "$PROXY_DB"
        
        # Unblock user if blocked due to quota
        if [[ "$status" == "blocked_quota" ]]; then
            uid=$(id -u "$username" 2>/dev/null)
            if [[ -n "$uid" ]]; then
                iptables -D OUTPUT -m owner --uid-owner $uid -j DROP 2>/dev/null
                sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_quota:/$username:\1:\2:active:/" "$PROXY_DB"
                log_message "User $username unblocked after quota reset"
            fi
        fi
        
        log_message "Quota reset for user $username, next reset: $next_reset_date"
    fi
done < "$PROXY_DB"

log_message "Monthly quota reset completed"
EOF

    chmod +x /usr/local/bin/proxy-quota-reset.sh
    
    # Create cron job for monthly reset (runs on 1st of each month)
    cat > /etc/cron.d/proxy-quota-reset << 'EOF'
# Proxy quota reset - runs on 1st of each month at 00:01
1 0 1 * * root /usr/local/bin/proxy-quota-reset.sh
EOF

    log_success "Monthly quota reset configured"
}

# Show bandwidth statistics
show_bandwidth_statistics() {
    echo -e "${CYAN}Bandwidth Usage Statistics${NC}\n"
    
    local current_month=$(date +%Y-%m)
    echo -e "${YELLOW}Current Month: $current_month${NC}\n"
    
    printf "%-20s %-15s %-15s %-15s %-10s\n" "Username" "Speed Limit" "Monthly Quota" "Used This Month" "Status"
    printf "%-20s %-15s %-15s %-15s %-10s\n" "--------" "-----------" "-------------" "---------------" "------"
    
    while IFS=':' read -r username password created_date status speed_limit monthly_quota quota_reset_date; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        # Get usage for current month
        local used_bytes=$(grep "^$username:$current_month:" "$BANDWIDTH_DB" 2>/dev/null | cut -d':' -f3 || echo "0")
        local used_gb=$((used_bytes / 1024 / 1024 / 1024))
        local used_mb=$((used_bytes / 1024 / 1024))
        
        # Format display
        local speed_display="$([ ${speed_limit:-0} -eq 0 ] && echo "Unlimited" || echo "${speed_limit}Mbps")"
        local quota_display="$([ ${monthly_quota:-0} -eq 0 ] && echo "Unlimited" || echo "${monthly_quota}GB")"
        local used_display="${used_gb}GB"
        [[ $used_gb -eq 0 && $used_mb -gt 0 ]] && used_display="${used_mb}MB"
        
        # Status color
        local status_display="$status"
        case $status in
            "active") status_display="${GREEN}Active${NC}" ;;
            "blocked_quota") status_display="${RED}Blocked${NC}" ;;
            "inactive") status_display="${YELLOW}Inactive${NC}" ;;
        esac
        
        printf "%-20s %-15s %-15s %-15s %-10s\n" "$username" "$speed_display" "$quota_display" "$used_display" "$status_display"
    done < "$PROXY_DB"
    
    echo
    
    # Show total usage
    local total_usage=$(awk -F: -v month="$current_month" '$2 == month {sum += $3} END {print sum+0}' "$BANDWIDTH_DB")
    local total_gb=$((total_usage / 1024 / 1024 / 1024))
    echo -e "${CYAN}Total Usage This Month: ${total_gb}GB${NC}"
}

# Upload proxy list to file.io
upload_proxy_list() {
    local proxy_content="$1"
    
    if [[ -z "$proxy_content" ]]; then
        return 1
    fi
    
    log_info "Uploading proxy list..."
    
    local temp_file="/tmp/proxy_list_$(date +%Y%m%d_%H%M%S).txt"
    echo -e "$proxy_content" > "$temp_file"
    
    local password=$(openssl rand -base64 12)
    local zip_file="/tmp/proxy_list_$(date +%Y%m%d_%H%M%S).zip"
    
    if command -v zip >/dev/null 2>&1; then
        zip -P "$password" "$zip_file" "$temp_file" >/dev/null 2>&1
        
        local json=$(curl -s -F "file=@$zip_file" https://file.io 2>/dev/null)
        local url=$(echo "$json" | jq -r '.link' 2>/dev/null)
        
        if [[ "$url" != "null" && -n "$url" ]]; then
            echo -e "\n${GREEN}✓ Proxy list uploaded successfully!${NC}"
            echo -e "${YELLOW}Download URL:${NC} $url"
            echo -e "${YELLOW}Archive Password:${NC} $password"
        else
            log_warning "Failed to upload to file.io"
        fi
        
        rm -f "$temp_file" "$zip_file"
    else
        log_warning "zip command not available for upload"
        rm -f "$temp_file"
    fi
}

# DELETE - Delete single proxy pair
delete_proxy_pair() {
    echo -e "${CYAN}Delete Proxy Pair${NC}\n"
    
    read_proxy_pairs
    
    read -p "Enter username to delete: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    
    if ! grep -q "^$username:" "$PROXY_DB" 2>/dev/null; then
        log_error "User '$username' not found"
        return 1
    fi
    
    read -p "Are you sure you want to delete user '$username'? [y/N]: " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Deletion cancelled"
        return 0
    fi
    
    # Remove bandwidth limits
    remove_bandwidth_limit "$username"
    
    # Unblock user
    unblock_user_access "$username"
    
    # Delete system user
    userdel "$username" 2>/dev/null
    
    # Remove from Squid
    htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1
    
    # Remove from databases
    sed -i "/^$username:/d" "$PROXY_DB"
    sed -i "/^$username:/d" "$BANDWIDTH_DB"
    
    systemctl reload squid >/dev/null 2>&1
    
    log_success "Proxy pair deleted: $username"
}

# DELETE - Delete all proxy pairs
delete_all_proxy_pairs() {
    echo -e "${RED}Delete All Proxy Pairs${NC}\n"
    
    local user_count=$(grep -v '^#' "$PROXY_DB" 2>/dev/null | grep -c '^[^[:space:]]*:' || echo "0")
    
    if [[ $user_count -eq 0 ]]; then
        log_warning "No proxy pairs to delete"
        return 0
    fi
    
    echo -e "${YELLOW}This will delete all $user_count proxy pairs and their bandwidth data!${NC}"
    read -p "Are you absolutely sure? Type 'DELETE ALL' to confirm: " confirm
    
    if [[ "$confirm" != "DELETE ALL" ]]; then
        log_info "Deletion cancelled"
        return 0
    fi
    
    log_info "Deleting all proxy pairs..."
    
    # Delete all users from database
    while IFS=':' read -r username password created_date status speed_limit monthly_quota quota_reset_date; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        # Remove bandwidth limits
        remove_bandwidth_limit "$username"
        
        # Unblock user
        unblock_user_access "$username"
        
        # Delete system user
        userdel "$username" 2>/dev/null
        
        # Remove from Squid
        htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1
    done < "$PROXY_DB"
    
    # Clear databases
    cat > "$PROXY_DB" << 'EOF'
# Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:MONTHLY_QUOTA_GB:QUOTA_RESET_DATE
# SPEED_LIMIT_MBPS: 0 = unlimited, >0 = limit in Mbps
# MONTHLY_QUOTA_GB: 0 = unlimited, >0 = limit in GB
EOF

    cat > "$BANDWIDTH_DB" << 'EOF'
# Bandwidth Usage Database
# Format: USERNAME:YEAR_MONTH:USED_BYTES:LAST_UPDATED
# YEAR_MONTH format: YYYY-MM (e.g., 2024-01)
EOF
    
    systemctl reload squid >/dev/null 2>&1
    
    log_success "All proxy pairs deleted"
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
    
    echo -e "\n${YELLOW}Traffic Control Status:${NC}"
    if tc qdisc show dev "$INTERFACE" | grep -q "qdisc htb"; then
        echo -e "Bandwidth Control: ${GREEN}Active${NC}"
        echo "Active bandwidth limits:"
        tc class show dev "$INTERFACE" | grep -E "class htb 1:[0-9]+" | while read line; do
            class_id=$(echo "$line" | grep -o "1:[0-9]\+" | cut -d: -f2)
            rate=$(echo "$line" | grep -o "rate [0-9]\+[a-zA-Z]\+" | cut -d' ' -f2)
            echo "  Class $class_id: $rate"
        done
    else
        echo -e "Bandwidth Control: ${YELLOW}Inactive${NC}"
    fi
}

# Test proxy functionality
test_proxy_pair() {
    echo -e "${CYAN}Test Proxy Pair${NC}\n"
    
    read_proxy_pairs
    
    read -p "Enter username to test: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    
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
    
    # Show bandwidth info
    echo -e "\n${YELLOW}Bandwidth Information:${NC}"
    local user_info=$(grep "^$username:" "$PROXY_DB")
    local speed_limit=$(echo "$user_info" | cut -d':' -f5)
    local monthly_quota=$(echo "$user_info" | cut -d':' -f6)
    local status=$(echo "$user_info" | cut -d':' -f4)
    
    echo "Speed Limit: $([ ${speed_limit:-0} -eq 0 ] && echo "Unlimited" || echo "${speed_limit}Mbps")"
    echo "Monthly Quota: $([ ${monthly_quota:-0} -eq 0 ] && echo "Unlimited" || echo "${monthly_quota}GB")"
    echo "Status: $status"
    
    # Show current month usage
    local current_month=$(date +%Y-%m)
    local used_bytes=$(grep "^$username:$current_month:" "$BANDWIDTH_DB" 2>/dev/null | cut -d':' -f3 || echo "0")
    local used_gb=$((used_bytes / 1024 / 1024 / 1024))
    echo "Usage This Month: ${used_gb}GB"
}

# Show logs
show_logs() {
    echo -e "${CYAN}Proxy Logs${NC}\n"
    echo -e "${YELLOW}1) HTTP Proxy Logs (last 20 lines)${NC}"
    echo -e "${YELLOW}2) SOCKS5 Proxy Logs (last 20 lines)${NC}"
    echo -e "${YELLOW}3) Bandwidth Monitor Logs${NC}"
    echo -e "${YELLOW}4) All Logs${NC}"
    echo
    
    read -p "Select log to view [1-4]: " log_choice
    
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
            echo -e "\n${CYAN}Bandwidth Monitor Log:${NC}"
            tail -20 /var/log/proxy-bandwidth-monitor.log 2>/dev/null || log_warning "Bandwidth monitor log not found"
            ;;
        4)
            echo -e "\n${CYAN}HTTP Proxy Access Log:${NC}"
            tail -10 /var/log/squid/access.log 2>/dev/null || log_warning "HTTP log not found"
            echo -e "\n${CYAN}SOCKS5 Proxy Log:${NC}"
            tail -10 /var/log/sockd.log 2>/dev/null || log_warning "SOCKS5 log not found"
            echo -e "\n${CYAN}Bandwidth Monitor Log:${NC}"
            tail -10 /var/log/proxy-bandwidth-monitor.log 2>/dev/null || log_warning "Bandwidth monitor log not found"
            ;;
        *)
            log_error "Invalid option"
            ;;
    esac
}

# Main menu
show_main_menu() {
    while true; do
        print_banner
        echo -e "\n${YELLOW}Enhanced Proxy Management Menu${NC}"
        echo -e "${YELLOW}Server: $SERVER_IP | HTTP: $HTTP_PORT | SOCKS5: $SOCKS_PORT${NC}"
        echo
        echo -e "${CYAN}CRUD Operations:${NC}"
        echo -e "${GREEN}1)${NC} Create Single Proxy Pair (with Bandwidth Control)"
        echo -e "${GREEN}2)${NC} Create Multiple Proxy Pairs (with Bandwidth Control)"
        echo -e "${GREEN}3)${NC} Read/List All Proxy Pairs (with Bandwidth Info)"
        echo -e "${GREEN}4)${NC} Update Proxy Bandwidth Settings"
        echo -e "${GREEN}5)${NC} Delete Single Proxy Pair"
        echo -e "${GREEN}6)${NC} Delete All Proxy Pairs"
        echo
        echo -e "${CYAN}Bandwidth Management:${NC}"
        echo -e "${BLUE}7)${NC} Show Bandwidth Statistics"
        echo -e "${BLUE}8)${NC} Monitor Bandwidth Usage (Real-time)"
        echo -e "${BLUE}9)${NC} Reset User Quota"
        echo
        echo -e "${CYAN}System Management:${NC}"
        echo -e "${PURPLE}10)${NC} Test Proxy Pair"
        echo -e "${PURPLE}11)${NC} Service Status"
        echo -e "${PURPLE}12)${NC} Restart Services"
        echo -e "${PURPLE}13)${NC} View Logs"
        echo
        echo -e "${RED}0)${NC} Exit"
        echo

        read -p "Select an option [0-13]: " choice

        case $choice in
            1) create_proxy_pair ;;
            2) create_multiple_proxy_pairs ;;
            3) read_proxy_pairs ;;
            4) update_proxy_bandwidth ;;
            5) delete_proxy_pair ;;
            6) delete_all_proxy_pairs ;;
            7) show_bandwidth_statistics ;;
            8) monitor_bandwidth_usage_realtime ;;
            9) reset_user_quota ;;
            10) test_proxy_pair ;;
            11) show_service_status ;;
            12) restart_services ;;
            13) show_logs ;;
            0) echo "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac

        echo
        read -p "Press Enter to continue..."
    done
}

# Real-time bandwidth monitoring
monitor_bandwidth_usage_realtime() {
    echo -e "${CYAN}Real-time Bandwidth Monitoring${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    
    while true; do
        clear
        echo -e "${CYAN}Real-time Bandwidth Usage - $(date)${NC}\n"
        
        # Show current connections
        echo -e "${YELLOW}Active Connections:${NC}"
        echo "HTTP Proxy: $(netstat -an | grep ":$HTTP_PORT " | grep ESTABLISHED | wc -l) connections"
        echo "SOCKS5 Proxy: $(netstat -an | grep ":$SOCKS_PORT " | grep ESTABLISHED | wc -l) connections"
        echo
        
        # Show bandwidth usage
        show_bandwidth_statistics
        
        sleep 5
    done
}

# Reset user quota
reset_user_quota() {
    echo -e "${CYAN}Reset User Quota${NC}\n"
    
    read_proxy_pairs
    
    read -p "Enter username to reset quota: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    
    if ! grep -q "^$username:" "$PROXY_DB" 2>/dev/null; then
        log_error "User '$username' not found"
        return 1
    fi
    
    read -p "Are you sure you want to reset quota for user '$username'? [y/N]: " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Reset cancelled"
        return 0
    fi
    
    # Remove bandwidth usage entries for this user
    sed -i "/^$username:/d" "$BANDWIDTH_DB"
    
    # Unblock user if blocked due to quota
    unblock_user_access "$username"
    
    # Update quota reset date
    local next_reset_date=$(date -d "next month" +%Y-%m-01)
    sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):.*/$username:\1:\2:\3:\4:\5:$next_reset_date/" "$PROXY_DB"
    
    log_success "Quota reset for user: $username"
}

# Check if already installed
check_existing_installation() {
    if [[ -f /etc/sockd.conf ]] && [[ -f /etc/squid/squid.conf ]] && systemctl is-active --quiet squid && systemctl is-active --quiet sockd; then
        log_info "Enhanced dual proxy system already installed. Entering management mode..."
        init_database
        show_main_menu
        exit 0
    fi
}

# Initial installation
install_enhanced_dual_proxy() {
    print_banner
    
    log_info "Starting enhanced dual proxy installation with bandwidth control..."
    
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
    monitor_bandwidth_usage
    setup_monthly_quota_reset
    
    # Create initial proxy pairs if requested
    if [[ $initial_count -gt 0 ]]; then
        log_info "Creating $initial_count initial proxy pairs (unlimited bandwidth)..."
        
        local proxy_list=""
        local quota_reset_date=$(date -d "next month" +%Y-%m-01)
        
        for ((i=1; i<=initial_count; i++)); do
            local username=$(generate_unique_username)
            local password=$(generate_unique_password)
            
            if [[ -n "$username" && -n "$password" ]]; then
                # Create system user
                useradd -M -s /usr/sbin/nologin "$username" 2>/dev/null
                echo "$username:$password" | chpasswd
                
                # Add to Squid
                htpasswd -b /etc/squid/passwd "$username" "$password" >/dev/null 2>&1
                
                # Add to database (unlimited by default)
                echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:0:0:$quota_reset_date" >> "$PROXY_DB"
                
                # Add to proxy list
                proxy_list+="HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password | Speed: Unlimited | Quota: Unlimited\n"
                proxy_list+="SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password | Speed: Unlimited | Quota: Unlimited\n\n"
            fi
        done
        
        # Restart Squid to reload users
        systemctl reload squid >/dev/null 2>&1
        
        echo -e "\n${GREEN}✓ Installation completed with $initial_count proxy pairs!${NC}\n"
        echo -e "${CYAN}Initial Proxy List (All Unlimited):${NC}"
        echo -e "$proxy_list"
        
        # Upload proxy list
        upload_proxy_list "$proxy_list"
    else
        echo -e "\n${GREEN}✓ Enhanced installation completed!${NC}"
        log_info "Use the management menu to create proxy pairs with bandwidth control"
    fi
    
    # Save installation info
    cat > /root/enhanced_dual_proxy_info.txt << EOF
Enhanced Dual Proxy Manager Installation
========================================
Installation Date: $(date)
Server IP: $SERVER_IP
HTTP Proxy Port: $HTTP_PORT
SOCKS5 Proxy Port: $SOCKS_PORT
Initial Proxy Pairs: $initial_count

New Features:
- Bandwidth speed limiting (per user)
- Monthly quota management (per user)
- Real-time bandwidth monitoring
- Automatic quota reset
- Advanced user management

Management:
- Run: bash $(realpath "$0")
- Config Directory: $CONFIG_DIR
- Proxy Database: $PROXY_DB
- Bandwidth Database: $BANDWIDTH_DB

Service Commands:
- HTTP Proxy: systemctl {start|stop|restart|status} squid
- SOCKS5 Proxy: systemctl {start|stop|restart|status} sockd

Log Files:
- HTTP Proxy: /var/log/squid/access.log
- SOCKS5 Proxy: /var/log/sockd.log
- Bandwidth Monitor: /var/log/proxy-bandwidth-monitor.log

Bandwidth Control:
- Speed limits applied per user (upload + download)
- Monthly quotas with automatic blocking
- Real-time usage monitoring
- Automatic monthly quota reset

Default Settings:
- All new proxies: Unlimited speed and quota
- Can be customized per user via management menu
EOF
    
    log_success "Installation information saved to /root/enhanced_dual_proxy_info.txt"
    
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
    install_enhanced_dual_proxy
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
        [[ -f /root/enhanced_dual_proxy_info.txt ]] && cat /root/enhanced_dual_proxy_info.txt || log_error "Info file not found"
        ;;
    "status")
        check_root
        get_network_info
        show_service_status
        ;;
    "stats")
        check_root
        init_database
        show_bandwidth_statistics
        ;;
    *)
        main
        ;;
esac