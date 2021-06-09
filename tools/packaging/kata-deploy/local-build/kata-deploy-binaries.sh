#!/bin/bash
# Copyright (c) 2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

[ -z "${DEBUG}" ] || set -x
set -o errexit
set -o nounset
set -o pipefail

readonly project="kata-containers"

readonly script_name="$(basename "${BASH_SOURCE[0]}")"
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly root_dir="$(cd "${script_dir}/.." && pwd)"
readonly prefix="/opt/kata"
readonly repo_root_dir="$(cd "${script_dir}/../../../.." && pwd)"
readonly version_file="${repo_root_dir}/VERSION"

readonly clh_builder="${repo_root_dir}/tools/packaging/static-build/cloud-hypervisor/build-static-clh.sh"
readonly firecracker_builder="${repo_root_dir}/tools/packaging/static-build/firecracker/build-static-firecracker.sh"
readonly kernel_builder="${repo_root_dir}/tools/packaging/kernel/build-kernel.sh"
readonly qemu_builder="${repo_root_dir}/tools/packaging/static-build/qemu/build-static-qemu.sh"

workdir="${WORKDIR:-$PWD}"

destdir="${workdir}/kata-static"

die() {
	msg="$*"
	echo "ERROR: ${msg}" >&2
	exit 1
}

info() {
	echo "INFO: $*"
}

usage() {
	return_code=${1:-0}
	cat <<EOT
This script is used as part of the ${project} release process.
It is used to create a tarball with static binaries.


Usage:
${script_name} <options> [version]

Args:
version: The kata version that will be use to create the tarball

options:

-h      : Show this help
EOT

	exit "${return_code}"
}


#Install guest image/initrd asset
install_image() {
	image_destdir="${destdir}/${prefix}/share/kata-containers/"
	info "Create image"
	image_tarball=$(find . -name 'kata-containers-'"${kata_version}"'-*.tar.gz')
	[ -f "${image_tarball}" ] || "${root_dir}/guest-image/build_image.sh" -v "${kata_version}"
	image_tarball=$(find . -name 'kata-containers-'"${kata_version}"'-*.tar.gz')
	[ -f "${image_tarball}" ] || die "image not found"
	info "Install image in destdir ${image_tarball}"
	mkdir -p "${image_destdir}"
	tar xf "${image_tarball}" -C "${image_destdir}"
	pushd "${destdir}/${prefix}/share/kata-containers/" >>/dev/null
	info "Create image default symlinks"
	image=$(find . -name 'kata-containers-image*.img')
	initrd=$(find . -name 'kata-containers-initrd*.initrd')
	ln -sf "${image}" kata-containers.img
	ln -sf "${initrd}" kata-containers-initrd.img
	popd >>/dev/null
	pushd ${destdir}
	tar -czvf ../kata-static-image.tar.gz *
	popd
}

#Install kernel asset
install_kernel() {
	info "build kernel"
	"${kernel_builder}" setup
	"${kernel_builder}" build
	info "install kernel"
	DESTDIR="${destdir}" PREFIX="${prefix}" "${kernel_builder}" install
}

#Install experimental kernel asset
install_experimental_kernel() {
	pushd "${root_dir}"
	info "build experimental kernel"
	./kernel/build-kernel.sh -e setup
	./kernel/build-kernel.sh -e build
	info "install experimental kernel"
	DESTDIR="${destdir}" PREFIX="${prefix}" ./kernel/build-kernel.sh -e install
	popd
	pushd ${destdir}
	tar -czvf ../kata-static-experimental-kernel.tar.gz *
	popd
}

# Install static qemu asset
install_qemu() {
	info "build static qemu"
	"${qemu_builder}"
}

# Install static firecracker asset
install_firecracker() {
	info "build static firecracker"
	"${firecracker_builder}"
	info "Install static firecracker"
	mkdir -p "${destdir}/opt/kata/bin/"
	sudo install -D --owner root --group root --mode 0744 firecracker/firecracker-static "${destdir}/opt/kata/bin/firecracker"
	sudo install -D --owner root --group root --mode 0744 firecracker/jailer-static "${destdir}/opt/kata/bin/jailer"
}

# Install static cloud-hypervisor asset
install_clh() {
	info "build static cloud-hypervisor"
	bash -x "${clh_builder}"
	info "Install static cloud-hypervisor"
	mkdir -p "${destdir}/opt/kata/bin/"
	sudo install -D --owner root --group root --mode 0744 cloud-hypervisor/cloud-hypervisor "${destdir}/opt/kata/bin/cloud-hypervisor"
}

#Install all components that are not assets
install_shimv2() {
	pushd "${repo_root_dir}/src/runtime"
	echo "Build"
	make \
		PREFIX="${prefix}" \
		QEMUCMD="qemu-system-x86_64"
	echo "Install"
	make PREFIX="${prefix}" \
		DESTDIR="${destdir}" \
		install
	popd
	sed -i -e '/^initrd =/d' "${destdir}/${prefix}/share/defaults/${project}/configuration-qemu.toml"
	sed -i -e '/^initrd =/d' "${destdir}/${prefix}/share/defaults/${project}/configuration-fc.toml"
	pushd "${destdir}/${prefix}/share/defaults/${project}"
	ln -sf "configuration-qemu.toml" configuration.toml
	popd
}

untar_qemu_binaries() {
	info "Install static qemu"
	tar xf kata-static-qemu.tar.gz -C "${destdir}"
}

get_kata_version() {
	local v
	v=$(cat "${version_file}")

	if ! git describe --exact-match --tags HEAD; then
		v="${v}~$(git rev-parse HEAD)"
	fi
	echo ${v}
}

handle_build(){
	local build_target
	build_target="$1"
	case "${build_target}" in
	all)
		install_shimv2
		install_experimental_kernel
		install_kernel
		install_clh
		install_qemu
		install_firecracker
		install_image
		;;
	cloud-hypervisor)
		install_clh
		;;

	firecracker)
		install_firecracker
		;;

	guest-rootfs)
		install_firecracker
		;;

	qemu)
		install_qemu
		;;

	shim-v2)
		install_shimv2
		;;

	kernel)
		install_kernel
		;;
	*)
		die "Invalid build target ${build_target}"
		;;
	esac

	tarball_name="${workdir}/kata-static-${build_target}.tar.xz"
	(cd "${destdir}"; tar cvfJ "${tarball_name}" ".")
	tar tvf "${tarball_name}"
}

main() {
	local build_target
	build_target="all"
	while getopts "hlpw:-:" opt; do
		case $opt in
		-)
			case "${OPTARG}" in
			build=*)
				build_target=${OPTARG#*=}
				;;
			esac
			;;
		h) usage 0 ;;
		esac
	done
	shift $((OPTIND - 1))

	kata_version=$(get_kata_version)

	echo "Build kata version ${kata_version}"
	workdir="${workdir}/kata-static-${kata_version}-$(uname -m)/"
	destdir="${workdir}/${build_target}"
	info "DESTDIR ${destdir}"
	info "Building $build_target"
	mkdir -p "${destdir}"
	(cd "${workdir}"; handle_build "${build_target}")

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main $@
fi
