FROM golang:alpine as builder

WORKDIR /go/src/github.com/boynux/squid-exporter
COPY . .

# Compile the binary statically, so it can be run without libraries.
RUN CGO_ENABLED=0 GOOS=linux go install -a -ldflags '-extldflags "-s -w -static"' .
#RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -a -ldflags '-extldflags "-s -w -static"' .

#FROM scratch
FROM alpine
RUN apk --no-cache add ca-certificates
WORKDIR /usr/local/bin
COPY --from=builder /go/bin/squid-exporter squid-exporter

# Allow /etc/hosts to be used for DNS
COPY --from=builder /etc/nsswitch.conf /etc/nsswitch.conf

EXPOSE 9301

CMD /usr/local/bin/squid-exporter -squid-hostname "rpi-k3s-worker0" -squid-port 3128 -listen ":9301"
