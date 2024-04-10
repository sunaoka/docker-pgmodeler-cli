PGM_VERSION := 1.1.2

IMAGE := sunaoka/pgmodeler-cli

PLATFORM := linux/arm64,linux/amd64

BUILDER := docker-pgmodeler-cli-builder

BUILDER_ARGS := --build-arg PGM_VERSION=$(PGM_VERSION) -t $(IMAGE):latest -t $(IMAGE):$(PGM_VERSION)

all: build

setup:
	(docker buildx ls | grep $(BUILDER)) || docker buildx create --name $(BUILDER)

build: setup
	docker buildx use $(BUILDER)
	docker buildx build --rm --no-cache --platform $(PLATFORM) $(BUILDER_ARGS) --push .
	docker buildx rm $(BUILDER)

.PHONY: all config setup build
