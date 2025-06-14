#!/bin/bash

# Flexible Dual Proxy Manager v4.0
# HTTP Proxy (Squid) + SOCKS5 Proxy (Dante)
# On-demand Bandwidth Control - No monthly restrictions
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
    echo "    FLEXIBLE DUAL PROXY MANAGER v4.0"
    echo "    HTTP + SOCKS5 with On-Demand Bandwidth Control"
    echo "    Giới hạn khi muốn - Không bắt buộc theo tháng"
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
# Flexible Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:TOTAL_QUOTA_GB:USED_BYTES
# SPEED_LIMIT_MBPS: 0 = Unlimited
# TOTAL_QUOTA_GB: 0 = Unlimited
# This file is automatically managed by the proxy manager
EOF
        log_info "Proxy database initialized"
    fi
    
    if [[ ! -f "$BANDWIDTH_DB" ]]; then
        cat > "$BANDWIDTH_DB" << 'EOF'
# Bandwidth Usage Database
# Format: USERNAME:USED_BYTES:LAST_UPDATED
# This file tracks total usage for quota management
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
        password="pass_$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)"
        
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
        apt-get install -y squid apache2-utils curl wget openssl make gcc zip jq bc
    else
        yum update -y
        yum install -y epel-release
        yum install -y squid httpd-tools curl wget openssl make gcc zip jq bc
    fi
    
    log_success "Packages installed successfully"
}

# Configure Squid (HTTP Proxy)
configure_squid() {
    log_info "Configuring Squid HTTP proxy..."
    
    [[ -f /etc/squid/squid.conf ]] && cp /etc/squid/squid.conf /etc/squid/squid.conf.backup
    
    cat > /etc/squid/squid.conf << EOF
# HTTP Proxy Configuration - Flexible Dual Proxy Manager
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
visible_hostname flexible-proxy-server
dns_v4_first on

# Performance settings
cache_mem 256 MB
maximum_object_size 128 MB
pipeline_prefetch on

# Logging with detailed format for bandwidth tracking
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
# SOCKS5 Proxy Configuration - Flexible Dual Proxy Manager
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
Description=Dante Socks Proxy v1.4.3 - Flexible Dual Proxy Manager
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

# Setup Traffic Control for bandwidth limiting
setup_traffic_control() {
    log_info "Setting up Traffic Control for bandwidth management..."
    
    # Remove existing qdisc
    tc qdisc del dev "$INTERFACE" root 2>/dev/null
    
    # Create HTB qdisc
    tc qdisc add dev "$INTERFACE" root handle 1: htb default 999
    
    # Create main class (1000Mbps ceiling)
    tc class add dev "$INTERFACE" parent 1: classid 1:1 htb rate 1000mbit
    
    # Create default class for unlimited users
    tc class add dev "$INTERFACE" parent 1:1 classid 1:999 htb rate 1000mbit ceil 1000mbit
    
    log_success "Traffic Control setup completed"
}

# Apply bandwidth limit to user
apply_bandwidth_limit() {
    local username="$1"
    local speed_mbps="$2"
    
    if [[ "$speed_mbps" -eq 0 ]]; then
        # Remove bandwidth limit (unlimited)
        remove_bandwidth_limit "$username"
        return 0
    fi
    
    local uid=$(id -u "$username" 2>/dev/null)
    if [[ -z "$uid" ]]; then
        log_error "User $username not found"
        return 1
    fi
    
    local class_id="1:$((1000 + uid % 1000))"
    
    # Remove existing class if exists
    tc class del dev "$INTERFACE" classid "$class_id" 2>/dev/null
    
    # Create new class with speed limit
    tc class add dev "$INTERFACE" parent 1:1 classid "$class_id" htb rate "${speed_mbps}mbit" ceil "${speed_mbps}mbit"
    
    # Remove existing filter
    tc filter del dev "$INTERFACE" protocol ip parent 1:0 handle "$uid" fw 2>/dev/null
    
    # Add filter for this user
    tc filter add dev "$INTERFACE" protocol ip parent 1:0 prio 1 handle "$uid" fw flowid "$class_id"
    
    # Remove existing iptables rule
    iptables -t mangle -D OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid" 2>/dev/null
    
    # Add iptables rule to mark packets
    iptables -t mangle -A OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid"
    
    log_success "Applied ${speed_mbps}Mbps limit to user $username"
}

# Remove bandwidth limit from user
remove_bandwidth_limit() {
    local username="$1"
    local uid=$(id -u "$username" 2>/dev/null)
    
    if [[ -n "$uid" ]]; then
        local class_id="1:$((1000 + uid % 1000))"
        
        # Remove TC class and filter
        tc class del dev "$INTERFACE" classid "$class_id" 2>/dev/null
        tc filter del dev "$INTERFACE" protocol ip parent 1:0 handle "$uid" fw 2>/dev/null
        
        # Remove iptables rule
        iptables -t mangle -D OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid" 2>/dev/null
        
        log_info "Removed bandwidth limit from user $username"
    fi
}

# Block user (quota exceeded)
block_user() {
    local username="$1"
    local uid=$(id -u "$username" 2>/dev/null)
    
    if [[ -n "$uid" ]]; then
        # Block all traffic from this user
        iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
        
        # Update status in database
        sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_quota:/" "$PROXY_DB"
        
        log_warning "User $username blocked due to quota exceeded"
    fi
}

# Unblock user
unblock_user() {
    local username="$1"
    local uid=$(id -u "$username" 2>/dev/null)
    
    if [[ -n "$uid" ]]; then
        # Remove block rule
        iptables -D OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
        
        # Update status in database
        sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_quota:/$username:\1:\2:active:/" "$PROXY_DB"
        
        log_success "User $username unblocked"
    fi
}

# Check and update bandwidth usage
update_bandwidth_usage() {
    local username="$1"
    
    # Parse Squid logs for this user's usage
    local used_bytes=$(awk -v user="$username" '
        $8 == user {
            bytes_sent = $5
            bytes_received = $6
            total_bytes += (bytes_sent + bytes_received)
        }
        END {
            print total_bytes + 0
        }
    ' /var/log/squid/access.log 2>/dev/null)
    
    # Update bandwidth database
    if grep -q "^$username:" "$BANDWIDTH_DB"; then
        sed -i "s/^$username:[^:]*:/$username:$used_bytes:/" "$BANDWIDTH_DB"
    else
        echo "$username:$used_bytes:$(date '+%Y-%m-%d %H:%M:%S')" >> "$BANDWIDTH_DB"
    fi
    
    # Update proxy database
    sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$/$username:\1:\2:\3:\4:\5:$used_bytes/" "$PROXY_DB"
    
    echo "$used_bytes"
}

# Check quota and block if exceeded
check_quota() {
    local username="$1"
    
    # Get quota from database
    local quota_gb=$(grep "^$username:" "$PROXY_DB" | cut -d':' -f6)
    
    if [[ "$quota_gb" -eq 0 ]]; then
        # Unlimited quota
        return 0
    fi
    
    # Get current usage
    local used_bytes=$(update_bandwidth_usage "$username")
    local quota_bytes=$((quota_gb * 1024 * 1024 * 1024))
    
    if [[ "$used_bytes" -ge "$quota_bytes" ]]; then
        block_user "$username"
        return 1
    fi
    
    return 0
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

# Create bandwidth monitoring script
create_bandwidth_monitor() {
    cat > /usr/local/bin/proxy-bandwidth-monitor.sh << 'EOF'
#!/bin/bash

# Bandwidth monitoring script for Flexible Dual Proxy Manager
PROXY_DB="/etc/proxy-manager/proxy_users.db"
BANDWIDTH_DB="/etc/proxy-manager/bandwidth_usage.db"

# Function to update bandwidth usage
update_bandwidth_usage() {
    local username="$1"
    
    # Parse Squid logs for this user's usage
    local used_bytes=$(awk -v user="$username" '
        $8 == user {
            bytes_sent = $5
            bytes_received = $6
            total_bytes += (bytes_sent + bytes_received)
        }
        END {
            print total_bytes + 0
        }
    ' /var/log/squid/access.log 2>/dev/null)
    
    # Update bandwidth database
    if grep -q "^$username:" "$BANDWIDTH_DB"; then
        sed -i "s/^$username:[^:]*:/$username:$used_bytes:/" "$BANDWIDTH_DB"
    else
        echo "$username:$used_bytes:$(date '+%Y-%m-%d %H:%M:%S')" >> "$BANDWIDTH_DB"
    fi
    
    # Update proxy database
    sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$/$username:\1:\2:\3:\4:\5:$used_bytes/" "$PROXY_DB"
    
    echo "$used_bytes"
}

# Function to check quota and block if exceeded
check_quota() {
    local username="$1"
    
    # Get quota from database
    local quota_gb=$(grep "^$username:" "$PROXY_DB" | cut -d':' -f6)
    
    if [[ "$quota_gb" -eq 0 ]]; then
        # Unlimited quota
        return 0
    fi
    
    # Get current usage
    local used_bytes=$(update_bandwidth_usage "$username")
    local quota_bytes=$((quota_gb * 1024 * 1024 * 1024))
    
    if [[ "$used_bytes" -ge "$quota_bytes" ]]; then
        # Block user
        local uid=$(id -u "$username" 2>/dev/null)
        if [[ -n "$uid" ]]; then
            iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
            sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_quota:/" "$PROXY_DB"
            echo "$(date): User $username blocked due to quota exceeded" >> /var/log/proxy-bandwidth-monitor.log
        fi
        return 1
    fi
    
    return 0
}

# Main monitoring loop
echo "$(date): Starting bandwidth monitoring" >> /var/log/proxy-bandwidth-monitor.log

# Check all active users
while IFS=':' read -r username password created_date status speed_limit quota used_bytes; do
    [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
    [[ "$status" != "active" ]] && continue
    
    check_quota "$username"
done < "$PROXY_DB"

echo "$(date): Bandwidth monitoring completed" >> /var/log/proxy-bandwidth-monitor.log
EOF

    chmod +x /usr/local/bin/proxy-bandwidth-monitor.sh
    
    # Create cron job for monitoring (every 5 minutes)
    cat > /etc/cron.d/proxy-bandwidth-monitor << 'EOF'
# Bandwidth monitoring for Flexible Dual Proxy Manager
*/5 * * * * root /usr/local/bin/proxy-bandwidth-monitor.sh
EOF
    
    log_success "Bandwidth monitoring script created"
}

# CRUD Operations

# CREATE - Add single proxy pair
create_proxy_pair() {
    log_info "Creating new proxy pair..."
    
    echo -e "\n${YELLOW}Bandwidth Configuration:${NC}"
    echo "1) Unlimited (default)"
    echo "2) Custom speed limit and total quota"
    
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
    local total_quota=0
    
    if [[ "$bandwidth_choice" = "2" ]]; then
        while true; do
            read -p "Enter speed limit in Mbps (0 for unlimited): " speed_limit
            if [[ "$speed_limit" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid number"
            fi
        done
        
        while true; do
            read -p "Enter total quota in GB (0 for unlimited): " total_quota
            if [[ "$total_quota" =~ ^[0-9]+$ ]]; then
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
    echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:$speed_limit:$total_quota:0" >> "$PROXY_DB"
    
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
    
    if [[ "$total_quota" -gt 0 ]]; then
        echo -e "${YELLOW}Total Quota:${NC}  ${total_quota}GB"
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
    local total_quota=0
    
    if [[ "$bandwidth_choice" = "2" ]]; then
        while true; do
            read -p "Enter speed limit in Mbps (0 for unlimited): " speed_limit
            if [[ "$speed_limit" =~ ^[0-9]+$ ]]; then
                break
            else
                log_error "Please enter a valid number"
            fi
        done
        
        while true; do
            read -p "Enter total quota in GB (0 for unlimited): " total_quota
            if [[ "$total_quota" =~ ^[0-9]+$ ]]; then
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
            echo "$username:$password:$(date '+%Y-%m-%d %H:%M:%S'):active:$speed_limit:$total_quota:0" >> "$PROXY_DB"
            
            # Apply bandwidth limit if specified
            if [[ "$speed_limit" -gt 0 ]]; then
                apply_bandwidth_limit "$username" "$speed_limit"
            fi
            
            # Add to proxy list
            proxy_list+="HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password"
            if [[ "$speed_limit" -gt 0 ]]; then
                proxy_list+=" | Speed: ${speed_limit}Mbps"
            else
                proxy_list+=" | Speed: Unlimited"
            fi
            if [[ "$total_quota" -gt 0 ]]; then
                proxy_list+=" | Quota: ${total_quota}GB"
            else
                proxy_list+=" | Quota: Unlimited"
            fi
            proxy_list+="\n"
            
            proxy_list+="SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password"
            if [[ "$speed_limit" -gt 0 ]]; then
                proxy_list+=" | Speed: ${speed_limit}Mbps"
            else
                proxy_list+=" | Speed: Unlimited"
            fi
            if [[ "$total_quota" -gt 0 ]]; then
                proxy_list+=" | Quota: ${total_quota}GB"
            else
                proxy_list+=" | Quota: Unlimited"
            fi
            proxy_list+="\n\n"
            
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
    echo -e "${CYAN}Current Proxy Pairs with Bandwidth Control:${NC}\n"
    
    if [[ ! -f "$PROXY_DB" ]] || [[ ! -s "$PROXY_DB" ]]; then
        log_warning "No proxy pairs found"
        return 0
    fi
    
    local count=0
    echo -e "${YELLOW}Format: HTTP and SOCKS5 pairs with bandwidth limits${NC}"
    echo -e "${YELLOW}Server IP: $SERVER_IP${NC}\n"
    
    while IFS=':' read -r username password created_date status speed_limit quota used_bytes; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        ((count++))
        echo -e "${PURPLE}[$count]${NC} User: ${GREEN}$username${NC}"
        echo -e "    HTTP:   $SERVER_IP:$HTTP_PORT:$username:$password"
        echo -e "    SOCKS5: $SERVER_IP:$SOCKS_PORT:$username:$password"
        echo -e "    Created: $created_date | Status: $status"
        
        if [[ "$speed_limit" -eq 0 ]]; then
            echo -e "    Speed Limit: Unlimited"
        else
            echo -e "    Speed Limit: ${speed_limit}Mbps"
        fi
        
        if [[ "$quota" -eq 0 ]]; then
            echo -e "    Total Quota: Unlimited"
        else
            echo -e "    Total Quota: ${quota}GB"
        fi
        
        # Calculate usage in MB/GB
        local used_mb=$((used_bytes / 1024 / 1024))
        if [[ $used_mb -gt 1024 ]]; then
            local used_gb=$((used_mb / 1024))
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
    
    local update_choice
    while true; do
        read -p "Select option [1-5]: " update_choice
        if [[ "$update_choice" =~ ^[1-5]$ ]]; then
            break
        else
            log_error "Please select 1-5"
        fi
    done
    
    case $update_choice in
        1)
            read -p "Enter new speed limit in Mbps (0 for unlimited): " new_speed
            if [[ "$new_speed" =~ ^[0-9]+$ ]]; then
                # Update speed limit in database
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:/$username:\1:\2:\3:$new_speed:/" "$PROXY_DB"
                apply_bandwidth_limit "$username" "$new_speed"
                log_success "Speed limit updated to ${new_speed}Mbps for user: $username"
            else
                log_error "Invalid speed limit"
            fi
            ;;
        2)
            read -p "Enter new total quota in GB (0 for unlimited): " new_quota
            if [[ "$new_quota" =~ ^[0-9]+$ ]]; then
                # Update quota in database
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:/$username:\1:\2:\3:\4:$new_quota:/" "$PROXY_DB"
                # Reset usage to 0
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$//$username:\1:\2:\3:\4:\5:0/" "$PROXY_DB"
                # Unblock user if was blocked
                unblock_user "$username"
                log_success "Total quota updated to ${new_quota}GB for user: $username"
            else
                log_error "Invalid quota"
            fi
            ;;
        3)
            read -p "Enter new speed limit in Mbps (0 for unlimited): " new_speed
            read -p "Enter new total quota in GB (0 for unlimited): " new_quota
            if [[ "$new_speed" =~ ^[0-9]+$ ]] && [[ "$new_quota" =~ ^[0-9]+$ ]]; then
                # Update both in database
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:/$username:\1:\2:\3:$new_speed:$new_quota:/" "$PROXY_DB"
                # Reset usage to 0
                sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$//$username:\1:\2:\3:\4:\5:0/" "$PROXY_DB"
                apply_bandwidth_limit "$username" "$new_speed"
                unblock_user "$username"
                log_success "Speed limit: ${new_speed}Mbps, Quota: ${new_quota}GB updated for user: $username"
            else
                log_error "Invalid input"
            fi
            ;;
        4)
            # Reset to unlimited
            sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:/$username:\1:\2:\3:0:0:/" "$PROXY_DB"
            sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$//$username:\1:\2:\3:\4:\5:0/" "$PROXY_DB"
            remove_bandwidth_limit "$username"
            unblock_user "$username"
            log_success "User $username reset to unlimited"
            ;;
        5)
            # Block/Unblock user
            local current_status=$(grep "^$username:" "$PROXY_DB" | cut -d':' -f4)
            if [[ "$current_status" = "active" ]]; then
                block_user "$username"
                log_success "User $username blocked"
            else
                unblock_user "$username"
                log_success "User $username unblocked"
            fi
            ;;
    esac
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
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
    
    # Remove bandwidth limit
    remove_bandwidth_limit "$username"
    
    # Unblock user
    unblock_user "$username"
    
    # Delete system user
    userdel "$username" 2>/dev/null
    
    # Remove from Squid
    htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1
    
    # Remove from databases
    sed -i "/^$username:/d" "$PROXY_DB"
    sed -i "/^$username:/d" "$BANDWIDTH_DB"
    
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
    while IFS=':' read -r username password created_date status speed_limit quota used_bytes; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        # Remove bandwidth limit
        remove_bandwidth_limit "$username"
        
        # Unblock user
        unblock_user "$username"
        
        # Delete system user
        userdel "$username" 2>/dev/null
        
        # Remove from Squid
        htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1
    done < "$PROXY_DB"
    
    # Clear databases (keep headers)
    cat > "$PROXY_DB" << 'EOF'
# Flexible Proxy Users Database
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:TOTAL_QUOTA_GB:USED_BYTES
# SPEED_LIMIT_MBPS: 0 = Unlimited
# TOTAL_QUOTA_GB: 0 = Unlimited
# This file is automatically managed by the proxy manager
EOF

    cat > "$BANDWIDTH_DB" << 'EOF'
# Bandwidth Usage Database
# Format: USERNAME:USED_BYTES:LAST_UPDATED
# This file tracks total usage for quota management
EOF
    
    # Restart Squid to reload users
    systemctl reload squid >/dev/null 2>&1
    
    log_success "All proxy pairs deleted"
}

# Show bandwidth statistics
show_bandwidth_statistics() {
    echo -e "${CYAN}Bandwidth Usage Statistics${NC}\n"
    
    if [[ ! -f "$PROXY_DB" ]] || [[ ! -s "$PROXY_DB" ]]; then
        log_warning "No proxy pairs found"
        return 0
    fi
    
    printf "%-20s %-15s %-15s %-15s %-10s\n" "Username" "Speed Limit" "Total Quota" "Used" "Status"
    printf "%-20s %-15s %-15s %-15s %-10s\n" "--------" "-----------" "-----------" "----" "------"
    
    local total_usage=0
    
    while IFS=':' read -r username password created_date status speed_limit quota used_bytes; do
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
        if [[ "$quota" -eq 0 ]]; then
            quota_display="Unlimited"
        else
            quota_display="${quota}GB"
        fi
        
        # Format usage
        local usage_display
        local used_mb=$((used_bytes / 1024 / 1024))
        if [[ $used_mb -gt 1024 ]]; then
            local used_gb=$((used_mb / 1024))
            usage_display="${used_gb}GB"
        else
            usage_display="${used_mb}MB"
        fi
        
        # Format status
        local status_display
        case $status in
            "active") status_display="Active" ;;
            "blocked_quota") status_display="Blocked" ;;
            *) status_display="$status" ;;
        esac
        
        printf "%-20s %-15s %-15s %-15s %-10s\n" "$username" "$speed_display" "$quota_display" "$usage_display" "$status_display"
        
        total_usage=$((total_usage + used_bytes))
    done < "$PROXY_DB"
    
    echo
    local total_mb=$((total_usage / 1024 / 1024))
    if [[ $total_mb -gt 1024 ]]; then
        local total_gb=$((total_mb / 1024))
        echo -e "${YELLOW}Total Usage: ${total_gb}GB${NC}"
    else
        echo -e "${YELLOW}Total Usage: ${total_mb}MB${NC}"
    fi
}

# Monitor bandwidth usage real-time
monitor_bandwidth_realtime() {
    echo -e "${CYAN}Real-time Bandwidth Usage Monitor${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    
    while true; do
        clear
        echo -e "${CYAN}Real-time Bandwidth Usage - $(date '+%Y-%m-%d %H:%M:%S')${NC}\n"
        
        # Show active connections
        local http_connections=$(netstat -an | grep ":$HTTP_PORT" | grep ESTABLISHED | wc -l)
        local socks_connections=$(netstat -an | grep ":$SOCKS_PORT" | grep ESTABLISHED | wc -l)
        
        echo -e "${YELLOW}Active Connections:${NC}"
        echo "HTTP Proxy: $http_connections connections"
        echo "SOCKS5 Proxy: $socks_connections connections"
        echo
        
        # Show bandwidth statistics
        show_bandwidth_statistics
        
        echo -e "\n${YELLOW}[Updates every 5 seconds - Press Ctrl+C to stop]${NC}"
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
    
    # Reset usage to 0 in database
    sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$//$username:\1:\2:\3:\4:\5:0/" "$PROXY_DB"
    
    # Remove from bandwidth database
    sed -i "/^$username:/d" "$BANDWIDTH_DB"
    
    # Unblock user if was blocked
    unblock_user "$username"
    
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
    
    echo "# Flexible Dual Proxy Export - $(date)" > "$export_file"
    echo "# Server: $SERVER_IP" >> "$export_file"
    echo "# HTTP Port: $HTTP_PORT | SOCKS5 Port: $SOCKS_PORT" >> "$export_file"
    echo "# Format: TYPE:IP:PORT:USERNAME:PASSWORD | Speed | Quota" >> "$export_file"
    echo "" >> "$export_file"
    
    local count=0
    while IFS=':' read -r username password created_date status speed_limit quota used_bytes; do
        # Skip comments and empty lines
        [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
        
        local speed_info
        if [[ "$speed_limit" -eq 0 ]]; then
            speed_info="Unlimited"
        else
            speed_info="${speed_limit}Mbps"
        fi
        
        local quota_info
        if [[ "$quota" -eq 0 ]]; then
            quota_info="Unlimited"
        else
            quota_info="${quota}GB"
        fi
        
        echo "HTTP:$SERVER_IP:$HTTP_PORT:$username:$password | Speed: $speed_info | Quota: $quota_info" >> "$export_file"
        echo "SOCKS5:$SERVER_IP:$SOCKS_PORT:$username:$password | Speed: $speed_info | Quota: $quota_info" >> "$export_file"
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
    
    echo -e "\n${YELLOW}Traffic Control Status:${NC}"
    if tc qdisc show dev "$INTERFACE" | grep -q "htb"; then
        echo -e "Bandwidth Control: ${GREEN}Active${NC}"
        echo "Active bandwidth limits:"
        tc -s class show dev "$INTERFACE" | grep "class htb 1:" | while read -r line; do
            local class_id=$(echo "$line" | awk '{print $3}')
            local rate=$(echo "$line" | grep -o "rate [0-9]*[a-zA-Z]*" | awk '{print $2}')
            if [[ -n "$rate" && "$rate" != "1000Mbit" ]]; then
                echo "  Class $class_id: $rate"
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
    
    # Show bandwidth information
    echo -e "\n${YELLOW}Bandwidth Information:${NC}"
    local user_info=$(grep "^$username:" "$PROXY_DB")
    local speed_limit=$(echo "$user_info" | cut -d':' -f5)
    local quota=$(echo "$user_info" | cut -d':' -f6)
    local used_bytes=$(echo "$user_info" | cut -d':' -f7)
    local status=$(echo "$user_info" | cut -d':' -f4)
    
    if [[ "$speed_limit" -eq 0 ]]; then
        echo "Speed Limit: Unlimited"
    else
        echo "Speed Limit: ${speed_limit}Mbps"
    fi
    
    if [[ "$quota" -eq 0 ]]; then
        echo "Total Quota: Unlimited"
    else
        echo "Total Quota: ${quota}GB"
    fi
    
    echo "Status: $status"
    
    local used_mb=$((used_bytes / 1024 / 1024))
    if [[ $used_mb -gt 1024 ]]; then
        local used_gb=$((used_mb / 1024))
        echo "Usage: ${used_gb}GB"
    else
        echo "Usage: ${used_mb}MB"
    fi
}

# Main menu
show_main_menu() {
    while true; do
        print_banner
        echo -e "\n${YELLOW}Flexible Proxy Management Menu${NC}"
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
        echo -e "${BLUE}10)${NC} Export Proxy Pairs"
        echo -e "${BLUE}11)${NC} Test Proxy Pair"
        echo -e "${BLUE}12)${NC} Service Status"
        echo -e "${BLUE}13)${NC} Restart Services"
        echo -e "${BLUE}14)${NC} View Logs"
        echo
        echo -e "${RED}0)${NC} Exit"
        echo

        read -p "Select an option [0-14]: " choice

        case $choice in
            1) create_proxy_pair ;;
            2) create_multiple_proxy_pairs ;;
            3) read_proxy_pairs ;;
            4) update_proxy_bandwidth ;;
            5) delete_proxy_pair ;;
            6) delete_all_proxy_pairs ;;
            7) show_bandwidth_statistics ;;
            8) monitor_bandwidth_realtime ;;
            9) reset_user_quota ;;
            10) export_proxy_pairs ;;
            11) test_proxy_pair ;;
            12) show_service_status ;;
            13) restart_services ;;
            14) show_logs ;;
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

# Check if already installed
check_existing_installation() {
    if [[ -f /etc/sockd.conf ]] && [[ -f /etc/squid/squid.conf ]] && systemctl is-active --quiet squid && systemctl is-active --quiet sockd; then
        log_info "Flexible dual proxy system already installed. Entering management mode..."
        init_database
        show_main_menu
        exit 0
    fi
}

# Initial installation
install_flexible_proxy() {
    print_banner
    
    log_info "Starting flexible dual proxy installation..."
    
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
    setup_traffic_control
    init_database
    create_bandwidth_monitor
    start_services
    
    # Create initial proxy pairs if requested
    if [[ $initial_count -gt 0 ]]; then
        log_info "Creating $initial_count initial proxy pairs (all unlimited)..."
        
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
                
                # Add to database (all unlimited)
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
    cat > /root/flexible_proxy_info.txt << EOF
Flexible Dual Proxy Manager Installation
========================================
Installation Date: $(date)
Server IP: $SERVER_IP
HTTP Proxy Port: $HTTP_PORT
SOCKS5 Proxy Port: $SOCKS_PORT
Initial Proxy Pairs: $initial_count

Features:
- On-demand bandwidth control (no monthly restrictions)
- Speed limits when needed (default: unlimited)
- Total quota limits when needed (default: unlimited)
- Real-time monitoring and statistics
- Automatic quota management

Management:
- Run: bash $(realpath "$0")
- Config Directory: $CONFIG_DIR
- Database: $PROXY_DB
- Bandwidth DB: $BANDWIDTH_DB

Service Commands:
- HTTP Proxy: systemctl {start|stop|restart|status} squid
- SOCKS5 Proxy: systemctl {start|stop|restart|status} sockd

Log Files:
- HTTP Proxy: /var/log/squid/access.log
- SOCKS5 Proxy: /var/log/sockd.log
- Bandwidth Monitor: /var/log/proxy-bandwidth-monitor.log
EOF
    
    log_success "Installation information saved to /root/flexible_proxy_info.txt"
    
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
    install_flexible_proxy
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
        [[ -f /root/flexible_proxy_info.txt ]] && cat /root/flexible_proxy_info.txt || log_error "Info file not found"
        ;;
    "status")
        check_root
        get_network_info
        show_service_status
        ;;
    "stats")
        check_root
        get_network_info
        init_database
        show_bandwidth_statistics
        ;;
    *)
        main
        ;;
esac