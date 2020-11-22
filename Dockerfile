# x11docker/deepin
# 
# Run deepin desktop in a Docker container. 
# Use x11docker to run image: 
#   https://github.com/mviereck/x11docker 
#
# Run deepin desktop with:
#   x11docker --desktop --init=systemd --cap-default -- x11docker/deepin
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
ENV LANG=en_US.utf8

# basics
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install --fix-broken -y && \
    env DEBIAN_FRONTEND=noninteractive apt-get install --fix-missing -y && \
    env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    apt-get -y autoremove && \
    apt-get clean && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-transport-https \
        deepin-keyring \
        dbus-x11 \
        gnupg \
        libcups2 \
        libpulse0 \
        libxv1 \
        locales-all \
        mesa-utils \
        mesa-utils-extra \
        procps \
        psmisc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# deepin desktop

# Dependencies of 'apt-get show dde'
# (excluded: dde-session-ui deepin-manual eject plymouth-theme-deepin-logo dde-printer deepin-screensaver)
RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        dde-control-center \
        dde-clipboard \
        dde-desktop \
        dde-dock \
        dde-file-manager \
        dde-kwin \
        dde-launcher \
        dde-qt5integration \
        deepin-artwork \
        deepin-default-settings \
        deepin-desktop-base \
        deepin-wallpapers \
        fonts-noto \
        startdde && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# once needed to add, obsolete now?
#RUN apt-get update && \
#    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#        at-spi2-core \
#        gnome-themes-standard \
#        gtk2-engines-murrine \
#        gtk2-engines-pixbuf \
#        pciutils && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/*


# additional applications
RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        dde-calendar \
        deepin-album \
        deepin-calculator \
        deepin-draw \
        deepin-editor \
        deepin-image-viewer \
        deepin-movie \
        deepin-music \
        deepin-screenshot \
        deepin-system-monitor \
        deepin-terminal \
        deepin-voice-note \
        oneko \
        sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# chinese fonts and input methods
#RUN apt-get update && \
#    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#        fcitx-sunpinyin \
#        fcitx-ui-classic \
#        xfonts-wqy \
#        fonts-wqy-microhei \
#        fonts-wqy-zenhei && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/*

CMD ["startdde"]
