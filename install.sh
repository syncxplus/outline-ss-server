#!/bin/sh

docker ps -a | grep shadowbox | awk '{print $1}' | xargs -I {} docker rm -f -v {}
docker images -a | grep shadowbox | awk '{print $3}' | xargs -I {} docker rmi {}
VERSION=1.1.1
docker run --name shadowbox --restart always -d --net host -v $PWD/shadowbox:/shadowbox syncxplus/shadowbox2:${VERSION}
