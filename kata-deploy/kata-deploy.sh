#!/bin/bash
kata_dir=$(realpath "${PWD}/..")
docker build -t build-kata-deploy --build-arg IMG_USER="${USER}"  .
docker run -ti -v /var/run/docker.sock:/var/run/docker.sock --env USER=${USER} -v "${kata_dir}:${kata_dir}" --rm build-kata-deploy bash -x "${kata_dir}/kdeploy.sh"
