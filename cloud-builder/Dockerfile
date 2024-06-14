# Based off gcr.io/gcp-runtimes/ubuntu_20_0_4
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:slim

ARG PACKER_VERSION=1.11.0

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install unzip && \
    gcloud components list && \
    mkdir -vp /tmp/packer && \
    curl -o /tmp/packer/packer_${PACKER_VERSION}_linux_amd64.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
    unzip /tmp/packer/packer_${PACKER_VERSION}_linux_amd64.zip -d /tmp/packer && \
    cp /tmp/packer/packer /usr/bin/packer
