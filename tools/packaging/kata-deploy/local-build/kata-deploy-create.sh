#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

script_dir=$(dirname "$(readlink -f "$0")")
bscript="${script_dir}/../../../../.github/workflows/generate-local-artifact-tarball.sh"

build_clh() {
	export cloud_hypervisor_repo="https://github.com/cloud-hypervisor/cloud-hypervisor"
	export cloud_hypervisor_version="v15.0"
	bash -x $bscript install_clh
	tar -tvf kata-static-clh.tar.gz
}

build_experimental_kernel(){
	export kernel_version=="$(yq r versions.yaml assets.kernel-experimental.version)"
	bash -x $bscript "install_experimental_kernel"
	tar -tvf kata-static-experimental-kernel.tar.gz
}

build_kata() {
	bash -x $bscript install_kata_components
	tar -tvf kata-static-kata-components.tar.gz
}

build_kernel() {
	export kernel_version=="$(yq r versions.yaml assets.version)"
	bash -x $bscript "install_experimental_kernel"
	bash -x $bscript install_kernel
	tar -tvf kata-static-kernel.tar.gz
}

build_qemu() {
	export qemu_repo="https://github.com/qemu/qemu"
	export qemu_repo="$(yq r versions.yaml assets.hypervisor.qemu.url)"
	export qemu_version="$(yq r versions.yaml assets.hypervisor.qemu.version)"
	bash -x $bscript install_qemu
	tar -tvf kata-static-qemu.tar.gz
}
build_qemu_experimental() {
	export qemu_repo="$(yq r versions.yaml assets.hypervisor.qemu-experimental.url)"
	export qemu_version="$(yq r versions.yaml assets.hypervisor.qemu-experimental.version)"
	bash -x $bscript install_qemu_experimental
	tar -tvf kata-static-qemu.tar.gz
}

build_firecracker() {
	bash -x $bscript install_firecracker
	tar -tvf kata-static-firecracker.tar.gz
}

build_guest_rootfs() {
	bash -x $bscript install_image
	tar -tvf kata-static-image.tar.gz
}

main(){

	mkdir -p kata-artifacts
	pushd kata-artifacts
	build_qemu
	#build_qemu_experimental
	build_kernel
	build_clh
	build_experimental_kernel
	build_firecracker
	build_guest_rootfs
	build_kata
	popd
	bash -x .github/workflows/gather-artifacts.sh
	tar -tvf kata-static.tar.xz
}

main $@
