#!/usr/bin/env bash

# Kiểm tra bash shell
if readlink /proc/$$/exe | grep -qs "dash"; then
    echo "This script needs to be run with bash, not sh"
    exit 1
fi

# Kiểm tra quyền root
if [[ "$EUID" -ne 0 ]]; then
    echo "Sorry, but you need to run this script as root"
    exit 2
fi

# Xác định loại hệ điều hành
if [[ -e /etc/debian_version ]]; then
    OStype=deb
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
    OStype=centos
else
    echo "This script only works on Debian, Ubuntu or CentOS"
    exit 3
fi

# Lấy tên giao diện LAN của hệ thống
interface="$(ip -o -4 route show to default | awk '{print $5}')"

# Kiểm tra nếu giao diện tồn tại
if [[ -n "$interface" && -d "/sys/class/net/$interface" ]]; then
    echo "Interface $interface exists."
else
    echo "Interface does not exist."
    exit 4
fi

# Tạo thư mục cấu hình 3proxy nếu chưa tồn tại
mkdir -p /etc/3proxy

# Cài đặt các yêu cầu cơ bản và 3proxy
if [[ "$OStype" = 'deb' ]]; then
    apt-get update
    apt-get -y install openssl make gcc
    # Cài đặt 3proxy
    wget https://github.com/z3APA3A/3proxy/archive/refs/tags/0.9.4.tar.gz
    tar xzf 0.9.4.tar.gz && cd 3proxy-0.9.4
    make -f Makefile.Linux
    cp bin/3proxy /etc/3proxy/
else
    yum -y install epel-release
    yum -y install openssl make gcc
    # Cài đặt 3proxy
    wget https://github.com/z3APA3A/3proxy/archive/refs/tags/0.9.4.tar.gz
    tar xzf 0.9.4.tar.gz && cd 3proxy-0.9.4
    make -f Makefile.Linux
    cp bin/3proxy /etc/3proxy/
fi

# Yêu cầu nhập số lượng proxy và giới hạn băng thông
read -p "Please enter the HTTP port number for the proxy server:  " -e -i 4099 http_port
read -p "Please enter the SOCKS5 port number for the proxy server:  " -e -i 5099 socks_port
read -p "Please enter the number of proxies to create: " -e numofproxy
read -p "Please enter the bandwidth limit in Mbps (e.g., 100 for 100Mbps): " limit

# Mở cổng trong UFW và iptables
if sudo ufw status | grep -q "Status: active"; then
    sudo ufw allow "$socks_port"/tcp
    sudo ufw allow "$http_port"/tcp
    echo "Ports $socks_port and $http_port opened in UFW."
else
    echo "UFW is not active or ports are already open."
fi

if ! sudo iptables -L | grep -q "ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:$socks_port"; then
    sudo iptables -A INPUT -p tcp --dport "$socks_port" -j ACCEPT
fi

if ! sudo iptables -L | grep -q "ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:$http_port"; then
    sudo iptables -A INPUT -p tcp --dport "$http_port" -j ACCEPT
fi

# Tạo username và password ngẫu nhiên
for i in $(seq 1 $numofproxy); do
    user[$i]=$(openssl rand -base64 8 | tr -dc 'a-zA-Z' | head -c 8)
    password[$i]=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)
done

# Tạo tệp cấu hình 3proxy
cat > /etc/3proxy/3proxy.cfg <<-EOF
# Specify valid name servers. You can locate them on your VPS in /etc/resolv.conf
nserver 8.8.8.8
nserver 8.8.4.4
nserver 1.1.1.1
nserver 1.0.0.1
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
daemon
log /var/log/3proxy/3proxy.log
logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"
archiver gz /usr/bin/gzip %F
rotate 1
authcache user 60
auth strong cache
deny * * 127.0.0.0/8,192.168.1.1
allow * * * 80-88,8080-8088 HTTP
allow * * * 443,8443 HTTPS
EOF

# Thêm proxy socks và HTTP cho mỗi người dùng
for i in $(seq 1 $numofproxy); do
    cat >> /etc/3proxy/3proxy.cfg <<-EOF
users ${user[$i]}:CL:${password[$i]}
proxy -p$http_port -i0.0.0.0 -e$interface
socks -p$socks_port -i0.0.0.0 -e$interface
allow ${user[$i]}
EOF
done

# Thêm cấu hình cho admin web UI
cat >> /etc/3proxy/3proxy.cfg <<-EOF
flush
auth iponly
allow * * 127.0.0.1
allow admin * 10.0.0.0/8
admin -p2525
EOF

# Khởi tạo dịch vụ systemd cho 3proxy
cat > /etc/systemd/system/3proxy.service <<-EOF
[Unit]
Description=3proxy Socks5 and HTTP Proxy
After=network.target

[Service]
ExecStart=/usr/local/bin/3proxy /etc/3proxy/3proxy.cfg
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Tải lại systemd và khởi động 3proxy
systemctl daemon-reload
systemctl enable 3proxy
systemctl start 3proxy

# Xóa cấu hình tc hiện tại trước khi thiết lập giới hạn băng thông mới
sudo tc qdisc del dev $interface root 2> /dev/null

# Áp dụng giới hạn băng thông mới
tc qdisc add dev $interface root handle 1: htb default 30
tc class add dev $interface parent 1: classid 1:1 htb rate ${limit}mbit ceil ${limit}mbit
tc class add dev $interface parent 1:1 classid 1:30 htb rate ${limit}mbit ceil ${limit}mbit
tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip src 0.0.0.0/0 flowid 1:30
tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip dst 0.0.0.0/0 flowid 1:30

# Xuất danh sách proxy
hostname=$(hostname -I | awk '{print $1}')
echo "Proxy list (SOCKS5 and HTTP in format IP:PORT:LOGIN:PASS):"
for i in $(seq 1 $numofproxy); do
    echo "$hostname:$socks_port:${user[$i]}:${password[$i]} (SOCKS5)"
    echo "$hostname:$http_port:${user[$i]}:${password[$i]} (HTTP)"
done
