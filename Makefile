PGM_VERSION := 1.2.1

IMAGE := sunaoka/pgmodeler-cli

PLATFORM := linux/arm64,linux/amd64

BUILDER := docker-pgmodeler-cli-builder

BUILDER_ARGS := --build-arg PGM_VERSION=$(PGM_VERSION) -t $(IMAGE):$(PGM_VERSION) -t $(IMAGE):latest

all: build

setup:
	(docker buildx ls | grep $(BUILDER)) || docker buildx create --name $(BUILDER)

build: setup
	docker buildx use $(BUILDER)
	docker buildx build --rm --no-cache --platform $(PLATFORM) $(BUILDER_ARGS) --push .
	docker buildx rm $(BUILDER)

release:
	git checkout develop
	git add .
	git commit -m "Bump to v$(PGM_VERSION)"
	git checkout main
	git merge develop --no-ff -m "Merge develop into main for v$(PGM_VERSION)"
	git tag -a v$(PGM_VERSION) -m "Release v$(PGM_VERSION)"
	git checkout develop
	git push origin main develop --tags

.PHONY: all config setup build release
