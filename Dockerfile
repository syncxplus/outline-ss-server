FROM golang:1.11.5-alpine3.9

LABEL maintainer="jibo@outlook.com"

RUN apk add --no-cache bash gcc git musl-dev

WORKDIR /go/src/app

COPY . .

ENV GO111MODULE=on

RUN go get -d -v ./... \
 && go install ./... \
 && mkdir /shadowbox \
 && mv config.yml /shadowbox/config.yml

ENV GIN_MODE=release

CMD ["outline-ss-server", "-config", "/shadowbox/config.yml"]
