# Final Dual Proxy Manager v5.0 - Complete Edition

Hệ thống quản lý proxy hoàn chỉnh và mạnh mẽ nhất với **KIỂM SOÁT BĂNG THÔNG LINH HOẠT** - cung cấp cả HTTP (Squid) và SOCKS5 (Dante) với đầy đủ các thao tác CRUD, giới hạn tốc độ và quản lý quota theo nhu cầu.

## 🚀 TÍNH NĂNG CHÍNH - HOÀN CHỈNH

### ⚡ **Kiểm soát Băng thông Linh hoạt**
- **Mặc định: UNLIMITED** cho tất cả proxy mới
- **Giới hạn khi muốn**: Set speed limit bất cứ lúc nào (0 = unlimited)
- **Cùng giá trị Up/Down**: 100Mbps = 100Mbps upload + 100Mbps download
- **Áp dụng đồng thời**: Cả HTTP và SOCKS5 của cùng user
- **Traffic Control (TC)**: Sử dụng HTB qdisc + iptables marking

### 📊 **Quản lý Quota Thông minh**
- **Mặc định: UNLIMITED** cho tất cả proxy mới
- **Total quota**: Không theo tháng, tự do set (ví dụ: 50GB total)
- **Tự động block**: Khi user hết quota
- **Reset quota**: Thủ công khi cần (gia hạn dịch vụ)
- **Real-time tracking**: Theo dõi usage liên tục

### 🎯 **Triết lý: "Thích thì giới hạn, không thì thôi!"**
- **Không ràng buộc**: Theo tháng hay chu kỳ nào
- **Hoàn toàn linh hoạt**: Thay đổi bất cứ lúc nào
- **Kinh doanh thực tế**: Phù hợp mọi mô hình
- **Quản lý đơn giản**: Interface thân thiện

## 🔧 TÍNH NĂNG QUẢN LÝ HOÀN CHỈNH

### 💼 **CRUD Operations Đầy đủ**
- **CREATE**: Tạo 1 hoặc hàng loạt proxy (1-100 cặp)
- **READ**: Xem danh sách với thông tin bandwidth chi tiết
- **UPDATE**: Cập nhật speed/quota/password/block status
- **DELETE**: Xóa từng cặp hoặc xóa tất cả

### 📈 **Bandwidth Management**
- **Real-time monitoring**: Theo dõi usage trực tiếp
- **Automatic blocking**: Tự động chặn khi hết quota
- **Manual blocking**: Chủ động block/unblock user
- **Quota reset**: Gia hạn dịch vụ cho khách hàng
- **Statistics**: Báo cáo usage tổng quan

### 🔄 **System Management**
- **Service control**: Start/stop/restart services
- **Export/Import**: Xuất danh sách proxy
- **Testing**: Kiểm tra proxy functionality
- **Logging**: Xem logs chi tiết
- **Status monitoring**: Theo dõi trạng thái hệ thống

## 📋 MENU QUẢN LÝ HOÀN CHỈNH

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
```

## 🎯 WORKFLOW SỬ DỤNG THỰC TẾ

### **Scenario 1: Tạo proxy unlimited (mặc định)**
```bash
sudo ./final-dual-proxy.sh

# Chọn option 1: Create Single Proxy Pair
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

### **Scenario 2: Tạo proxy với giới hạn**
```bash
# Chọn option 1: Create Single Proxy Pair
Bandwidth Configuration:
1) Unlimited (default)
2) Custom speed limit and total quota    ← Chọn 2

Enter speed limit in Mbps (0 for unlimited): 100
Enter total quota in GB (0 for unlimited): 20

# Kết quả:
✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
Speed Limit:  100Mbps
Total Quota:  20GB
```

### **Scenario 3: Khách hàng hết quota, muốn gia hạn**
```bash
# Chọn option 10: Reset User Quota
Enter username to reset quota: proxy_e5f6g7h8
Are you sure you want to reset quota for user 'proxy_e5f6g7h8'? [y/N]: y

✓ Quota reset for user: proxy_e5f6g7h8
# User có thể dùng tiếp từ 0GB
```

### **Scenario 4: Upgrade khách hàng lên unlimited**
```bash
# Chọn option 4: Update Proxy Bandwidth Settings
Enter username to update: proxy_e5f6g7h8

Update Options:
1) Update speed limit only
2) Update total quota only  
3) Update both speed limit and quota
4) Reset to unlimited    ← Chọn 4
5) Block/Unblock user

✓ User proxy_e5f6g7h8 reset to unlimited
```

## 📊 HIỂN THỊ THÔNG TIN CHI TIẾT

### **List Proxy với Bandwidth Info**
```
Current Proxy Pairs with Bandwidth Control:

Format: HTTP and SOCKS5 pairs with bandwidth limits
Server IP: 192.168.1.100

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
    Total Quota: 20GB
    Usage: 20GB

[3] User: proxy_x9y8z7w6
    HTTP:   192.168.1.100:3128:proxy_x9y8z7w6:pass_q1w2e3r4
    SOCKS5: 192.168.1.100:1080:proxy_x9y8z7w6:pass_q1w2e3r4
    Created: 2024-01-15 10:30:27 | Status: blocked_manual
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
proxy_e5f6g7h8       100Mbps         20GB            20GB            Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Blocked   

Total Usage: 23GB
```

### **Real-time Monitoring**
```
Real-time Bandwidth Usage - 2024-01-20 15:30:45

Active Connections:
HTTP Proxy: 25 connections
SOCKS5 Proxy: 18 connections

Username             Speed Limit     Total Quota     Used            Status    
--------             -----------     -----------     ----            ------    
proxy_a1b2c3d4       Unlimited       Unlimited       2GB             Active    
proxy_e5f6g7h8       100Mbps         20GB            20GB            Blocked   
proxy_x9y8z7w6       50Mbps          Unlimited       1GB             Blocked   

Total Usage: 23GB

[Updates every 5 seconds - Press Ctrl+C to stop]
```

## 🛠️ CÀI ĐẶT VÀ SỬ DỤNG

### **Cài đặt Final Version**
```bash
# Tải script final
wget https://raw.githubusercontent.com/your-repo/final-dual-proxy.sh
chmod +x final-dual-proxy.sh

# Chạy cài đặt
sudo ./final-dual-proxy.sh
```

### **Các lệnh quản lý**
```bash
# Vào menu quản lý
sudo ./final-dual-proxy.sh menu

# Xem thông tin cài đặt
sudo ./final-dual-proxy.sh info

# Kiểm tra trạng thái dịch vụ
sudo ./final-dual-proxy.sh status

# Xem thống kê bandwidth
sudo ./final-dual-proxy.sh stats
```

## 🔍 TECHNICAL IMPLEMENTATION

### **Database Structure**
```bash
# /etc/proxy-manager/proxy_users.db
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:TOTAL_QUOTA_GB:USED_BYTES

proxy_a1b2c3d4:pass_x9y8z7w6:2024-01-15 10:30:25:active:0:0:2147483648
proxy_e5f6g7h8:pass_m3n4o5p6:2024-01-15 10:30:26:blocked_quota:100:20:21474836480
proxy_x9y8z7w6:pass_q1w2e3r4:2024-01-15 10:30:27:blocked_manual:50:0:1073741824

# Giải thích:
# STATUS: active, blocked_quota, blocked_manual
# SPEED_LIMIT_MBPS: 0 = Unlimited
# TOTAL_QUOTA_GB: 0 = Unlimited
# USED_BYTES: Total bytes đã sử dụng
```

### **Traffic Control Implementation**
```bash
# Setup HTB qdisc
tc qdisc add dev eth0 root handle 1: htb default 999

# Main class (1000Mbps ceiling)
tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbit

# Default class cho unlimited users
tc class add dev eth0 parent 1:1 classid 1:999 htb rate 1000mbit ceil 1000mbit

# Class cho user có giới hạn (ví dụ: 100Mbps)
tc class add dev eth0 parent 1:1 classid 1:1001 htb rate 100mbit ceil 100mbit

# Filter traffic theo UID
tc filter add dev eth0 protocol ip parent 1:0 prio 1 handle 1001 fw flowid 1:1001

# Mark packets với iptables
iptables -t mangle -A OUTPUT -m owner --uid-owner 1001 -j MARK --set-mark 1001
```

### **Bandwidth Monitoring System**
```bash
# Monitoring script: /usr/local/bin/proxy-bandwidth-monitor.sh
# Chạy mỗi 5 phút: */5 * * * * root /usr/local/bin/proxy-bandwidth-monitor.sh

# Parse Squid logs để tính usage
awk -v user="username" '$3 == user {total += ($5 + $6)} END {print total}' /var/log/squid/access.log

# Auto block khi hết quota
if [[ "$current_usage" -ge "$quota_bytes" ]]; then
    iptables -I OUTPUT -m owner --uid-owner "$uid" -j DROP
    sed -i "s/:active:/:blocked_quota:/" proxy_users.db
fi
```

### **Blocking System**
```bash
# Auto block (hết quota)
iptables -I OUTPUT -m owner --uid-owner $uid -j DROP
sed -i "s/:active:/:blocked_quota:/" proxy_users.db

# Manual block
iptables -I OUTPUT -m owner --uid-owner $uid -j DROP
sed -i "s/:active:/:blocked_manual:/" proxy_users.db

# Unblock
iptables -D OUTPUT -m owner --uid-owner $uid -j DROP
sed -i "s/:blocked_.*:/:active:/" proxy_users.db
```

## 🎯 USE CASES CHO KINH DOANH

### **Gói Free/Trial**
```bash
# Tạo proxy unlimited để khách test
create_proxy_pair
# -> Chọn option 1: Unlimited

# Kết quả: Proxy không giới hạn gì
```

### **Gói Basic**
```bash
# Tạo proxy với giới hạn cơ bản
create_proxy_pair
# -> Chọn option 2: Custom
# -> Speed: 50Mbps, Quota: 10GB

# Kết quả: Proxy 50Mbps, 10GB total
```

### **Gói Premium**
```bash
# Tạo proxy tốc độ cao, không giới hạn dung lượng
create_proxy_pair
# -> Chọn option 2: Custom
# -> Speed: 200Mbps, Quota: 0 (unlimited)

# Kết quả: Proxy 200Mbps, unlimited quota
```

### **Gói Enterprise**
```bash
# Tạo proxy hoàn toàn unlimited
create_proxy_pair
# -> Chọn option 1: Unlimited

# Kết quả: Proxy không giới hạn gì
```

### **Quản lý khách hàng**
```bash
# Khách hàng hết quota → Gia hạn
reset_user_quota
# -> Nhập username → Reset về 0GB

# Khách hàng muốn upgrade → Thay đổi settings
update_proxy_bandwidth
# -> Chọn option 4: Reset to unlimited

# Tạm dừng dịch vụ → Block user
update_proxy_bandwidth
# -> Chọn option 5: Block user

# Khôi phục dịch vụ → Unblock user
update_proxy_bandwidth
# -> Chọn option 5: Unblock user
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

# Xem bandwidth usage real-time
watch -n 1 'tc -s class show dev eth0'
```

### **Kiểm tra User Status**
```bash
# Xem user bị block
sudo grep "blocked" /etc/proxy-manager/proxy_users.db

# Xem user unlimited
sudo grep ":0:0:" /etc/proxy-manager/proxy_users.db

# Xem user có speed limit
sudo awk -F: '$5 > 0' /etc/proxy-manager/proxy_users.db

# Xem user có quota limit
sudo awk -F: '$6 > 0' /etc/proxy-manager/proxy_users.db
```

### **Debug Bandwidth Monitoring**
```bash
# Chạy monitor script thủ công
sudo /usr/local/bin/proxy-bandwidth-monitor.sh

# Xem log
sudo tail -f /var/log/proxy-bandwidth-monitor.log

# Test quota check
username="proxy_a1b2c3d4"
used_bytes=$(awk -v user="$username" '$3 == user {total += ($5 + $6)} END {print total+0}' /var/log/squid/access.log)
echo "User $username used: $((used_bytes / 1024 / 1024)) MB"
```

### **Fix Common Issues**
```bash
# Reset traffic control nếu bị lỗi
sudo tc qdisc del dev eth0 root
sudo tc qdisc add dev eth0 root handle 1: htb default 999
sudo tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbit

# Restart services
sudo systemctl restart squid sockd

# Reapply bandwidth limits
sudo ./final-dual-proxy.sh menu
# -> Option 13: Service Status để kiểm tra
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
echo 'net.ipv4.tcp_rmem = 4096 87380 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 134217728' >> /etc/sysctl.conf
sysctl -p
```

### **Squid Optimization**
```bash
# Tăng cache memory
cache_mem 512 MB

# Tăng maximum object size  
maximum_object_size 256 MB

# Custom log format cho bandwidth tracking
logformat combined %>a %[ui %[un [%tl] "%rm %ru HTTP/%rv" %>Hs %<st "%{Referer}>h" "%{User-Agent}>h" %Ss:%Sh %<A %tr
```

## 🎉 KẾT LUẬN

**Final Dual Proxy Manager v5.0** là giải pháp hoàn chỉnh và mạnh mẽ nhất cho việc quản lý proxy với kiểm soát băng thông linh hoạt:

### ✅ **Đảm bảo 100%**
- **Mặc định UNLIMITED** cho tất cả proxy mới
- **Giới hạn KHI CẦN** - hoàn toàn linh hoạt
- **Tự động + Thủ công blocking** - kiểm soát hoàn toàn
- **Real-time monitoring** - theo dõi trực tiếp
- **Quota management** - gia hạn dễ dàng

### 🚀 **Phù hợp cho**
- **Kinh doanh proxy** chuyên nghiệp
- **ISP** cung cấp dịch vụ proxy
- **Enterprise** cần kiểm soát bandwidth
- **Personal use** với quản lý nâng cao
- **Reseller** proxy services

### 💡 **Unique Features**
- **Flexible bandwidth control** - thích thì giới hạn
- **No time restrictions** - không ràng buộc thời gian
- **Dual proxy support** - HTTP + SOCKS5 cùng credentials
- **Complete CRUD operations** - quản lý toàn diện
- **Real-time statistics** - thống kê trực tiếp
- **Automatic quota enforcement** - tự động chặn
- **Business-ready interface** - giao diện chuyên nghiệp

### 🔥 **Tính năng độc quyền**
- **Traffic Control + iptables** - kiểm soát chính xác
- **Automatic bandwidth monitoring** - theo dõi tự động
- **Flexible quota system** - không theo tháng
- **Complete logging system** - log đầy đủ
- **Export/Import functionality** - xuất nhập dữ liệu
- **Real-time testing** - test proxy trực tiếp

---

**🔥 Đặc biệt**: Script này là phiên bản FINAL hoàn chỉnh nhất, kết hợp tất cả tính năng từ cả 2 phiên bản trước với **BANDWIDTH CONTROL LINH HOẠT HOÀN TOÀN** như bạn yêu cầu!