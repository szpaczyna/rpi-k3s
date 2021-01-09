#!/bin/bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
#docker run --rm --privileged multiarch/qemu-user-static:register --reset qemu
docker buildx create --use
docker buildx inspect --bootstrap
docker buildx build --push --platform "linux/arm64/v8" -t registry.shpaq.org/cockroachdb:v20.2.3 .
