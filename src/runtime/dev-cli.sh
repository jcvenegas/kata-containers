#!/bin/bash

container_image="local-kata-runtime"
sudo docker build -t "${container_image}" .
rm -f kata-runtime.tar.gz
sudo docker run --rm -v "$(pwd):/out"  -ti "${container_image}" sh -c 'cp -r kata-runtime.tar.gz /out'
