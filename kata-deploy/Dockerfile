FROM ubuntu
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y sudo

# Install docker
RUN sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get install docker-ce-cli -y

ARG IMG_USER=kata-builder
ARG UID=1000
ARG GID=1000
RUN adduser ${IMG_USER} --uid=${UID}
RUN sh -c "echo '${IMG_USER} ALL=NOPASSWD: ALL' >> /etc/sudoers"

# kernel deps
RUN apt install -y flex bison libelf-dev bc iptables build-essential
RUN apt install -y git


# kata deps
RUN apt install -y golang


ENV USER ${IMG_USER}
USER ${UID}:${GID}
