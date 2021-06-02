#!/bin/bash

script_dir=$(dirname "$(readlink -f "$0")")
tool_dir=$(realpath ${script_dir}/..)

docker run --rm --user "$(id -u)":"$(id -g)" -v "$tool_dir":"${tool_dir}" -w "${tool_dir}" rust:alpine cargo build
cp "${tool_dir}/target/debug/kata-deploy-builder" .
