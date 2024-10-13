 #!/usr/bin/env bash

# Author - akmaslov-dev
# Modified by ThienTranJP
# Simple script to setup dante socks proxy server
# Should work on Debian, Ubuntu and CentOS

# Check for bash shell
if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit 1
fi

# Checking for root permission
if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, but you need to run this script as root"
	exit 2
fi

# Checking for distro type (Debian, Ubuntu or CentOS)
if [[ -e /etc/debian_version ]]; then
	OStype=deb
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	OStype=centos
else
	echo "You should only run this installer on Debian, Ubuntu or CentOS"
	exit 3
fi

# Checking for previous installation with this script
if [[ -e /etc/sockd.conf ]]; then
    while : ; do
	clear
		echo "Dante socks proxy is already installed."
		echo " "
		echo "What do you want to do now?"
		echo "	1) Xem danh sách proxy hiện có"
		echo "	2) Thêm một proxy user mới"
		echo "	3) Xóa một proxy user"
		echo "	4) Xóa toàn bộ cấu hình server proxy"
		echo "	5) Thay đổi giới hạn tốc độ proxy"
		echo "	6) Exit"
		read -p "Select an option [1-4]: " option
		case $option in
			1)
				hostname=$(hostname -I | awk '{print $1}')
				for i in $(seq 1 $numofproxy); do
					if [[ -n "${user[$i]}" ]]; then
						echo "$hostname:$port:${user[$i]}:${password[$i]}"
					fi
				done
				;;
			2)
				# Creating new user for proxy
				echo " "
				# Getting new Login
				read -p "Please enter the name for new proxy user: " -e -i proxyuser usernew
				echo " "
				# Getting new password for new user
				while true; do
					read -s -p "Now we need a VERY, VERY STRONG PASSWORD for new proxy user: " passwordnew
					echo " "
					read -s -p "Please retype your password (again): " passwordnew2
					echo " "
					[ "$passwordnew" = "$passwordnew2" ] && break
					echo "Password and password confirmation does not match"
					echo " "
					echo "Please try again"
					echo " "
				done
				# Check if user name is not empty
				if [[ -z "$usernew" ]]; then
					echo "Error: Username cannot be empty."
					exit 1
				fi
				# Creating new proxy user
				useradd -M -s /usr/sbin/nologin -p "$(openssl passwd -1 "$passwordnew")" "$usernew"
				echo " "
				echo "New user added!"
				exit
				;;
			3)
				# Deleting an existing user
				read -p "Please enter the name of the user to delete: " deluser
				echo " "
				if getent passwd "$deluser" > /dev/null 2>&1; then
					userdel "$deluser"
					echo "User $deluser deleted!"
				else
					echo "Cannot find user with this name!"
				fi
				exit
				;;
			4)
				echo " "
				read -p "Do you really want to remove Dante socks proxy server? [y/n]: " -e -i n REMOVE
				if [[ "$REMOVE" = 'y' ]]; then
					if [[ "$OStype" = 'deb' ]]; then
						# If deb based distro
						systemctl stop sockd
						update-rc.d -f sockd remove
						rm -f /etc/init.d/sockd
						rm -f /etc/sockd.conf
						rm -f /usr/sbin/sockd
						echo " "
						echo "Dante socks proxy server deleted!"
					else
						# If CentOS
						systemctl stop sockd
						systemctl disable sockd
						rm -f /etc/systemd/system/sockd.service
						rm -f /usr/sbin/sockd
						rm -f /etc/sockd.conf
						systemctl daemon-reload
						systemctl reset-failed
						# Checking for firewalld
						if pgrep firewalld > /dev/null; then
							delport="$(grep 'port =' /etc/sockd.conf | awk '{print $5}')"
							firewall-cmd --zone=public --remove-port="$delport"/tcp
							firewall-cmd --zone=public --remove-port="$delport"/udp
							firewall-cmd --runtime-to-permanent
							firewall-cmd --reload
						fi
						echo " "
						echo "Dante socks proxy server deleted!"
					fi
				else
					echo " "
					echo "Removal process aborted!"
				fi
				exit
				;;
			5)
                # Change proxy speed limit
                echo "Enter new limit in Mbps (e.g., 100 for 100Mbps):"
                read -p "New limit: " newlimit

                # Remove existing traffic control settings
                tc qdisc del dev $interface root

                # Apply new traffic control settings with the specified limit
                tc qdisc add dev $interface root handle 1: htb default 30
                tc class add dev $interface parent 1: classid 1:1 htb rate ${newlimit}mbit ceil ${newlimit}mbit
                tc class add dev $interface parent 1:1 classid 1:30 htb rate ${newlimit}mbit ceil ${newlimit}mbit

                # Apply filter for traffic control
                tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip src 0.0.0.0/0 flowid 1:30
                tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip dst 0.0.0.0/0 flowid 1:30

                echo "Traffic limit updated to ${newlimit}Mbps"
                ;;
			;;
			6)
				# Just exit this script
				exit;;
		esac
	done
else
	clear
	# Obtaining name for system LAN interface
	interface="$(ip -o -4 route show to default | awk '{print $5}')"
	# Kiểm tra nếu người dùng nhập vào port hợp lệ
	while true; do
		read -p "Please enter the port number for our proxy server:  " -e -i 1080 port
		if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
			break
		else
			echo "Invalid input! Please enter a valid port number (1-65535)."
		fi
	done
	echo " "

    # Kiểm tra và mở cổng với UFW và iptables
    # Check if UFW is active and open the specified port if needed
    if sudo ufw status | grep -q "Status: active"; then
        sudo ufw allow "$port"/tcp
        echo "Port $port opened in UFW."
    else
        echo "UFW is not active or port $port is already open."
    fi

    # Check if iptables is active and open the specified port if needed
    if sudo iptables -L | grep -q "ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:$port"; then
        echo "Port $port is already open in iptables."
    else
        sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
        echo "Port $port opened in iptables."
    fi    

	# Kiểm tra nếu người dùng nhập vào số lượng proxy hợp lệ
	while true; do
		read -p "Please enter the number of proxies to create: " -e numofproxy
		if [[ "$numofproxy" =~ ^[0-9]+$ ]] && [ "$numofproxy" -ge 1 ]; then
			break
		else
			echo "Invalid input! Please enter a valid number of proxies (greater than 0)."
		fi
	done
	echo " "

	# Hỏi người dùng về giới hạn băng thông (Mbps)
	read -p "Please enter the bandwidth limit in Mbps (e.g., 100 for 100Mbps): " limit

	# Kiểm tra nếu người dùng nhập vào là một số hợp lệ
	if ! [[ "$limit" =~ ^[0-9]+$ ]]; then
		echo "Invalid input! Please enter a valid number."
		exit 1
	fi
	
	# Generate random username and password for each proxy
	for i in $(seq 1 $numofproxy); do
		user[$i]=$(openssl rand -base64 8 | tr -dc 'a-zA-Z' | head -c 8)
		password[$i]=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)
	done

	# Installing minimal requirements
	if [[ "$OStype" = 'deb' ]]; then
		# If deb based distro
		apt-get update
		apt-get -y install openssl make gcc
	else
		# Else, the distro is CentOS
		yum -y install epel-release
		yum -y install openssl make gcc
	fi

	# Getting Dante 1.4.3
	wget https://www.inet.no/dante/files/dante-1.4.3.tar.gz
	# Unpacking
	tar xvfz dante-1.4.3.tar.gz && cd dante-1.4.3 || exit 4
	# Configuring Dante
	./configure \
	--prefix=/usr \
	--sysconfdir=/etc \
	--localstatedir=/var \
	--disable-client \
	--without-libwrap \
	--without-bsdauth \
	--without-gssapi \
	--without-krb5 \
	--without-upnp \
	--without-pam
	# Compiling Dante
	make && make install

	# Creating /etc/sockd.conf
	cat > /etc/sockd.conf <<-EOF
	internal: $interface port = $port
	external: $interface
	user.privileged: root
	user.unprivileged: nobody
	socksmethod: username
	logoutput: /var/log/sockd.log
	client pass {
		from: 0.0.0.0/0 to: 0.0.0.0/0
		log: error
		socksmethod: username
	}
	socks pass {
		from: 0.0.0.0/0 to: 0.0.0.0/0
		command: bind connect udpassociate
		log: error
		socksmethod: username
	}
	EOF

	# Creating new users for proxy
	for i in $(seq 1 $numofproxy); do
		# Check if username is valid
		if [[ -z "${user[$i]}" ]]; then
			echo "Error: Generated username is empty. Skipping user $i."
			continue
		fi
		useradd -M -s /usr/sbin/nologin "${user[$i]}"
		echo "${user[$i]}:${password[$i]}" | chpasswd
	done

	# Creating services
	if [[ "$OStype" = 'deb' ]]; then
		# Creating sockd daemon for Debian/Ubuntu
		cat > /etc/systemd/system/sockd.service <<-'EOF'
		[Unit]
		Description=Dante Socks Proxy v1.4.3
		After=network.target

		[Service]
		Type=forking
		PIDFile=/var/run/sockd.pid
		ExecStart=/usr/sbin/sockd -D -f /etc/sockd.conf
		ExecReload=/bin/kill -HUP $MAINPID
		KillMode=process
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
		EOF

		# Restarting systemctl daemon
		systemctl daemon-reload
		# Enabling autostart for sockd service
		systemctl enable sockd
		# Starting sockd daemon
		systemctl start sockd
	else
		# Creating systemctl service for CentOS
		cat > /etc/systemd/system/sockd.service <<-'EOF'
		[Unit]
		Description=Dante Socks Proxy v1.4.3
		After=network.target

		[Service]
		Type=forking
		PIDFile=/var/run/sockd.pid
		ExecStart=/usr/sbin/sockd -D -f /etc/sockd.conf
		ExecReload=/bin/kill -HUP $MAINPID
		KillMode=process
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
		EOF

		# Restarting systemctl daemon
		systemctl daemon-reload
		# Enabling autostart for sockd service
		systemctl enable sockd
		# Starting service
		systemctl start sockd
	fi

	# Set up traffic control (tc) for bandwidth limitation với limit người dùng nhập vào
	tc qdisc add dev $interface root handle 1: htb default 30
	tc class add dev $interface parent 1: classid 1:1 htb rate ${limit}mbit ceil ${limit}mbit
	tc class add dev $interface parent 1:1 classid 1:30 htb rate ${limit}mbit ceil ${limit}mbit

	# Giới hạn toàn bộ traffic qua $interface với giá trị $limit Mbps
	tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip src 0.0.0.0/0 flowid 1:30
	tc filter add dev $interface protocol ip parent 1:0 prio 1 u32 match ip dst 0.0.0.0/0 flowid 1:30

	# In ra thông báo xác nhận giới hạn băng thông đã được thiết lập
	echo "Traffic control applied, limiting to ${limit}Mbps for upload and download"

	# Output proxy list to console
	hostname=$(hostname -I | awk '{print $1}')
	for i in $(seq 1 $numofproxy); do
		if [[ -n "${user[$i]}" ]]; then
			echo "$hostname:$port:${user[$i]}:${password[$i]}"
		fi
	done
	# Output proxy information to a file
	# hostname=$(hostname -I | awk '{print $1}')
	# output_file=~/proxy_info.txt
	# for i in $(seq 1 $numofproxy); do
	# 	if [[ -n "${user[$i]}" ]]; then
	# 		echo "$hostname:$port:${user[$i]}:${password[$i]}" >> "$output_file"
	# 	fi
	# done
	# cat "$output_file"

	# # Transfer the file to a remote machine (replace with your own details)
	# remote_user="root"
	# remote_host="192.168.0.196"
	# remote_path="/root/"

	# scp "$output_file" "$remote_user@$remote_host:$remote_path"

	# Print success message
	echo "All Done and Success by ThienTranJP"
fi
