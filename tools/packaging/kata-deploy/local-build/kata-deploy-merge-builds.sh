#!/bin/bash
# Copyright (c) 2021 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

kata_dir=${1:-build}

cd "${kata_dir}"
for c in ./kata-static-*.tar.xz
do
    echo "untarring tarball $c"
    tar -xvf $c
done

tar cvfJ ../kata-static.tar.xz ./opt
