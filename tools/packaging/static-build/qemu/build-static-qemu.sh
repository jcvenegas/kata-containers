#!/bin/bash
#
# Copyright (c) 2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die(){ local msg="$*" ; echo "ERROR: $msg" >&2; exit 1;}


qemu_repo="${qemu_repo:-}"
qemu_version="${qemu_version:-}"

[ -n "$qemu_repo" ] || die "failed to get qemu repo"
[ -n "$qemu_version" ] || die "failed to get qemu version"

"${script_dir}/build-base-qemu.sh" "${qemu_repo}" "${qemu_version}" "" "kata-static-qemu.tar.gz"
