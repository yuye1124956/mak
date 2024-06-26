#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "请以root用户运行."
    exit 1
fi

workdir="/root/name.com"

if [ ! -d "$workdir" ]; then
   mkdir -p "$workdir"
fi

read -p "请输入用户名: " name
read -p "请输入令牌: " token
read -p "请输入域名: " domain
read -p "请输入CFNS: " NS
read -p "请输入CFNS2: " NS2

cat > "$workdir/name.sh" <<EOF
#!/bin/bash
curl -u '$name:$token' 'https://api.name.com/v4/domains/$domain:setNameservers' -X POST -H 'Content-Type: application/json' --data '{"nameservers":["ns1.name.com","ns2.name.com","ns3.name.com","ns4.name.com"]}'
EOF

cat > "$workdir/cloudflare.sh" <<EOF
#!/bin/bash
curl -u '$name:$token' 'https://api.name.com/v4/domains/$domain:setNameservers' -X POST -H 'Content-Type: application/json' --data '{"nameservers":["$NS","$NS2"]}'
EOF

chmod +x "$workdir"/*.sh

(crontab -l 2>/dev/null; echo "0 2 * * * $workdir/cloudflare.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 5 * * * $workdir/name.sh") | crontab -

echo "定时任务已添加: $workdir/cloudflare.sh 每天凌晨2点, $workdir/name.sh 每天凌晨5点"

echo "当前crontab任务列表:"
crontab -l

echo "手动运行脚本以测试:"
echo "运行 $workdir/cloudflare.sh"
$workdir/cloudflare.sh
echo "运行 $workdir/name.sh"
$workdir/name.sh

echo "请查看 /var/log/cron 或 /var/log/syslog 以确认cron任务是否正常运行."
