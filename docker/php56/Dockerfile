# PHP 5.6-FPM for legacy apps (e.g. TTM) - same /var/www mount as PHP 8.3
# Use only for projects that require PHP 5.6; all other projects use the main php service.
# Base image uses Debian Stretch (EOL) – point apt at archive.debian.org so installs work.

FROM php:5.6-fpm

ENV DEBIAN_FRONTEND=noninteractive

# Debian Stretch is EOL; use archive repos so apt-get works
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list \
    && sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list \
    && sed -i '/stretch-updates/d' /etc/apt/sources.list

# Dependencies for extensions (--allow-unauthenticated: Stretch archive keys expired)
RUN apt-get update && apt-get install -y --no-install-recommends --allow-unauthenticated \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Configure and install GD (PHP 5.6 style)
RUN docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli \
    gd \
    mbstring \
    zip \
    pcntl

# Trust /var/www for Git (same as main PHP image)
RUN git config --global --add safe.directory '*'

# Use www-data UID/GID 1000 so bind-mounted project files stay writable by host user
# (same as main PHP image); avoids needing chown and keeps Windows/WSL copy-paste working
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Composer 1.x (Composer 2 requires PHP 7.2+)
RUN curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --1 \
    && rm /tmp/composer-setup.php

WORKDIR /var/www

EXPOSE 9000
