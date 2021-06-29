all-parallel:
	make all -j7

all: cloud-hypervisor firecracker kernel qemu rootfs-image rootfs-initrd shim-v2

cloud-hypervisor:
	./kata-deploy-binaries-in-docker.sh -s --build=$@
firecracker:
	./kata-deploy-binaries-in-docker.sh -s --build=$@
kernel:
	./kata-deploy-binaries-in-docker.sh -s --build=$@
qemu:
	./kata-deploy-binaries-in-docker.sh -s --build=$@
rootfs-image:
	./kata-deploy-binaries-in-docker.sh -s --build=$@
rootfs-initrd:
	./kata-deploy-binaries-in-docker.sh -s --build=$@
shim-v2:
	./kata-deploy-binaries-in-docker.sh -s --build=$@

merge-builds:
	./kata-deploy-merge-builds.sh build
