FROM alpine

RUN apk add --no-cache git make musl-dev go linux-headers
ADD . /kata/runtime
WORKDIR /kata/runtime

ENV PREFIX=/opt/kata
RUN make
RUN make install
WORKDIR /opt
RUN tar -czvf /root/kata-runtime.tar.gz *
WORKDIR /root
