#!/bin/bash

set -e
set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

container_image="local-kata-kernel"
sudo docker build -f "${script_dir}/Dockerfile" -t "${container_image}" "${script_dir}/.."
rm -f kata-kernel.tar.gz
set -x
#shared_build_dir="/kata/kernel/build"
#sudo docker run --rm -v "$(pwd):/${shared_build_dir}"  -ti "${container_image}" bash -x -c './build-kernel.sh -v v5.4.71 setup'
#sudo docker run --rm -v "$(pwd):/out"  -ti "${container_image}" sh -c './build-kernel.sh -v v5.4.71 build'
#sudo docker run --rm -v "$(pwd):/out"  -ti "${container_image}" sh -c './build-kernel.sh -v v5.4.71 install'
#sudo docker run --rm -v "$(pwd):/out"  -ti "${container_image}" sh -c 'cp -r kata-kernel.tar.gz /out'
