#!/usr/bin/env sh
set -x
curl -OL https://raw.githubusercontent.com/syncxplus/outline-ss-server/ufo/scripts/v2ray.json
docker rm -v -f v2ray
docker run --name v2ray --net host --restart always -v ${PWD}/v2ray.json:/etc/v2ray/config.json -d v2ray/official
