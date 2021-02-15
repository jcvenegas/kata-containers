FROM ubuntu


RUN apt-get update
RUN apt-get install -y bison
RUN apt-get install -y curl
RUN apt-get install -y flex
RUN apt-get install -y xz-utils
RUN apt-get install -y build-essential

ADD kernel  /kata/kernel/
ADD scripts /kata/scripts
WORKDIR /kata/kernel
RUN ./build-kernel.sh -v v5.4.71 setup
