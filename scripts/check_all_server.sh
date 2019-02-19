#!/bin/sh
command -v ./go-shadowsocks2 >/dev/null 2>&1 || {
  if [[ "`uname -s`" == "Linux" ]]; then
    url=https://github.com/shadowsocks/go-shadowsocks2/releases/download/v0.0.11/shadowsocks2-linux.gz
  else
    url=https://github.com/shadowsocks/go-shadowsocks2/releases/download/v0.0.11/shadowsocks2-macos.gz
  fi
  curl -L ${url} -o go-shadowsocks2.gz \
  && gunzip go-shadowsocks2.gz \
  && chmod a+x go-shadowsocks2
}
command -v jq >/dev/null 2>&1 || {
  if [[ "`uname -s`" == "Linux" ]]; then
    curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/bin/jq
    chmod a+x /usr/bin/jq
  else
    brew install jq
  fi
}
function clear {
  pkill -SIGKILL -f go-shadowsocks2 >/dev/null 2>&1
}
function check_server {
  ip=${1}
  proxyPort=${2}
  accounts=`curl -s -u user:123456 --connect-timeout 5 -m 5 ${ip}:8080/outline`
  port=`echo ${accounts} | jq -r '.accessKeys[0].port' 2>/dev/null`
  password=`echo ${accounts} | jq -r '.accessKeys[0].password' 2>/dev/null`
  ./go-shadowsocks2 -c ss://AEAD_CHACHA20_POLY1305:${password}@${ip}:${port} -socks :${proxyPort} >/dev/null 2>&1 &
  sleep 3
  findIp=`curl -s -x socks5://localhost:${proxyPort} http://checkip.amazonaws.com`
  if [[ "${findIp}" == "${ip}" ]]; then
    echo ${ip} success
  else
    echo ${ip} failed
  fi
}
clear
admin=$(echo $1 | tr [A-Z] [a-z])
[[ -z "${admin}" ]] && {
  echo Missing domain name
  exit 1
}
response=`curl -ks https://${admin}/api/v3/get-server-monitor-info/`
servers=`echo ${response} | jq -r '.[].targets.charge,.[].targets.free' | grep 8080 | awk '{l=index($0,"\"");a=substr($0,l+1);print a;}' | awk '{r=index($0,":");a=substr($0,0,r-1);print a;}'`
total=`echo "${servers}" | awk 'END{print NR}'`
echo Count server: ${total}
p=10
for i in `seq 1 ${total}`; do {
  check_server `echo "${servers}" | awk 'FNR=="'${i}'"{print}'` $[8000+${p}] &
  if [[ ${p} -lt 1 ]]; then
    p=10
    wait
    clear
  else
    p=$[${p}-1]
  fi
}
done
wait
