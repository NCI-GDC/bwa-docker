#!/bin/bash


function build {
	make -C $1 docker-login build
}

function publish {
	make -C $1 publish
}

case "$1" in
	build)
		for version in *; do
			if [ -d "${version}" ]; then
				echo "Building $version"
				build $version
			fi
		done
	;;
	publish)
		for version in *; do
			if [ -d "${version}" ]; then
				echo "Publishing: $version"
				publish $version
			fi
		done
	;;
esac
