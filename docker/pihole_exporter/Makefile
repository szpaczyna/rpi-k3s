VERSION?=v1
REGISTRY="registry.shpaq.org"
IMAGE=pihole_exporter

prepare: install
  docker buildx create --use
 # docker buildx inspect --bootstrap

build-push:
	docker buildx build --push --platform linux/arm64/v8 -t ${REGISTRY}/${IMAGE}:${VERIION} .

build-local:
	docker buildx build --load --platform linux/arm64/v8 -t ${IMAGE}:${VERSION} .
