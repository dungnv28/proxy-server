# Flexible Dual Proxy Manager v4.0

Hệ thống quản lý proxy linh hoạt với **KIỂM SOÁT BĂNG THÔNG KHI CẦN** - cung cấp cả HTTP (Squid) và SOCKS5 (Dante) với đầy đủ các thao tác CRUD, giới hạn tốc độ và quota khi muốn.

## 🚀 TÍNH NĂNG CHÍNH - LINH HOẠT HOÀN TOÀN

### ⚡ **Giới hạn tốc độ KHI CẦN**
- **Mặc định: UNLIMITED** cho tất cả proxy mới
- **Giới hạn khi muốn**: Có thể set speed limit bất cứ lúc nào
- **Cùng giá trị Up/Down**: 100Mbps = 100Mbps up + 100Mbps down
- **Áp dụng cho cả HTTP và SOCKS5** của cùng user

### 📊 **Quản lý Quota KHI CẦN**
- **Mặc định: UNLIMITED** cho tất cả proxy mới
- **Giới hạn khi muốn**: Set total quota bất cứ lúc nào (không theo tháng)
- **Tự động chặn** khi hết quota
- **Reset quota** thủ công khi cần

### 🎯 **Triết lý: "Thích thì giới hạn thôi!"**
- **Không bắt buộc** theo tháng hay chu kỳ nào
- **Tự do** set limit khi cần cho kinh doanh
- **Linh hoạt** thay đổi bất cứ lúc nào
- **Đơn giản** và thực tế

## 🔧 WORKFLOW SỬ DỤNG

### 🎯 **Tạo Proxy Mới**
```bash
sudo ./flexible-dual-proxy.sh

# Chọn option 1: Create Single Proxy Pair
# Hệ thống hỏi:

Bandwidth Configuration:
1) Unlimited (default)    ← Chọn này nếu muốn unlimited
2) Custom speed limit and total quota    ← Chọn này nếu muốn giới hạn

# Nếu chọn 1: Tạo proxy unlimited hoàn toàn
# Nếu chọn 2: Nhập speed (Mbps) và quota (GB)
```

### 🔄 **Thay đổi sau khi tạo**
```bash
# Vào menu quản lý
sudo ./flexible-dual-proxy.sh menu

# Chọn option 4: Update Proxy Bandwidth Settings
# Có thể:
1) Chỉ thay đổi speed limit
2) Chỉ thay đổi quota
3) Thay đổi cả hai
4) Reset về unlimited
5) Block/Unblock user
```

## 📋 MENU QUẢN LÝ LINH HOẠT

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
```

## 🎯 VÍ DỤ SỬ DỤNG THỰC TẾ

### **Scenario 1: Tạo proxy unlimited (mặc định)**
```bash
# Tạo proxy mới
1) Create Single Proxy Pair

Bandwidth Configuration:
1) Unlimited (default)    ← Chọn 1
2) Custom speed limit and total quota

# Kết quả:
✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
Speed Limit:  Unlimited
Total Quota:  Unlimited
```

### **Scenario 2: Khách hàng muốn mua gói có giới hạn**
```bash
# Tạo proxy với giới hạn
1) Create Single Proxy Pair

Bandwidth Configuration:
1) Unlimited (default)
2) Custom speed limit and total quota    ← Chọn 2

Enter speed limit in Mbps (0 for unlimited): 100
Enter total quota in GB (0 for unlimited): 50

# Kết quả:
✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
Speed Limit:  100Mbps
Total Quota:  50GB
```

### **Scenario 3: Khách hàng muốn upgrade**
```bash
# Update proxy hiện có
4) Update Proxy Bandwidth Settings

Enter username to update: proxy_e5f6g7h8

Update Options:
1) Update speed limit only
2) Update total quota only  
3) Update both speed limit and quota
4) Reset to unlimited    ← Chọn này để upgrade lên unlimited
5) Block/Unblock user

# Kết quả:
✓ User proxy_e5f6g7h8 reset to unlimited
```

### **Scenario 4: Khách hàng hết quota, muốn gia hạn**
```bash
# Reset quota cho user
9) Reset User Quota

Enter username to reset quota: proxy_e5f6g7h8
Are you sure you want to reset quota for user 'proxy_e5f6g7h8'? [y/N]: y

# Kết quả:
✓ Quota reset for user: proxy_e5f6g7h8
```

## 📊 HIỂN THỊ THÔNG TIN CHI TIẾT

### **List Proxy với Bandwidth Info**
```
Current Proxy Pairs with Bandwidth Control:

[1] User: proxy_a1b2c3d4
    HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
    SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
    Created: 2024-01-15 10:30:25 | Status: active
    Speed Limit: Unlimited
    Total Quota: Unlimited
    Usage: 2GB

[2] User: proxy_e5f6g7h8
    HTTP:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
    SOCKS5: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
    Created: 2024-01-15 10:30:26 | Status: blocked_quota
    Speed Limit: 100Mbps
    Total Quota: 50GB
    Usage: 50GB

[3] User: proxy_x9y8z7w6
    HTTP:   192.168.1.100:3128:proxy_x9y8z7w6:pass_q1w2e3r4
    SOCKS5: 192.168.1.100:1080:proxy_x9y8z7w6:pass_q1w2e3r4
    Created: 2024-01-15 10:30:27 | Status: active
    Speed Limit: 50Mbps
    Total Quota: Unlimited
    Usage: 1GB

Total proxy pairs: 3
```

### **Bandwidth Statistics**
```
Bandwidth Usage Statistics

Username             Speed Limit     Total Quota     Used            Status    
--------             -----------     -----------     ----            ------    
proxy_a1b2c3d4       Unlimited       Unlimited       2GB             Active    
proxy_e5f6g7h8       100Mbps         50GB            50GB            Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Active    

Total Usage: 53GB
```

## 🛠️ CÀI ĐẶT VÀ SỬ DỤNG

### **Cài đặt Flexible Version**
```bash
# Tải script flexible
wget https://raw.githubusercontent.com/your-repo/flexible-dual-proxy.sh
chmod +x flexible-dual-proxy.sh

# Chạy cài đặt
sudo ./flexible-dual-proxy.sh
```

### **Các lệnh quản lý**
```bash
# Vào menu quản lý
sudo ./flexible-dual-proxy.sh menu

# Xem thông tin cài đặt
sudo ./flexible-dual-proxy.sh info

# Kiểm tra trạng thái dịch vụ
sudo ./flexible-dual-proxy.sh status

# Xem thống kê bandwidth
sudo ./flexible-dual-proxy.sh stats
```

## 🎯 USE CASES CHO KINH DOANH

### **Gói Free/Trial**
- **Speed**: Unlimited
- **Quota**: Unlimited
- **Price**: Free
- **Note**: Để khách hàng test

### **Gói Basic**
- **Speed**: 50Mbps
- **Quota**: 20GB total
- **Price**: $5 one-time
- **Note**: Hết quota thì mua thêm

### **Gói Premium**
- **Speed**: 100Mbps
- **Quota**: Unlimited
- **Price**: $15 one-time
- **Note**: Chỉ giới hạn tốc độ

### **Gói Enterprise**
- **Speed**: Unlimited
- **Quota**: Unlimited
- **Price**: $30 one-time
- **Note**: Không giới hạn gì

### **Quản lý linh hoạt**
```bash
# Khách hàng mua gói Basic
create_proxy_pair
# -> Chọn custom: 50Mbps, 20GB

# Khách hàng hết quota, muốn mua thêm
reset_user_quota
# -> Reset quota về 0, khách dùng tiếp

# Khách hàng muốn upgrade lên Premium
update_proxy_bandwidth
# -> Chọn option 3: Set 100Mbps, Unlimited quota

# Khách hàng muốn downgrade
update_proxy_bandwidth
# -> Chọn option 3: Set 50Mbps, 10GB quota

# Tạm dừng dịch vụ khách hàng
update_proxy_bandwidth
# -> Chọn option 5: Block user
```

## 🔍 TECHNICAL IMPLEMENTATION

### **Database Structure**
```bash
# /etc/proxy-manager/proxy_users.db
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:TOTAL_QUOTA_GB:USED_BYTES

proxy_a1b2c3d4:pass_x9y8z7w6:2024-01-15 10:30:25:active:0:0:2147483648
proxy_e5f6g7h8:pass_m3n4o5p6:2024-01-15 10:30:26:blocked_quota:100:50:53687091200
proxy_x9y8z7w6:pass_q1w2e3r4:2024-01-15 10:30:27:active:50:0:1073741824

# Giải thích:
# SPEED_LIMIT_MBPS: 0 = Unlimited
# TOTAL_QUOTA_GB: 0 = Unlimited
# USED_BYTES: Tổng bytes đã sử dụng
```

### **Traffic Control Implementation**
```bash
# Tạo HTB qdisc
tc qdisc add dev eth0 root handle 1: htb default 999

# Class chính (1000Mbps ceiling)
tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbit

# Class cho user có giới hạn (ví dụ: 100Mbps)
tc class add dev eth0 parent 1:1 classid 1:1001 htb rate 100mbit ceil 100mbit

# Filter traffic theo UID
tc filter add dev eth0 protocol ip parent 1:0 prio 1 handle 1001 fw flowid 1:1001

# Mark packets với iptables
iptables -t mangle -A OUTPUT -m owner --uid-owner 1001 -j MARK --set-mark 1001
```

### **Quota Management**
```bash
# Monitoring script chạy mỗi 5 phút
*/5 * * * * root /usr/local/bin/proxy-bandwidth-monitor.sh

# Parse Squid logs để tính usage
awk -v user="username" '$8 == user {total += ($5 + $6)} END {print total}' /var/log/squid/access.log

# Block user khi hết quota
iptables -I OUTPUT -m owner --uid-owner $uid -j DROP

# Update status trong database
sed -i "s/:active:/:blocked_quota:/" proxy_users.db
```

## 🔧 TROUBLESHOOTING

### **Kiểm tra Traffic Control**
```bash
# Xem qdisc hiện tại
sudo tc qdisc show dev eth0

# Xem classes với statistics
sudo tc -s class show dev eth0

# Xem filters
sudo tc filter show dev eth0
```

### **Kiểm tra User Status**
```bash
# Xem user bị block
sudo grep "blocked_quota" /etc/proxy-manager/proxy_users.db

# Xem usage của user
sudo grep "proxy_a1b2c3d4" /etc/proxy-manager/proxy_users.db

# Test connection từ user
sudo -u proxy_a1b2c3d4 curl -s --max-time 5 http://ifconfig.me
```

### **Debug Bandwidth Monitoring**
```bash
# Chạy monitor script thủ công
sudo /usr/local/bin/proxy-bandwidth-monitor.sh

# Xem log
sudo tail -f /var/log/proxy-bandwidth-monitor.log

# Test quota check
username="proxy_a1b2c3d4"
used_bytes=$(awk -v user="$username" '$8 == user {total += ($5 + $6)} END {print total+0}' /var/log/squid/access.log)
echo "User $username used: $((used_bytes / 1024 / 1024)) MB"
```

## 📈 PERFORMANCE OPTIMIZATION

### **System Tuning**
```bash
# Tăng file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize network stack
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
sysctl -p
```

### **Squid Optimization**
```bash
# Tăng cache memory
cache_mem 1024 MB

# Tăng maximum object size  
maximum_object_size 512 MB
```

## 🎉 KẾT LUẬN

**Flexible Dual Proxy Manager v4.0** là giải pháp hoàn hảo cho triết lý **"Thích thì giới hạn thôi!"**:

### ✅ **Đảm bảo 100%**
- **Mặc định UNLIMITED** cho tất cả proxy mới
- **Giới hạn KHI CẦN** - không bắt buộc
- **Thay đổi bất cứ lúc nào** - linh hoạt hoàn toàn
- **Không theo tháng** - tự do quản lý quota
- **Real-time control** - thay đổi tức thì

### 🚀 **Phù hợp cho**
- **Kinh doanh proxy** linh hoạt
- **Không muốn ràng buộc** theo tháng
- **Quản lý đơn giản** và thực tế
- **Khách hàng đa dạng** nhu cầu

### 💡 **Unique Features**
- **On-demand bandwidth control** - chỉ khi cần
- **No monthly restrictions** - không ràng buộc thời gian
- **Instant changes** - thay đổi tức thì
- **Business flexibility** - linh hoạt kinh doanh
- **Simple management** - quản lý đơn giản

---

**🔥 Đặc biệt**: Script này là phiên bản duy nhất có **BANDWIDTH CONTROL LINH HOẠT** - giới hạn khi muốn, không bắt buộc theo tháng như bạn yêu cầu!