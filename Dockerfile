FROM debian:buster

ENV DEEPIN_RELEASE=lion

ENV PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/games:/usr/games

#COPY stable /usr/share/debootstrap/scripts/lion

RUN mkdir -p /usr/share/debootstrap/scripts && \
    echo "mirror_style release\n\
download_style apt\n\
finddebs_style from-indices\n\
variants - buildd fakechroot minbase\n\
keyring /usr/share/keyrings/deepin-archive-camel-keyring.gpg\n\
. /usr/share/debootstrap/scripts/debian-common \n\
" > /usr/share/debootstrap/scripts/$DEEPIN_RELEASE


RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y debootstrap curl
RUN curl -fsSL http://packages.deepin.com/deepin/pool/main/d/deepin-keyring/deepin-keyring_2020.03.13-1_all.deb -o /debian_keyring.deb
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y ./debian_keyring.deb
RUN dpkg -x /debian_keyring.deb /rootfs  
RUN debootstrap --variant=minbase --arch=amd64 $DEEPIN_RELEASE rootfs http://packages.deepin.com/deepin/

#Use the rootfs directory name based on the naming convention used by the Dockerfile here:
# https://github.com/debuerreotype/docker-debian-artifacts/blob/794e462d2825fb1ebb3d54ff5c93dd401cf28b9a/stable/Dockerfile   
FROM scratch
LABEL maintainer='Hongyi Zhao <hongyi.zhao@gmail.com>'
COPY --from=0 /rootfs /

RUN sed -i "s/mesg n/tty -s \&\& mesg n/" /root/.profile && \
    apt-get update && \
    apt --fix-broken -y install && \
    apt-get -y autoremove --purge && apt-get autoclean -y && apt-get clean -y && \
    find /var/lib/apt/lists -type f -delete && \
    find /var/cache -type f -delete

# choose a mirror
RUN echo "deb http://packages.deepin.com/deepin/ $DEEPIN_RELEASE main non-free contrib" > /etc/apt/sources.list

# basics
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get -y autoremove && \
    apt-get clean && \
    apt-get install -y gnupg \
    dbus-x11 \
    libxv1 \
    locales-all \
    mesa-utils \
    mesa-utils-extra \
    procps \
    psmisc

# deepin desktop
RUN apt-get install -y --no-install-recommends \
    dde \
    at-spi2-core \
    gnome-themes-standard \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    pciutils

# additional applications
RUN apt-get install -y \
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
RUN apt-get install -y \
    xfonts-wqy fonts-wqy-microhei fonts-wqy-zenhei

CMD ["startdde"]
