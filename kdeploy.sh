#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

bscript="../.github/workflows/generate-local-artifact-tarball.sh"

build_clh() {
	##  TODO get version from versions.yaml
	export cloud_hypervisor_repo="https://github.com/cloud-hypervisor/cloud-hypervisor"
	export cloud_hypervisor_version="v15.0"
	bash -x $bscript install_clh
	tar -tvf kata-static-clh.tar.gz
}

build_experimental_kernel(){
	##  TODO get version from versions.yaml
	export kernel_version="v5.10.25"
	bash -x $bscript "install_experimental_kernel"
	tar -tvf kata-static-experimental-kernel.tar.gz
}

build_kata() {
	bash -x $bscript install_kata_components
	tar -tvf kata-static-kata-components.tar.gz
}

build_kernel() {
	##  TODO get version from versions.yaml
	export kernel_version="v5.10.25"
	bash -x $bscript install_kernel
	tar -tvf kata-static-kernel.tar.gz
}

build_qemu() {
	##  TODO get version from versions.yaml
	## TODO fix  replace mv
	export qemu_repo="https://github.com/qemu/qemu"
	export qemu_version="v5.2.0"
	bash -x $bscript install_qemu
	tar -tvf kata-static-qemu.tar.gz
}

main(){

	#Problems to solve
	# Still depends on host, should need just docker
	# Still takes some time to build
	mkdir -p kata-artifacts
	pushd kata-artifacts
	build_kernel
	build_clh
	build_experimental_kernel
	#buildstr: "install_firecracker"
	#buildstr: "install_image"
	build_kata
	build_qemu
	popd
	bash -x .github/workflows/gather-artifacts.sh
	tar -tvf kata-static.tar.xz
}

main $@
