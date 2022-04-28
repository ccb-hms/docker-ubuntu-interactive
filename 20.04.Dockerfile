#
# R Container Image
# Author: Nathan Palmer
# Copyright: Harvard Medical School
#

FROM ubuntu:20.04

#------------------------------------------------------------------------------
# Basic initial system configuration
#------------------------------------------------------------------------------

USER root

# install standard Ubuntu Server packages
RUN yes | unminimize

# we're going to create a non-root user at runtime and give the user sudo
RUN apt-get update && \
	apt-get -y install sudo \
	&& echo "Set disable_coredump false" >> /etc/sudo.conf
	
# set locale info
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& apt-get update && apt-get install -y locales \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ=America/New_York

WORKDIR /tmp

#------------------------------------------------------------------------------
# Install system tools and libraries via apt
#------------------------------------------------------------------------------

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install \
		-y \
		ca-certificates \
		curl \
		less \
		libgomp1 \
		libpango-1.0-0 \
		libxt6 \
		libsm6 \
		make \
		texinfo \
		libtiff-dev \
		libpng-dev \
		libicu-dev \
		libpcre3 \
		libpcre3-dev \
		libbz2-dev \
		liblzma-dev \
		gcc \
		g++ \
		openjdk-8-jre \
		openjdk-8-jdk \
		gfortran \
		libreadline-dev \
		libx11-dev \
		libcurl4-openssl-dev \ 
		libssl-dev \
		libxml2-dev \
		wget \
		libtinfo5 \
		openssh-server \
		ssh \
		xterm \
		xauth \
		screen \
		tmux \
		git \
		libgit2-dev \
		nano \
		emacs \
		vim \
		man-db \
		zsh \
		unixodbc \
		unixodbc-dev \
		gnupg \
		krb5-user \
		python3-dev \
		python3 \ 
		python3-pip \
		alien \
		libaio1 \
		pkg-config \ 
		libkrb5-dev \
		unzip \
		cifs-utils \
		lsof \
		libnlopt-dev \
		libopenblas-openmp-dev \
		libpcre2-dev \
		systemd \
		libcairo2-dev \
	&& rm -rf /var/lib/apt/lists/*


#------------------------------------------------------------------------------
# Configure system tools
#------------------------------------------------------------------------------

# required for ssh and sshd	
RUN mkdir /var/run/sshd	

# enable password authedtication over SSH
RUN sed -i 's!^#PasswordAuthentication yes!PasswordAuthentication yes!' /etc/ssh/sshd_config

# configure X11
RUN sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config \
    && sed -i "s/^.*X11UseLocalhost.*$/X11UseLocalhost no/" /etc/ssh/sshd_config \
    && grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config	

# tell git to use the cache credential helper and set a 1 day-expiration
RUN git config --system credential.helper 'cache --timeout 86400'


#------------------------------------------------------------------------------
# Install and configure database connectivity components
#------------------------------------------------------------------------------

# install FreeTDS driver
WORKDIR /tmp
RUN wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.1.40.tar.gz
RUN tar zxvf freetds-1.1.40.tar.gz
RUN cd freetds-1.1.40 && ./configure --enable-krb5 && make && make install
RUN rm -r /tmp/freetds*

# tell unixodbc where to find the FreeTDS driver shared object
RUN echo '\n\
[FreeTDS]\n\
Driver = /usr/local/lib/libtdsodbc.so \n\
' >> /etc/odbcinst.ini

# install pyodbc
RUN pip3 install pyodbc


#------------------------------------------------------------------------------
# Install S6 supervisor
#------------------------------------------------------------------------------
ENV S6_VERSION=v3.1.0.1
RUN ARCH=$(dpkg --print-architecture) \
	&& if [ "$ARCH" = "arm64" ]; then ARCH=aarch64; fi \
	&& if [ "$ARCH" = "amd64" ]; then ARCH=x86_64; fi \
	&& DOWNLOAD_FILE=s6-overlay-noarch.tar.xz \
    && wget -P /tmp/ "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${DOWNLOAD_FILE}" \
    && tar -C / -Jxpf /tmp/${DOWNLOAD_FILE} \
	&& DOWNLOAD_FILE=s6-overlay-${ARCH}.tar.xz \
    && wget -P /tmp/ "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${DOWNLOAD_FILE}" \
    && tar -C / -Jxpf /tmp/${DOWNLOAD_FILE}

ENV PATH "${PATH}:/command" 


#------------------------------------------------------------------------------
# Create s6 sshd service
#------------------------------------------------------------------------------

RUN mkdir -p /etc/s6-overlay/s6-rc.d/sshd
RUN echo 'longrun' >> /etc/s6-overlay/s6-rc.d/sshd/type
RUN echo '#!/bin/sh\nexec 2>&1\n/usr/sbin/sshd -D -e' >> /etc/s6-overlay/s6-rc.d/sshd/run
RUN mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd
EXPOSE 22


#------------------------------------------------------------------------------
# Install user configuration script
#------------------------------------------------------------------------------

COPY create_user.sh /etc/cont-init.d/create_user.sh
RUN chmod 777 /etc/cont-init.d/create_user.sh

#------------------------------------------------------------------------------
# Final odds and ends
#------------------------------------------------------------------------------

# Create a mount point for host file system
RUN mkdir /HostData

ENTRYPOINT ["/init"]
