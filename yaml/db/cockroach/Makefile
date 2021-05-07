VERSION?=v20.2.8
REGISTRY="registry.shpaq.org"
IMAGE=cockroachdb
HUB=szpaczyn
HUB_IMAGE=cockroachdb-arm64

default: build-push

reset-env:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name multiarch --driver docker-container --use
	docker buildx inspect --bootstrap

build-push:
	docker buildx build --push --platform linux/arm64 -t ${REGISTRY}/${IMAGE}:${VERSION} .

build-hub:
	docker buildx build --push --platform linux/arm64 -t ${HUB}/${HUB_IMAGE}:${VERSION} .

build-local:
	docker buildx build --load --platform linux/arm64 -t ${IMAGE}:${VERSION} .
