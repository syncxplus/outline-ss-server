FROM alpine:3.9

LABEL maintainer="jibo@outlook.com"

RUN apk add --no-cache curl jq \
  && curl -sOL https://github.com/shadowsocks/go-shadowsocks2/releases/download/v0.0.11/shadowsocks2-linux.gz \
  && gunzip shadowsocks2-linux.gz \
  && chmod a+x shadowsocks2-linux \
  && mv shadowsocks2-linux /usr/local/bin/go-shadowsocks2

COPY check_server.sh /usr/local/bin/check_server

ENTRYPOINT ["check_server"]
