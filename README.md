# Dual Proxy Manager v3.0

Hệ thống quản lý proxy toàn diện cung cấp cả HTTP (Squid) và SOCKS5 (Dante) với đầy đủ các thao tác CRUD. Mỗi cặp proxy chia sẻ cùng thông tin đăng nhập cho cả hai giao thức HTTP và SOCKS5.

## 🚀 Tính năng chính

### ✨ Hỗ trợ Dual Proxy
- **HTTP Proxy** (Squid) - Cổng 3128 (mặc định)
- **SOCKS5 Proxy** (Dante) - Cổng 1080 (mặc định)
- **Thông tin đăng nhập chung** - Cùng username/password cho cả hai giao thức

### 🔧 Thao tác CRUD đầy đủ
- **CREATE** - Tạo một hoặc nhiều cặp proxy
- **READ** - Liệt kê và xem tất cả cấu hình proxy
- **UPDATE** - Thay đổi mật khẩu với tạo unique tự động
- **DELETE** - Xóa một hoặc tất cả cặp proxy

## 🎯 NHỮNG ĐIỀU SCRIPT NÀY ĐẢM BẢO

### ✅ **Username/Password luôn UNIQUE**
- Hệ thống tự động kiểm tra trùng lặp
- Tạo username với prefix `proxy_` + mã hex ngẫu nhiên
- Tạo password với prefix `pass_` + mã ngẫu nhiên 12 ký tự
- Không bao giờ tạo ra 2 user/pass giống nhau

### ✅ **Format chuẩn IP:PORT:USER:PASS**
```
HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
```

### ✅ **Cả HTTP và SOCKS5 cùng user/pass**
- Một cặp thông tin đăng nhập cho cả 2 giao thức
- Tiện lợi cho người dùng, dễ quản lý
- Đồng bộ hoàn toàn giữa HTTP và SOCKS5

### ✅ **CRUD operations đầy đủ**
- **CREATE**: Tạo 1 hoặc hàng loạt proxy (1-100 cặp)
- **READ**: Xem danh sách, xuất file, hiển thị chi tiết
- **UPDATE**: Cập nhật mật khẩu với unique guarantee
- **DELETE**: Xóa từng cặp hoặc xóa tất cả

### ✅ **Database quản lý chặt chẽ**
- File database: `/etc/proxy-manager/proxy_users.db`
- Lưu trữ: USERNAME:PASSWORD:CREATED_DATE:STATUS
- Tự động backup và khôi phục
- Kiểm tra tính toàn vẹn dữ liệu

### ✅ **Upload tự động lên file.io**
- Tự động tạo file ZIP có mật khẩu bảo vệ
- Upload lên file.io với link download
- Cung cấp mật khẩu giải nén
- Backup local trong `/tmp/`

## 🔐 Tính năng bảo mật

### 🛡️ **Tạo thông tin đăng nhập an toàn**
- Sử dụng OpenSSL để tạo mã ngẫu nhiên
- Kiểm tra unique qua 100 lần thử
- Mã hóa mật khẩu trong hệ thống
- Không lưu trữ plain text password

### 🔒 **Quản lý truy cập**
- Chỉ user được xác thực mới sử dụng proxy
- Không cho phép truy cập ẩn danh
- Cách ly giữa các phiên proxy
- Log đầy đủ các hoạt động

## 📋 Yêu cầu hệ thống

### Hệ điều hành được hỗ trợ
- Ubuntu 18.04+ / Debian 9+
- CentOS 7+ / RHEL 7+
- Các bản phân phối Linux khác có systemd

### Yêu cầu phần cứng
- Quyền root (sudo)
- Tối thiểu 1GB RAM
- 10GB dung lượng trống
- Kết nối Internet để cài đặt packages

## 🛠️ Cài đặt

### Cài đặt nhanh
```bash
# Tải và chạy script cài đặt
wget https://raw.githubusercontent.com/your-repo/dual-proxy.sh -O dual-proxy.sh
chmod +x dual-proxy.sh
sudo ./dual-proxy.sh
```

### Cài đặt thủ công
```bash
# Clone repository
git clone https://github.com/your-repo/dual-proxy-manager.git
cd dual-proxy-manager

# Cấp quyền thực thi
chmod +x dual-proxy.sh

# Chạy script cài đặt
sudo ./dual-proxy.sh
```

## 🎯 Cách sử dụng

### Thiết lập lần đầu
1. Chạy script với quyền root: `sudo ./dual-proxy.sh`
2. Cấu hình cổng HTTP proxy (mặc định: 3128)
3. Cấu hình cổng SOCKS5 proxy (mặc định: 1080)
4. Chọn tạo proxy pairs ban đầu (tùy chọn)
5. Cài đặt hoàn tất tự động

### Lệnh quản lý
```bash
# Vào menu quản lý
sudo ./dual-proxy.sh menu

# Xem thông tin cài đặt
sudo ./dual-proxy.sh info

# Kiểm tra trạng thái dịch vụ
sudo ./dual-proxy.sh status
```

## 📖 Hướng dẫn thao tác CRUD

### CREATE - Tạo Proxy

#### Tạo một cặp proxy
- Tự động tạo username và password unique
- Tạo user hệ thống và cấu hình cả HTTP và SOCKS5
- Trả về thông tin đăng nhập định dạng: `IP:PORT:USER:PASS`

**Ví dụ kết quả:**
```
✓ Cặp proxy đã được tạo thành công!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
```

#### Tạo nhiều cặp proxy
- Tạo hàng loạt từ 1-100 cặp proxy
- Thanh tiến trình hiển thị quá trình tạo
- Tự động tạo file và upload lên file.io
- File ZIP được bảo vệ bằng mật khẩu

**Ví dụ output:**
```
✓ Đã tạo 10 cặp proxy thành công!

Danh sách proxy:
HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6

HTTP:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
SOCKS5: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6

✓ Danh sách proxy đã được upload thành công!
Download URL: https://file.io/abc123
Archive Password: randomPassword123
```

### READ - Xem Proxy

#### Liệt kê tất cả cặp proxy
- Hiển thị tất cả cặp proxy đang hoạt động
- Hiển thị ngày tạo và trạng thái
- Format: Cả thông tin HTTP và SOCKS5 cho mỗi user

**Ví dụ hiển thị:**
```
Current Proxy Pairs:

Format: HTTP and SOCKS5 pairs
Server IP: 192.168.1.100

[1] User: proxy_a1b2c3d4
    HTTP:   192.168.1.100:3128:proxy_a1b2c3d4:pass_x9y8z7w6
    SOCKS5: 192.168.1.100:1080:proxy_a1b2c3d4:pass_x9y8z7w6
    Created: 2024-01-15 10:30:25 | Status: active

[2] User: proxy_e5f6g7h8
    HTTP:   192.168.1.100:3128:proxy_e5f6g7h8:pass_m3n4o5p6
    SOCKS5: 192.168.1.100:1080:proxy_e5f6g7h8:pass_m3n4o5p6
    Created: 2024-01-15 10:30:26 | Status: active

Total proxy pairs: 2
```

#### Xuất danh sách proxy
- Tạo file proxy được định dạng
- Upload lên file.io với bảo vệ mật khẩu
- Backup file local trong `/tmp/`

### UPDATE - Cập nhật Proxy

#### Cập nhật mật khẩu proxy
- Chọn user từ danh sách hiện có
- Tạo mật khẩu mới unique
- Cập nhật cả HTTP và SOCKS5 authentication
- Tự động reload dịch vụ

**Ví dụ:**
```
Enter username to update: proxy_a1b2c3d4

✓ Mật khẩu đã được cập nhật thành công!
HTTP Proxy:   192.168.1.100:3128:proxy_a1b2c3d4:pass_newPassword123
SOCKS5 Proxy: 192.168.1.100:1080:proxy_a1b2c3d4:pass_newPassword123
```

### DELETE - Xóa Proxy

#### Xóa một cặp proxy
- Chọn user từ danh sách tương tác
- Xác nhận trước khi xóa
- Xóa khỏi tất cả hệ thống (user, HTTP, SOCKS5)

#### Xóa tất cả cặp proxy
- Yêu cầu gõ "DELETE ALL" để xác nhận
- Xóa hàng loạt tất cả proxy users
- Giữ nguyên cấu hình hệ thống

## 🔧 Cấu hình

### Cổng mặc định
- **HTTP Proxy**: 3128
- **SOCKS5 Proxy**: 1080

### File cấu hình
- **Squid Config**: `/etc/squid/squid.conf`
- **Dante Config**: `/etc/sockd.conf`
- **User Database**: `/etc/proxy-manager/proxy_users.db`
- **Password File**: `/etc/squid/passwd`

### Quản lý dịch vụ
```bash
# HTTP Proxy (Squid)
systemctl start|stop|restart|status squid

# SOCKS5 Proxy (Dante)
systemctl start|stop|restart|status sockd
```

## 🧪 Kiểm tra Proxy

### Kiểm tra tích hợp
Sử dụng tùy chọn "Test Proxy Pair" trong menu quản lý để xác minh chức năng.

### Kiểm tra thủ công

#### Kiểm tra HTTP Proxy
```bash
curl -x username:password@your-server-ip:3128 http://ifconfig.me
```

#### Kiểm tra SOCKS5 Proxy
```bash
curl --socks5 username:password@your-server-ip:1080 http://ifconfig.me
```

### Cấu hình trình duyệt

#### HTTP Proxy
- **Loại Proxy**: HTTP
- **Server**: IP server của bạn
- **Port**: 3128 (hoặc cổng đã cấu hình)
- **Username/Password**: Từ danh sách proxy của bạn

#### SOCKS5 Proxy
- **Loại Proxy**: SOCKS5
- **Server**: IP server của bạn
- **Port**: 1080 (hoặc cổng đã cấu hình)
- **Username/Password**: Từ danh sách proxy của bạn

## 📁 Cấu trúc file

```
/etc/proxy-manager/
├── proxy_users.db          # Database người dùng
/etc/squid/
├── squid.conf              # Cấu hình HTTP proxy
├── passwd                  # Mật khẩu HTTP proxy
/etc/
├── sockd.conf              # Cấu hình SOCKS5 proxy
/var/log/
├── squid/access.log        # Log HTTP proxy
├── sockd.log               # Log SOCKS5 proxy
/root/
├── dual_proxy_info.txt     # Thông tin cài đặt
```

## 🔍 Xử lý sự cố

### Các vấn đề thường gặp

#### Dịch vụ không khởi động
```bash
# Kiểm tra trạng thái dịch vụ
systemctl status squid
systemctl status sockd

# Kiểm tra log
journalctl -u squid -f
journalctl -u sockd -f
```

#### Cổng đã được sử dụng
```bash
# Kiểm tra cổng đang được sử dụng
netstat -tulpn | grep :3128
netstat -tulpn | grep :1080

# Dừng tiến trình xung đột nếu cần
sudo fuser -k 3128/tcp
sudo fuser -k 1080/tcp
```

#### Vấn đề Firewall
```bash
# Kiểm tra trạng thái firewall
ufw status
firewall-cmd --list-all

# Mở cổng thủ công nếu cần
ufw allow 3128/tcp
ufw allow 1080/tcp
```

#### Vấn đề xác thực
```bash
# Xác minh user tồn tại
grep username /etc/proxy-manager/proxy_users.db

# Kiểm tra file mật khẩu Squid
cat /etc/squid/passwd

# Reload dịch vụ
systemctl reload squid
systemctl restart sockd
```

### Phân tích Log

#### Log HTTP Proxy
```bash
# Log truy cập real-time
tail -f /var/log/squid/access.log

# Log lỗi
tail -f /var/log/squid/cache.log
```

#### Log SOCKS5 Proxy
```bash
# Log SOCKS5 real-time
tail -f /var/log/sockd.log
```

## 🔒 Cân nhắc bảo mật

### Thực hành tốt nhất
- Thay đổi cổng mặc định để bảo mật
- Sử dụng mật khẩu mạnh, unique (tự động tạo)
- Thường xuyên theo dõi log truy cập
- Giới hạn truy cập vào giao diện quản lý
- Giữ hệ thống được cập nhật

### Cấu hình Firewall
Script tự động cấu hình:
- UFW (Ubuntu/Debian)
- Firewalld (CentOS/RHEL)
- Iptables (fallback)

### Kiểm soát truy cập
- Chỉ user được xác thực mới có thể sử dụng proxy
- Không cho phép truy cập ẩn danh
- Cách ly user giữa các phiên proxy

## 📈 Tối ưu hiệu suất

### Tối ưu Squid
```bash
# Chỉnh sửa /etc/squid/squid.conf
cache_mem 512 MB                    # Tăng bộ nhớ cache
maximum_object_size 256 MB          # Cache object lớn hơn
```

### Giới hạn hệ thống
```bash
# Tăng giới hạn file descriptor
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

## 🆘 Hỗ trợ

### Nhận trợ giúp
1. Kiểm tra phần xử lý sự cố
2. Xem lại file log để tìm lỗi
3. Xác minh file cấu hình
4. Kiểm tra kết nối mạng

### Báo cáo vấn đề
Khi báo cáo vấn đề, vui lòng bao gồm:
- Hệ điều hành và phiên bản
- Thông báo lỗi từ log
- Các bước để tái tạo vấn đề
- Chi tiết cấu hình (không bao gồm dữ liệu nhạy cảm)

## 📄 Giấy phép

Dự án này được cấp phép theo MIT License - xem file LICENSE để biết chi tiết.

## 🤝 Đóng góp

1. Fork repository
2. Tạo feature branch
3. Thực hiện thay đổi
4. Test kỹ lưỡng
5. Gửi pull request

## 📚 Tài nguyên bổ sung

### Tài liệu liên quan
- [Tài liệu Squid Proxy](http://www.squid-cache.org/Doc/)
- [Tài liệu Dante SOCKS Server](https://www.inet.no/dante/doc/)
- [Hướng dẫn cấu hình Linux Proxy](https://wiki.archlinux.org/title/Proxy_server)

### Lệnh hữu ích
```bash
# Theo dõi sử dụng proxy
watch -n 1 'netstat -an | grep :3128 | wc -l'
watch -n 1 'netstat -an | grep :1080 | wc -l'

# Kiểm tra hiệu suất proxy
iftop -i eth0 -P

# Theo dõi tài nguyên hệ thống
htop
```

## 🎉 Kết luận

**Dual Proxy Manager v3.0** là giải pháp hoàn chỉnh cho việc quản lý proxy với đầy đủ tính năng CRUD, đảm bảo tính unique và format chuẩn. Script này phù hợp cho cả mục đích cá nhân và thương mại.

---

**Lưu ý quan trọng**: Script này yêu cầu quyền root và sẽ thay đổi cấu hình hệ thống. Luôn test trong môi trường không phải production trước.

**🔥 Đặc biệt**: Script đảm bảo 100% không trùng lặp username/password và tự động upload lên file.io với mật khẩu bảo vệ!