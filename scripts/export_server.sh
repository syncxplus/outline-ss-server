#!/usr/bin/env bash
echo Exporting server ...
admin=$(echo $1 | tr [A-Z] [a-z])
[[ -z "${admin}" ]] && {
  echo Missing domain name
  exit 1
}
curl -ks https://${admin}/api/v3/get-server-monitor-info/ | jq '.[]' | jq '.targets.free, .labels' | sed 's/\[/},{"targets":\[/1' | sed 's/\]/\],"labels":/1' | sed '1 s/},/[/1' | awk '{print $0} END{print "}]"}' > ss-free.json
curl -ks https://${admin}/api/v3/get-server-monitor-info/ | jq '.[]' | jq '.targets.charge, .labels' | sed 's/\[/},{"targets":\[/1' | sed 's/\]/\],"labels":/1' | sed '1 s/},/[/1' | awk '{print $0} END{print "}]"}' > ss-vip.json
echo Finish
