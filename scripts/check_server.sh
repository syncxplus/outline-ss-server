#!/bin/sh
ip=${1}
[[ -z "${ip}" ]] && {
  echo Missing parameter ip
  exit 1
}
accounts=`curl -s -u user:123456 --connect-timeout 10 -m 10 ${ip}:8080/outline`
port=`echo ${accounts} | jq -r '.accessKeys[0].port'`
password=`echo ${accounts} | jq -r '.accessKeys[0].password'`
[[ -z "${port}" ]] && {
  echo Failed to retrieve accessKeys from ${ip}
  exit 1
}
echo Picking port ${port}, password ${password}
go-shadowsocks2 -c ss://AEAD_CHACHA20_POLY1305:${password}@${ip}:${port} -verbose -socks :1080 &
sleep 5
findIp=`curl -s -x socks5://localhost:1080 http://checkip.amazonaws.com`
echo ${findIp}, ${ip}
if [[ "${findIp}" == "${ip}" ]]; then
  echo true
else
  echo false
fi
pkill -9 -f go-shadowsocks2
