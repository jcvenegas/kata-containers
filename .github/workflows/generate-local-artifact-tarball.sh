#!/bin/bash
# Copyright (c) 2019 Intel Corporation
# Copyright (c) 2020 Ant Group
#
# SPDX-License-Identifier: Apache-2.0
#

set -o errexit
set -o pipefail

script_dir=$(dirname "$(readlink -f "$0")")

KATA_REPO=$(realpath ${script_dir}/../..)


main() {
    artifact_stage=${1:-}
    artifact=$(echo  ${artifact_stage} | sed -n -e 's/^install_//p' | sed -r 's/_/-/g')
    if [ -z "${artifact}" ]; then
        "Scripts needs artifact name to build"
        exit 1
    fi

    pushd $KATA_REPO/tools/packaging/release
    source ./kata-deploy-binaries.sh
    ${artifact_stage} HEAD
    popd

    mv $KATA_REPO/tools/packaging/release/kata-static-${artifact}.tar.gz .
}

main $@
