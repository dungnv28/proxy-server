#!/bin/bash

# Dual Proxy Installation Script (HTTP + SOCKS5)
# HTTP Proxy: Squid
# SOCKS5 Proxy: Dante
# Compatible with Ubuntu, Debian, CentOS, RHEL
# Version: 2.0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
HTTP_PORT=3128
SOCKS_PORT=1080
PROXY_USERS=()
PROXY_PASSWORDS=()
SERVER_IP=""
INTERFACE=""

# Functions
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "══════════════════════════════════════════════════════════════"
    echo "    DUAL PROXY INSTALLER v2.0"
    echo "    HTTP Proxy (Squid) + SOCKS5 Proxy (Dante)"
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
# HTTP Proxy Configuration
http_port ${HTTP_PORT}

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm HTTP Proxy Authentication Required
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED

# Access control
http_access allow authenticated
http_access deny all

# Network settings
visible_hostname http-proxy-server
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
dns_nameservers 8.8.8.8 8.8.4.4 1.1.1.1

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

# Additional security
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
    
    # Download and compile Dante
    cd /tmp
    wget https://www.inet.no/dante/files/dante-1.4.3.tar.gz
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
        --without-pam
    
    make && make install
    
    log_success "Dante compiled and installed"
}

# Configure Dante
configure_dante() {
    log_info "Configuring Dante SOCKS5 proxy..."
    
    # Create Dante configuration
    cat > /etc/sockd.conf << EOF
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
Description=Dante Socks Proxy v1.4.3
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
        ufw allow ${HTTP_PORT}/tcp
        ufw allow ${SOCKS_PORT}/tcp
        log_info "UFW rules added"
    fi
    
    # Firewalld (CentOS/RHEL)
    if command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${HTTP_PORT}/tcp
        firewall-cmd --permanent --add-port=${SOCKS_PORT}/tcp
        firewall-cmd --reload
        log_info "Firewalld rules added"
    fi
    
    # Iptables
    if command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT -p tcp --dport $HTTP_PORT -j ACCEPT
        iptables -I INPUT -p tcp --dport $SOCKS_PORT -j ACCEPT
        
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

# Generate proxy users
generate_users() {
    local num_users="$1"
    
    log_info "Generating $num_users proxy users..."
    
    for ((i=1; i<=num_users; i++)); do
        local username="user_$(openssl rand -hex 3)"
        local password="pass_$(openssl rand -hex 3)"
        
        PROXY_USERS+=("$username")
        PROXY_PASSWORDS+=("$password")
        
        # Create system user
        useradd -M -s /usr/sbin/nologin "$username"
        echo "$username:$password" | chpasswd
        
        # Add to Squid
        htpasswd -b /etc/squid/passwd "$username" "$password"
    done
    
    log_success "$num_users users generated"
}

# Start services
start_services() {
    log_info "Starting proxy services..."
    
    # Start Squid
    systemctl enable squid
    systemctl restart squid
    
    # Start Dante
    systemctl enable sockd
    systemctl restart sockd
    
    # Check service status
    sleep 3
    
    if systemctl is-active --quiet squid; then
        log_success "Squid HTTP proxy started successfully"
    else
        log_error "Failed to start Squid"
        systemctl status squid
    fi
    
    if systemctl is-active --quiet sockd; then
        log_success "Dante SOCKS5 proxy started successfully"
    else
        log_error "Failed to start Dante"
        systemctl status sockd
    fi
}

# Generate proxy files
generate_proxy_files() {
    log_info "Generating proxy files..."
    
    # Create HTTP proxy list
    > http_proxies.txt
    > socks5_proxies.txt
    > all_proxies.txt
    
    echo "# HTTP Proxies (IP:PORT:USERNAME:PASSWORD)" > http_proxies.txt
    echo "# SOCKS5 Proxies (IP:PORT:USERNAME:PASSWORD)" > socks5_proxies.txt
    echo "# All Proxies" > all_proxies.txt
    echo "# HTTP Proxies:" >> all_proxies.txt
    
    for ((i=0; i<${#PROXY_USERS[@]}; i++)); do
        local user="${PROXY_USERS[$i]}"
        local pass="${PROXY_PASSWORDS[$i]}"
        
        # HTTP proxy format
        echo "$SERVER_IP:$HTTP_PORT:$user:$pass" >> http_proxies.txt
        echo "$SERVER_IP:$HTTP_PORT:$user:$pass" >> all_proxies.txt
        
        # SOCKS5 proxy format
        echo "$SERVER_IP:$SOCKS_PORT:$user:$pass" >> socks5_proxies.txt
    done
    
    echo "" >> all_proxies.txt
    echo "# SOCKS5 Proxies:" >> all_proxies.txt
    cat socks5_proxies.txt | grep -v "^#" >> all_proxies.txt
    
    log_success "Proxy files generated"
}

# Upload files to file.io
upload_files() {
    log_info "Creating and uploading proxy archive..."
    
    local password=$(openssl rand -base64 12)
    
    # Create zip archive
    zip -P "$password" proxy_list.zip http_proxies.txt socks5_proxies.txt all_proxies.txt
    
    # Upload to file.io
    local json=$(curl -s -F "file=@proxy_list.zip" https://file.io)
    local url=$(echo "$json" | jq -r '.link' 2>/dev/null)
    
    if [[ "$url" != "null" && -n "$url" ]]; then
        echo -e "\n${GREEN}Proxy files uploaded successfully!${NC}"
        echo -e "${YELLOW}Download URL:${NC} $url"
        echo -e "${YELLOW}Archive Password:${NC} $password"
    else
        log_warning "Failed to upload to file.io, files are available locally"
    fi
}

# Display proxy information
show_proxy_info() {
    clear
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                PROXY INSTALLATION COMPLETED                  ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}Server Information:${NC}"
    echo "  Server IP: $SERVER_IP"
    echo "  HTTP Proxy Port: $HTTP_PORT"
    echo "  SOCKS5 Proxy Port: $SOCKS_PORT"
    echo "  Total Users: ${#PROXY_USERS[@]}"
    echo
    echo -e "${YELLOW}Proxy Usage Examples:${NC}"
    echo -e "${CYAN}HTTP Proxy:${NC}"
    echo "  curl -x ${PROXY_USERS[0]}:${PROXY_PASSWORDS[0]}@$SERVER_IP:$HTTP_PORT http://ifconfig.me"
    echo
    echo -e "${CYAN}SOCKS5 Proxy:${NC}"
    echo "  curl --socks5 ${PROXY_USERS[0]}:${PROXY_PASSWORDS[0]}@$SERVER_IP:$SOCKS_PORT http://ifconfig.me"
    echo
    echo -e "${YELLOW}Configuration Files:${NC}"
    echo "  HTTP Proxies: $(pwd)/http_proxies.txt"
    echo "  SOCKS5 Proxies: $(pwd)/socks5_proxies.txt"
    echo "  All Proxies: $(pwd)/all_proxies.txt"
    echo
    echo -e "${YELLOW}Service Management:${NC}"
    echo "  HTTP Proxy: systemctl {start|stop|restart|status} squid"
    echo "  SOCKS5 Proxy: systemctl {start|stop|restart|status} sockd"
    echo
    echo -e "${YELLOW}Log Files:${NC}"
    echo "  HTTP Proxy: /var/log/squid/access.log"
    echo "  SOCKS5 Proxy: /var/log/sockd.log"
    echo
    
    # Save info to file
    cat > /root/proxy_info.txt << EOF
Dual Proxy Server Information
=============================
Installation Date: $(date)
Server IP: $SERVER_IP
HTTP Proxy Port: $HTTP_PORT
SOCKS5 Proxy Port: $SOCKS_PORT
Total Users: ${#PROXY_USERS[@]}

Sample Proxy Credentials:
Username: ${PROXY_USERS[0]}
Password: ${PROXY_PASSWORDS[0]}

HTTP Proxy String: ${PROXY_USERS[0]}:${PROXY_PASSWORDS[0]}@$SERVER_IP:$HTTP_PORT
SOCKS5 Proxy String: ${PROXY_USERS[0]}:${PROXY_PASSWORDS[0]}@$SERVER_IP:$SOCKS_PORT

Test Commands:
HTTP: curl -x ${PROXY_USERS[0]}:${PROXY_PASSWORDS[0]}@$SERVER_IP:$HTTP_PORT http://ifconfig.me
SOCKS5: curl --socks5 ${PROXY_USERS[0]}:${PROXY_PASSWORDS[0]}@$SERVER_IP:$SOCKS_PORT http://ifconfig.me
EOF
    
    log_success "Installation information saved to /root/proxy_info.txt"
}

# Management menu
show_menu() {
    while true; do
        print_banner
        echo -e "\n${YELLOW}Proxy Management Menu${NC}"
        echo -e "${YELLOW}Server IP: $SERVER_IP | HTTP Port: $HTTP_PORT | SOCKS5 Port: $SOCKS_PORT${NC}"
        echo
        echo -e "${CYAN}1)${NC} Add Single User"
        echo -e "${CYAN}2)${NC} Add Multiple Random Users"
        echo -e "${CYAN}3)${NC} Delete User"
        echo -e "${CYAN}4)${NC} List All Users"
        echo -e "${CYAN}5)${NC} Restart Services"
        echo -e "${CYAN}6)${NC} View Service Status"
        echo -e "${CYAN}7)${NC} Generate New Proxy Files"
        echo -e "${CYAN}8)${NC} Show Installation Info"
        echo -e "${CYAN}9)${NC} Uninstall All"
        echo -e "${CYAN}0)${NC} Exit"
        echo

        read -p "Select an option [0-9]: " choice

        case $choice in
            1) add_single_user ;;
            2) add_multiple_users ;;
            3) delete_user ;;
            4) list_users ;;
            5) restart_services ;;
            6) show_service_status ;;
            7) regenerate_files ;;
            8) cat /root/proxy_info.txt 2>/dev/null || log_error "Info file not found" ;;
            9) uninstall_all ;;
            0) echo "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac

        echo
        read -p "Press Enter to continue..."
    done
}

# Add single user
add_single_user() {
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo
    
    if [[ -z "$username" || -z "$password" ]]; then
        log_error "Username and password cannot be empty"
        return 1
    fi
    
    # Create system user
    useradd -M -s /usr/sbin/nologin "$username"
    echo "$username:$password" | chpasswd
    
    # Add to Squid
    htpasswd -b /etc/squid/passwd "$username" "$password"
    
    log_success "User '$username' added successfully"
}

# Add multiple users
add_multiple_users() {
    read -p "Enter number of users to create: " num_users
    
    if [[ ! "$num_users" =~ ^[0-9]+$ ]] || [[ "$num_users" -lt 1 ]]; then
        log_error "Invalid number of users"
        return 1
    fi
    
    generate_users "$num_users"
    generate_proxy_files
    upload_files
}

# Delete user
delete_user() {
    echo "Current users:"
    awk -F: '$3 > 1000 && $7 == "/usr/sbin/nologin" && $1 != "nobody" {print $1}' /etc/passwd
    
    read -p "Enter username to delete: " username
    
    if getent passwd "$username" > /dev/null 2>&1; then
        userdel "$username"
        htpasswd -D /etc/squid/passwd "$username" 2>/dev/null
        log_success "User '$username' deleted"
    else
        log_error "User not found"
    fi
}

# List users
list_users() {
    echo -e "${CYAN}Current proxy users:${NC}"
    awk -F: '$3 > 1000 && $7 == "/usr/sbin/nologin" && $1 != "nobody" {print "  " $1}' /etc/passwd
}

# Restart services
restart_services() {
    log_info "Restarting proxy services..."
    systemctl restart squid
    systemctl restart sockd
    log_success "Services restarted"
}

# Show service status
show_service_status() {
    echo -e "${CYAN}Service Status:${NC}"
    echo -n "Squid (HTTP): "
    systemctl is-active squid
    echo -n "Dante (SOCKS5): "
    systemctl is-active sockd
}

# Regenerate files
regenerate_files() {
    # Get current users
    PROXY_USERS=()
    PROXY_PASSWORDS=()
    
    while IFS=':' read -r username _ _ _ _ _ shell; do
        if [[ $username != "nobody" && $shell == "/usr/sbin/nologin" ]]; then
            PROXY_USERS+=("$username")
            # Note: Can't retrieve original passwords, using placeholder
            PROXY_PASSWORDS+=("password_reset_required")
        fi
    done < <(awk -F: '$3 > 1000 && $7 == "/usr/sbin/nologin" {print}' /etc/passwd)
    
    generate_proxy_files
    log_warning "Note: Existing user passwords are not retrievable. Consider recreating users if needed."
}

# Uninstall all
uninstall_all() {
    read -p "Are you sure you want to uninstall all proxy services? [y/N]: " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Uninstall cancelled"
        return 0
    fi
    
    log_info "Uninstalling proxy services..."
    
    # Stop services
    systemctl stop squid sockd
    systemctl disable squid sockd
    
    # Remove configuration files
    rm -f /etc/squid/squid.conf /etc/squid/passwd
    rm -f /etc/sockd.conf
    rm -f /etc/systemd/system/sockd.service
    
    # Remove users
    awk -F: '$3 > 1000 && $7 == "/usr/sbin/nologin" && $1 != "nobody" {print $1}' /etc/passwd | while read -r user; do
        userdel "$user"
    done
    
    # Remove proxy files
    rm -f http_proxies.txt socks5_proxies.txt all_proxies.txt proxy_list.zip
    rm -f /root/proxy_info.txt
    
    systemctl daemon-reload
    
    log_success "Uninstallation completed"
}

# Check if already installed
check_existing_installation() {
    if [[ -f /etc/sockd.conf ]] && systemctl is-active --quiet squid; then
        log_info "Proxy services already installed. Entering management mode..."
        get_network_info
        show_menu
        exit 0
    fi
}

# Main installation function
main() {
    print_banner
    
    # Pre-installation checks
    check_shell
    check_root
    detect_os
    check_existing_installation
    get_network_info
    
    # Get user input
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
        read -p "Enter number of proxy users to create: " num_users
        if [[ "$num_users" =~ ^[0-9]+$ ]] && [[ "$num_users" -ge 1 ]]; then
            break
        else
            log_error "Invalid number of users"
        fi
    done
    
    # Installation process
    log_info "Starting dual proxy installation..."
    
    install_packages
    configure_squid
    install_dante
    configure_dante
    configure_firewall
    generate_users "$num_users"
    start_services
    generate_proxy_files
    upload_files
    show_proxy_info
    
    log_success "Installation completed successfully!"
    
    # Enter management mode
    read -p "Press Enter to enter management mode..."
    show_menu
}

# Handle command line arguments
case "${1:-}" in
    "menu")
        get_network_info 2>/dev/null
        show_menu
        ;;
    "info")
        [[ -f /root/proxy_info.txt ]] && cat /root/proxy_info.txt || log_error "Info file not found"
        ;;
    *)
        main
        ;;
esac
