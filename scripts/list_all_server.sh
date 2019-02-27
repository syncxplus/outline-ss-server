#!/bin/sh
command -v jq >/dev/null 2>&1 || {
  if [[ "`uname -s`" == "Linux" ]]; then
    curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/bin/jq
    chmod a+x /usr/bin/jq
  else
    brew install jq
  fi
}
function list_server {
  ip=${1}
  accounts=`curl -s -u user:123456 --connect-timeout 5 -m 5 ${ip}:8080/outline`
  port=`echo ${accounts} | jq -r '.accessKeys[0].port' 2>/dev/null`
  password=`echo ${accounts} | jq -r '.accessKeys[0].password' 2>/dev/null`
  echo ss://AEAD_CHACHA20_POLY1305:${password}@${ip}:${port}
}
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
  list_server `echo "${servers}" | awk 'FNR=="'${i}'"{print}'` &
  if [[ ${p} -lt 1 ]]; then
    p=10
    wait
  else
    p=$[${p}-1]
  fi
}
done
wait
