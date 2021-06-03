#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")
tool_dir=$(realpath ${script_dir}/..)

container_image=kata-deploy-builder-build-env
docker build -t "${container_image}" "${script_dir}"
docker run --rm --user "$(id -u)":"$(id -g)" -v "$tool_dir":"${tool_dir}" -w "${tool_dir}" "${container_image}" cargo build
cp "${tool_dir}/target/debug/kata-deploy-builder" .
