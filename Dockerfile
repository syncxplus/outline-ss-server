FROM golang:1.12.0-alpine3.9

LABEL maintainer="jibo@outlook.com"

RUN apk add --no-cache bash curl gcc git musl-dev

WORKDIR /go/src/app

COPY . .

ENV GO111MODULE=on

RUN go get -d -v ./... \
 && go install ./... \
 && mkdir /shadowbox \
 && curl -sL https://raw.githubusercontent.com/syncxplus/outline-ss-server/ufo/scripts/config.yml -o /shadowbox/config.yml

ENV GIN_MODE=release

CMD ["outline-ss-server", "-config", "/shadowbox/config.yml"]
