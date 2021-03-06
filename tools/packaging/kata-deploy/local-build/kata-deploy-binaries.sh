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

readonly prefix="/opt/kata"
readonly repo_root_dir="$(cd "${script_dir}/../../../.." && pwd)"
readonly version_file="${repo_root_dir}/VERSION"
readonly versions_yaml="${repo_root_dir}/versions.yaml"

readonly clh_builder="${repo_root_dir}/tools/packaging/static-build/cloud-hypervisor/build-static-clh.sh"
readonly firecracker_builder="${repo_root_dir}/tools/packaging/static-build/firecracker/build-static-firecracker.sh"
readonly kernel_builder="${repo_root_dir}/tools/packaging/kernel/build-kernel.sh"
readonly qemu_builder="${repo_root_dir}/tools/packaging/static-build/qemu/build-static-qemu.sh"
readonly rootfs_builder="${repo_root_dir}/tools/packaging/guest-image/build_image.sh"

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

-h|--help      	      : Show this help
--build=<asset>       :
	all
	cloud-hypervisor
	firecracker
	kernel
	qemu
	rootfs-image
	rootfs-initrd
	shim-v2
EOT

	exit "${return_code}"
}

#Install guest image
install_image() {
	info "Create image"
	set -x
	bash -x "${rootfs_builder}" --imagetype=image --prefix="${prefix}" --destdir="${destdir}"
}

#Install guest initrd
install_initrd() {
	info "Create initrd"
	"${rootfs_builder}" --imagetype=initrd --prefix="${prefix}" --destdir="${destdir}"
}

#Install kernel asset
install_kernel() {
	info "build kernel"
	export kernel_version=="$(yq r $versions_yaml assets.version)"
	"${kernel_builder}" setup
	"${kernel_builder}" build
	info "install kernel"
	DESTDIR="${destdir}" PREFIX="${prefix}" "${kernel_builder}" install
}

#Install experimental kernel asset
install_experimental_kernel() {
	info "build experimental kernel"
	export kernel_version="$(yq r $versions_yaml assets.kernel-experimental.version)"
	"${kernel_builder}" -e setup
	"${kernel_builder}" -e build
	info "install experimental kernel"
	DESTDIR="${destdir}" PREFIX="${prefix}" "${kernel_builder}" -e install
}

# Install static qemu asset
install_qemu() {
	info "build static qemu"
	export qemu_repo="$(yq r $versions_yaml assets.hypervisor.qemu.url)"
	export qemu_version="$(yq r $versions_yaml assets.hypervisor.qemu.version)"
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
	local cloud_hypervisor_repo
	local cloud_hypervisor_version

	cloud_hypervisor_repo="$(yq r $versions_yaml assets.hypervisor.cloud_hypervisor.url)"
	cloud_hypervisor_version="$(yq r $versions_yaml assets.hypervisor.cloud_hypervisor.version)"

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

get_kata_version() {
	local v
	v=$(cat "${version_file}")

	if ! git describe --exact-match --tags HEAD; then
		v="${v}~$(git rev-parse HEAD)"
	fi
	echo ${v}
}

handle_build() {
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

	rootfs-image)
		install_image
		;;

	rootfs-initrd)
		install_initrd
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
	(
		cd "${destdir}"
		sudo tar cvfJ "${tarball_name}" "."
	)
	tar tvf "${tarball_name}"
}

main() {
	local build_targets
	build_targets=(
		cloud-hypervisor
		firecracker
		rootfs-image
		rootfs-initrd
		qemu
		shim-v2
		kernel
	)
	while getopts "hlpw:-:" opt; do
		case $opt in
		-)
			case "${OPTARG}" in
			build=*)
				build_targets=(${OPTARG#*=})
				;;
			help)
				usage 0
				;;
			*)
				usage 1
				;;
			esac
			;;
		h) usage 0 ;;
		*) usage 1 ;;
		esac
	done
	shift $((OPTIND - 1))

	set -x
	kata_version=$(get_kata_version)

	echo "Build kata version ${kata_version}"
	workdir="${workdir}/build"
	for t in "${build_targets[@]}"; do
		destdir="${workdir}/${t}/destdir"
		builddir="${workdir}/${t}/builddir"
		info "DESTDIR ${destdir}"
		info "Building $t"
		mkdir -p "${destdir}"
		mkdir -p "${builddir}"
		(
			cd "${builddir}"
			handle_build "${t}"
		)
	done

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main $@
fi
