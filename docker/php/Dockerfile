# Laravel shared PHP 8.3-FPM container
# Replicates production: single PHP for all projects
# Includes all required extensions, Composer, Node LTS, Supervisor

FROM php:8.3-fpm

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-client \
    ghostscript \
    git \
    unzip \
    vim \
    nano \
    poppler-utils \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libmagickwand-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libgmp-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    gd \
    pdo_mysql \
    mbstring \
    xml \
    curl \
    zip \
    bcmath \
    intl \
    opcache \
    exif \
    pcntl \
    soap \
    xsl \
    gmp

# PECL extensions
RUN pecl install redis imagick \
    && docker-php-ext-enable redis imagick

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Install Node.js LTS (20.x)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Xdebug (config loaded conditionally via php.ini)
ARG XDEBUG_VERSION=3.3.1
RUN pecl install xdebug-${XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug || true

# MariaDB/MySQL client: disable SSL so mysql/mariadb CLI works when server has no SSL (e.g. migratedbschema:update)
RUN printf '%s\n' '[client]' 'skip-ssl' '[mysql]' 'skip-ssl' > /etc/my.cnf && chmod 644 /etc/my.cnf

# Create log directory and set permissions
RUN mkdir -p /var/log/php /var/log/supervisor \
    && chown -R www-data:www-data /var/log/php /var/log/supervisor

# Use www-data with UID/GID 1000 for host volume compatibility
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Git: trust /var/www when running as root (bind-mounted host projects have host ownership)
RUN git config --global --add safe.directory '*'

WORKDIR /var/www

# Development: show errors; Xdebug uses XDEBUG_MODE from .env
ENV PHP_IDE_CONFIG="serverName=laravel-docker"

EXPOSE 9000

# Run as root so Supervisor can start PHP-FPM and workers (PHP-FPM runs as www-data)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
