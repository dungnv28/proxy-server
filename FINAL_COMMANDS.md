# FINAL DUAL PROXY MANAGER - COMMAND REFERENCE

## 🎯 **CÁC LỆNH COMMAND LINE CHÍNH**

### 1. **LỆNH KHỞI CHẠY FINAL VERSION**
```bash
# Chạy script final hoàn chỉnh
sudo ./final-dual-proxy.sh

# Hoặc với bash
sudo bash final-dual-proxy.sh
```

### 2. **CÁC LỆNH THAM SỐ FINAL**

#### 🔧 **Menu Management**
```bash
# Vào menu quản lý final (bỏ qua cài đặt)
sudo ./final-dual-proxy.sh menu
```

#### 📊 **Xem thống kê bandwidth**
```bash
# Hiển thị bandwidth statistics
sudo ./final-dual-proxy.sh stats
```

#### 🔍 **Kiểm tra trạng thái final**
```bash
# Kiểm tra trạng thái dịch vụ + traffic control
sudo ./final-dual-proxy.sh status
```

#### 📋 **Xem thông tin final**
```bash
# Hiển thị thông tin cài đặt final
sudo ./final-dual-proxy.sh info
```

## 🖥️ **MENU TƯƠNG TÁC FINAL**

### 📋 **MENU CHÍNH (Final Interactive Menu)**
```
Final Dual Proxy Management Menu
Server: 192.168.1.100 | HTTP: 3128 | SOCKS5: 1080

CRUD Operations:
1) Create Single Proxy Pair (with Bandwidth Control)
2) Create Multiple Proxy Pairs (with Bandwidth Control)  
3) Read/List All Proxy Pairs (with Bandwidth Info)
4) Update Proxy Bandwidth Settings
5) Update Proxy Password
6) Delete Single Proxy Pair
7) Delete All Proxy Pairs

Bandwidth Management:
8) Show Bandwidth Statistics
9) Monitor Bandwidth Usage (Real-time)
10) Reset User Quota

System Management:
11) Export Proxy Pairs
12) Test Proxy Pair
13) Service Status
14) Restart Services
15) View Logs

0) Exit

Select an option [0-15]:
```

## 🔧 **CHI TIẾT CÁC LỆNH FINAL MENU**

### **1) Create Single Proxy Pair (Final Bandwidth Control)**
```
Creating new proxy pair with bandwidth control...

Bandwidth Configuration:
1) Unlimited (default)    ← MẶC ĐỊNH - Không giới hạn gì
2) Custom speed limit and total quota    ← Chỉ khi muốn giới hạn

Select option [1-2]: 1    ← Chọn 1 cho unlimited

✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
Speed Limit:  Unlimited
Total Quota:  Unlimited
```

**Hoặc nếu muốn giới hạn:**
```
Select option [1-2]: 2    ← Chọn 2 cho custom

Enter speed limit in Mbps (0 for unlimited): 100
Enter total quota in GB (0 for unlimited): 20

✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
Speed Limit:  100Mbps
Total Quota:  20GB
```

### **2) Create Multiple Proxy Pairs (Final Bandwidth Control)**
```
Enter number of proxy pairs to create: 10

Bandwidth Configuration for all proxies:
1) Unlimited (default)    ← Tất cả sẽ unlimited
2) Custom speed limit and total quota    ← Tất cả sẽ có cùng giới hạn

Select option [1-2]: 1    ← Chọn unlimited cho tất cả

Creating 10 proxy pairs...
Progress: 10/10

✓ Created 10 proxy pairs successfully!

Proxy List:
HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6 | Speed: Unlimited | Quota: Unlimited
SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6 | Speed: Unlimited | Quota: Unlimited
...

✓ Proxy list uploaded successfully!
Download URL: https://file.io/abc123
Archive Password: randomPassword123
```

### **3) Read/List All Proxy Pairs (với Final Bandwidth Info)**
```
Current Proxy Pairs with Bandwidth Control:

Format: HTTP and SOCKS5 pairs with bandwidth limits
Server IP: 192.168.1.100

[1] User: proxy_a1b2c3d4
    HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
    SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
    Created: 2024-01-15 10:30:25 | Status: active
    Speed Limit: Unlimited    ← Không giới hạn tốc độ
    Total Quota: Unlimited    ← Không giới hạn dung lượng
    Usage: 2GB

[2] User: proxy_e5f6g7h8
    HTTP:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
    SOCKS5: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
    Created: 2024-01-15 10:30:26 | Status: blocked_quota
    Speed Limit: 100Mbps     ← Có giới hạn tốc độ
    Total Quota: 20GB        ← Có giới hạn dung lượng
    Usage: 20GB              ← Đã hết quota

[3] User: proxy_x9y8z7w6
    HTTP:   192.168.1.100:3128:proxy_x9y8z7w6:pass_q1w2e3r4
    SOCKS5: 192.168.1.100:1080:proxy_x9y8z7w6:pass_q1w2e3r4
    Created: 2024-01-15 10:30:27 | Status: blocked_manual
    Speed Limit: 50Mbps      ← Có giới hạn tốc độ
    Total Quota: Unlimited   ← Không giới hạn dung lượng
    Usage: 1GB               ← Bị block thủ công

Total proxy pairs: 3
```

### **4) Update Proxy Bandwidth Settings (FINAL LINH HOẠT)**
```
Update Proxy Bandwidth Settings

[Hiển thị danh sách proxy như trên]

Enter username to update: proxy_a1b2c3d4

Update Options:
1) Update speed limit only           ← Chỉ thay đổi tốc độ
2) Update total quota only           ← Chỉ thay đổi quota
3) Update both speed limit and quota ← Thay đổi cả hai
4) Reset to unlimited               ← Về lại unlimited
5) Block/Unblock user               ← Chặn/bỏ chặn user

Select option [1-5]: 4    ← Ví dụ: Reset về unlimited

✓ User proxy_a1b2c3d4 reset to unlimited
```

**Ví dụ khác - Thêm giới hạn cho user unlimited:**
```
Select option [1-5]: 3    ← Thay đổi cả hai

Enter new speed limit in Mbps (0 for unlimited): 200
Enter new total quota in GB (0 for unlimited): 50

✓ Speed: 200Mbps, Quota: 50GB updated for user: proxy_a1b2c3d4
```

**Ví dụ khác - Block/Unblock user:**
```
Select option [1-5]: 5    ← Block/Unblock

Current status: active
1) Block user (stop access)
2) Unblock user (restore access)

Select [1-2]: 1    ← Block user

✓ User proxy_a1b2c3d4 blocked manually
```

### **5) Update Proxy Password**
```
Update Proxy Password

[Hiển thị danh sách proxy]

Enter username to update password: proxy_a1b2c3d4

✓ Password updated successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_newPassword123
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_newPassword123
```

### **8) Show Bandwidth Statistics**
```
Bandwidth Usage Statistics

Username             Speed Limit     Total Quota     Used            Status    
--------             -----------     -----------     ----            ------    
proxy_a1b2c3d4       Unlimited       Unlimited       2GB             Active    
proxy_e5f6g7h8       100Mbps         20GB            20GB            Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Blocked   
proxy_m7n8o9p0       200Mbps         50GB            25GB            Active    
proxy_q3r4s5t6       Unlimited       10GB            5GB             Active    

Total Usage: 53GB
```

### **9) Monitor Bandwidth Usage (Real-time)**
```
Real-time Bandwidth Usage - 2024-01-20 15:30:45

Active Connections:
HTTP Proxy: 35 connections
SOCKS5 Proxy: 28 connections

Username             Speed Limit     Total Quota     Used            Status    
--------             -----------     -----------     ----            ------    
proxy_a1b2c3d4       Unlimited       Unlimited       2GB             Active    
proxy_e5f6g7h8       100Mbps         20GB            20GB            Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Blocked   

Total Usage: 23GB

[Updates every 5 seconds - Press Ctrl+C to stop]
```

### **10) Reset User Quota (Gia hạn dịch vụ)**
```
Reset User Quota

[Hiển thị danh sách proxy]

Enter username to reset quota: proxy_e5f6g7h8
Are you sure you want to reset quota for user 'proxy_e5f6g7h8'? [y/N]: y

✓ Quota reset for user: proxy_e5f6g7h8

# User này giờ có thể dùng tiếp từ 0GB
# Nếu bị block do quota sẽ tự động unblock
```

### **12) Test Proxy Pair (Final Enhanced với Bandwidth Info)**
```
Test Proxy Pair

Enter username to test: proxy_a1b2c3d4

Testing proxy pair for user: proxy_a1b2c3d4

Testing HTTP Proxy...
✓ HTTP Proxy working - External IP: 203.0.113.1

Testing SOCKS5 Proxy...
✓ SOCKS5 Proxy working - External IP: 203.0.113.1

Bandwidth Information:
Speed Limit: Unlimited
Total Quota: Unlimited
Status: active
Usage: 2GB
```

### **13) Service Status (Final Enhanced với Traffic Control)**
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
  Class 1001: 100Mbit    ← User có giới hạn 100Mbps
  Class 1002: 50Mbit     ← User có giới hạn 50Mbps
  Class 1003: 200Mbit    ← User có giới hạn 200Mbps
```

### **15) View Logs (Final Enhanced)**
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
[2024-01-20 15:45:45] User proxy_e5f6g7h8 exceeded quota: 21474836480 bytes / 21474836480 bytes
[2024-01-20 15:50:45] Bandwidth monitoring completed
```

## 🔧 **CÁC LỆNH HỆ THỐNG FINAL**

### **Database Queries cho Final System**
```bash
# Xem tất cả proxy users
sudo cat /etc/proxy-manager/proxy_users.db

# Tìm user unlimited (speed và quota)
sudo grep ":0:0:" /etc/proxy-manager/proxy_users.db

# Tìm user có giới hạn tốc độ
sudo awk -F: '$5 > 0 {print $1 ": " $5 "Mbps"}' /etc/proxy-manager/proxy_users.db

# Tìm user có giới hạn quota
sudo awk -F: '$6 > 0 {print $1 ": " $6 "GB"}' /etc/proxy-manager/proxy_users.db

# Tìm user bị block do hết quota
sudo grep "blocked_quota" /etc/proxy-manager/proxy_users.db

# Tìm user bị block thủ công
sudo grep "blocked_manual" /etc/proxy-manager/proxy_users.db

# Tìm user đang active
sudo grep ":active:" /etc/proxy-manager/proxy_users.db

# Tính tổng usage của tất cả users
sudo awk -F: 'NR>7 && $1 !~ /^#/ {sum += $7} END {print "Total usage: " sum/1024/1024/1024 " GB"}' /etc/proxy-manager/proxy_users.db
```

### **Traffic Control Management cho Final**
```bash
# Xem tất cả qdisc
sudo tc qdisc show dev eth0

# Xem tất cả classes với statistics
sudo tc -s class show dev eth0

# Xem chỉ classes có giới hạn (không phải unlimited)
sudo tc -s class show dev eth0 | grep -A 3 "class htb 1:" | grep -v "1000Mbit" | grep -v "class htb 1:1 " | grep -v "class htb 1:999"

# Xem user nào đang có bandwidth limit
sudo tc filter show dev eth0 | grep "handle"

# Test bandwidth cho user cụ thể
username="proxy_e5f6g7h8"
uid=$(id -u "$username" 2>/dev/null)
if [[ -n "$uid" ]]; then
    class_id="1:$((1000 + uid % 1000))"
    sudo tc -s class show dev eth0 classid "$class_id"
fi

# Monitor bandwidth real-time cho tất cả users
watch -n 1 'tc -s class show dev eth0 | grep -A 2 "class htb 1:" | grep -E "(class|Sent)"'
```

### **Final User Management**
```bash
# Thêm giới hạn cho user unlimited
username="proxy_a1b2c3d4"
speed_mbps=100
quota_gb=20
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):0:0:\([^:]*\)$/$username:\1:\2:\3:$speed_mbps:$quota_gb:\4/" /etc/proxy-manager/proxy_users.db

# Xóa giới hạn cho user (về unlimited)
username="proxy_e5f6g7h8"
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:\([^:]*\)$/$username:\1:\2:\3:0:0:\4/" /etc/proxy-manager/proxy_users.db

# Reset quota cho user (gia hạn)
username="proxy_e5f6g7h8"
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$/$username:\1:\2:\3:\4:\5:0/" /etc/proxy-manager/proxy_users.db

# Block user thủ công
username="proxy_e5f6g7h8"
uid=$(id -u "$username" 2>/dev/null)
if [[ -n "$uid" ]]; then
    sudo iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP
    sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_manual:/" /etc/proxy-manager/proxy_users.db
fi

# Unblock user thủ công
username="proxy_e5f6g7h8"
uid=$(id -u "$username" 2>/dev/null)
if [[ -n "$uid" ]]; then
    sudo iptables -D OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
    sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_.*:/$username:\1:\2:active:/" /etc/proxy-manager/proxy_users.db
fi

# Apply bandwidth limit cho user
username="proxy_e5f6g7h8"
speed_mbps=100
uid=$(id -u "$username" 2>/dev/null)
if [[ -n "$uid" ]]; then
    class_id="1:$((1000 + uid % 1000))"
    sudo tc class add dev eth0 parent 1:1 classid "$class_id" htb rate "${speed_mbps}mbit" ceil "${speed_mbps}mbit"
    sudo tc filter add dev eth0 protocol ip parent 1:0 prio 1 handle "$uid" fw flowid "$class_id"
    sudo iptables -t mangle -A OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid"
fi

# Remove bandwidth limit cho user (unlimited)
username="proxy_a1b2c3d4"
uid=$(id -u "$username" 2>/dev/null)
if [[ -n "$uid" ]]; then
    class_id="1:$((1000 + uid % 1000))"
    sudo tc class del dev eth0 classid "$class_id" 2>/dev/null
    sudo tc filter del dev eth0 protocol ip parent 1: handle "$uid" fw 2>/dev/null
    sudo iptables -t mangle -D OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid" 2>/dev/null
fi
```

## 📊 **CÁC LỆNH MONITORING FINAL**

### **Real-time Monitoring**
```bash
# Monitor connections theo thời gian thực
watch -n 1 'echo "HTTP: $(netstat -an | grep ":3128" | grep ESTABLISHED | wc -l) | SOCKS5: $(netstat -an | grep ":1080" | grep ESTABLISHED | wc -l)"'

# Monitor bandwidth usage real-time cho tất cả users
watch -n 5 'tc -s class show dev eth0 | grep -A 2 "class htb 1:" | grep -E "(class|Sent)"'

# Monitor user status real-time
watch -n 10 'echo "Active: $(grep ":active:" /etc/proxy-manager/proxy_users.db | wc -l) | Blocked Quota: $(grep ":blocked_quota:" /etc/proxy-manager/proxy_users.db | wc -l) | Blocked Manual: $(grep ":blocked_manual:" /etc/proxy-manager/proxy_users.db | wc -l)"'

# Monitor total usage real-time
watch -n 30 'awk -F: "NR>7 && \$1 !~ /^#/ {sum += \$7} END {print \"Total usage: \" sum/1024/1024/1024 \" GB\"}" /etc/proxy-manager/proxy_users.db'
```

### **Usage Calculation Advanced**
```bash
# Tính usage cho user cụ thể từ Squid logs
username="proxy_a1b2c3d4"
used_bytes=$(sudo awk -v user="$username" '$3 == user {
    bytes_sent = $5
    bytes_received = $6
    if (bytes_sent ~ /^[0-9]+$/ && bytes_received ~ /^[0-9]+$/) {
        total += (bytes_sent + bytes_received)
    }
} END {print total+0}' /var/log/squid/access.log)
echo "User $username used: $((used_bytes / 1024 / 1024)) MB"

# Tính usage trong khoảng thời gian cụ thể
start_time=$(date -d "1 hour ago" +%s)
username="proxy_a1b2c3d4"
used_bytes=$(sudo awk -v user="$username" -v start="$start_time" '$1 > start && $3 == user {
    bytes_sent = $5
    bytes_received = $6
    if (bytes_sent ~ /^[0-9]+$/ && bytes_received ~ /^[0-9]+$/) {
        total += (bytes_sent + bytes_received)
    }
} END {print total+0}' /var/log/squid/access.log)
echo "User $username used in last hour: $((used_bytes / 1024 / 1024)) MB"

# Top 10 users theo usage
sudo awk -F: 'NR>7 && $1 !~ /^#/ {print $1 ":" $7}' /etc/proxy-manager/proxy_users.db | sort -t: -k2 -nr | head -10 | while IFS=: read user bytes; do
    gb=$((bytes / 1024 / 1024 / 1024))
    mb=$(((bytes % (1024*1024*1024)) / 1024 / 1024))
    echo "User $user: ${gb}GB ${mb}MB"
done

# Tính usage theo ngày
today=$(date +%Y-%m-%d)
sudo awk -v date="$today" '$1 ~ date {
    user = $3
    bytes_sent = $5
    bytes_received = $6
    if (bytes_sent ~ /^[0-9]+$/ && bytes_received ~ /^[0-9]+$/) {
        user_usage[user] += (bytes_sent + bytes_received)
    }
} END {
    for (user in user_usage) {
        print user ":" user_usage[user]
    }
}' /var/log/squid/access.log | sort -t: -k2 -nr
```

## 🔧 **CÁC LỆNH TROUBLESHOOTING FINAL**

### **Debug Bandwidth Control**
```bash
# Kiểm tra user có bandwidth limit không
username="proxy_e5f6g7h8"
user_info=$(sudo grep "^$username:" /etc/proxy-manager/proxy_users.db)
speed_limit=$(echo "$user_info" | cut -d':' -f5)
quota_gb=$(echo "$user_info" | cut -d':' -f6)
status=$(echo "$user_info" | cut -d':' -f4)

echo "User: $username"
if [[ "$speed_limit" -eq 0 ]]; then
    echo "Speed: Unlimited"
else
    echo "Speed: ${speed_limit}Mbps"
fi

if [[ "$quota_gb" -eq 0 ]]; then
    echo "Quota: Unlimited"
else
    echo "Quota: ${quota_gb}GB"
fi

echo "Status: $status"

# Kiểm tra user có bị block không
uid=$(id -u "$username" 2>/dev/null)
if [[ -n "$uid" ]]; then
    if sudo iptables -L OUTPUT -n -v | grep -q "owner UID match $uid"; then
        echo "User is BLOCKED by iptables"
    else
        echo "User is NOT blocked by iptables"
    fi
fi
```

### **Fix Common Issues**
```bash
# Reset hoàn toàn traffic control
sudo tc qdisc del dev eth0 root 2>/dev/null
sudo tc qdisc add dev eth0 root handle 1: htb default 999
sudo tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbit
sudo tc class add dev eth0 parent 1:1 classid 1:999 htb rate 1000mbit ceil 1000mbit

# Reapply tất cả bandwidth limits
while IFS=':' read -r username password created_date status speed_limit quota_gb used_bytes; do
    [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
    [[ "$speed_limit" -eq 0 ]] && continue
    
    uid=$(id -u "$username" 2>/dev/null)
    [[ -z "$uid" ]] && continue
    
    class_id="1:$((1000 + uid % 1000))"
    sudo tc class add dev eth0 parent 1:1 classid "$class_id" htb rate "${speed_limit}mbit" ceil "${speed_limit}mbit" 2>/dev/null
    sudo tc filter add dev eth0 protocol ip parent 1:0 prio 1 handle "$uid" fw flowid "$class_id" 2>/dev/null
    sudo iptables -t mangle -A OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid" 2>/dev/null
done < /etc/proxy-manager/proxy_users.db

# Reapply tất cả blocks
sudo grep "blocked" /etc/proxy-manager/proxy_users.db | cut -d':' -f1 | while read username; do
    uid=$(id -u "$username" 2>/dev/null)
    [[ -n "$uid" ]] && sudo iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP 2>/dev/null
done

# Clean up iptables mangle table
sudo iptables -t mangle -F OUTPUT

# Restart services
sudo systemctl restart squid sockd

# Run bandwidth monitor manually
sudo /usr/local/bin/proxy-bandwidth-monitor.sh
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

# Monitor bandwidth per user với TC
sudo tc -s class show dev eth0 | grep -A 3 "class htb 1:" | grep -E "(class|Sent)" | while read line; do
    if [[ "$line" =~ class.*1:([0-9]+) ]]; then
        class_id="${BASH_REMATCH[1]}"
        if [[ "$class_id" != "1" && "$class_id" != "999" ]]; then
            echo "Class $class_id:"
        fi
    elif [[ "$line" =~ Sent.*bytes ]]; then
        echo "  $line"
    fi
done
```

## 🎯 **WORKFLOW COMMANDS CHO KINH DOANH**

### **Tạo gói proxy cho khách hàng**
```bash
# Gói Free/Trial (unlimited)
sudo ./final-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 1 (Unlimited)

# Gói Basic (50Mbps, 10GB)
sudo ./final-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 2 -> 50 -> 10

# Gói Premium (100Mbps, unlimited quota)
sudo ./final-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 2 -> 100 -> 0

# Gói Enterprise (unlimited)
sudo ./final-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 1 (Unlimited)

# Tạo hàng loạt cho reseller
sudo ./final-dual-proxy.sh menu
# -> Chọn 2 -> Nhập số lượng -> Chọn cấu hình
```

### **Quản lý khách hàng**
```bash
# Khách hàng hết quota, muốn gia hạn
sudo ./final-dual-proxy.sh menu
# -> Chọn 10 (Reset User Quota) -> Nhập username

# Khách hàng muốn upgrade lên unlimited
sudo ./final-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 4 (Reset to unlimited)

# Khách hàng muốn upgrade tốc độ
sudo ./final-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 1 (Update speed only)

# Khách hàng muốn mua thêm quota
sudo ./final-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 2 (Update quota only)

# Tạm dừng dịch vụ khách hàng
sudo ./final-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 5 (Block user)

# Khôi phục dịch vụ khách hàng
sudo ./final-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 5 (Unblock user)

# Đổi password cho khách hàng
sudo ./final-dual-proxy.sh menu
# -> Chọn 5 (Update Proxy Password) -> Nhập username
```

### **Monitoring và Báo cáo**
```bash
# Xem thống kê tổng quan
sudo ./final-dual-proxy.sh stats

# Monitor real-time
sudo ./final-dual-proxy.sh menu
# -> Chọn 9 (Monitor Bandwidth Usage)

# Xuất báo cáo cho khách hàng
sudo ./final-dual-proxy.sh menu
# -> Chọn 11 (Export Proxy Pairs)

# Test proxy cho khách hàng
sudo ./final-dual-proxy.sh menu
# -> Chọn 12 (Test Proxy Pair) -> Nhập username

# Kiểm tra trạng thái hệ thống
sudo ./final-dual-proxy.sh status
```

## 🎯 **TÓM TẮT CÁC LỆNH QUAN TRỌNG NHẤT**

### **🔥 Top 20 Lệnh Final Thường Dùng:**

1. `sudo ./final-dual-proxy.sh` - Chạy script final
2. `sudo ./final-dual-proxy.sh menu` - Vào menu quản lý final
3. `sudo ./final-dual-proxy.sh stats` - Xem bandwidth statistics
4. `sudo ./final-dual-proxy.sh status` - Kiểm tra trạng thái + TC
5. `sudo grep ":0:0:" /etc/proxy-manager/proxy_users.db` - Tìm user unlimited
6. `sudo grep "blocked" /etc/proxy-manager/proxy_users.db` - Tìm user bị block
7. `sudo awk -F: '$5 > 0' /etc/proxy-manager/proxy_users.db` - Tìm user có speed limit
8. `sudo awk -F: '$6 > 0' /etc/proxy-manager/proxy_users.db` - Tìm user có quota limit
9. `sudo tc -s class show dev eth0` - Xem bandwidth usage real-time
10. `sudo netstat -an | grep ":3128" | wc -l` - Đếm HTTP connections
11. `sudo netstat -an | grep ":1080" | wc -l` - Đếm SOCKS5 connections
12. `sudo /usr/local/bin/proxy-bandwidth-monitor.sh` - Chạy monitor thủ công
13. `sudo systemctl restart squid sockd` - Restart cả 2 services
14. `watch -n 5 'tc -s class show dev eth0'` - Monitor bandwidth real-time
15. `sudo tail -f /var/log/proxy-bandwidth-monitor.log` - Xem monitor log
16. `sudo grep ":active:" /etc/proxy-manager/proxy_users.db | wc -l` - Đếm user active
17. `sudo awk -F: 'NR>7 {sum += $7} END {print sum/1024/1024/1024 " GB"}' /etc/proxy-manager/proxy_users.db` - Tổng usage
18. `curl -x user:pass@ip:3128 http://ifconfig.me` - Test HTTP proxy
19. `curl --socks5 user:pass@ip:1080 http://ifconfig.me` - Test SOCKS5 proxy
20. `sudo tc qdisc show dev eth0` - Kiểm tra traffic control

### **🚨 Lệnh Khẩn Cấp Final:**
```bash
# Reset hoàn toàn hệ thống
sudo systemctl stop squid sockd
sudo tc qdisc del dev eth0 root
sudo iptables -t mangle -F
sudo iptables -F OUTPUT

# Khởi động lại hoàn toàn
sudo ./final-dual-proxy.sh menu
# -> Chọn 14 (Restart Services)
# -> Chọn 13 (Service Status) để kiểm tra

# Unblock tất cả users
sudo iptables -F OUTPUT
sudo sed -i 's/:blocked_.*:/:active:/g' /etc/proxy-manager/proxy_users.db

# Reset tất cả về unlimited
sudo sed -i 's/:\([0-9]\+\):\([0-9]\+\):/:0:0:/g' /etc/proxy-manager/proxy_users.db
```

### **📊 Lệnh Monitoring Quan trọng:**
```bash
# Dashboard real-time
watch -n 5 'echo "=== FINAL DUAL PROXY DASHBOARD ===" && echo "Active Users: $(grep ":active:" /etc/proxy-manager/proxy_users.db | wc -l)" && echo "Blocked Users: $(grep "blocked" /etc/proxy-manager/proxy_users.db | wc -l)" && echo "HTTP Connections: $(netstat -an | grep ":3128" | grep ESTABLISHED | wc -l)" && echo "SOCKS5 Connections: $(netstat -an | grep ":1080" | grep ESTABLISHED | wc -l)" && echo "Total Usage: $(awk -F: "NR>7 && \$1 !~ /^#/ {sum += \$7} END {print sum/1024/1024/1024 \" GB\"}" /etc/proxy-manager/proxy_users.db)"'

# Top users by usage
sudo awk -F: 'NR>7 && $1 !~ /^#/ {print $1 ":" $7}' /etc/proxy-manager/proxy_users.db | sort -t: -k2 -nr | head -5

# Users cần chú ý (gần hết quota)
while IFS=':' read -r username password created_date status speed_limit quota_gb used_bytes; do
    [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
    [[ "$quota_gb" -eq 0 ]] && continue
    
    quota_bytes=$((quota_gb * 1024 * 1024 * 1024))
    if [[ "$used_bytes" -gt 0 ]]; then
        percentage=$((used_bytes * 100 / quota_bytes))
        if [[ "$percentage" -gt 80 ]]; then
            echo "WARNING: User $username used ${percentage}% of quota"
        fi
    fi
done < /etc/proxy-manager/proxy_users.db
```

---

**💡 Lưu ý**: Final version cung cấp **KIỂM SOÁT HOÀN TOÀN** với tất cả tính năng từ cả 2 phiên bản trước, plus thêm nhiều tính năng mới cho quản lý chuyên nghiệp!