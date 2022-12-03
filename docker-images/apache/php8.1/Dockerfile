FROM ubuntu:jammy
ENV DEBIAN_FRONTEND noninteractive
RUN \
  echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu jammy main" >> /etc/apt/sources.list && \
  apt update && \
  apt install -y gnupg && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C && \
  apt update && \
  apt install -y \
    apache2 \
    php8.1 \
    php8.1-fpm \
    php8.1-curl \
    php8.1-gd \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-zip \
    php8.1-mysqli \
    php8.1-mysqlnd \
    php8.1-dom \
    php8.1-exif && \
  a2ensite 000-default

EXPOSE 80
VOLUME /var/www/html
