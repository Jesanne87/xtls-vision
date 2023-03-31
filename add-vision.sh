#!/bin/bash
export MYIP=$(curl -sS ipv4.icanhazip.com)
Green='\033[32m'
Red='\033[31m'
Yellow='\033[33m'
NC='\033[0m'
# // TOTAL ACC CREATE  VLESS TCP XTLS
export total3=$(grep -c -E "^#xray-vless-xtls" "/usr/local/etc/xray/config.json")
if [[ "$MYIP" = "" ]]; then
     domain=$(cat /usr/local/etc/xray/domain)
else
     domain=$IP
fi
# CREATE USER VLESS XTLS
function menu1 () {
clear
xtls="$(cat ~/xray.inf | grep -w "Port" | cut -d: -f2|sed 's/ //g')"
echo -e " ${Yellow}┌──────────────────────────────────────────────────────┐\e[m"
echo -e " ${Yellow}│             CREATE USER XRAY VLESS XTLS               ${Yellow}│\e[m"
echo -e " ${Yellow}└──────────────────────────────────────────────────────┘ \e[m"
until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		read -rp "Username: " -e user
		CLIENT_EXISTS=$(grep -w $user /usr/local/etc/xray/config.json | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
			echo ""
			echo "A client with the specified name was already created, please choose another name."
			exit 1
		fi
	done
export uuid=$(cat /proc/sys/kernel/random/uuid)
read -p "Bug Address (Example: www.google.com) : " address
read -p "Bug SNI/Host (Example : m.facebook.com) : " sni
read -p "Expired (days) : " masaaktif

bug_addr=${address}.
bug_addr2=$address
if [[ $address == "" ]]; then
sts=$bug_addr2
else
sts=$bug_addr
fi

export exp=`date -d "$masaaktif days" +"%Y-%m-%d"`
export harini=`date -d "0 days" +"%Y-%m-%d"`

sed -i '/#xray-vless-xtls$/a\#vxtls '"$user $exp $harini $uuid"'\
},{"id": "'""$uuid""'","flow": "'""xtls-rprx-vision""'","level": '"0"',"email": "'""$user""'"' /usr/local/etc/xray/config.json

export vlesslink1="vless://${uuid}@${sts}${domain}:$xtls?security=xtls&encryption=none&headerType=none&type=tcp&flow=xtls-rprx-vision&sni=$sni#${user}"

systemctl restart xray.service

clear
echo -e ""
echo -e " ${Yellow}┌──────────────────────────────────────────────────────┐${NC}"
echo -e " ${Yellow}│                   XRAY VLESS XTLS                    ${Yellow}│${NC}"
echo -e " ${Yellow}└──────────────────────────────────────────────────────┘ ${NC}"
echo -e "Remarks        : ${user}"
echo -e "Domain         : ${domain}"
echo -e "Ip/Host        : ${MYIP}"
echo -e "Port Xtls      : $xtls"
echo -e "User ID        : ${uuid}"
echo -e "Encryption     : None"
echo -e "Network        : TCP"
echo -e "Flow           : xtls-rprx-vision"
echo -e "allowInsecure  : True"
echo -e " ${Yellow}•────────────────•\e[m"
echo -e "Link Xtls Direct  : ${vlesslink1}"
echo -e " ${Yellow}•────────────────•\e[m"
echo -e "Created  : $harini"
echo -e "Expired  : $exp"
echo ""
read -n 1 -s -r -p "Press any key to back on menu"
menu
}

# MENU XRAY VMESS & VLESS
clear

echo -e "   ${Yellow}┌──────────────────────────────────────────────────────┐\e[m"
echo -e "   ${Yellow}│               XRAY VLESS TCP TLS(Vision)             ${Yellow}│\e[m"
echo -e "   ${Yellow}└──────────────────────────────────────────────────────┘\e[m"
echo -e "      [\e[${Yellow} 01${NC}] • Create Xray VLess Xtls Account\e[m"
echo -e "      [\e[${Yellow} 08${NC}] • Trial User Vless Xtls\e[m"
echo -e "      [\e[${Yellow} 09${NC}] • Deleting Xray Vless Xtls Account\e[m"
echo -e "      [\e[${Yellow} 10${NC}] • Renew Xray Vless Xtls Account\e[m"
echo -e "      [\e[${Yellow} 11${NC}] • Show Config Vless Xtls Account\e[m"
echo -e "      [\e[${Yellow} 12${NC}] • Check User Login Vless Xtls\e[m"
echo -e ""
echo -e "   ${Yellow}    >> Total :${Yellow} ${total3} Client\e[m"
echo -e ""
echo -e "                 Press [ x ] To Go Main Menu "
echo -e ""
read -rp "        Please Input Number  [1-12 or x] :  "  num
echo -e ""
if [[ "$num" = "1" ]]; then
menu1
elif [[ "$num" = "2" ]]; then
menu8
elif [[ "$num" = "3" ]]; then
menu9
elif [[ "$num" = "4" ]]; then
menu10
elif [[ "$num" = "5" ]]; then
menu11
elif [[ "$num" = "6" ]]; then
menu12
elif [[ "$num" = "7" ]]; then
menu13
elif [[ "$num" = "8" ]]; then
menu14
elif [[ "$num" = "9" ]]; then
menu15
elif [[ "$num" = "10" ]]; then
menu16
elif [[ "$num" = "11" ]]; then
menu17
elif [[ "$num" = "12" ]]; then
menu18
elif [[ "$num" = "x" ]]; then
xray-menu
else
echo -e "\e[1;31mYou Entered The Wrong Number, Please Try Again!\e[0m"
sleep 1
add-vision.sh
fi