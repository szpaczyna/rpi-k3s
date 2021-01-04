#!/bin/bash
apt -y install qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --use
docker buildx inspect --bootstrap
docker buildx build --load --platform "linux/arm64" -t cockroachdb:v20.2.3 .
