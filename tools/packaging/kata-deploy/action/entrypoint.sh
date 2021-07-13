#!/bin/bash
#
# Copyright (c) 2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#
set -o errexit
set -o pipefail
set -o nounset

CONTAINER_IMAGE="$1"
echo "provided package reference: ${CONTAINER_IMAGE}

# Since this is the entrypoint for the container image, we know that the AKS and Kata setup/testing
# scripts are located at root.
source /setup-aks.sh
source /test-kata.sh

trap destroy_aks EXIT

setup_aks
test_kata
