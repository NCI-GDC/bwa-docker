#!/bin/bash -x
set -o pipefail
SOFTWARE="bwa"

while getopts b:t: option; do
	case "${option}" in

	b) BRANCH=${OPTARG} ;;
	*) echo "${OPTARG}" not supported! ;;
	esac
done

export DOCKER_BUILDKIT=1
export BUILDKIT_STEP_LOG_MAX_SIZE=10485760
export BUILDKIT_STEP_LOG_MAX_SPEED=1048576

BASE_CONTAINER_REGISTRY="${BASE_CONTAINER_REGISTRY:-docker.osdc.io}"
PROXY="${PROXY:-}"
BRANCH="${BRANCH-}"
BUILD_ROOT_DIR=$(pwd)
GIT_SHORT_HASH=$(git rev-parse --short HEAD)

# Initialize Registry array
REGISTRIES=()
if [ "$BRANCH" = "$CI_DEFAULT_BRANCH" ] || [ -n "$SCM_TAG" ]; then
	# Which internal registry to push the images to.
	# Production registries/quay on release
	REGISTRIES+=("containers.osdc.io" "quay.io")
else
	# Dev registry otherwise
	REGISTRIES+=("dev-containers.osdc.io")
fi

# Populate the IMAGE_TAGS variable with an array listing the tags to set,
# including all versions and registries. Pass the "directory" of the image
# as an argument.
function populate_image_tags() {
	IMAGE_TAGS=()
	for REGISTRY in "${REGISTRIES[@]}"; do
		IMAGE_TAGS+=("${REGISTRY}/ncigdc/${SOFTWARE}:$1")
		IMAGE_TAGS+=("${REGISTRY}/ncigdc/${SOFTWARE}:$1-${GIT_SHORT_HASH}")
	done
}

set -e
for directory in *; do
	if [ -d "${directory}" ]; then
	    # Ignore directories without a justfile
		if [ ! -f "${directory}"/justfile ]; then
			cd "$BUILD_ROOT_DIR"
			continue
		fi

		cd "${directory}"

		echo "Building ${directory} ..."
		# Build version image, tagging as build-<software>:<version>

		# Allow per-version Dockerfile
		DOCKERFILE=$(just emit-dockerfile)
		VERSION=$(just emit-version)
		BUILD_TAG="build-${SOFTWARE}:${directory}"
		docker buildx build --compress --progress plain \
  			-t "${BUILD_TAG}" \
  			-f "${DOCKERFILE}" \
  			. \
  			--label org.opencontainers.image.created="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  			--label org.opencontainers.image.revision="${GIT_SHORT_HASH}" \
  			--label org.opencontainers.ref.name="${SOFTWARE}:${directory}" \
  			--build-arg http_proxy="${PROXY}" \
  			--build-arg https_proxy="${PROXY}" \
  			--build-arg VERSION="${VERSION}" \
  			--build-arg REGISTRY="${BASE_CONTAINER_REGISTRY}"

		# Assign the final tags now so later images can build on this one.
		populate_image_tags "${directory}"
		for TAG in "${IMAGE_TAGS[@]}"; do
			docker tag "${BUILD_TAG}" "$TAG"
		done

		# Cleanup build image
		docker rmi "${BUILD_TAG}"
		
		cd ..
	fi
done

echo "Successfully built all containers!"

cd "$BUILD_ROOT_DIR"

if [[ -n "$GITLAB_CI" ]]; then
	# Only publish on CI
	for directory in *; do
		if [ -d "${directory}" ]; then
			if [ ! -f "${directory}"/justfile ]; then
				continue
			fi

			echo "Pushing and cleaning up."

			populate_image_tags "${directory}"
			for TAG in "${IMAGE_TAGS[@]}"; do
				docker push "${TAG}" | ts "[PUSH] %H:%M:%S - $directory -"
				docker rmi "${TAG}" | ts "[PUSH] %H:%M:%S - $directory -"
				echo "${TAG} is all set"
			done
		fi
	done
fi
echo "All done!"
