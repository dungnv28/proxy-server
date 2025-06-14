# FINAL DUAL PROXY MANAGER - HƯỚNG DẪN SỬ DỤNG HOÀN CHỈNH

## 🎯 **GIỚI THIỆU TỔNG QUAN**

**Final Dual Proxy Manager v5.0** là phiên bản hoàn chỉnh và mạnh mẽ nhất, kết hợp tất cả tính năng từ các phiên bản trước với **KIỂM SOÁT BĂNG THÔNG LINH HOẠT HOÀN TOÀN**.

### ✨ **Tính năng độc quyền**
- **Dual Proxy**: HTTP (Squid) + SOCKS5 (Dante) cùng credentials
- **Flexible Bandwidth Control**: Thích thì giới hạn, không thì thôi
- **Complete CRUD**: Tạo, đọc, cập nhật, xóa hoàn chỉnh
- **Real-time Monitoring**: Theo dõi trực tiếp
- **Automatic Quota Management**: Tự động chặn khi hết quota
- **Business-ready**: Sẵn sàng cho kinh doanh

## 🚀 **CÀI ĐẶT NHANH**

### **Bước 1: Tải và cài đặt**
```bash
# Tải script
wget https://raw.githubusercontent.com/your-repo/final-dual-proxy.sh
chmod +x final-dual-proxy.sh

# Chạy cài đặt
sudo ./final-dual-proxy.sh
```

### **Bước 2: Cấu hình ban đầu**
```bash
# Script sẽ hỏi:
Enter HTTP proxy port (default: 3128): 3128
Enter SOCKS5 proxy port (default: 1080): 1080
Create initial proxy pairs? [y/N]: y
Enter number of initial proxy pairs (1-50): 5

# Kết quả: 5 proxy pairs unlimited được tạo
```

### **Bước 3: Vào menu quản lý**
```bash
sudo ./final-dual-proxy.sh menu
```

## 📋 **HƯỚNG DẪN SỬ DỤNG CHI TIẾT**

### **1. TẠO PROXY (CREATE)**

#### **🔧 Tạo một proxy pair**
```bash
# Chọn option 1 trong menu
1) Create Single Proxy Pair (with Bandwidth Control)

# Chọn cấu hình bandwidth:
Bandwidth Configuration:
1) Unlimited (default)    ← Chọn cho unlimited
2) Custom speed limit and total quota    ← Chọn cho có giới hạn
```

**Ví dụ tạo unlimited:**
```bash
Select option [1-2]: 1

✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
Speed Limit:  Unlimited
Total Quota:  Unlimited
```

**Ví dụ tạo có giới hạn:**
```bash
Select option [1-2]: 2
Enter speed limit in Mbps (0 for unlimited): 100
Enter total quota in GB (0 for unlimited): 20

✓ Proxy pair created successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
Speed Limit:  100Mbps
Total Quota:  20GB
```

#### **🔧 Tạo nhiều proxy pairs**
```bash
# Chọn option 2 trong menu
2) Create Multiple Proxy Pairs (with Bandwidth Control)

Enter number of proxy pairs to create: 10

# Chọn cấu hình cho tất cả:
Bandwidth Configuration for all proxies:
1) Unlimited (default)
2) Custom speed limit and total quota

# Kết quả: 10 proxy pairs với cùng cấu hình
```

### **2. XEM PROXY (READ)**

#### **🔍 Liệt kê tất cả proxy**
```bash
# Chọn option 3 trong menu
3) Read/List All Proxy Pairs (with Bandwidth Info)
```

**Kết quả hiển thị:**
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
    Total Quota: 20GB
    Usage: 20GB

Total proxy pairs: 2
```

#### **📊 Xem thống kê bandwidth**
```bash
# Chọn option 8 trong menu
8) Show Bandwidth Statistics

# Hoặc dùng lệnh nhanh:
sudo ./final-dual-proxy.sh stats
```

### **3. CẬP NHẬT PROXY (UPDATE)**

#### **🔧 Cập nhật bandwidth settings**
```bash
# Chọn option 4 trong menu
4) Update Proxy Bandwidth Settings

Enter username to update: proxy_a1b2c3d4

Update Options:
1) Update speed limit only
2) Update total quota only  
3) Update both speed limit and quota
4) Reset to unlimited
5) Block/Unblock user
```

**Các ví dụ cập nhật:**

**Thay đổi chỉ tốc độ:**
```bash
Select option [1-5]: 1
Enter new speed limit in Mbps (0 for unlimited): 200

✓ Speed limit updated to 200Mbps for user: proxy_a1b2c3d4
```

**Reset về unlimited:**
```bash
Select option [1-5]: 4

✓ User proxy_a1b2c3d4 reset to unlimited
```

**Block/Unblock user:**
```bash
Select option [1-5]: 5

Current status: active
1) Block user (stop access)
2) Unblock user (restore access)

Select [1-2]: 1

✓ User proxy_a1b2c3d4 blocked manually
```

#### **🔧 Cập nhật password**
```bash
# Chọn option 5 trong menu
5) Update Proxy Password

Enter username to update password: proxy_a1b2c3d4

✓ Password updated successfully!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_newPassword123
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_newPassword123
```

### **4. XÓA PROXY (DELETE)**

#### **🗑️ Xóa một proxy pair**
```bash
# Chọn option 6 trong menu
6) Delete Single Proxy Pair

Enter username to delete: proxy_e5f6g7h8
Are you sure you want to delete user 'proxy_e5f6g7h8'? [y/N]: y

✓ Proxy pair deleted: proxy_e5f6g7h8
```

#### **🗑️ Xóa tất cả proxy pairs**
```bash
# Chọn option 7 trong menu
7) Delete All Proxy Pairs

This will delete all 10 proxy pairs!
Are you absolutely sure? Type 'DELETE ALL' to confirm: DELETE ALL

✓ All proxy pairs deleted
```

### **5. QUẢN LÝ BANDWIDTH**

#### **📊 Monitor real-time**
```bash
# Chọn option 9 trong menu
9) Monitor Bandwidth Usage (Real-time)

# Kết quả:
Real-time Bandwidth Usage - 2024-01-20 15:30:45

Active Connections:
HTTP Proxy: 25 connections
SOCKS5 Proxy: 18 connections

Username             Speed Limit     Total Quota     Used            Status    
--------             -----------     -----------     ----            ------    
proxy_a1b2c3d4       Unlimited       Unlimited       2GB             Active    
proxy_e5f6g7h8       100Mbps         20GB            20GB            Blocked   

[Updates every 5 seconds - Press Ctrl+C to stop]
```

#### **🔄 Reset quota (gia hạn)**
```bash
# Chọn option 10 trong menu
10) Reset User Quota

Enter username to reset quota: proxy_e5f6g7h8
Are you sure you want to reset quota for user 'proxy_e5f6g7h8'? [y/N]: y

✓ Quota reset for user: proxy_e5f6g7h8
# User có thể dùng tiếp từ 0GB
```

### **6. QUẢN LÝ HỆ THỐNG**

#### **📤 Export proxy list**
```bash
# Chọn option 11 trong menu
11) Export Proxy Pairs

✓ Exported 5 proxy pairs to: /tmp/proxy_export_20240120_153045.txt

✓ Proxy list uploaded successfully!
Download URL: https://file.io/abc123
Archive Password: randomPassword123
```

#### **🧪 Test proxy**
```bash
# Chọn option 12 trong menu
12) Test Proxy Pair

Enter username to test: proxy_a1b2c3d4

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

#### **📊 Kiểm tra trạng thái**
```bash
# Chọn option 13 trong menu
13) Service Status

# Hoặc dùng lệnh nhanh:
sudo ./final-dual-proxy.sh status

# Kết quả:
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
```

## 🎯 **WORKFLOW KINH DOANH**

### **Scenario 1: Khách hàng mới muốn dùng thử**
```bash
# Tạo proxy unlimited cho trial
sudo ./final-dual-proxy.sh menu
# -> Option 1 -> Option 1 (Unlimited)

# Kết quả: Proxy không giới hạn để khách test
```

### **Scenario 2: Khách hàng mua gói Basic**
```bash
# Tạo proxy với giới hạn
sudo ./final-dual-proxy.sh menu
# -> Option 1 -> Option 2 -> Speed: 50Mbps, Quota: 10GB

# Kết quả: Proxy 50Mbps, 10GB total
```

### **Scenario 3: Khách hàng hết quota**
```bash
# Khách báo không dùng được
# Kiểm tra: Option 3 -> Thấy status: blocked_quota

# Khách muốn gia hạn
# Reset quota: Option 10 -> Nhập username

# Kết quả: Khách dùng tiếp từ 0GB
```

### **Scenario 4: Khách hàng muốn upgrade**
```bash
# Khách muốn từ Basic lên Premium
sudo ./final-dual-proxy.sh menu
# -> Option 4 -> Nhập username -> Option 3
# -> Speed: 100Mbps, Quota: 0 (unlimited)

# Kết quả: Proxy 100Mbps unlimited quota
```

### **Scenario 5: Tạm dừng dịch vụ**
```bash
# Khách không thanh toán
sudo ./final-dual-proxy.sh menu
# -> Option 4 -> Nhập username -> Option 5 -> Block

# Kết quả: Khách không thể dùng proxy
```

### **Scenario 6: Khôi phục dịch vụ**
```bash
# Khách đã thanh toán
sudo ./final-dual-proxy.sh menu
# -> Option 4 -> Nhập username -> Option 5 -> Unblock

# Kết quả: Khách dùng lại được proxy
```

## 🔧 **CÁC LỆNH NHANH**

### **Lệnh thường dùng:**
```bash
# Vào menu quản lý
sudo ./final-dual-proxy.sh menu

# Xem thống kê
sudo ./final-dual-proxy.sh stats

# Kiểm tra trạng thái
sudo ./final-dual-proxy.sh status

# Xem thông tin cài đặt
sudo ./final-dual-proxy.sh info
```

### **Lệnh database:**
```bash
# Xem tất cả users
sudo cat /etc/proxy-manager/proxy_users.db

# Tìm user unlimited
sudo grep ":0:0:" /etc/proxy-manager/proxy_users.db

# Tìm user bị block
sudo grep "blocked" /etc/proxy-manager/proxy_users.db

# Đếm user active
sudo grep ":active:" /etc/proxy-manager/proxy_users.db | wc -l
```

### **Lệnh monitoring:**
```bash
# Đếm connections
echo "HTTP: $(netstat -an | grep ":3128" | grep ESTABLISHED | wc -l)"
echo "SOCKS5: $(netstat -an | grep ":1080" | grep ESTABLISHED | wc -l)"

# Xem bandwidth real-time
sudo tc -s class show dev eth0

# Monitor tổng usage
sudo awk -F: 'NR>7 {sum += $7} END {print sum/1024/1024/1024 " GB"}' /etc/proxy-manager/proxy_users.db
```

## 🧪 **TEST PROXY**

### **Test HTTP Proxy:**
```bash
curl -x username:password@your-server-ip:3128 http://ifconfig.me
```

### **Test SOCKS5 Proxy:**
```bash
curl --socks5 username:password@your-server-ip:1080 http://ifconfig.me
```

### **Test với browser:**
1. Mở browser settings
2. Tìm proxy settings
3. Cấu hình:
   - **HTTP Proxy**: IP:3128, username:password
   - **SOCKS5 Proxy**: IP:1080, username:password

## 🔍 **TROUBLESHOOTING**

### **Vấn đề thường gặp:**

#### **1. Proxy không hoạt động**
```bash
# Kiểm tra services
sudo systemctl status squid sockd

# Kiểm tra ports
sudo netstat -tulpn | grep -E "(3128|1080)"

# Restart services
sudo systemctl restart squid sockd
```

#### **2. Bandwidth limit không hoạt động**
```bash
# Kiểm tra traffic control
sudo tc qdisc show dev eth0

# Reset traffic control
sudo tc qdisc del dev eth0 root
sudo ./final-dual-proxy.sh menu
# -> Option 14 (Restart Services)
```

#### **3. User bị block không đúng**
```bash
# Kiểm tra iptables
sudo iptables -L OUTPUT -n -v

# Unblock thủ công
username="proxy_abc123"
uid=$(id -u "$username")
sudo iptables -D OUTPUT -m owner --uid-owner "$uid" -j DROP
```

#### **4. Quota không chính xác**
```bash
# Chạy monitor thủ công
sudo /usr/local/bin/proxy-bandwidth-monitor.sh

# Xem log
sudo tail -f /var/log/proxy-bandwidth-monitor.log
```

## 📊 **MONITORING VÀ BÁO CÁO**

### **Dashboard real-time:**
```bash
watch -n 5 'echo "=== FINAL DUAL PROXY DASHBOARD ===" && 
echo "Active Users: $(grep ":active:" /etc/proxy-manager/proxy_users.db | wc -l)" && 
echo "Blocked Users: $(grep "blocked" /etc/proxy-manager/proxy_users.db | wc -l)" && 
echo "HTTP Connections: $(netstat -an | grep ":3128" | grep ESTABLISHED | wc -l)" && 
echo "SOCKS5 Connections: $(netstat -an | grep ":1080" | grep ESTABLISHED | wc -l)" && 
echo "Total Usage: $(awk -F: "NR>7 && \$1 !~ /^#/ {sum += \$7} END {print sum/1024/1024/1024 \" GB\"}" /etc/proxy-manager/proxy_users.db)"'
```

### **Top users by usage:**
```bash
sudo awk -F: 'NR>7 && $1 !~ /^#/ {print $1 ":" $7}' /etc/proxy-manager/proxy_users.db | sort -t: -k2 -nr | head -10
```

### **Users cần chú ý (gần hết quota):**
```bash
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

## 🎉 **KẾT LUẬN**

**Final Dual Proxy Manager v5.0** cung cấp giải pháp hoàn chỉnh cho việc quản lý proxy với:

### ✅ **Ưu điểm chính:**
- **Linh hoạt hoàn toàn**: Thích thì giới hạn, không thì thôi
- **Quản lý đơn giản**: Interface thân thiện, dễ sử dụng
- **Kinh doanh thực tế**: Phù hợp mọi mô hình kinh doanh
- **Monitoring mạnh mẽ**: Theo dõi real-time, báo cáo chi tiết
- **Tự động hóa**: Auto block/unblock, quota management

### 🚀 **Phù hợp cho:**
- **Cá nhân**: Sử dụng proxy cá nhân
- **Doanh nghiệp nhỏ**: Cung cấp proxy cho nhân viên
- **Kinh doanh proxy**: Bán proxy chuyên nghiệp
- **ISP**: Cung cấp dịch vụ proxy
- **Reseller**: Bán lại proxy

### 💡 **Tính năng độc quyền:**
- **Dual proxy support**: HTTP + SOCKS5 cùng credentials
- **Flexible bandwidth control**: Không ràng buộc thời gian
- **Complete CRUD operations**: Quản lý toàn diện
- **Real-time statistics**: Thống kê trực tiếp
- **Business-ready interface**: Sẵn sàng kinh doanh

---

**🔥 Final Dual Proxy Manager v5.0** - Giải pháp proxy hoàn chỉnh và mạnh mẽ nhất cho mọi nhu cầu!