# ENHANCED DUAL PROXY - BANDWIDTH CONTROL COMMANDS

## 🎯 **CÁC LỆNH BANDWIDTH CONTROL CHÍNH**

### 1. **LỆNH KHỞI CHẠY ENHANCED VERSION**
```bash
# Chạy script enhanced với bandwidth control
sudo ./enhanced-dual-proxy.sh

# Hoặc với bash
sudo bash enhanced-dual-proxy.sh
```

### 2. **CÁC LỆNH THAM SỐ MỚI**

#### 🔧 **Menu Management**
```bash
# Vào menu quản lý enhanced (bỏ qua cài đặt)
sudo ./enhanced-dual-proxy.sh menu
```

#### 📊 **Xem thống kê bandwidth**
```bash
# Hiển thị bandwidth statistics
sudo ./enhanced-dual-proxy.sh stats
```

#### 🔍 **Kiểm tra trạng thái nâng cao**
```bash
# Kiểm tra trạng thái dịch vụ + traffic control
sudo ./enhanced-dual-proxy.sh status
```

#### 📋 **Xem thông tin enhanced**
```bash
# Hiển thị thông tin cài đặt enhanced
sudo ./enhanced-dual-proxy.sh info
```

## 🖥️ **MENU TƯƠNG TÁC ENHANCED**

### 📋 **MENU CHÍNH (Enhanced Interactive Menu)**
```
Enhanced Proxy Management Menu
Server: 192.168.1.100 | HTTP: 3128 | SOCKS5: 1080

CRUD Operations:
1) Create Single Proxy Pair (with Bandwidth Control)
2) Create Multiple Proxy Pairs (with Bandwidth Control)  
3) Read/List All Proxy Pairs (with Bandwidth Info)
4) Update Proxy Bandwidth Settings
5) Delete Single Proxy Pair
6) Delete All Proxy Pairs

Bandwidth Management:
7) Show Bandwidth Statistics
8) Monitor Bandwidth Usage (Real-time)
9) Reset User Quota

System Management:
10) Test Proxy Pair
11) Service Status
12) Restart Services
13) View Logs

0) Exit

Select an option [0-13]:
```

## 🔧 **CHI TIẾT CÁC LỆNH BANDWIDTH MENU**

### **1) Create Single Proxy Pair (with Bandwidth Control)**
```
Creating new proxy pair with bandwidth control...

Bandwidth Configuration:
1) Unlimited (default)
2) Custom speed limit and monthly quota

Select option [1-2]: 2
Enter speed limit in Mbps (e.g., 100): 100
Enter monthly quota in GB (0 for unlimited): 5

✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
Speed Limit:  100Mbps
Monthly Quota: 5GB
```

### **2) Create Multiple Proxy Pairs (with Bandwidth Control)**
```
Enter number of proxy pairs to create: 10

Bandwidth Configuration for all proxies:
1) Unlimited (default)
2) Custom speed limit and monthly quota

Select option [1-2]: 2
Enter speed limit in Mbps (e.g., 100): 50
Enter monthly quota in GB (0 for unlimited): 10

Creating 10 proxy pairs with bandwidth control...
Progress: 10/10

✓ Created 10 proxy pairs successfully!

Proxy List with Bandwidth Settings:
HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6 | Speed: 50Mbps | Quota: 10GB
SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6 | Speed: 50Mbps | Quota: 10GB
```

### **3) Read/List All Proxy Pairs (with Bandwidth Info)**
```
Current Proxy Pairs with Bandwidth Control:

Format: HTTP and SOCKS5 pairs with bandwidth limits
Server IP: 192.168.1.100

[1] User: proxy_a1b2c3d4
    HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
    SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
    Created: 2024-01-15 10:30:25 | Status: active
    Speed Limit: 100Mbps
    Monthly Quota: 5GB
    Usage This Month: 2GB
    Quota Reset: 2024-02-01

[2] User: proxy_e5f6g7h8
    HTTP:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
    SOCKS5: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
    Created: 2024-01-15 10:30:26 | Status: blocked_quota
    Speed Limit: Unlimited
    Monthly Quota: 3GB
    Usage This Month: 3GB
    Quota Reset: 2024-02-01

Total proxy pairs: 2
```

### **4) Update Proxy Bandwidth Settings**
```
Update Proxy Bandwidth Settings

Current Proxy Pairs with Bandwidth Control:
[Hiển thị danh sách như trên]

Enter username to update: proxy_a1b2c3d4

Update Options:
1) Update speed limit only
2) Update monthly quota only  
3) Update both speed limit and quota
4) Reset to unlimited
5) Block/Unblock user

Select option [1-5]: 3
Enter new speed limit in Mbps (0 for unlimited): 200
Enter new monthly quota in GB (0 for unlimited): 10

✓ Bandwidth settings updated for user: proxy_a1b2c3d4
Speed: 200Mbps
Quota: 10GB
```

### **7) Show Bandwidth Statistics**
```
Bandwidth Usage Statistics

Current Month: 2024-01

Username             Speed Limit     Monthly Quota   Used This Month Status    
--------             -----------     -------------   --------------- ------    
proxy_a1b2c3d4       100Mbps         5GB             2GB             Active    
proxy_e5f6g7h8       Unlimited       3GB             3GB             Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Active    

Total Usage This Month: 6GB
```

### **8) Monitor Bandwidth Usage (Real-time)**
```
Real-time Bandwidth Usage - 2024-01-20 15:30:45

Active Connections:
HTTP Proxy: 15 connections
SOCKS5 Proxy: 8 connections

Username             Speed Limit     Monthly Quota   Used This Month Status    
--------             -----------     -------------   --------------- ------    
proxy_a1b2c3d4       100Mbps         5GB             2GB             Active    
proxy_e5f6g7h8       Unlimited       3GB             3GB             Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Active    

Total Usage This Month: 6GB

[Updates every 5 seconds - Press Ctrl+C to stop]
```

### **9) Reset User Quota**
```
Reset User Quota

Current Proxy Pairs with Bandwidth Control:
[Hiển thị danh sách]

Enter username to reset quota: proxy_e5f6g7h8
Are you sure you want to reset quota for user 'proxy_e5f6g7h8'? [y/N]: y

✓ Quota reset for user: proxy_e5f6g7h8
```

### **10) Test Proxy Pair (Enhanced)**
```
Test Proxy Pair

Enter username to test: proxy_a1b2c3d4

Testing proxy pair for user: proxy_a1b2c3d4

Testing HTTP Proxy...
✓ HTTP Proxy working - External IP: 203.0.113.1

Testing SOCKS5 Proxy...
✓ SOCKS5 Proxy working - External IP: 203.0.113.1

Bandwidth Information:
Speed Limit: 100Mbps
Monthly Quota: 5GB
Status: active
Usage This Month: 2GB
```

### **11) Service Status (Enhanced)**
```
Service Status:
Squid (HTTP):   Running
Dante (SOCKS5): Running

Port Status:
HTTP Port 3128:   Open
SOCKS5 Port 1080: Open

Traffic Control Status:
Bandwidth Control: Active
Active bandwidth limits:
  Class 1001: 100Mbit
  Class 1002: 50Mbit
  Class 1003: 200Mbit
```

### **13) View Logs (Enhanced)**
```
Proxy Logs

1) HTTP Proxy Logs (last 20 lines)
2) SOCKS5 Proxy Logs (last 20 lines)
3) Bandwidth Monitor Logs
4) All Logs

Select log to view [1-4]: 3

Bandwidth Monitor Log:
[2024-01-20 15:30:45] Starting bandwidth monitoring
[2024-01-20 15:35:45] User proxy_a1b2c3d4 used 104857600 bytes
[2024-01-20 15:40:45] User proxy_e5f6g7h8 blocked due to quota exceeded
[2024-01-20 15:45:45] Bandwidth monitoring completed
```

## 🔧 **CÁC LỆNH HỆ THỐNG TRAFFIC CONTROL**

### **Quản lý Traffic Control (TC)**
```bash
# Xem tất cả qdisc
sudo tc qdisc show

# Xem qdisc cho interface cụ thể
sudo tc qdisc show dev eth0

# Xem tất cả classes
sudo tc class show dev eth0

# Xem class với statistics
sudo tc -s class show dev eth0

# Xem tất cả filters
sudo tc filter show dev eth0

# Xóa tất cả tc rules
sudo tc qdisc del dev eth0 root

# Tạo lại tc structure
sudo tc qdisc add dev eth0 root handle 1: htb default 999
sudo tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbit
```

### **Quản lý iptables cho Bandwidth**
```bash
# Xem mangle table
sudo iptables -t mangle -L -n -v

# Xem OUTPUT chain (user marking)
sudo iptables -t mangle -L OUTPUT -n -v

# Xem PREROUTING chain (connection tracking)
sudo iptables -t mangle -L PREROUTING -n -v

# Xóa tất cả mangle rules
sudo iptables -t mangle -F

# Test marking cho user cụ thể
sudo iptables -t mangle -I OUTPUT -m owner --uid-owner 1001 -j LOG --log-prefix "USER_1001: "

# Xem log
sudo tail -f /var/log/kern.log | grep "USER_1001"
```

## 📊 **CÁC LỆNH MONITORING VÀ DEBUG**

### **Bandwidth Monitoring Scripts**
```bash
# Chạy bandwidth monitor thủ công
sudo /usr/local/bin/proxy-bandwidth-monitor.sh

# Xem log bandwidth monitor
sudo tail -f /var/log/proxy-bandwidth-monitor.log

# Chạy quota reset thủ công
sudo /usr/local/bin/proxy-quota-reset.sh

# Xem log quota reset
sudo tail -f /var/log/proxy-quota-reset.log
```

### **Database Queries**
```bash
# Xem proxy users database
sudo cat /etc/proxy-manager/proxy_users.db

# Xem bandwidth usage database
sudo cat /etc/proxy-manager/bandwidth_usage.db

# Tìm user cụ thể
sudo grep "proxy_a1b2c3d4" /etc/proxy-manager/proxy_users.db

# Xem usage tháng hiện tại
current_month=$(date +%Y-%m)
sudo grep ":$current_month:" /etc/proxy-manager/bandwidth_usage.db

# Tính tổng usage
sudo awk -F: -v month="$current_month" '$2 == month {sum += $3} END {print sum+0}' /etc/proxy-manager/bandwidth_usage.db
```

### **Real-time Connection Monitoring**
```bash
# Đếm connections HTTP
sudo netstat -an | grep ":3128" | grep ESTABLISHED | wc -l

# Đếm connections SOCKS5
sudo netstat -an | grep ":1080" | grep ESTABLISHED | wc -l

# Xem connections chi tiết
sudo netstat -anp | grep ":3128"
sudo netstat -anp | grep ":1080"

# Monitor connections real-time
watch -n 1 'echo "HTTP: $(netstat -an | grep ":3128" | grep ESTABLISHED | wc -l) | SOCKS5: $(netstat -an | grep ":1080" | grep ESTABLISHED | wc -l)"'
```

### **Bandwidth Usage Calculation**
```bash
# Parse Squid logs cho bandwidth
sudo awk '{
    timestamp = $1
    username = $8  
    bytes_sent = $5
    bytes_received = $6
    if (username != "-") {
        total_bytes = bytes_sent + bytes_received
        user_usage[username] += total_bytes
    }
} END {
    for (user in user_usage) {
        print user ":" user_usage[user]
    }
}' /var/log/squid/access.log

# Tính usage theo thời gian
start_time=$(date -d "1 hour ago" +%s)
sudo awk -v start="$start_time" '{
    if ($1 > start && $8 != "-") {
        user_usage[$8] += ($5 + $6)
    }
} END {
    for (user in user_usage) {
        print user ":" user_usage[user]
    }
}' /var/log/squid/access.log
```

## 🔧 **CÁC LỆNH TROUBLESHOOTING BANDWIDTH**

### **Debug Traffic Control**
```bash
# Kiểm tra xem TC có hoạt động không
sudo tc qdisc show dev eth0 | grep htb

# Kiểm tra classes có được tạo không
sudo tc class show dev eth0 | grep "class htb"

# Kiểm tra filters
sudo tc filter show dev eth0

# Test bandwidth limit
# Tạo test user với UID 9999
sudo useradd -u 9999 testuser
sudo tc class add dev eth0 parent 1:1 classid 1:9999 htb rate 10mbit ceil 10mbit
sudo tc filter add dev eth0 protocol ip parent 1:0 prio 1 handle 9999 fw flowid 1:9999
sudo iptables -t mangle -A OUTPUT -m owner --uid-owner 9999 -j MARK --set-mark 9999

# Test với wget
sudo -u testuser wget --limit-rate=20m http://speedtest.tele2.net/100MB.zip

# Xem statistics
sudo tc -s class show dev eth0 classid 1:9999
```

### **Debug User Blocking**
```bash
# Kiểm tra user có bị block không
uid=$(id -u proxy_a1b2c3d4)
sudo iptables -L OUTPUT -n -v | grep "owner UID match $uid"

# Test connection từ user bị block
sudo -u proxy_a1b2c3d4 curl -s --max-time 5 http://ifconfig.me

# Unblock user thủ công
sudo iptables -D OUTPUT -m owner --uid-owner $uid -j DROP

# Block user thủ công
sudo iptables -I OUTPUT -m owner --uid-owner $uid -j DROP
```

### **Debug Quota System**
```bash
# Kiểm tra quota cho user
username="proxy_a1b2c3d4"
current_month=$(date +%Y-%m)
used_bytes=$(sudo grep "^$username:$current_month:" /etc/proxy-manager/bandwidth_usage.db | cut -d':' -f3)
echo "User $username used: $((used_bytes / 1024 / 1024)) MB this month"

# Kiểm tra quota limit
quota_gb=$(sudo grep "^$username:" /etc/proxy-manager/proxy_users.db | cut -d':' -f6)
echo "User $username quota: $quota_gb GB"

# Tính phần trăm sử dụng
if [[ $quota_gb -gt 0 ]]; then
    quota_bytes=$((quota_gb * 1024 * 1024 * 1024))
    percentage=$((used_bytes * 100 / quota_bytes))
    echo "Usage: $percentage%"
fi
```

### **Performance Monitoring**
```bash
# Monitor CPU usage của proxy processes
top -p $(pgrep squid | tr '\n' ',' | sed 's/,$//')
top -p $(pgrep sockd | tr '\n' ',' | sed 's/,$//')

# Monitor memory usage
ps aux | grep -E "(squid|sockd)" | grep -v grep

# Monitor disk I/O
sudo iotop -p $(pgrep squid),$(pgrep sockd)

# Monitor network traffic
sudo iftop -i eth0 -P

# Monitor bandwidth per user
sudo tc -s class show dev eth0 | grep -A 3 "class htb 1:"
```

## 🎯 **CÁC LỆNH AUTOMATION**

### **Cron Jobs Management**
```bash
# Xem cron jobs hiện tại
sudo crontab -l

# Xem system cron jobs
ls -la /etc/cron.d/

# Kiểm tra bandwidth monitor cron
cat /etc/cron.d/proxy-bandwidth-monitor

# Kiểm tra quota reset cron
cat /etc/cron.d/proxy-quota-reset

# Test cron job thủ công
sudo run-parts --test /etc/cron.d/

# Xem cron logs
sudo tail -f /var/log/cron
```

### **Log Rotation**
```bash
# Xem log rotation config
cat /etc/logrotate.d/squid

# Rotate logs thủ công
sudo logrotate -f /etc/logrotate.d/squid

# Kiểm tra log sizes
du -sh /var/log/squid/*
du -sh /var/log/sockd.log
du -sh /var/log/proxy-*.log
```

## 🔄 **CÁC LỆNH MAINTENANCE**

### **Database Maintenance**
```bash
# Backup databases
sudo cp /etc/proxy-manager/proxy_users.db /etc/proxy-manager/proxy_users.db.backup
sudo cp /etc/proxy-manager/bandwidth_usage.db /etc/proxy-manager/bandwidth_usage.db.backup

# Clean old bandwidth data (older than 3 months)
three_months_ago=$(date -d "3 months ago" +%Y-%m)
sudo sed -i "/:[0-9]\{4\}-[0-9]\{2\}:/d" /etc/proxy-manager/bandwidth_usage.db

# Optimize database (remove empty lines)
sudo sed -i '/^$/d' /etc/proxy-manager/proxy_users.db
sudo sed -i '/^$/d' /etc/proxy-manager/bandwidth_usage.db
```

### **System Cleanup**
```bash
# Clean old proxy files
sudo find /tmp -name "proxy_*" -mtime +7 -delete

# Clean old logs
sudo find /var/log -name "*.log.*" -mtime +30 -delete

# Clean squid cache
sudo squid -k shutdown
sudo rm -rf /var/spool/squid/*
sudo squid -z
sudo systemctl start squid
```

## 🎯 **TÓM TẮT CÁC LỆNH QUAN TRỌNG NHẤT**

### **🔥 Top 15 Lệnh Enhanced Thường Dùng:**

1. `sudo ./enhanced-dual-proxy.sh` - Chạy script enhanced
2. `sudo ./enhanced-dual-proxy.sh menu` - Vào menu quản lý enhanced
3. `sudo ./enhanced-dual-proxy.sh stats` - Xem bandwidth statistics
4. `sudo ./enhanced-dual-proxy.sh status` - Kiểm tra trạng thái + TC
5. `sudo tc -s class show dev eth0` - Xem bandwidth usage real-time
6. `sudo iptables -t mangle -L OUTPUT -n -v` - Xem user marking rules
7. `sudo cat /etc/proxy-manager/bandwidth_usage.db` - Xem usage database
8. `sudo /usr/local/bin/proxy-bandwidth-monitor.sh` - Chạy monitor thủ công
9. `sudo netstat -an | grep ":3128" | wc -l` - Đếm HTTP connections
10. `sudo netstat -an | grep ":1080" | wc -l` - Đếm SOCKS5 connections
11. `sudo tail -f /var/log/proxy-bandwidth-monitor.log` - Xem monitor log
12. `sudo tc qdisc show dev eth0` - Kiểm tra traffic control
13. `sudo grep "blocked_quota" /etc/proxy-manager/proxy_users.db` - Tìm user bị block
14. `sudo systemctl restart squid sockd` - Restart cả 2 services
15. `watch -n 1 'tc -s class show dev eth0'` - Monitor bandwidth real-time

### **🚨 Lệnh Khẩn Cấp Enhanced:**
```bash
# Dừng tất cả và reset traffic control
sudo systemctl stop squid sockd
sudo tc qdisc del dev eth0 root
sudo iptables -t mangle -F

# Khởi động lại hoàn toàn
sudo systemctl restart squid sockd
sudo ./enhanced-dual-proxy.sh menu
# -> Chọn option 11 (Service Status) để kiểm tra
```

---

**💡 Lưu ý**: Tất cả lệnh bandwidth control cần quyền root (sudo). Enhanced version cung cấp kiểm soát băng thông hoàn chỉnh với real-time monitoring và automatic quota management.