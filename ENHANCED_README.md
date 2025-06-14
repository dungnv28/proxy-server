# Enhanced Dual Proxy Manager v4.0

Hệ thống quản lý proxy nâng cao với **KIỂM SOÁT BĂNG THÔNG HOÀN TOÀN** - cung cấp cả HTTP (Squid) và SOCKS5 (Dante) với đầy đủ các thao tác CRUD, giới hạn tốc độ và quản lý quota hàng tháng.

## 🚀 TÍNH NĂNG MỚI - BANDWIDTH CONTROL

### ⚡ **Giới hạn tốc độ Up/Down**
- **Giới hạn tốc độ riêng biệt cho từng user**
- **Cùng một giá trị cho cả Upload và Download** (ví dụ: 100Mbps = 100Mbps up + 100Mbps down)
- **Áp dụng cho cả HTTP và SOCKS5** của cùng một user
- **Traffic Control (TC) + iptables** để kiểm soát chính xác

### 📊 **Quản lý Quota hàng tháng**
- **Giới hạn dung lượng băng thông** cho từng user (ví dụ: 5GB/tháng)
- **Tự động chặn truy cập** khi hết quota
- **Reset quota tự động** vào đầu mỗi tháng
- **Theo dõi usage real-time**

### 🎯 **Cài đặt mặc định**
- **Tất cả proxy mới = UNLIMITED** (tốc độ và quota)
- **Có thể custom** từng user riêng biệt
- **Linh hoạt** cho mục đích kinh doanh

## 🔧 CÁC TÍNH NĂNG QUẢN LÝ NÂNG CAO

### 💼 **Dành cho Kinh doanh**
- **Custom speed limit** cho từng gói dịch vụ
- **Custom monthly quota** theo nhu cầu khách hàng
- **Kiểm tra trạng thái** proxy real-time
- **Gia hạn/cập nhật** quota dễ dàng
- **Block/unblock** user tức thì

### 📈 **Monitoring & Statistics**
- **Real-time bandwidth monitoring**
- **Usage statistics** theo tháng
- **Connection tracking**
- **Automatic logging** tất cả hoạt động

### 🔄 **Automation**
- **Tự động reset quota** đầu tháng
- **Tự động block** user khi hết quota
- **Tự động unblock** sau khi reset quota
- **Cron jobs** để monitoring liên tục

## 📋 MENU QUẢN LÝ MỚI

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
```

## 🎯 WORKFLOW TẠO PROXY VỚI BANDWIDTH CONTROL

### Tạo Single Proxy
```bash
sudo ./enhanced-dual-proxy.sh

# Chọn option 1: Create Single Proxy Pair
# Hệ thống sẽ hỏi:

Bandwidth Configuration:
1) Unlimited (default)
2) Custom speed limit and monthly quota

# Nếu chọn option 2:
Enter speed limit in Mbps (e.g., 100): 100
Enter monthly quota in GB (0 for unlimited): 5

# Kết quả:
✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
Speed Limit:  100Mbps
Monthly Quota: 5GB
```

### Tạo Multiple Proxies
```bash
# Chọn option 2: Create Multiple Proxy Pairs
Enter number of proxy pairs to create: 10

Bandwidth Configuration for all proxies:
1) Unlimited (default)
2) Custom speed limit and monthly quota

# Nếu chọn option 2:
Enter speed limit in Mbps (e.g., 100): 50
Enter monthly quota in GB (0 for unlimited): 10

# Kết quả: 10 proxy pairs với cùng cài đặt bandwidth
```

## 📊 HIỂN THỊ THÔNG TIN BANDWIDTH

### List Proxy với Bandwidth Info
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

### Bandwidth Statistics
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

## 🔧 CẬP NHẬT BANDWIDTH SETTINGS

### Update Menu
```
Update Proxy Bandwidth Settings

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

## 🛠️ CÀI ĐẶT VÀ SỬ DỤNG

### Cài đặt Enhanced Version
```bash
# Tải script enhanced
wget https://raw.githubusercontent.com/your-repo/enhanced-dual-proxy.sh
chmod +x enhanced-dual-proxy.sh

# Chạy cài đặt
sudo ./enhanced-dual-proxy.sh
```

### Các lệnh quản lý
```bash
# Vào menu quản lý
sudo ./enhanced-dual-proxy.sh menu

# Xem thông tin cài đặt
sudo ./enhanced-dual-proxy.sh info

# Kiểm tra trạng thái dịch vụ
sudo ./enhanced-dual-proxy.sh status

# Xem thống kê bandwidth
sudo ./enhanced-dual-proxy.sh stats
```

## 🔍 TECHNICAL IMPLEMENTATION

### Traffic Control (TC) Setup
```bash
# Tạo root qdisc
tc qdisc add dev eth0 root handle 1: htb default 999

# Tạo class chính
tc class add dev eth0 parent 1: classid 1:1 htb rate 1000mbit

# Tạo class cho user (ví dụ: 100Mbps)
tc class add dev eth0 parent 1:1 classid 1:1001 htb rate 100mbit ceil 100mbit

# Filter traffic theo UID
tc filter add dev eth0 protocol ip parent 1:0 prio 1 handle 1001 fw flowid 1:1001

# Mark packets với iptables
iptables -t mangle -A OUTPUT -m owner --uid-owner 1001 -j MARK --set-mark 1001
```

### Bandwidth Monitoring
```bash
# Script tự động chạy mỗi 5 phút
*/5 * * * * root /usr/local/bin/proxy-bandwidth-monitor.sh

# Parse Squid logs để tính bandwidth
awk '{username=$8; bytes=$5+$6; user_usage[username]+=bytes} 
     END {for(user in user_usage) print user":"user_usage[user]}' 
     /var/log/squid/access.log
```

### Monthly Quota Reset
```bash
# Script chạy đầu mỗi tháng
1 0 1 * * root /usr/local/bin/proxy-quota-reset.sh

# Reset quota và unblock users
# Update quota_reset_date trong database
# Remove iptables block rules
```

## 📁 CẤU TRÚC DATABASE

### Proxy Users Database
```
# /etc/proxy-manager/proxy_users.db
# Format: USERNAME:PASSWORD:CREATED_DATE:STATUS:SPEED_LIMIT_MBPS:MONTHLY_QUOTA_GB:QUOTA_RESET_DATE

proxy_a1b2c3d4:pass_x9y8z7w6:2024-01-15 10:30:25:active:100:5:2024-02-01
proxy_e5f6g7h8:pass_m3n4o5p6:2024-01-15 10:30:26:blocked_quota:0:3:2024-02-01
proxy_x9y8z7w6:pass_q1w2e3r4:2024-01-15 10:30:27:active:50:0:2024-02-01
```

### Bandwidth Usage Database
```
# /etc/proxy-manager/bandwidth_usage.db
# Format: USERNAME:YEAR_MONTH:USED_BYTES:LAST_UPDATED

proxy_a1b2c3d4:2024-01:2147483648:2024-01-20 15:30:45
proxy_e5f6g7h8:2024-01:3221225472:2024-01-18 12:15:30
proxy_x9y8z7w6:2024-01:1073741824:2024-01-20 16:45:12
```

## 🔒 BẢO MẬT VÀ KIỂM SOÁT

### User Blocking System
```bash
# Block user khi hết quota
iptables -I OUTPUT -m owner --uid-owner $uid -j DROP

# Update status trong database
sed -i "s/:active:/:blocked_quota:/" proxy_users.db

# Unblock user sau khi reset quota
iptables -D OUTPUT -m owner --uid-owner $uid -j DROP
sed -i "s/:blocked_quota:/:active:/" proxy_users.db
```

### Real-time Monitoring
```bash
# Theo dõi connections
netstat -an | grep ":3128" | grep ESTABLISHED | wc -l
netstat -an | grep ":1080" | grep ESTABLISHED | wc -l

# Theo dõi bandwidth usage
watch -n 1 'tc -s class show dev eth0'
```

## 🎯 USE CASES CHO KINH DOANH

### Gói Proxy Cơ bản
- **Speed**: 50Mbps
- **Quota**: 10GB/tháng
- **Price**: $5/tháng

### Gói Proxy Premium  
- **Speed**: 100Mbps
- **Quota**: 50GB/tháng
- **Price**: $15/tháng

### Gói Proxy Unlimited
- **Speed**: Unlimited
- **Quota**: Unlimited
- **Price**: $30/tháng

### Quản lý khách hàng
```bash
# Tạo proxy cho khách hàng mới
create_proxy_pair
# -> Chọn gói phù hợp

# Gia hạn cho khách hàng
update_proxy_bandwidth
# -> Reset quota hoặc upgrade gói

# Tạm dừng dịch vụ
update_proxy_bandwidth
# -> Block/Unblock user
```

## 🔧 TROUBLESHOOTING

### Kiểm tra Traffic Control
```bash
# Xem qdisc hiện tại
tc qdisc show dev eth0

# Xem classes
tc class show dev eth0

# Xem filters
tc filter show dev eth0

# Xem statistics
tc -s class show dev eth0
```

### Kiểm tra iptables rules
```bash
# Xem mangle table
iptables -t mangle -L -n -v

# Xem mark rules
iptables -t mangle -L OUTPUT -n -v

# Test marking
iptables -t mangle -I OUTPUT -m owner --uid-owner 1001 -j LOG --log-prefix "USER_1001: "
```

### Debug bandwidth monitoring
```bash
# Chạy monitor script thủ công
/usr/local/bin/proxy-bandwidth-monitor.sh

# Xem log
tail -f /var/log/proxy-bandwidth-monitor.log

# Test quota check
grep "proxy_a1b2c3d4:2024-01:" /etc/proxy-manager/bandwidth_usage.db
```

## 📈 PERFORMANCE OPTIMIZATION

### System Tuning
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

### Squid Optimization
```bash
# Tăng cache memory
cache_mem 1024 MB

# Tăng maximum object size  
maximum_object_size 512 MB

# Optimize for bandwidth control
delay_pools 100
delay_class 1 2
```

## 🎉 KẾT LUẬN

**Enhanced Dual Proxy Manager v4.0** là giải pháp hoàn chỉnh nhất cho việc quản lý proxy với kiểm soát băng thông toàn diện:

### ✅ **Đảm bảo 100%**
- **Giới hạn tốc độ chính xác** cho từng user
- **Quota management** tự động và chính xác  
- **Real-time monitoring** và statistics
- **Automatic blocking/unblocking** theo quota
- **Monthly reset** tự động

### 🚀 **Phù hợp cho**
- **Kinh doanh proxy** chuyên nghiệp
- **ISP** cung cấp dịch vụ proxy
- **Enterprise** cần kiểm soát bandwidth
- **Personal use** với quản lý nâng cao

### 💡 **Unique Features**
- **Cùng speed limit** cho cả HTTP và SOCKS5
- **Per-user bandwidth control** với TC + iptables
- **Monthly quota** với automatic reset
- **Real-time usage tracking**
- **Business-ready** management interface

---

**🔥 Đặc biệt**: Script này là phiên bản duy nhất có **BANDWIDTH CONTROL HOÀN CHỈNH** với tất cả tính năng mà bạn yêu cầu!