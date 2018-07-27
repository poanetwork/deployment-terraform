FROM ubuntu:16.04

RUN apt-get update -qq && \
  apt-get install -qqy \
  apt-transport-https \
  build-essential \
  libssl-dev \
  curl \
  git \
  unzip \
  lsb-release \
  software-properties-common \
  coreutils \
  python \
  python-dev 

ENV TERAFORM_VERSION="0.11.7"
ENV ANSIBLE_VERSION="2.5.4"

RUN \
  curl -fSs https://releases.hashicorp.com/terraform/${TERAFORM_VERSION}/terraform_${TERAFORM_VERSION}_linux_amd64.zip \
  -o terraform_${TERAFORM_VERSION}_linux_amd64.zip && \
  unzip terraform_${TERAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin && \
  rm terraform_${TERAFORM_VERSION}_linux_amd64.zip

RUN \
  curl -fsSL https://releases.ansible.com/ansible/ansible-${ANSIBLE_VERSION}.tar.gz -o ansible.tar.gz && \
  mkdir ansible; tar -xzf ansible.tar.gz -C ansible --strip-components 1 && \
  curl https://bootstrap.pypa.io/get-pip.py | python && \
  pip install -U pip setuptools packaging && \
  cd ansible && make && make install

RUN \
  AZ_REPO=$(lsb_release -cs); \
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
  tee /etc/apt/sources.list.d/azure-cli.list && \
  curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
  apt-get update && apt-get install -qqy azure-cli
