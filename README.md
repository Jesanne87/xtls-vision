### Super-Lite-vless-vision
xtls-rprx-vision

```
wget https://raw.githubusercontent.com/Jesanne87/xtls-vision/main/xtls-vision.sh && chmod +x xtls-vision.sh && ./xtls-vision.sh
```

```
sysctl -w net.ipv6.conf.all.disable_ipv6=1 && sysctl -w net.ipv6.conf.default.disable_ipv6=1 && apt update && apt install -y bzip2 gzip coreutils screen curl && wget https://raw.githubusercontent.com/Jesanne87/xtls-vision/main/xtls-vision.sh && chmod +x xtls-vision.sh && sed -i -e 's/\r$//' xtls-vision.sh && screen -S xtls-vision ./xtls-vision.sh
```
