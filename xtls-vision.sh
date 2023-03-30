#!/usr/bin/bash
# Thanks for using.

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
stty erase ^?
script_version="1.1.84"
xray_dir="/usr/local/etc/xray"
xray_log_dir="/var/log/xray"
xray_access_log="$xray_log_dir/access.log"
xray_error_log="$xray_log_dir/error.log"
xray_conf="/usr/local/etc/xray/config.json"
cert_dir="/usr/local/etc/xray"
info_file="$HOME/xray.inf"

if [[ $EUID -ne 0 ]]; then
error "You have to run this script as root."
fi

Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

info() {
	echo "[*] $*"
}

error() {
	echo -e "${Red}[-]${Font} $*"
	exit 1
}

success() {
	echo -e "${Green}[+]${Font} $*"
}

warning() {
	echo -e "${Yellow}[*]${Font} $*"
}

panic() {
	echo -e "${RedBG}$*${Font}"
	exit 1
}

ol_version=$(curl -sL github.com/Jesanne87/xtls-vision/raw/vision/xtls-vision.sh | grep "script_version=" | head -1 | awk -F '=|"' '{print $3}')
if [[ ! $(echo -e "$ol_version\n$script_version" | sort -rV | head -n 1) == "$script_version" ]]; then
wget -O xray-yes-en.sh github.com/Jesanne87/xtls-vision/raw/vision/xtls-vision.sh || fail=1
[[ $fail -eq 1 ]] && warning "Failed to update" && sleep 2 && return 0
success "Successfully updated"
sleep 2
./xtls-vision.sh "$*"
exit 0
fi

read -rp "Your domain: " xray_domain
[[ -z $xray_domain ]] && install_all
echo ""
echo "Method:"
echo ""
echo "1. IPv4 only"
echo "2. IPv6 only"
echo "3. IPv4 & IPv6"
echo ""
read -rp "Enter a number (default IPv4 only): " ip_type
[[ -z $ip_type ]] && ip_type=1
if [[ $ip_type -eq 1 ]]; then
domain_ip=$(ping -4 "$xray_domain" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
server_ip=$(curl -sL https://api64.ipify.org -4) || fail=1
[[ $fail -eq 1 ]] && error "Failed to get local IP address"
[[ "$server_ip" == "$domain_ip" ]] && success "The domain name has been resolved to the local IP address" && success=1
if [[ $success -ne 1 ]]; then
warning "The domain name is not resolved to the local IP address, the certificate issuance may fail"
read -rp "Continue? (yes/no): " choice
case $choice in
yes)
;;
y)
;;
no)
exit 1
;;
n)
exit 1
;;
*)
exit 1
;;
esac
fi
elif [[ $ip_type -eq 2 ]]; then
domain_ip=$(ping -6 "$xray_domain" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
server_ip=$(curl -sL https://api64.ipify.org -6) || fail=1
[[ $fail -eq 1 ]] && error "Failed to get the local IP address"
[[ "$server_ip" == "$domain_ip" ]] && success "The domain name has been resolved to the local IP address" && success=1
if [[ $success -ne 1 ]]; then
warning "The domain name is not resolved to the local IP address, the certificate issuance may fail"
read -rp "Continue? (yes/no):" choice
case $choice in
yes)
;;
y)
;;
no)
exit 1
;;
n)
exit 1
;;
*)
exit 1
;;
esac
fi
elif [[ $ip_type -eq 3 ]]; then
domain_ip=$(ping -4 "$xray_domain" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
server_ip=$(curl -sL https://api64.ipify.org -4) || fail=1
[[ $fail -eq 1 ]] && error "Failed to get the local IP address (IPv4)"
[[ "$server_ip" == "$domain_ip" ]] && success "The domain name has been resolved to the local IP address (IPv4)" && success=1
if [[ $success -ne 1 ]]; then
warning "The domain name is not resolved to the local IP address (IPv4), the certificate issuance may fail"
read -rp "Continue? (yes/no):" choice
case $choice in
yes)
;;
y)
;;
no)
exit 1
;;
n)
exit 1
;;
*)
exit 1
;;
esac
fi
domain_ip6=$(ping -6 "$xray_domain" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
server_ip6=$(curl -sL https://api64.ipify.org -6) || fail=1
[[ $fail -eq 1 ]] && error "Failed to get the local IP address (IPv6)"
[[ "$server_ip" == "$domain_ip" ]] && success "The domain name has been resolved to the local IP address (IPv6)" && success=1
if [[ $success -ne 1 ]]; then
warning "The domain name is not resolved to the local IP address (IPv6), the certificate application may fail"
read -rp "Continue? (yes/no):" choice
case $choice in
yes)
;;
y)
;;
no)
exit 1
;;
n)
exit 1
;;
*)
exit 1
;;
esac
fi
else
error "Please enter a correct number"
fi
read -rp "Please enter the passwd for xray (default UUID): " passwd
read -rp "Please enter the port for xray (default 443): " port
[[ -z $port ]] && port=443
[[ $port -gt 65535 ]] && echo "Please enter a correct port" && install_all
configure_firewall
success "Everything is ready, the installation is about to start."

source /etc/os-release || source /usr/lib/os-release || panic "The operating system is not supported"
if [[ $ID == "centos" ]]; then
PM="yum"
INS="yum install -y"
elif [[ $ID == "debian" || $ID == "ubuntu" ]]; then
PM="apt-get"
INS="apt-get install -y"
else
error "The operating system is not supported"
fi

if [[ $(type -P ufw) ]]; then
if [[ $port -ne 443 ]]; then
ufw allow $port/tcp || fail=1
ufw allow $port/udp || fail=1
success "Successfully opened port $port"
fi
ufw allow 22,80,443/tcp || fail=1
ufw allow 1024:65535/udp || fail=1
yes|ufw enable || fail=1
yes|ufw reload || fail=1
elif [[ $(type -P firewalld) ]]; then
systemctl start --now firewalld
if [[ $port -ne 443 ]]; then
firewall-offline-cmd --add-port=$port/tcp || fail=1
firewall-offline-cmd --add-port=$port/udp || fail=1
success "Successfully opened port $port"
fi
firewall-offline-cmd --add-port=22/tcp --add-port=80/tcp --add-port=443/tcp || fail=1
firewall-offline-cmd --add-port=1024-65535/udp || fail=1
firewall-cmd --reload || fail=1
else
warning "Please configure the firewall by yourself."
fi
if [[ $fail -eq 1 ]]; then
warning "Failed to configure the firewall, please configure by yourself."
else
success "Successfully configured the firewall"
fi

if ss -tnlp | grep -q ":80 "; then
error "Port 80 is occupied (it's required for certificate application)"
fi
if [[ $port -eq "443" ]] && ss -tnlp | grep -q ":443 "; then
error "Port 443 is occupied"
elif ss -tnlp | grep -q ":$port "; then
error "Port $port is occupied"
fi

echo -e [Info] "Installing the software packages"
rpm_packages="tar zip unzip openssl lsof git jq socat crontabs"
apt_packages="tar zip unzip openssl lsof git jq socat cron"
if [[ $PM == "apt-get" ]]; then
$PM update
$INS wget curl ca-certificates
update-ca-certificates
$PM update
$INS $apt_packages
elif [[ $PM == "yum" || $PM == "dnf" ]]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
$INS wget curl ca-certificates epel-release
update-ca-trust force-enable
$INS $rpm_packages
fi
success "Successfully installed the packages"
info "Installing acme.sh"
curl -L get.acme.sh | bash || error "Failed to install acme.sh"
success "Successfully installed acme.sh"

info "Installing Xray"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install --version 1.7.5
ps -ef | sed '/grep/d' | grep -q bin/xray || error "Failed to install Xray"
success "Successfully installed Xray"

	[[ -z $passwd ]] && uuid=$(xray uuid) || uuidv5=$(xray uuid -i "$passwd") || error "Failed to generate UUID"

	info "Issuing a ssl certificate"
	/root/.acme.sh/acme.sh --issue \
		-d "$xray_domain" \
		--server letsencrypt \
		--keylength ec-256 \
		--fullchain-file $cert_dir/cert.pem \
		--key-file $cert_dir/key.pem \
		--standalone \
		--force || error "Failed to issue a ssl certificate"
	success "Successfully issued a ssl certificate"
	chmod 600 $cert_dir/*.pem
	if id nobody | grep -q nogroup; then
		chown nobody:nogroup $cert_dir/*.pem
	else
		chown nobody:nobody $cert_dir/*.pem
	fi

	xtls_flow="xtls-rprx-vision"
	cat > $xray_conf << EOF
{
  "log": {
    "access": "$xray_access_log",
    "error": "$xray_error_log",
    "loglevel": "warning"
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "port": $port,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${passwd:-$uuid}",
            "flow": "$xtls_flow"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "minVersion": "1.2",
          "certificates": [
            {
              "certificateFile": "$cert_dir/cert.pem",
              "keyFile": "$cert_dir/key.pem"
            }
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ]
}
EOF

	systemctl restart xray
	ps -ef | sed '/grep/d' | grep -q bin/xray || error "Failed to restart Xray"
	success "Successfully restarted Xray"
	sleep 2
	
	crontab -l | grep -q Xray || echo -e "$(crontab -l)\n0 0 * * * /usr/bin/bash -c \"\$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)\"" | crontab || warning "Failed to add a cron job with crontab"

	success "Successfully installed Xray (VLESS XTLS Vision)"
	echo ""
	echo ""
	echo -e "$Green Xray configuration $Font" | tee $info_file
	echo -e "$Green Address: $Font $server_ip " | tee -a $info_file
	echo -e "$Green Port: $Font $port " | tee -a $info_file
	echo -e "$Green UUID/Passwd: $Font ${passwd:-$uuid}" | tee -a $info_file
	echo -e "$Green Flow: $Font $xtls_flow" | tee -a $info_file
	echo -e "$Green SNI: $Font $xray_domain" | tee -a $info_file
	echo -e "$Green TLS: $Font ${RedBG}TLS${Font}" | tee -a $info_file
	echo ""
	echo -e "$Green Share link: $Font vless://${uuidv5:-$uuid}@$xray_domain:$port?flow=$xtls_flow&security=tls&sni=$xray_domain#$xray_domain" | tee -a $info_file
	echo ""
	#echo -e "${GreenBG} Tip: ${Font}You can use flow control ${RedBG}xtls-rprx-splice${Font} on the Linux platform to get better performance."


#cd /usr/bin
#wget -O menu "https://raw.githubusercontent.com/Jesanne87/xtls-vision/main/menu.sh"
#chmod +x menu
#rm -f menu.sh
#cd

