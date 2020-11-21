FROM debian:buster
ENV DEEPIN_RELEASE=apricot
#ENV PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/games:/usr/games

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
        curl && \
    curl -fsSL http://packages.deepin.com/deepin/pool/main/d/deepin-keyring/deepin-keyring_2020.03.13-1_all.deb -o /deepin_keyring.deb && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ./deepin_keyring.deb && \
    dpkg -x /deepin_keyring.deb /rootfs && \
    echo "$DEEPIN_RELEASE" > /rootfs/release

RUN debootstrap --variant=minbase --arch=amd64 $DEEPIN_RELEASE rootfs http://packages.deepin.com/deepin/

################# 

FROM scratch
COPY --from=0 /rootfs /

#RUN sed -i "s/mesg n/tty -s \&\& mesg n/" /root/.profile && \
#    apt-get update && \
#    apt --fix-broken -y install && \
#    apt-get -y autoremove --purge && apt-get autoclean -y && \
#    apt-get clean -y && \
#    find /var/lib/apt/lists -type f -delete && \
#    find /var/cache -type f -delete

# Choose a mirror close to your location.
# Many further mirror listed at:
#   https://www.deepin.org/en/mirrors/packages/
#ENV MIRROR=http://packages.deepin.com/deepin/
#ENV MIRROR=http://mirrors.ustc.edu.cn/deepin/
ENV MIRROR=http://mirrors.kernel.org/deepin/
#ENV MIRROR=http://ftp.fau.de/deepin/

# source list entry based on chosen mirror and release
RUN echo "deb $MIRROR $(cat /release) main non-free contrib" > /etc/apt/sources.list

# basics
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get update && \
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
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        dde \
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
        xfonts-wqy fonts-wqy-microhei fonts-wqy-zenhei

CMD ["startdde"]
