# Dual Proxy Manager v3.0

A comprehensive proxy management solution that provides both HTTP (Squid) and SOCKS5 (Dante) proxies with full CRUD operations. Each proxy pair shares the same credentials for both HTTP and SOCKS5 protocols.

## 🚀 Features

### ✨ Dual Proxy Support
- **HTTP Proxy** (Squid) - Port 3128 (default)
- **SOCKS5 Proxy** (Dante) - Port 1080 (default)
- **Shared Credentials** - Same username/password for both protocols

### 🔧 Full CRUD Operations
- **CREATE** - Add single or multiple proxy pairs
- **READ** - List and view all proxy configurations
- **UPDATE** - Change passwords with unique generation
- **DELETE** - Remove single or all proxy pairs

### 🔐 Security Features
- **Unique Credentials** - No duplicate usernames or passwords
- **Random Generation** - Cryptographically secure credential generation
- **Database Management** - Centralized user database
- **Authentication** - Strong authentication for both protocols

### 📊 Management Features
- **Interactive Menu** - User-friendly CRUD interface
- **Service Management** - Start/stop/restart proxy services
- **Real-time Testing** - Test proxy functionality
- **Log Monitoring** - View proxy access logs
- **Export Functions** - Generate and upload proxy lists

## 📋 Requirements

### Supported Operating Systems
- Ubuntu 18.04+ / Debian 9+
- CentOS 7+ / RHEL 7+
- Other systemd-based Linux distributions

### System Requirements
- Root access (sudo)
- Minimum 1GB RAM
- 10GB free disk space
- Internet connection for package installation

## 🛠️ Installation

### Quick Install
```bash
# Download and run the installer
wget https://raw.githubusercontent.com/your-repo/dual-proxy.sh -O dual-proxy.sh
chmod +x dual-proxy.sh
sudo ./dual-proxy.sh
```

### Manual Installation
```bash
# Clone repository
git clone https://github.com/your-repo/dual-proxy-manager.git
cd dual-proxy-manager

# Make executable
chmod +x dual-proxy.sh

# Run installer
sudo ./dual-proxy.sh
```

## 🎯 Usage

### First Time Setup
1. Run the script as root: `sudo ./dual-proxy.sh`
2. Configure HTTP proxy port (default: 3128)
3. Configure SOCKS5 proxy port (default: 1080)
4. Choose to create initial proxy pairs (optional)
5. Installation completes automatically

### Management Commands
```bash
# Enter management menu
sudo ./dual-proxy.sh menu

# View installation info
sudo ./dual-proxy.sh info

# Check service status
sudo ./dual-proxy.sh status
```

## 📖 CRUD Operations Guide

### CREATE Operations

#### Create Single Proxy Pair
- Automatically generates unique username and password
- Creates system user and configures both HTTP and SOCKS5
- Returns credentials in format: `IP:PORT:USER:PASS`

#### Create Multiple Proxy Pairs
- Batch creation of 1-100 proxy pairs
- Progress indicator during creation
- Automatic file generation and upload to file.io
- Password-protected ZIP archive

### READ Operations

#### List All Proxy Pairs
- Displays all active proxy pairs
- Shows creation date and status
- Format: Both HTTP and SOCKS5 credentials for each user

#### Export Proxy Lists
- Generates formatted proxy files
- Uploads to file.io with password protection
- Local file backup in `/tmp/`

### UPDATE Operations

#### Update Proxy Password
- Select user from existing list
- Generates new unique password
- Updates both HTTP and SOCKS5 authentication
- Automatic service reload

### DELETE Operations

#### Delete Single Proxy Pair
- Interactive user selection
- Confirmation prompt
- Removes from all systems (user, HTTP, SOCKS5)

#### Delete All Proxy Pairs
- Requires typing "DELETE ALL" for confirmation
- Bulk removal of all proxy users
- Preserves system configuration

## 🔧 Configuration

### Default Ports
- **HTTP Proxy**: 3128
- **SOCKS5 Proxy**: 1080

### Configuration Files
- **Squid Config**: `/etc/squid/squid.conf`
- **Dante Config**: `/etc/sockd.conf`
- **User Database**: `/etc/proxy-manager/proxy_users.db`
- **Password File**: `/etc/squid/passwd`

### Service Management
```bash
# HTTP Proxy (Squid)
systemctl start|stop|restart|status squid

# SOCKS5 Proxy (Dante)
systemctl start|stop|restart|status sockd
```

## 📊 Proxy Format

### Standard Format
```
HTTP:   IP:PORT:USERNAME:PASSWORD
SOCKS5: IP:PORT:USERNAME:PASSWORD
```

### Example Output
```
HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
```

## 🧪 Testing Proxies

### Built-in Testing
Use the management menu option "Test Proxy Pair" to verify functionality.

### Manual Testing

#### HTTP Proxy Test
```bash
curl -x username:password@your-server-ip:3128 http://ifconfig.me
```

#### SOCKS5 Proxy Test
```bash
curl --socks5 username:password@your-server-ip:1080 http://ifconfig.me
```

### Browser Configuration

#### HTTP Proxy
- **Proxy Type**: HTTP
- **Server**: Your server IP
- **Port**: 3128 (or your configured port)
- **Username/Password**: From your proxy list

#### SOCKS5 Proxy
- **Proxy Type**: SOCKS5
- **Server**: Your server IP
- **Port**: 1080 (or your configured port)
- **Username/Password**: From your proxy list

## 📁 File Structure

```
/etc/proxy-manager/
├── proxy_users.db          # User database
/etc/squid/
├── squid.conf              # HTTP proxy configuration
├── passwd                  # HTTP proxy passwords
/etc/
├── sockd.conf              # SOCKS5 proxy configuration
/var/log/
├── squid/access.log        # HTTP proxy logs
├── sockd.log               # SOCKS5 proxy logs
/root/
├── dual_proxy_info.txt     # Installation information
```

## 🔍 Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check service status
systemctl status squid
systemctl status sockd

# Check logs
journalctl -u squid -f
journalctl -u sockd -f
```

#### Port Already in Use
```bash
# Check what's using the port
netstat -tulpn | grep :3128
netstat -tulpn | grep :1080

# Kill conflicting processes if needed
sudo fuser -k 3128/tcp
sudo fuser -k 1080/tcp
```

#### Firewall Issues
```bash
# Check firewall status
ufw status
firewall-cmd --list-all

# Open ports manually if needed
ufw allow 3128/tcp
ufw allow 1080/tcp
```

#### Authentication Problems
```bash
# Verify user exists
grep username /etc/proxy-manager/proxy_users.db

# Check Squid password file
cat /etc/squid/passwd

# Reload services
systemctl reload squid
systemctl restart sockd
```

### Log Analysis

#### HTTP Proxy Logs
```bash
# Real-time access log
tail -f /var/log/squid/access.log

# Error log
tail -f /var/log/squid/cache.log
```

#### SOCKS5 Proxy Logs
```bash
# Real-time SOCKS5 log
tail -f /var/log/sockd.log
```

## 🔒 Security Considerations

### Best Practices
- Change default ports for security
- Use strong, unique passwords (automatically generated)
- Regularly monitor access logs
- Limit access to management interface
- Keep system updated

### Firewall Configuration
The script automatically configures:
- UFW (Ubuntu/Debian)
- Firewalld (CentOS/RHEL)
- Iptables (fallback)

### Access Control
- Only authenticated users can use proxies
- No anonymous access allowed
- User isolation between proxy sessions

## 📈 Performance Tuning

### Squid Optimization
```bash
# Edit /etc/squid/squid.conf
cache_mem 512 MB                    # Increase cache memory
maximum_object_size 256 MB          # Larger object cache
```

### System Limits
```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

## 🆘 Support

### Getting Help
1. Check the troubleshooting section
2. Review log files for errors
3. Verify configuration files
4. Test network connectivity

### Reporting Issues
When reporting issues, please include:
- Operating system and version
- Error messages from logs
- Steps to reproduce the problem
- Configuration details (without sensitive data)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📚 Additional Resources

### Related Documentation
- [Squid Proxy Documentation](http://www.squid-cache.org/Doc/)
- [Dante SOCKS Server Documentation](https://www.inet.no/dante/doc/)
- [Linux Proxy Configuration Guide](https://wiki.archlinux.org/title/Proxy_server)

### Useful Commands
```bash
# Monitor proxy usage
watch -n 1 'netstat -an | grep :3128 | wc -l'
watch -n 1 'netstat -an | grep :1080 | wc -l'

# Check proxy performance
iftop -i eth0 -P

# Monitor system resources
htop
```

---

**Note**: This script requires root privileges and will modify system configurations. Always test in a non-production environment first.