VERSION = 0.7.15
DOCKER_REPO = bwa

SHORT_HASH := $(shell git rev-parse --short HEAD)
DOCKER_URL := quay.io/ncigdc
DOCKER_IMAGE := ${DOCKER_URL}/${DOCKER_REPO}:${VERSION}
DOCKER_IMAGE_HASH := ${DOCKER_URL}/${DOCKER_REPO}:${VERSION}-${SHORT_HASH}

.PHONY: version version-* name
name:
	@echo ${NAME}

version:
	@echo --- VERSION: ${VERSION} ---

version-docker:
	@echo ${DOCKER_IMAGE_COMMIT}
	@echo ${DOCKER_IMAGE}

.PHONY: docker-*
docker-login:
	@echo
	docker login -u=${QUAY_USERNAME} -p=${QUAY_PASSWORD} quay.io

.PHONY: build build-*
build: build-docker

build-docker:
	@echo
	@echo -- Building docker --
	docker build . \
		--file ../Dockerfile.multi \
		--build-arg VERSION=${VERSION} \
		-t "${DOCKER_IMAGE}" \
		-t "${DOCKER_IMAGE_HASH}"

.PHONY: run-docker
run-docker:
	@echo
	docker run --rm ${DOCKER_IMAGE}

.PHONY: publish
publish: docker-login
	docker push ${DOCKER_IMAGE}
	docker push ${DOCKER_IMAGE_HASH}
