# FLEXIBLE DUAL PROXY - COMMAND REFERENCE

## 🎯 **CÁC LỆNH FLEXIBLE BANDWIDTH CONTROL**

### 1. **LỆNH KHỞI CHẠY FLEXIBLE VERSION**
```bash
# Chạy script flexible với bandwidth control linh hoạt
sudo ./flexible-dual-proxy.sh

# Hoặc với bash
sudo bash flexible-dual-proxy.sh
```

### 2. **CÁC LỆNH THAM SỐ FLEXIBLE**

#### 🔧 **Menu Management**
```bash
# Vào menu quản lý flexible (bỏ qua cài đặt)
sudo ./flexible-dual-proxy.sh menu
```

#### 📊 **Xem thống kê bandwidth**
```bash
# Hiển thị bandwidth statistics
sudo ./flexible-dual-proxy.sh stats
```

#### 🔍 **Kiểm tra trạng thái flexible**
```bash
# Kiểm tra trạng thái dịch vụ + traffic control
sudo ./flexible-dual-proxy.sh status
```

#### 📋 **Xem thông tin flexible**
```bash
# Hiển thị thông tin cài đặt flexible
sudo ./flexible-dual-proxy.sh info
```

## 🖥️ **MENU TƯƠNG TÁC FLEXIBLE**

### 📋 **MENU CHÍNH (Flexible Interactive Menu)**
```
Flexible Proxy Management Menu
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
10) Export Proxy Pairs
11) Test Proxy Pair
12) Service Status
13) Restart Services
14) View Logs

0) Exit

Select an option [0-14]:
```

## 🔧 **CHI TIẾT CÁC LỆNH FLEXIBLE MENU**

### **1) Create Single Proxy Pair (Flexible Bandwidth Control)**
```
Creating new proxy pair...

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
Enter total quota in GB (0 for unlimited): 50

✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
Speed Limit:  100Mbps
Total Quota:  50GB
```

### **2) Create Multiple Proxy Pairs (Flexible Bandwidth Control)**
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
```

### **3) Read/List All Proxy Pairs (với Bandwidth Info)**
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
    Total Quota: 50GB        ← Có giới hạn dung lượng
    Usage: 50GB              ← Đã hết quota

[3] User: proxy_x9y8z7w6
    HTTP:   192.168.1.100:3128:proxy_x9y8z7w6:pass_q1w2e3r4
    SOCKS5: 192.168.1.100:1080:proxy_x9y8z7w6:pass_q1w2e3r4
    Created: 2024-01-15 10:30:27 | Status: active
    Speed Limit: 50Mbps      ← Có giới hạn tốc độ
    Total Quota: Unlimited   ← Không giới hạn dung lượng
    Usage: 1GB

Total proxy pairs: 3
```

### **4) Update Proxy Bandwidth Settings (LINH HOẠT)**
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
Enter new total quota in GB (0 for unlimited): 100

✓ Speed limit: 200Mbps, Quota: 100GB updated for user: proxy_a1b2c3d4
```

**Ví dụ khác - Chỉ thay đổi tốc độ:**
```
Select option [1-5]: 1    ← Chỉ thay đổi speed

Enter new speed limit in Mbps (0 for unlimited): 500

✓ Speed limit updated to 500Mbps for user: proxy_a1b2c3d4
```

### **7) Show Bandwidth Statistics**
```
Bandwidth Usage Statistics

Username             Speed Limit     Total Quota     Used            Status    
--------             -----------     -----------     ----            ------    
proxy_a1b2c3d4       Unlimited       Unlimited       2GB             Active    
proxy_e5f6g7h8       100Mbps         50GB            50GB            Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Active    
proxy_m7n8o9p0       200Mbps         100GB           25GB            Active    
proxy_q3r4s5t6       Unlimited       20GB            5GB             Active    

Total Usage: 83GB
```

### **8) Monitor Bandwidth Usage (Real-time)**
```
Real-time Bandwidth Usage - 2024-01-20 15:30:45

Active Connections:
HTTP Proxy: 25 connections
SOCKS5 Proxy: 18 connections

Username             Speed Limit     Total Quota     Used            Status    
--------             -----------     -----------     ----            ------    
proxy_a1b2c3d4       Unlimited       Unlimited       2GB             Active    
proxy_e5f6g7h8       100Mbps         50GB            50GB            Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Active    

Total Usage: 53GB

[Updates every 5 seconds - Press Ctrl+C to stop]
```

### **9) Reset User Quota (Gia hạn dịch vụ)**
```
Reset User Quota

[Hiển thị danh sách proxy]

Enter username to reset quota: proxy_e5f6g7h8
Are you sure you want to reset quota for user 'proxy_e5f6g7h8'? [y/N]: y

✓ Quota reset for user: proxy_e5f6g7h8

# User này giờ có thể dùng tiếp từ 0GB
```

### **11) Test Proxy Pair (Enhanced với Bandwidth Info)**
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

### **12) Service Status (Enhanced với Traffic Control)**
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

## 🔧 **CÁC LỆNH HỆ THỐNG FLEXIBLE**

### **Database Queries cho Flexible System**
```bash
# Xem tất cả proxy users
sudo cat /etc/proxy-manager/proxy_users.db

# Tìm user unlimited
sudo grep ":0:0:" /etc/proxy-manager/proxy_users.db

# Tìm user có giới hạn tốc độ
sudo awk -F: '$5 > 0 {print $1 ": " $5 "Mbps"}' /etc/proxy-manager/proxy_users.db

# Tìm user có giới hạn quota
sudo awk -F: '$6 > 0 {print $1 ": " $6 "GB"}' /etc/proxy-manager/proxy_users.db

# Tìm user bị block do hết quota
sudo grep "blocked_quota" /etc/proxy-manager/proxy_users.db

# Tính tổng usage của tất cả users
sudo awk -F: 'NR>4 {sum += $7} END {print "Total usage: " sum/1024/1024/1024 " GB"}' /etc/proxy-manager/proxy_users.db
```

### **Traffic Control Management cho Flexible**
```bash
# Xem tất cả classes (bao gồm unlimited users)
sudo tc class show dev eth0

# Xem chỉ classes có giới hạn
sudo tc -s class show dev eth0 | grep -A 3 "rate [0-9]*[a-zA-Z]*bit" | grep -v "1000Mbit"

# Xem user nào đang có bandwidth limit
sudo tc filter show dev eth0 | grep "handle"

# Test bandwidth cho user cụ thể
username="proxy_e5f6g7h8"
uid=$(id -u "$username")
sudo tc -s class show dev eth0 classid 1:$((1000 + uid % 1000))
```

### **Flexible User Management**
```bash
# Thêm giới hạn cho user unlimited
username="proxy_a1b2c3d4"
speed_mbps=100
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):0:/$username:\1:\2:\3:$speed_mbps:/" /etc/proxy-manager/proxy_users.db

# Xóa giới hạn cho user (về unlimited)
username="proxy_e5f6g7h8"
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):[^:]*:[^:]*:/$username:\1:\2:\3:0:0:/" /etc/proxy-manager/proxy_users.db

# Reset quota cho user
username="proxy_e5f6g7h8"
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):\([^:]*\):[^:]*$//$username:\1:\2:\3:\4:\5:0/" /etc/proxy-manager/proxy_users.db

# Block user thủ công
username="proxy_e5f6g7h8"
uid=$(id -u "$username")
sudo iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):active:/$username:\1:\2:blocked_quota:/" /etc/proxy-manager/proxy_users.db

# Unblock user thủ công
username="proxy_e5f6g7h8"
uid=$(id -u "$username")
sudo iptables -D OUTPUT -m owner --uid-owner "$uid" -j DROP
sudo sed -i "s/^$username:\([^:]*\):\([^:]*\):blocked_quota:/$username:\1:\2:active:/" /etc/proxy-manager/proxy_users.db
```

## 📊 **CÁC LỆNH MONITORING FLEXIBLE**

### **Real-time Monitoring**
```bash
# Monitor connections theo thời gian thực
watch -n 1 'echo "HTTP: $(netstat -an | grep ":3128" | grep ESTABLISHED | wc -l) | SOCKS5: $(netstat -an | grep ":1080" | grep ESTABLISHED | wc -l)"'

# Monitor bandwidth usage real-time
watch -n 5 'tc -s class show dev eth0 | grep -A 2 "class htb 1:" | grep -E "(class|Sent)"'

# Monitor user status
watch -n 10 'grep -E "(active|blocked)" /etc/proxy-manager/proxy_users.db | wc -l'
```

### **Usage Calculation**
```bash
# Tính usage cho user cụ thể
username="proxy_a1b2c3d4"
used_bytes=$(sudo awk -v user="$username" '$8 == user {total += ($5 + $6)} END {print total+0}' /var/log/squid/access.log)
echo "User $username used: $((used_bytes / 1024 / 1024)) MB"

# Tính usage trong 1 giờ qua
start_time=$(date -d "1 hour ago" +%s)
username="proxy_a1b2c3d4"
used_bytes=$(sudo awk -v user="$username" -v start="$start_time" '$1 > start && $8 == user {total += ($5 + $6)} END {print total+0}' /var/log/squid/access.log)
echo "User $username used in last hour: $((used_bytes / 1024 / 1024)) MB"

# Top 5 users theo usage
sudo awk -F: 'NR>4 {print $1 ":" $7}' /etc/proxy-manager/proxy_users.db | sort -t: -k2 -nr | head -5 | while IFS=: read user bytes; do
    mb=$((bytes / 1024 / 1024))
    echo "User $user: ${mb}MB"
done
```

## 🔧 **CÁC LỆNH TROUBLESHOOTING FLEXIBLE**

### **Debug Bandwidth Control**
```bash
# Kiểm tra user có bandwidth limit không
username="proxy_e5f6g7h8"
speed_limit=$(sudo grep "^$username:" /etc/proxy-manager/proxy_users.db | cut -d':' -f5)
if [[ "$speed_limit" -eq 0 ]]; then
    echo "User $username: Unlimited speed"
else
    echo "User $username: ${speed_limit}Mbps limit"
fi

# Kiểm tra user có quota limit không
quota_limit=$(sudo grep "^$username:" /etc/proxy-manager/proxy_users.db | cut -d':' -f6)
if [[ "$quota_limit" -eq 0 ]]; then
    echo "User $username: Unlimited quota"
else
    echo "User $username: ${quota_limit}GB quota"
fi

# Kiểm tra user có bị block không
status=$(sudo grep "^$username:" /etc/proxy-manager/proxy_users.db | cut -d':' -f4)
echo "User $username status: $status"
```

### **Fix Common Issues**
```bash
# Reset traffic control nếu bị lỗi
sudo tc qdisc del dev eth0 root 2>/dev/null
sudo tc qdisc add dev eth0 root handle 1: htb default 999
sudo tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbit
sudo tc class add dev eth0 parent 1:1 classid 1:999 htb rate 1000mbit ceil 1000mbit

# Reapply bandwidth limits cho tất cả users
while IFS=':' read -r username password created_date status speed_limit quota used_bytes; do
    [[ "$username" =~ ^#.*$ ]] || [[ -z "$username" ]] && continue
    [[ "$speed_limit" -eq 0 ]] && continue
    
    uid=$(id -u "$username" 2>/dev/null)
    [[ -z "$uid" ]] && continue
    
    class_id="1:$((1000 + uid % 1000))"
    sudo tc class add dev eth0 parent 1:1 classid "$class_id" htb rate "${speed_limit}mbit" ceil "${speed_limit}mbit"
    sudo tc filter add dev eth0 protocol ip parent 1:0 prio 1 handle "$uid" fw flowid "$class_id"
    sudo iptables -t mangle -A OUTPUT -m owner --uid-owner "$uid" -j MARK --set-mark "$uid"
done < /etc/proxy-manager/proxy_users.db

# Reapply blocks cho users hết quota
sudo grep "blocked_quota" /etc/proxy-manager/proxy_users.db | cut -d':' -f1 | while read username; do
    uid=$(id -u "$username" 2>/dev/null)
    [[ -n "$uid" ]] && sudo iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP
done
```

## 🎯 **WORKFLOW COMMANDS CHO KINH DOANH**

### **Tạo gói proxy cho khách hàng**
```bash
# Gói Free (unlimited)
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 1 (Unlimited)

# Gói Basic (50Mbps, 20GB)
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 2 -> 50 -> 20

# Gói Premium (100Mbps, unlimited quota)
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 2 -> 100 -> 0

# Gói Enterprise (unlimited)
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 1 -> Chọn 1 (Unlimited)
```

### **Quản lý khách hàng**
```bash
# Khách hàng hết quota, muốn gia hạn
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 9 (Reset User Quota) -> Nhập username

# Khách hàng muốn upgrade
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 4 (Reset to unlimited)

# Khách hàng muốn downgrade
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 3 (Update both) -> Nhập giới hạn mới

# Tạm dừng dịch vụ
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 5 (Block user)

# Khôi phục dịch vụ
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 4 (Update Bandwidth) -> Chọn 5 (Unblock user)
```

## 🎯 **TÓM TẮT CÁC LỆNH QUAN TRỌNG NHẤT**

### **🔥 Top 15 Lệnh Flexible Thường Dùng:**

1. `sudo ./flexible-dual-proxy.sh` - Chạy script flexible
2. `sudo ./flexible-dual-proxy.sh menu` - Vào menu quản lý flexible
3. `sudo ./flexible-dual-proxy.sh stats` - Xem bandwidth statistics
4. `sudo ./flexible-dual-proxy.sh status` - Kiểm tra trạng thái + TC
5. `sudo grep ":0:0:" /etc/proxy-manager/proxy_users.db` - Tìm user unlimited
6. `sudo grep "blocked_quota" /etc/proxy-manager/proxy_users.db` - Tìm user bị block
7. `sudo awk -F: '$5 > 0' /etc/proxy-manager/proxy_users.db` - Tìm user có speed limit
8. `sudo awk -F: '$6 > 0' /etc/proxy-manager/proxy_users.db` - Tìm user có quota limit
9. `sudo tc -s class show dev eth0` - Xem bandwidth usage real-time
10. `sudo netstat -an | grep ":3128" | wc -l` - Đếm HTTP connections
11. `sudo netstat -an | grep ":1080" | wc -l` - Đếm SOCKS5 connections
12. `sudo /usr/local/bin/proxy-bandwidth-monitor.sh` - Chạy monitor thủ công
13. `sudo systemctl restart squid sockd` - Restart cả 2 services
14. `watch -n 5 'tc -s class show dev eth0'` - Monitor bandwidth real-time
15. `sudo tail -f /var/log/proxy-bandwidth-monitor.log` - Xem monitor log

### **🚨 Lệnh Khẩn Cấp Flexible:**
```bash
# Reset hoàn toàn traffic control
sudo tc qdisc del dev eth0 root
sudo ./flexible-dual-proxy.sh menu
# -> Chọn 13 (Restart Services)

# Unblock tất cả users
sudo iptables -t mangle -F
sudo sed -i 's/:blocked_quota:/:active:/g' /etc/proxy-manager/proxy_users.db

# Reset tất cả về unlimited
sudo sed -i 's/:\([0-9]\+\):\([0-9]\+\):/:0:0:/g' /etc/proxy-manager/proxy_users.db
```

---

**💡 Lưu ý**: Flexible version cho phép bạn **"thích thì giới hạn thôi"** - không bắt buộc theo tháng, hoàn toàn linh hoạt theo nhu cầu kinh doanh!