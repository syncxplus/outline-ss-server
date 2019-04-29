#!/bin/sh

servers=`curl -ks https://api.ufovpn.io/api/v3/get-server-monitor-info/ | jq '.[].targets.free' | grep 8080 | awk '{l=index($0,"\"");a=substr($0,l+1);print a;}' | awk '{r=index($0,":");a=substr($0,0,r-1);print a;}' | xargs -I {} echo ssh -i ~/.ssh/testbird.pem -o stricthostkeychecking=no cloudsigma@{} sudo docker pull syncxplus/shadowbox2:1.1.12`

total=`echo "${servers}" | awk 'END{print NR}'`
echo Count server: ${total}

p=50
for i in `seq 1 ${total}`; do {
  c=`echo "${servers}" | awk 'FNR=="'${i}'"{print}'`
  $c &
  if [[ ${p} -lt 1 ]]; then
    p=50
    wait
  else
    p=$[${p}-1]
  fi
}
done
wait
