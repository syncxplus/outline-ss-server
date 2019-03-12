FROM golang:1.12.0-alpine3.9

LABEL maintainer="jibo@outlook.com"

RUN apk add --no-cache bash curl gcc git musl-dev openssl

WORKDIR /go/src/app

COPY . .

ENV GO111MODULE=on

RUN go get -d -v ./... \
 && go install ./... \
 && mkdir /shadowbox \
 && curl -sL https://raw.githubusercontent.com/syncxplus/outline-ss-server/ufo/scripts/config.yml -o /shadowbox/config.yml \
 && openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/CN=localhost" -keyout /shadowbox/key -out /shadowbox/cert >/dev/null 2>&1

ENV GIN_MODE=release

CMD ["outline-ss-server", "-config", "/shadowbox/config.yml", "-cert", "/shadowbox/cert", "-key", "/shadowbox/key"]
