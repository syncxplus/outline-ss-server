#!/bin/sh

[[ ! -d "${PWD}/shadowbox" ]] && mkdir ${PWD}/shadowbox
[[ ! -f "${PWD}/shadowbox/config.yml" ]] && {
  curl -kL https://raw.githubusercontent.com/syncxplus/outline-ss-server/ufo/scripts/config.yml -o ${PWD}/shadowbox/config.yml
}

VERSION=1.1.4
docker ps -a | grep shadowbox | awk '{print $1}' | xargs -I {} docker rm -f -v {}
docker run --name shadowbox --restart always -d --net host -v ${PWD}/shadowbox:/shadowbox syncxplus/shadowbox2:${VERSION}
