#!/usr/bin/bash
# Thanks for using.
#
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

check_root() {
	if [[ $EUID -ne 0 ]]; then
		error "You have to run this script as root."
	fi
}

Green='\033[0;32m'
Red='\033[0;31m'
Yellow='\033[0;33m'
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
NC='\033[0m'

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

configure_firewall() {
	fail=0
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
		return 0
	fi
	if [[ $fail -eq 1 ]]; then
		warning "Failed to configure the firewall, please configure by yourself."
	else
		success "Successfully configured the firewall"
	fi
}

xray_restart() {
	systemctl restart xray
	ps -ef | sed '/grep/d' | grep -q bin/xray || error "Failed to restart Xray"
	success "Successfully restarted Xray"
	read -n1 -r -p "Press any key to continue..."
    sleep 1
    menu
}

update_xray() {
	bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - install --beta
	ps -ef | sed '/grep/d' | grep -q bin/xray || error "Failed to update Xray"
	success "Successfully updated Xray"
}

uninstall_all() {
	get_info
	bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" - remove --purge
	rm -rf $info_file
	success "Uninstalled Xray-core"
	sleep 1
  menu
}

mod_uuid() {
	uuid_old=$(jq '.inbounds[].settings.clients[].id' $xray_conf || fail=1)
	[[ $(echo "$uuid_old" | jq '' | wc -l) -gt 1 ]] && error "There are multiple UUIDs, please modify by yourself"
	uuid_old=$(echo "$uuid_old" | sed 's/\"//g')
	read -rp "Please enter the password for Xray (default UUID): " passwd
	generate_uuid
	sed -i "s/$uuid_old/${uuid:-$uuidv5}/g" $xray_conf $info_file
	grep -q "$uuid" $xray_conf && success "Successfully modified the UUID" || error "Failed to modify the UUID"
	sleep 2
	xray_restart
	menu
}

mod_port() {
	port_old=$(jq '.inbounds[].port' $xray_conf || fail=1)
	[[ $(echo "$port_old" | jq '' | wc -l) -gt 1 ]] && error "There are multiple ports, please modify by yourself"
	read -rp "Please enter the port for Xray (default 443): " port
	[[ -z $port ]] && port=443
	[[ $port -gt 65535 ]] && echo "Please enter a correct port" && mod_port
	[[ $port -ne 443 ]] && configure_firewall $port
	configure_firewall
	sed -i "s/$port_old/$port/g" $xray_conf $info_file
	grep -q $port $xray_conf && success "Successfully modified the port" || error "Failed to modify the port"
	sleep 2
	xray_restart
	menu
}

show_access_log() {
	[[ -e $xray_access_log ]] && tail -f $xray_access_log || panic "The file doesn't exist"

}

show_error_log() {
	[[ -e $xray_error_log ]] && tail -f $xray_error_log || panic "The file doesn't exist"
 read -n1 -r -p "Press any key to continue..."

}

show_configuration() {
	[[ -e $info_file ]] && cat $info_file && exit 0
	panic "The info file doesn't exist"
}

clear
echo ""
echo -e " ${Yellow}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e " ${Yellow}╠═══════════════════════════════════════════════════════╣${NC}"
echo -e " ${Yellow}║   ${NC}•••───[ Moded Script By JsPhantom @ 2023 ]───•••   ${Yellow} ║${NC}"
echo -e " ${Yellow}╠═══════════════════════════════════════════════════════╣${NC}"
echo -e " ${Yellow}╠═══════════════════════════════════════════════════════╣${NC}"
echo -e " ${Yellow}║                  ${NC}───[ Lite Menu ]───                  ${Yellow}║${NC}"
echo -e " ${Yellow}╠═══════════════════════════════════════════════════════╣${NC}"
echo -e " ${Yellow}║  ${NC}[${Red}01${NC}] ${Yellow}My config           ${NC}[${Red}05${NC}] ${Yellow}Uninstall Xray-core    ${Yellow}║${NC}"
echo -e " ${Yellow}║  ${NC}[${Red}02${NC}] ${Yellow}Change My UUID      ${NC}[${Red}06${NC}] ${Yellow}Check access logs      ${Yellow}║${NC}"
echo -e " ${Yellow}║  ${NC}[${Red}03${NC}] ${Yellow}Change Port         ${NC}[${Red}07${NC}] ${Yellow}Check error logs       ${Yellow}║${NC}"
echo -e " ${Yellow}║  ${NC}[${Red}04${NC}] ${Yellow}Update Xray-core    ${NC}[${Red}08${NC}] ${Yellow}Restart Xray Service   ${Yellow}║${NC}"
echo -e " ${Yellow}╠═══════════════════════════════════════════════════════╣${NC}"
echo -e " ${Yellow}╚═══════════════════════════════════════════════════════╝${NC}"
	echo ""
echo -e "                [Ctrl + C] Exit From Script"
	echo ""
	read -rp "Please enter a number: " choice
	case $choice in
	1)
		show_configuration
		;;
	2)
		mod_uuid
		;;
	3)
		mod_port
		;;
	4)
		update_xray
		;;
	5)
		uninstall_all
		;;
	6)
		show_access_log
		;;
	7)
		show_error_log
		;;
	8)
		xray_restart
		;;
	*)
    echo -e "Please enter an correct number"
		sleep 1
    menu
		;;
	esac