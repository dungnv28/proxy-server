# DUAL PROXY MANAGER - COMMAND REFERENCE

## 🎯 **CÁC LỆNH COMMAND LINE CHÍNH**

### 1. **LỆNH KHỞI CHẠY CHÍNH**
```bash
# Chạy script cài đặt hoặc vào menu quản lý
sudo ./dual-proxy.sh

# Hoặc với bash
sudo bash dual-proxy.sh
```

### 2. **CÁC LỆNH THAM SỐ**

#### 🔧 **Menu Management**
```bash
# Vào menu quản lý trực tiếp (bỏ qua cài đặt)
sudo ./dual-proxy.sh menu
```

#### 📊 **Xem thông tin**
```bash
# Hiển thị thông tin cài đặt
sudo ./dual-proxy.sh info
```

#### 🔍 **Kiểm tra trạng thái**
```bash
# Kiểm tra trạng thái dịch vụ
sudo ./dual-proxy.sh status
```

## 🖥️ **CÁC LỆNH TRONG MENU TƯƠNG TÁC**

### 📋 **MENU CHÍNH (Interactive Menu)**
Khi chạy `sudo ./dual-proxy.sh menu`, bạn sẽ thấy:

```
DUAL PROXY MANAGER v3.0 - CRUD Operations
══════════════════════════════════════════════════════════════

Proxy Management Menu
Server: 192.168.1.100 | HTTP: 3128 | SOCKS5: 1080

CRUD Operations:
1) Create Single Proxy Pair
2) Create Multiple Proxy Pairs  
3) Read/List All Proxy Pairs
4) Update Proxy Password
5) Delete Single Proxy Pair
6) Delete All Proxy Pairs

Management:
7) Export Proxy Pairs
8) Test Proxy Pair
9) Service Status
10) Restart Services
11) View Logs

0) Exit

Select an option [0-11]:
```

### 🔧 **CHI TIẾT CÁC LỆNH MENU**

#### **1) Create Single Proxy Pair**
- Tự động tạo 1 cặp proxy (HTTP + SOCKS5)
- Username: `proxy_` + mã hex ngẫu nhiên
- Password: `pass_` + mã 12 ký tự ngẫu nhiên
- Output format: `IP:PORT:USER:PASS`

#### **2) Create Multiple Proxy Pairs**
- Nhập số lượng proxy cần tạo (1-100)
- Tạo hàng loạt với thanh tiến trình
- Tự động upload lên file.io
- Tạo file ZIP có mật khẩu bảo vệ

#### **3) Read/List All Proxy Pairs**
- Hiển thị tất cả proxy pairs hiện có
- Format: HTTP và SOCKS5 cho mỗi user
- Thông tin: Username, Password, Ngày tạo, Trạng thái

#### **4) Update Proxy Password**
- Chọn user từ danh sách
- Tự động tạo password mới unique
- Cập nhật cả HTTP và SOCKS5
- Reload dịch vụ tự động

#### **5) Delete Single Proxy Pair**
- Chọn user cần xóa
- Xác nhận trước khi xóa
- Xóa khỏi tất cả hệ thống

#### **6) Delete All Proxy Pairs**
- Yêu cầu gõ "DELETE ALL"
- Xóa tất cả proxy users
- Giữ nguyên cấu hình hệ thống

#### **7) Export Proxy Pairs**
- Xuất danh sách proxy ra file
- Upload lên file.io với mật khẩu
- Backup local trong /tmp/

#### **8) Test Proxy Pair**
- Chọn user để test
- Kiểm tra HTTP proxy
- Kiểm tra SOCKS5 proxy
- Hiển thị IP external

#### **9) Service Status**
- Trạng thái Squid (HTTP)
- Trạng thái Dante (SOCKS5)
- Trạng thái cổng (Open/Closed)

#### **10) Restart Services**
- Restart Squid
- Restart Dante
- Kiểm tra trạng thái sau restart

#### **11) View Logs**
- HTTP Proxy Logs (20 dòng cuối)
- SOCKS5 Proxy Logs (20 dòng cuối)
- Cả hai logs

## 🔧 **CÁC LỆNH HỆ THỐNG QUẢN LÝ DỊCH VỤ**

### **Quản lý Squid (HTTP Proxy)**
```bash
# Khởi động Squid
sudo systemctl start squid

# Dừng Squid
sudo systemctl stop squid

# Khởi động lại Squid
sudo systemctl restart squid

# Reload cấu hình Squid (không ngắt kết nối)
sudo systemctl reload squid

# Kiểm tra trạng thái Squid
sudo systemctl status squid

# Bật tự khởi động
sudo systemctl enable squid

# Tắt tự khởi động
sudo systemctl disable squid
```

### **Quản lý Dante (SOCKS5 Proxy)**
```bash
# Khởi động Dante
sudo systemctl start sockd

# Dừng Dante
sudo systemctl stop sockd

# Khởi động lại Dante
sudo systemctl restart sockd

# Kiểm tra trạng thái Dante
sudo systemctl status sockd

# Bật tự khởi động
sudo systemctl enable sockd

# Tắt tự khởi động
sudo systemctl disable sockd
```

## 📊 **CÁC LỆNH GIÁM SÁT VÀ DEBUG**

### **Xem Logs Real-time**
```bash
# Log HTTP Proxy (Squid)
sudo tail -f /var/log/squid/access.log

# Log SOCKS5 Proxy (Dante)
sudo tail -f /var/log/sockd.log

# Log hệ thống cho Squid
sudo journalctl -u squid -f

# Log hệ thống cho Dante
sudo journalctl -u sockd -f
```

### **Kiểm tra Cổng và Kết nối**
```bash
# Kiểm tra cổng HTTP (3128)
sudo netstat -tulpn | grep :3128

# Kiểm tra cổng SOCKS5 (1080)
sudo netstat -tulpn | grep :1080

# Đếm số kết nối HTTP
sudo netstat -an | grep :3128 | wc -l

# Đếm số kết nối SOCKS5
sudo netstat -an | grep :1080 | wc -l

# Kiểm tra tiến trình Squid
sudo ps aux | grep squid

# Kiểm tra tiến trình Dante
sudo ps aux | grep sockd
```

### **Kiểm tra Cấu hình**
```bash
# Kiểm tra cấu hình Squid
sudo squid -k parse

# Test cấu hình Squid
sudo squid -k check

# Xem cấu hình Squid
sudo cat /etc/squid/squid.conf

# Xem cấu hình Dante
sudo cat /etc/sockd.conf

# Xem database users
sudo cat /etc/proxy-manager/proxy_users.db
```

## 🧪 **CÁC LỆNH TEST PROXY**

### **Test HTTP Proxy**
```bash
# Test với curl
curl -x username:password@your-server-ip:3128 http://ifconfig.me

# Test với wget
wget --proxy-user=username --proxy-password=password \
     --proxy=on --http-proxy=your-server-ip:3128 \
     -O - http://ifconfig.me

# Test kết nối
telnet your-server-ip 3128
```

### **Test SOCKS5 Proxy**
```bash
# Test với curl
curl --socks5 username:password@your-server-ip:1080 http://ifconfig.me

# Test với proxychains
echo "socks5 your-server-ip 1080 username password" >> /etc/proxychains.conf
proxychains curl http://ifconfig.me

# Test kết nối
telnet your-server-ip 1080
```

## 🔧 **CÁC LỆNH TROUBLESHOOTING**

### **Khi Dịch vụ Không Khởi động**
```bash
# Kiểm tra lỗi chi tiết
sudo systemctl status squid -l
sudo systemctl status sockd -l

# Xem log lỗi
sudo journalctl -u squid --no-pager
sudo journalctl -u sockd --no-pager

# Kiểm tra cấu hình
sudo squid -k parse
sudo /usr/sbin/sockd -f /etc/sockd.conf -V
```

### **Khi Cổng Bị Chiếm**
```bash
# Tìm tiến trình đang sử dụng cổng
sudo lsof -i :3128
sudo lsof -i :1080

# Kill tiến trình (thay PID)
sudo kill -9 PID

# Hoặc kill theo cổng
sudo fuser -k 3128/tcp
sudo fuser -k 1080/tcp
```

### **Khi Firewall Chặn**
```bash
# UFW
sudo ufw allow 3128/tcp
sudo ufw allow 1080/tcp
sudo ufw status

# Firewalld
sudo firewall-cmd --permanent --add-port=3128/tcp
sudo firewall-cmd --permanent --add-port=1080/tcp
sudo firewall-cmd --reload

# Iptables
sudo iptables -I INPUT -p tcp --dport 3128 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 1080 -j ACCEPT
```

## 📁 **CÁC LỆNH QUẢN LÝ FILE**

### **Backup và Restore**
```bash
# Backup cấu hình
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.backup
sudo cp /etc/sockd.conf /etc/sockd.conf.backup
sudo cp /etc/proxy-manager/proxy_users.db /etc/proxy-manager/proxy_users.db.backup

# Restore cấu hình
sudo cp /etc/squid/squid.conf.backup /etc/squid/squid.conf
sudo cp /etc/sockd.conf.backup /etc/sockd.conf
sudo cp /etc/proxy-manager/proxy_users.db.backup /etc/proxy-manager/proxy_users.db
```

### **Xem và Chỉnh sửa File**
```bash
# Chỉnh sửa cấu hình Squid
sudo nano /etc/squid/squid.conf

# Chỉnh sửa cấu hình Dante
sudo nano /etc/sockd.conf

# Xem database users
sudo cat /etc/proxy-manager/proxy_users.db

# Xem file passwords Squid
sudo cat /etc/squid/passwd
```

## 🔄 **CÁC LỆNH MAINTENANCE**

### **Dọn dẹp Logs**
```bash
# Xóa log cũ Squid
sudo truncate -s 0 /var/log/squid/access.log
sudo truncate -s 0 /var/log/squid/cache.log

# Xóa log cũ Dante
sudo truncate -s 0 /var/log/sockd.log

# Rotate logs
sudo logrotate -f /etc/logrotate.d/squid
```

### **Cập nhật và Bảo trì**
```bash
# Cập nhật packages
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL

# Kiểm tra disk space
df -h

# Kiểm tra memory usage
free -h

# Kiểm tra CPU usage
top
htop
```

## 🎯 **TÓM TẮT CÁC LỆNH QUAN TRỌNG NHẤT**

### **🔥 Top 10 Lệnh Thường Dùng:**

1. `sudo ./dual-proxy.sh` - Chạy script chính
2. `sudo ./dual-proxy.sh menu` - Vào menu quản lý
3. `sudo ./dual-proxy.sh status` - Kiểm tra trạng thái
4. `sudo systemctl restart squid` - Restart HTTP proxy
5. `sudo systemctl restart sockd` - Restart SOCKS5 proxy
6. `sudo tail -f /var/log/squid/access.log` - Xem log HTTP
7. `sudo tail -f /var/log/sockd.log` - Xem log SOCKS5
8. `curl -x user:pass@ip:3128 http://ifconfig.me` - Test HTTP
9. `curl --socks5 user:pass@ip:1080 http://ifconfig.me` - Test SOCKS5
10. `sudo netstat -tulpn | grep :3128` - Kiểm tra cổng

### **🚨 Lệnh Khẩn Cấp:**
```bash
# Dừng tất cả proxy
sudo systemctl stop squid sockd

# Khởi động lại tất cả
sudo systemctl restart squid sockd

# Kiểm tra nhanh trạng thái
sudo systemctl is-active squid sockd
```

---

**💡 Lưu ý**: Tất cả lệnh quản lý dịch vụ cần quyền root (sudo). Menu tương tác cung cấp giao diện thân thiện nhất cho người dùng không chuyên về command line.