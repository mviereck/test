# x11docker/deepin
# 
# Run deepin desktop in a Docker container. 
# Use x11docker to run image: 
#   https://github.com/mviereck/x11docker 
#
# Run deepin desktop with:
#   x11docker --desktop --init=systemd -- --cap-add=IPC_LOCK --security-opt seccomp=unconfined -- x11docker/deepin
#
# Run single application:
#   x11docker x11docker/deepin deepin-terminal
#
# Options:
# Persistent home folder stored on host with   --home
# Share host file or folder with option        --share PATH
# Hardware acceleration with option            --gpu
# Clipboard sharing with option                --clipboard
# Language locale setting with option          --lang [=$LANG]
# Sound support with option                    --pulseaudio
# Printer support with option                  --printer
# Webcam support with option                   --webcam
#
# See x11docker --help for further options.

#### stage 0: debian, debootstrap ####
FROM debian:buster

# Choose a deepin mirror close to your location.
# Many further mirrors listed at: https://www.deepin.org/en/mirrors/packages/
#ENV DEEPIN_MIRROR=http://packages.deepin.com/deepin/
#ENV DEEPIN_MIRROR=http://mirrors.ustc.edu.cn/deepin/
ENV DEEPIN_MIRROR=http://mirrors.kernel.org/deepin/
#ENV DEEPIN_MIRROR=http://ftp.fau.de/deepin/

ENV DEEPIN_RELEASE=apricot

# debootstrap script
RUN mkdir -p /usr/share/debootstrap/scripts && \
    echo "mirror_style release\n\
download_style apt\n\
finddebs_style from-indices\n\
variants - buildd fakechroot minbase\n\
keyring /usr/share/keyrings/deepin-archive-camel-keyring.gpg\n\
. /usr/share/debootstrap/scripts/debian-common \n\
" > /usr/share/debootstrap/scripts/$DEEPIN_RELEASE

RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        debootstrap \
        gnupg && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 425956BB3E31DF51 && \
    mv /etc/apt/sources.list /etc/apt/sources.list.debian && \
    echo "deb $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" > /etc/apt/sources.list && \
    apt-get update && \
    apt-get download deepin-keyring && \
    dpkg -i /deepin-keyring* && \
    rm /etc/apt/sources.list && \
    mv /etc/apt/sources.list.debian /etc/apt/sources.list && \
    mkdir -p /rootfs && \
    dpkg -x /deepin-keyring* /rootfs && \
    echo "deb $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" > /rootfs/etc/apt/sources.list

RUN debootstrap --variant=minbase --arch=amd64 $DEEPIN_RELEASE /rootfs $DEEPIN_MIRROR

#### stage 1: deepin ####
FROM scratch
COPY --from=0 /rootfs /

ENV SHELL=/bin/bash

# basics
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install --fix-broken -y && \
    env DEBIAN_FRONTEND=noninteractive apt-get install --fix-missing -y && \
    env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    apt-get -y autoremove && \
    apt-get clean && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        gnupg \
        dbus-x11 \
        libxv1 \
        locales-all \
        mesa-utils \
        mesa-utils-extra \
        procps \
        psmisc

# deepin desktop

# workaround to fix dependency pbis-open
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        aptitude \
        curl && \
    curl -fsSL http://mirrors.kernel.org/deepin/pool/non-free/p/pbis-open/pbis-open_8.5.7.385.2_amd64.deb -o /pbis-open.deb && \
    curl -fsSL http://mirrors.kernel.org/deepin/pool/non-free/p/pbis-open-upgrade/pbis-open-upgrade_8.5.7.385_amd64.deb -o /pbis-open-upgrade.deb && \
    dpkg -i /pbis-open-upgrade.deb /pbis-open.deb

#RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends dde-qt5xcb-plugin ukui-greeter
#RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
RUN aptitude install -f -y -R \
        dde \
        deepin-keyring \
        at-spi2-core \
        gnome-themes-standard \
        gtk2-engines-murrine \
        gtk2-engines-pixbuf \
        pciutils

# additional applications
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        deepin-calculator \
        deepin-image-viewer \
        deepin-screenshot \
        deepin-system-monitor \
        deepin-terminal \
        deepin-movie \
        gedit \
        oneko \
        sudo \
        synaptic \
        apt-transport-https

# chinese fonts
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        xfonts-wqy \
        fonts-wqy-microhei \
        fonts-wqy-zenhei

CMD ["startdde"]
