#!/bin/bash

# Final Dual Proxy Manager v5.0 - Complete Edition
# HTTP Proxy (Squid) + SOCKS5 Proxy (Dante) with Flexible Bandwidth Control
# Full CRUD operations + Bandwidth Management + Quota Control
# Author: Enhanced by AI Assistant - Final Version

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configuration files and directories
PROXY_DB="/etc/proxy-manager/proxy_users.db"
BANDWIDTH_DB="/etc/proxy-manager/bandwidth_usage.db"
CONFIG_DIR="/etc/proxy-manager"
HTTP_PORT=3128
SOCKS_PORT=1080
SERVER_IP=""
INTERFACE=""

# Global variables
MONITORING_ENABLED=false

# Functions
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "══════════════════════════════════════════════════════════════"
    echo "    FINAL DUAL PROXY MANAGER v5.0 - Complete Edition"
    echo "    HTTP Proxy (Squid) + SOCKS5 Proxy (Dante)"
    echo "    Full CRUD + Flexible Bandwidth Control + Quota Management"
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
init_databases() {
    mkdir -p "$CONFIG_DIR"
    
    # Initialize proxy users database
    if [[ ! -f "$PROXY_DB" ]]; then
        cat > "$PROXY_DB" << 'EOF'
# Final Dual Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:TOTAL_QUOTA_GB:USED_BYTES
# STATUS: active, blocked_quota, blocked_manual
# SPEED_LIMIT_MBPS: 0 = Unlimited
# TOTAL_QUOTA_GB: 0 = Unlimited
# USED_BYTES: Total bytes used
EOF
        log_info "Proxy users database initialized"
    fi
    
    # Initialize bandwidth usage database
    if [[ ! -f "$BANDWIDTH_DB" ]]; then
        cat > "$BANDWIDTH_DB" << 'EOF'
# Bandwidth Usage Tracking Database
# Format: USERNAME:TIMESTAMP:BYTES_USED:SESSION_ID
# This file tracks real-time bandwidth usage for quota management
EOF
        log_info "Bandwidth usage database initialized"
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
        password="pass_$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)"
        
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
        apt-get install -y squid apache2-utils curl wget openssl make gcc zip jq bc iptables-persistent
    else
        yum update -y
        yum install -y epel-release
        yum install -y squid httpd-tools curl wget openssl make gcc zip jq bc iptables-services
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
# Final Dual Proxy Manager - HTTP Proxy Configuration
http_port ${HTTP_PORT}

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm "Final Dual Proxy Authentication Required"
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED

# Access control
http_access allow authenticated
http_access deny all

# Network settings
visible_hostname final-dual-proxy-server
dns_v4_first on

# Performance settings
cache_mem 512 MB
maximum_object_size 256 MB
pipeline_prefetch on

# Logging with detailed format for bandwidth tracking
access_log /var/log/squid/access.log combined
cache_log /var/log/squid/cache.log
pid_filename /var/run/squid.pid

# Custom log format for bandwidth monitoring
logformat combined %>a %[ui %[un [%tl] "%rm %ru HTTP/%rv" %>Hs %<st "%{Referer}>h" "%{User-Agent}>h" %Ss:%Sh %<A %tr

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
# Final Dual Proxy Manager - SOCKS5 Proxy Configuration
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
Description=Dante Socks Proxy v1.4.3 - Final Dual Proxy Manager
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

# Setup Traffic Control for bandwidth limiting
setup_traffic_control() {
    log_info "Setting up Traffic Control for bandwidth management..."
    
    # Remove existing qdisc if any
    tc qdisc del dev "$INTERFACE" root 2>/dev/null
    
    # Create HTB qdisc
    tc qdisc add dev "$INTERFACE" root handle 1: htb default 999
    
    # Create main class (1000Mbps ceiling)
    tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate 1000mbit
    
    # Create default class for unlimited users
    tc class add dev "$INTERFACE" parent 1:1 classid 1:999 htb rate 1000mbit ceil 1000mbit
    
    log_success "Traffic Control setup completed"
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

# Create bandwidth monitoring script
create_bandwidth_monitor() {
    log_info "Creating bandwidth monitoring system..."
    
    # Create bandwidth monitor script
    cat > /usr/local/bin/proxy-bandwidth-monitor.sh << 'EOF'
#!/bin/bash

# Final Dual Proxy Manager - Bandwidth Monitor
# Monitors bandwidth usage and enforces quotas

PROXY_DB="/etc/proxy-manager/proxy_users.db"
BANDWIDTH_DB="/etc/proxy-manager/bandwidth_usage.db"
LOG_FILE="/var/log/proxy-bandwidth-monitor.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to get user bandwidth usage from Squid logs
get_user_bandwidth() {
    local username="$1"
    local bytes_used=0
    
    # Parse Squid access log for user bandwidth
    if [[ -f /var/log/squid/access.log ]]; then
        bytes_used=$(awk -v user="$username" '
            $3 == user {
                bytes_sent = $5
                bytes_received = $6
                if (bytes_sent ~ /^[0-9]+$/ && bytes_received ~ /^[0-9]+$/) {
                    total += (bytes_sent + bytes_received)
                }
            }
            END { print total+0 }
        ' /var/log/squid/access.log)
    fi
    
    echo "$bytes_used"
}

# Function to update user bandwidth usage in database
update_user_bandwidth() {
    local username="$1"
    local used_bytes="$2"
    
    # Update the used_bytes field in proxy_users.db
    sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$/$username:\1:\2:\3:\4:\5:$used_bytes/" "$PROXY_DB"
}

# Function to block user when quota exceeded
block_user() {
    local username="$1"
    local uid=$(id -u "$username" 2>/dev/null)
    
    if [[ -n "$uid" ]]; then
        # Block with iptables
        iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
        
        # Update status in database
        sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_quota:/" "$PROXY_DB"
        
        log_message "User $username blocked due to quota exceeded"
    fi
}

# Main monitoring loop
log_message "Starting bandwidth monitoring"

while IFS=':' read -r username password created_date status speed_limit quota_gb used_bytes; do
    # Skip comments and empty lines
    [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
    
    # Skip if user doesn't exist
    if ! getent passwd "$username" >/dev/null 2>&1; then
        continue
    fi
    
    # Get current bandwidth usage
    current_usage=$(get_user_bandwidth "$username")
    
    # Update usage in database
    update_user_bandwidth "$username" "$current_usage"
    
    # Check quota if user has limit
    if [[ "$quota_gb" -gt 0 && "$status" == "active" ]]; then
        quota_bytes=$((quota_gb * 1024 * 1024 * 1024))
        
        if [[ "$current_usage" -ge "$quota_bytes" ]]; then
            block_user "$username"
            log_message "User $username exceeded quota: ${current_usage} bytes / ${quota_bytes} bytes"
        fi
    fi
    
done < "$PROXY_DB"

log_message "Bandwidth monitoring completed"
EOF

    chmod +x /usr/local/bin/proxy-bandwidth-monitor.sh
    
    # Create cron job for bandwidth monitoring
    cat > /etc/cron.d/proxy-bandwidth-monitor << 'EOF'
# Final Dual Proxy Manager - Bandwidth Monitoring
# Runs every 5 minutes
*/5 * * * * root /usr/local/bin/proxy-bandwidth-monitor.sh
EOF
    
    log_success "Bandwidth monitoring system created"
}

# Apply bandwidth limit to user
apply_bandwidth_limit() {
    local username="$1"
    local speed_mbps="$2"
    
    if [[ "$speed_mbps" -eq 0 ]]; then
        # Remove bandwidth limit (unlimited)
        local uid=$(id -u "$username" 2>/dev/null)
        if [[ -n "$uid" ]]; then
            local class_id="1:$((1000 + uid % 1000))"
            tc class del dev "$INTERFACE" classid "$class_id" 2>/dev/null
            tc filter del dev "$INTERFACE" protocol ip parent 1: handle "$uid" fw 2>/dev/null
            iptables -t mangle -D OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid" 2>/dev/null
        fi
    else
        # Apply bandwidth limit
        local uid=$(id -u "$username" 2>/dev/null)
        if [[ -n "$uid" ]]; then
            local class_id="1:$((1000 + uid % 1000))"
            
            # Create class for user
            tc class add dev "$INTERFACE" parent 1:1 classid "$class_id" htb rate "${speed_mbps}mbit" ceil "${speed_mbps}mbit" 2>/dev/null
            
            # Create filter for user traffic
            tc filter add dev "$INTERFACE" protocol ip parent 1:0 prio 1 handle "$uid" fw flowid "$class_id" 2>/dev/null
            
            # Mark packets with iptables
            iptables -t mangle -D OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid" 2>/dev/null
            iptables -t mangle -A OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid"
        fi
    fi
}

# Block/Unblock user
toggle_user_block() {
    local username="$1"
    local action="$2"  # "block" or "unblock"
    
    local uid=$(id -u "$username" 2>/dev/null)
    if [[ -z "$uid" ]]; then
        log_error "User $username not found"
        return 1
    fi
    
    if [[ "$action" == "block" ]]; then
        # Block user
        iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
        sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_manual:/" "$PROXY_DB"
        sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_quota:/$username:\1:\2:blocked_manual:/" "$PROXY_DB"
        log_success "User $username blocked manually"
    else
        # Unblock user
        iptables -D OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
        sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_manual:/$username:\1:\2:active:/" "$PROXY_DB"
        sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_quota:/$username:\1:\2:active:/" "$PROXY_DB"
        log_success "User $username unblocked"
    fi
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

# CREATE - Add single proxy pair with bandwidth control
create_proxy_pair() {
    log_info "Creating new proxy pair with bandwidth control..."
    
    echo -e "\n${YELLOW}Bandwidth Configuration:${NC}"
    echo "1) Unlimited (default)"
    echo "2) Custom speed limit and total quota"
    echo
    
    local bandwidth_choice
    while true; do
        read -p "Select option [1-2]: " bandwidth_choice
        if [[ "$bandwidth_choice" =~ ^[12]$ ]]; then
            break
        else
            log_error "Please select 1 or 2"
        fi
    done
    
    local speed_limit=0
    local quota_gb=0
    
    if [[ "$bandwidth_choice" == "2" ]]; then
        while true; do
            read -p "Enter speed limit in Mbps (0 for unlimited): " speed_limit
            if [[ "$speed_limit" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid number"
            fi
        done
        
        while true; do
            read -p "Enter total quota in GB (0 for unlimited): " quota_gb
            if [[ "$quota_gb" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid number"
            fi
        done
    fi
    
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
    echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:$speed_limit:$quota_gb:0" >> "$PROXY_DB"
    
    # Apply bandwidth limit if specified
    if [[ "$speed_limit" -gt 0 ]]; then
        apply_bandwidth_limit "$username" "$speed_limit"
    fi
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    echo -e "\n${GREEN}✓ Proxy pair created successfully!${NC}"
    echo -e "${YELLOW}HTTP Proxy:${NC}   $SERVER_IP:$HTTP_PORT:$username:$password"
    echo -e "${YELLOW}SOCKS5 Proxy:${NC} $SERVER_IP:$SOCKS_PORT:$username:$password"
    
    if [[ "$speed_limit" -gt 0 ]]; then
        echo -e "${YELLOW}Speed Limit:${NC}  ${speed_limit}Mbps"
    else
        echo -e "${YELLOW}Speed Limit:${NC}  Unlimited"
    fi
    
    if [[ "$quota_gb" -gt 0 ]]; then
        echo -e "${YELLOW}Total Quota:${NC}  ${quota_gb}GB"
    else
        echo -e "${YELLOW}Total Quota:${NC}  Unlimited"
    fi
    
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
    
    echo -e "\n${YELLOW}Bandwidth Configuration for all proxies:${NC}"
    echo "1) Unlimited (default)"
    echo "2) Custom speed limit and total quota"
    echo
    
    local bandwidth_choice
    while true; do
        read -p "Select option [1-2]: " bandwidth_choice
        if [[ "$bandwidth_choice" =~ ^[12]$ ]]; then
            break
        else
            log_error "Please select 1 or 2"
        fi
    done
    
    local speed_limit=0
    local quota_gb=0
    
    if [[ "$bandwidth_choice" == "2" ]]; then
        while true; do
            read -p "Enter speed limit in Mbps (0 for unlimited): " speed_limit
            if [[ "$speed_limit" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid number"
            fi
        done
        
        while true; do
            read -p "Enter total quota in GB (0 for unlimited): " quota_gb
            if [[ "$quota_gb" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid number"
            fi
        done
    fi
    
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
            echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:$speed_limit:$quota_gb:0" >> "$PROXY_DB"
            
            # Apply bandwidth limit if specified
            if [[ "$speed_limit" -gt 0 ]]; then
                apply_bandwidth_limit "$username" "$speed_limit"
            fi
            
            # Add to proxy list
            if [[ "$speed_limit" -gt 0 ]]; then
                local speed_info="${speed_limit}Mbps"
            else
                local speed_info="Unlimited"
            fi
            
            if [[ "$quota_gb" -gt 0 ]]; then
                local quota_info="${quota_gb}GB"
            else
                local quota_info="Unlimited"
            fi
            
            proxy_list+="HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password | Speed: $speed_info | Quota: $quota_info\n"
            proxy_list+="SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password | Speed: $speed_info | Quota: $quota_info\n\n"
            
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
    local filename="/tmp/proxy_pairs_$(date +%Y%m%d_%H%M%S).txt"
    echo -e "$proxy_list" > "$filename"
    log_success "Proxy list saved to $filename"
    
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
    
    while IFS=':' read -r username password created_date status speed_limit quota_gb used_bytes; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        ((count++))
        echo -e "${PURPLE}[$count]${NC} User: ${GREEN}$username${NC}"
        echo -e "    HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password"
        echo -e "    SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password"
        echo -e "    Created: $created_date | Status: $status"
        
        # Display speed limit
        if [[ "$speed_limit" -eq 0 ]]; then
            echo -e "    Speed Limit: Unlimited"
        else
            echo -e "    Speed Limit: ${speed_limit}Mbps"
        fi
        
        # Display quota
        if [[ "$quota_gb" -eq 0 ]]; then
            echo -e "    Total Quota: Unlimited"
        else
            echo -e "    Total Quota: ${quota_gb}GB"
        fi
        
        # Display usage
        local used_mb=$((used_bytes / 1024 / 1024))
        local used_gb=$((used_bytes / 1024 / 1024 / 1024))
        if [[ "$used_gb" -gt 0 ]]; then
            echo -e "    Usage: ${used_gb}GB"
        else
            echo -e "    Usage: ${used_mb}MB"
        fi
        
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
    echo "2) Update total quota only"
    echo "3) Update both speed limit and quota"
    echo "4) Reset to unlimited"
    echo "5) Block/Unblock user"
    echo
    
    local choice
    while true; do
        read -p "Select option [1-5]: " choice
        if [[ "$choice" =~ ^[1-5]$ ]]; then
            break
        else
            log_error "Please select 1-5"
        fi
    done
    
    case $choice in
        1)
            # Update speed limit only
            local new_speed
            while true; do
                read -p "Enter new speed limit in Mbps (0 for unlimited): " new_speed
                if [[ "$new_speed" =~ ^[0-9]+$ ]]; then
                    break
                else
                    log_error "Please enter a valid number"
                fi
            done
            
            # Update database
            sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:\([^:]*\):\([^:]*\)$/$username:\1:\2:\3:$new_speed:\4:\5/" "$PROXY_DB"
            
            # Apply bandwidth limit
            apply_bandwidth_limit "$username" "$new_speed"
            
            if [[ "$new_speed" -eq 0 ]]; then
                log_success "Speed limit removed for user: $username"
            else
                log_success "Speed limit updated to ${new_speed}Mbps for user: $username"
            fi
            ;;
        2)
            # Update quota only
            local new_quota
            while true; do
                read -p "Enter new total quota in GB (0 for unlimited): " new_quota
                if [[ "$new_quota" =~ ^[0-9]+$ ]]; then
                    break
                else
                    log_error "Please enter a valid number"
                fi
            done
            
            # Update database
            sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:\([^:]*\)$/$username:\1:\2:\3:\4:$new_quota:\5/" "$PROXY_DB"
            
            if [[ "$new_quota" -eq 0 ]]; then
                log_success "Quota limit removed for user: $username"
            else
                log_success "Quota updated to ${new_quota}GB for user: $username"
            fi
            ;;
        3)
            # Update both
            local new_speed new_quota
            while true; do
                read -p "Enter new speed limit in Mbps (0 for unlimited): " new_speed
                if [[ "$new_speed" =~ ^[0-9]+$ ]]; then
                    break
                else
                    log_error "Please enter a valid number"
                fi
            done
            
            while true; do
                read -p "Enter new total quota in GB (0 for unlimited): " new_quota
                if [[ "$new_quota" =~ ^[0-9]+$ ]]; then
                    break
                else
                    log_error "Please enter a valid number"
                fi
            done
            
            # Update database
            sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:\([^:]*\)$/$username:\1:\2:\3:$new_speed:$new_quota:\4/" "$PROXY_DB"
            
            # Apply bandwidth limit
            apply_bandwidth_limit "$username" "$new_speed"
            
            local speed_info quota_info
            if [[ "$new_speed" -eq 0 ]]; then
                speed_info="Unlimited"
            else
                speed_info="${new_speed}Mbps"
            fi
            
            if [[ "$new_quota" -eq 0 ]]; then
                quota_info="Unlimited"
            else
                quota_info="${new_quota}GB"
            fi
            
            log_success "Speed: $speed_info, Quota: $quota_info updated for user: $username"
            ;;
        4)
            # Reset to unlimited
            sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:\([^:]*\)$/$username:\1:\2:\3:0:0:\4/" "$PROXY_DB"
            apply_bandwidth_limit "$username" 0
            log_success "User $username reset to unlimited"
            ;;
        5)
            # Block/Unblock user
            local current_status=$(grep "^$username:" "$PROXY_DB" | cut -d':' -f4)
            echo -e "\nCurrent status: $current_status"
            echo "1) Block user (stop access)"
            echo "2) Unblock user (restore access)"
            
            local block_choice
            while true; do
                read -p "Select [1-2]: " block_choice
                if [[ "$block_choice" =~ ^[12]$ ]]; then
                    break
                else
                    log_error "Please select 1 or 2"
                fi
            done
            
            if [[ "$block_choice" == "1" ]]; then
                toggle_user_block "$username" "block"
            else
                toggle_user_block "$username" "unblock"
            fi
            ;;
    esac
}

# UPDATE - Update proxy password
update_proxy_password() {
    echo -e "${CYAN}Update Proxy Password${NC}\n"
    
    # List current users
    read_proxy_pairs
    
    read -p "Enter username to update password: " username
    
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
    
    # Remove bandwidth limits
    apply_bandwidth_limit "$username" 0
    
    # Remove any blocks
    toggle_user_block "$username" "unblock" 2>/dev/null
    
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
    while IFS=':' read -r username password created_date status speed_limit quota_gb used_bytes; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        # Remove bandwidth limits
        apply_bandwidth_limit "$username" 0
        
        # Remove any blocks
        toggle_user_block "$username" "unblock" 2>/dev/null
        
        # Delete system user
        userdel "$username" 2>/dev/null
        
        # Remove from Squid
        htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1
    done < "$PROXY_DB"
    
    # Clear database (keep header)
    cat > "$PROXY_DB" << 'EOF'
# Final Dual Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:TOTAL_QUOTA_GB:USED_BYTES
# STATUS: active, blocked_quota, blocked_manual
# SPEED_LIMIT_MBPS: 0 = Unlimited
# TOTAL_QUOTA_GB: 0 = Unlimited
# USED_BYTES: Total bytes used
EOF
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    log_success "All proxy pairs deleted"
}

# Show bandwidth statistics
show_bandwidth_statistics() {
    echo -e "${CYAN}Bandwidth Usage Statistics${NC}\n"
    
    if [[ ! -f "$PROXY_DB" ]] || [[ ! -s "$PROXY_DB" ]]; then
        log_warning "No proxy data found"
        return 0
    fi
    
    printf "%-20s %-15s %-15s %-15s %-10s\n" "Username" "Speed Limit" "Total Quota" "Used" "Status"
    printf "%-20s %-15s %-15s %-15s %-10s\n" "--------" "-----------" "-----------" "----" "------"
    
    local total_usage=0
    
    while IFS=':' read -r username password created_date status speed_limit quota_gb used_bytes; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        # Format speed limit
        local speed_display
        if [[ "$speed_limit" -eq 0 ]]; then
            speed_display="Unlimited"
        else
            speed_display="${speed_limit}Mbps"
        fi
        
        # Format quota
        local quota_display
        if [[ "$quota_gb" -eq 0 ]]; then
            quota_display="Unlimited"
        else
            quota_display="${quota_gb}GB"
        fi
        
        # Format usage
        local used_gb=$((used_bytes / 1024 / 1024 / 1024))
        local used_mb=$((used_bytes / 1024 / 1024))
        local usage_display
        if [[ "$used_gb" -gt 0 ]]; then
            usage_display="${used_gb}GB"
        else
            usage_display="${used_mb}MB"
        fi
        
        # Format status
        local status_display
        case $status in
            "active") status_display="Active" ;;
            "blocked_quota") status_display="Blocked" ;;
            "blocked_manual") status_display="Blocked" ;;
            *) status_display="Unknown" ;;
        esac
        
        printf "%-20s %-15s %-15s %-15s %-10s\n" "$username" "$speed_display" "$quota_display" "$usage_display" "$status_display"
        
        total_usage=$((total_usage + used_bytes))
    done < "$PROXY_DB"
    
    echo
    local total_gb=$((total_usage / 1024 / 1024 / 1024))
    echo "Total Usage: ${total_gb}GB"
}

# Monitor bandwidth usage real-time
monitor_bandwidth_realtime() {
    echo -e "${CYAN}Real-time Bandwidth Usage Monitoring${NC}"
    echo "Press Ctrl+C to stop monitoring"
    echo
    
    while true; do
        clear
        echo -e "${CYAN}Real-time Bandwidth Usage - $(date '+%Y-%m-%d %H:%M:%S')${NC}\n"
        
        # Show active connections
        local http_connections=$(netstat -an 2>/dev/null | grep ":$HTTP_PORT" | grep ESTABLISHED | wc -l)
        local socks_connections=$(netstat -an 2>/dev/null | grep ":$SOCKS_PORT" | grep ESTABLISHED | wc -l)
        
        echo -e "${YELLOW}Active Connections:${NC}"
        echo "HTTP Proxy: $http_connections connections"
        echo "SOCKS5 Proxy: $socks_connections connections"
        echo
        
        # Show bandwidth statistics
        show_bandwidth_statistics
        
        echo
        echo "[Updates every 5 seconds - Press Ctrl+C to stop]"
        
        sleep 5
    done
}

# Reset user quota
reset_user_quota() {
    echo -e "${CYAN}Reset User Quota${NC}\n"
    
    # List current users
    read_proxy_pairs
    
    read -p "Enter username to reset quota: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty"
        return 1
    fi
    
    # Check if user exists
    if ! grep -q "^$username:" "$PROXY_DB" 2>/dev/null; then
        log_error "User '$username' not found"
        return 1
    fi
    
    # Confirm reset
    read -p "Are you sure you want to reset quota for user '$username'? [y/N]: " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Reset cancelled"
        return 0
    fi
    
    # Reset usage to 0
    sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$/$username:\1:\2:\3:\4:\5:0/" "$PROXY_DB"
    
    # Unblock user if blocked due to quota
    local current_status=$(grep "^$username:" "$PROXY_DB" | cut -d':' -f4)
    if [[ "$current_status" == "blocked_quota" ]]; then
        toggle_user_block "$username" "unblock"
    fi
    
    log_success "Quota reset for user: $username"
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
    
    echo "# Final Dual Proxy Export - $(date)" > "$export_file"
    echo "# Server: $SERVER_IP" >> "$export_file"
    echo "# HTTP Port: $HTTP_PORT | SOCKS5 Port: $SOCKS_PORT" >> "$export_file"
    echo "# Format: TYPE:IP:PORT:USERNAME:PASSWORD:SPEED_LIMIT:QUOTA" >> "$export_file"
    echo "" >> "$export_file"
    
    local count=0
    while IFS=':' read -r username password created_date status speed_limit quota_gb used_bytes; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        local speed_info quota_info
        if [[ "$speed_limit" -eq 0 ]]; then
            speed_info="Unlimited"
        else
            speed_info="${speed_limit}Mbps"
        fi
        
        if [[ "$quota_gb" -eq 0 ]]; then
            quota_info="Unlimited"
        else
            quota_info="${quota_gb}GB"
        fi
        
        echo "HTTP:$SERVER_IP:$HTTP_PORT:$username:$password:$speed_info:$quota_info" >> "$export_file"
        echo "SOCKS5:$SERVER_IP:$SOCKS_PORT:$username:$password:$speed_info:$quota_info" >> "$export_file"
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
    echo "HTTP Port $HTTP_PORT:   $(netstat -ln 2>/dev/null | grep ":$HTTP_PORT " >/dev/null && echo -e "${GREEN}Open${NC}" || echo -e "${RED}Closed${NC}")"
    echo "SOCKS5 Port $SOCKS_PORT: $(netstat -ln 2>/dev/null | grep ":$SOCKS_PORT " >/dev/null && echo -e "${GREEN}Open${NC}" || echo -e "${RED}Closed${NC}")"
    
    echo -e "\n${YELLOW}Traffic Control Status:${NC}"
    if tc qdisc show dev "$INTERFACE" 2>/dev/null | grep -q "htb"; then
        echo -e "Bandwidth Control: ${GREEN}Active${NC}"
        echo "Active bandwidth limits:"
        tc -s class show dev "$INTERFACE" 2>/dev/null | grep -A 1 "class htb 1:" | grep -E "(class|rate)" | while read line; do
            if [[ "$line" =~ class.*1:([0-9]+) ]]; then
                class_id="${BASH_REMATCH[1]}"
                if [[ "$class_id" != "1" && "$class_id" != "999" ]]; then
                    echo "  Class $class_id: $(echo "$line" | grep -o 'rate [0-9]*[a-zA-Z]*' | cut -d' ' -f2)"
                fi
            fi
        done
    else
        echo -e "Bandwidth Control: ${RED}Inactive${NC}"
    fi
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
    
    # Get user info from database
    local user_info=$(grep "^$username:" "$PROXY_DB" 2>/dev/null)
    if [[ -z "$user_info" ]]; then
        log_error "User '$username' not found"
        return 1
    fi
    
    local password=$(echo "$user_info" | cut -d':' -f2)
    local status=$(echo "$user_info" | cut -d':' -f4)
    local speed_limit=$(echo "$user_info" | cut -d':' -f5)
    local quota_gb=$(echo "$user_info" | cut -d':' -f6)
    local used_bytes=$(echo "$user_info" | cut -d':' -f7)
    
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
    
    # Show bandwidth information
    echo -e "\n${YELLOW}Bandwidth Information:${NC}"
    if [[ "$speed_limit" -eq 0 ]]; then
        echo "Speed Limit: Unlimited"
    else
        echo "Speed Limit: ${speed_limit}Mbps"
    fi
    
    if [[ "$quota_gb" -eq 0 ]]; then
        echo "Total Quota: Unlimited"
    else
        echo "Total Quota: ${quota_gb}GB"
    fi
    
    echo "Status: $status"
    
    local used_gb=$((used_bytes / 1024 / 1024 / 1024))
    local used_mb=$((used_bytes / 1024 / 1024))
    if [[ "$used_gb" -gt 0 ]]; then
        echo "Usage: ${used_gb}GB"
    else
        echo "Usage: ${used_mb}MB"
    fi
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
        echo -e "\n${YELLOW}Final Dual Proxy Management Menu${NC}"
        echo -e "${YELLOW}Server: $SERVER_IP | HTTP: $HTTP_PORT | SOCKS5: $SOCKS_PORT${NC}"
        echo
        echo -e "${CYAN}CRUD Operations:${NC}"
        echo -e "${GREEN}1)${NC} Create Single Proxy Pair (with Bandwidth Control)"
        echo -e "${GREEN}2)${NC} Create Multiple Proxy Pairs (with Bandwidth Control)"
        echo -e "${GREEN}3)${NC} Read/List All Proxy Pairs (with Bandwidth Info)"
        echo -e "${GREEN}4)${NC} Update Proxy Bandwidth Settings"
        echo -e "${GREEN}5)${NC} Update Proxy Password"
        echo -e "${GREEN}6)${NC} Delete Single Proxy Pair"
        echo -e "${GREEN}7)${NC} Delete All Proxy Pairs"
        echo
        echo -e "${CYAN}Bandwidth Management:${NC}"
        echo -e "${BLUE}8)${NC} Show Bandwidth Statistics"
        echo -e "${BLUE}9)${NC} Monitor Bandwidth Usage (Real-time)"
        echo -e "${BLUE}10)${NC} Reset User Quota"
        echo
        echo -e "${CYAN}System Management:${NC}"
        echo -e "${PURPLE}11)${NC} Export Proxy Pairs"
        echo -e "${PURPLE}12)${NC} Test Proxy Pair"
        echo -e "${PURPLE}13)${NC} Service Status"
        echo -e "${PURPLE}14)${NC} Restart Services"
        echo -e "${PURPLE}15)${NC} View Logs"
        echo
        echo -e "${RED}0)${NC} Exit"
        echo

        read -p "Select an option [0-15]: " choice

        case $choice in
            1) create_proxy_pair ;;
            2) create_multiple_proxy_pairs ;;
            3) read_proxy_pairs ;;
            4) update_proxy_bandwidth ;;
            5) update_proxy_password ;;
            6) delete_proxy_pair ;;
            7) delete_all_proxy_pairs ;;
            8) show_bandwidth_statistics ;;
            9) monitor_bandwidth_realtime ;;
            10) reset_user_quota ;;
            11) export_proxy_pairs ;;
            12) test_proxy_pair ;;
            13) show_service_status ;;
            14) restart_services ;;
            15) show_logs ;;
            0) echo "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac

        echo
        read -p "Press Enter to continue..."
    done
}

# Check if already installed
check_existing_installation() {
    if [[ -f /etc/sockd.conf ]] && [[ -f /etc/squid/squid.conf ]] && systemctl is-active --quiet squid && systemctl is-active --quiet sockd; then
        log_info "Final dual proxy system already installed. Entering management mode..."
        init_databases
        show_main_menu
        exit 0
    fi
}

# Initial installation
install_final_dual_proxy() {
    print_banner
    
    log_info "Starting Final Dual Proxy installation..."
    
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
    setup_traffic_control
    configure_firewall
    init_databases
    create_bandwidth_monitor
    start_services
    
    # Create initial proxy pairs if requested
    if [[ $initial_count -gt 0 ]]; then
        log_info "Creating $initial_count initial proxy pairs (unlimited)..."
        
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
                
                # Add to database (unlimited by default)
                echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:0:0:0" >> "$PROXY_DB"
                
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
        echo -e "\n${GREEN}✓ Installation completed!${NC}"
        log_info "Use the management menu to create proxy pairs"
    fi
    
    # Save installation info
    cat > /root/final_dual_proxy_info.txt << EOF
Final Dual Proxy Manager Installation
====================================
Installation Date: $(date)
Server IP: $SERVER_IP
HTTP Proxy Port: $HTTP_PORT
SOCKS5 Proxy Port: $SOCKS_PORT
Initial Proxy Pairs: $initial_count

Features:
- Full CRUD Operations
- Flexible Bandwidth Control
- Quota Management
- Real-time Monitoring
- Automatic Blocking

Management:
- Run: bash $(realpath "$0")
- Config Directory: $CONFIG_DIR
- Users Database: $PROXY_DB
- Bandwidth Database: $BANDWIDTH_DB

Service Commands:
- HTTP Proxy: systemctl {start|stop|restart|status} squid
- SOCKS5 Proxy: systemctl {start|stop|restart|status} sockd

Log Files:
- HTTP Proxy: /var/log/squid/access.log
- SOCKS5 Proxy: /var/log/sockd.log
- Bandwidth Monitor: /var/log/proxy-bandwidth-monitor.log

Bandwidth Control:
- Traffic Control: tc qdisc show dev $INTERFACE
- Monitoring: /usr/local/bin/proxy-bandwidth-monitor.sh
- Cron Job: /etc/cron.d/proxy-bandwidth-monitor
EOF
    
    log_success "Installation information saved to /root/final_dual_proxy_info.txt"
    
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
    install_final_dual_proxy
}

# Handle command line arguments
case "${1:-}" in
    "menu")
        check_shell
        check_root
        get_network_info
        init_databases
        show_main_menu
        ;;
    "info")
        [[ -f /root/final_dual_proxy_info.txt ]] && cat /root/final_dual_proxy_info.txt || log_error "Info file not found"
        ;;
    "status")
        check_root
        get_network_info
        show_service_status
        ;;
    "stats")
        check_root
        get_network_info
        init_databases
        show_bandwidth_statistics
        ;;
    *)
        main
        ;;
esac