
# gcloud auth configure-docker us-east1-docker.pkg.dev
# docker build . -t us-east1-docker.pkg.dev/gcp-asigbahgcp-nprd-47930/bah-builders/bah-kali-linux-img
# docker push us-east1-docker.pkg.dev/gcp-asigbahgcp-nprd-47930/bah-builders/bah-kali-linux-img

# Based off Debian Bookworm
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:slim

ARG PACKER_VERSION=1.15.3

RUN printf "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8\n" > /etc/default/locale && \
    export DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC && \
    export APT_OPTS="-o Dpkg::Options::=--force-confmiss -o Dpkg::Options::=--force-confnew -o DPkg::Progress-Fancy=0 -o APT::Color=0" && \
    apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install unzip xz-utils curl libguestfs-tools jq qemu-utils && \
    gcloud components list && \
    mkdir -vp /tmp/packer && \
    curl -o /tmp/packer/packer_${PACKER_VERSION}_linux_amd64.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
    unzip /tmp/packer/packer_${PACKER_VERSION}_linux_amd64.zip -d /tmp/packer && \
    cp /tmp/packer/packer /usr/bin/packer
