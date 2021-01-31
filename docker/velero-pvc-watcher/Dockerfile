FROM golang:1.13-buster AS build
COPY . /go/src/velero-pvc-watcher
WORKDIR /go/src/velero-pvc-watcher
RUN GOARCH=arm64 CGO_ENABLED=0 GOOS=linux go build -v -o /go/bin/velero-pvc-watcher .


FROM alpine
COPY --from=build /go/bin/velero-pvc-watcher /
ENTRYPOINT /velero-pvc-watcher
