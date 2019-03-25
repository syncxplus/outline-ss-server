#!/bin/sh

DATA_DIR=${PWD}/shadowbox

[[ ! -d "${DATA_DIR}" ]] && mkdir ${DATA_DIR}

[[ ! -f "${DATA_DIR}/config.yml" ]] && {
  curl -kL https://raw.githubusercontent.com/syncxplus/outline-ss-server/ufo/scripts/config.yml -o ${DATA_DIR}/config.yml
}

CERT=${DATA_DIR}/cert
KEY=${DATA_DIR}/key

[[ ! -f "${CERT}" || ! -f "${KEY}" ]] && {
  rm -rf "${CERT}" "${KEY}"
  IP=`curl checkip.amazonaws.com`
  command -v openssl >/dev/null 2>&1 || {
    if [[ -f "/etc/redhat-release" ]]; then
      yum install -y openssl
    elif [[ -f "/etc/lsb-release" ]]; then
      apt-get install -y openssl
    fi
  }
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/CN=${IP}" -keyout "${KEY}" -out "${CERT}" >/dev/null 2>&1
}

VERSION=1.1.9
docker pull syncxplus/shadowbox2:${VERSION}
docker ps -a | grep shadowbox | awk '{print $1}' | xargs -I {} docker rm -f -v {}
docker run --name shadowbox --restart always -d --net host -v ${DATA_DIR}:/shadowbox syncxplus/shadowbox2:${VERSION}
