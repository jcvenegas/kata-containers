#!/bin/bash
kata_dir=$(realpath "${PWD}/..")
uid=$(id -u ${USER})
gid=$(id -g ${USER})

docker build -t build-kata-deploy \
	--build-arg IMG_USER="${USER}"\
	--build-arg UID=${uid}\
	--build-arg GID=${gid}\
	.
docker run -i \
	-v /var/run/docker.sock:/var/run/docker.sock \
	--user ${uid}:${gid} \
	--env USER=${USER} -v "${kata_dir}:${kata_dir}" \
	--rm \
	-w ${kata_dir}\
	build-kata-deploy bash -x "${kata_dir}/kdeploy.sh"
