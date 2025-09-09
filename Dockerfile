FROM php:8.2-apache

ARG PHP_MEMORY_LIMIT=256M
ARG PHP_MAX_EXECUTION_TIME=600
ARG PHP_UPLOAD_MAX_FILESIZE=500M
ARG PHP_POST_MAX_SIZE=500M

# Use production PHP settings
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Update and install dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpng-dev \
        libzip-dev \
        zlib1g-dev \
        libonig-dev \
        curl \
        sendmail \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo \
        pdo_mysql \
        zip \
        mbstring \
        gd

# Configure PHP
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory-limit.ini \
    && echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/docker-php-max-execution-time.ini \
    && echo "upload_max_filesize = 500M" >> /usr/local/etc/php/conf.d/docker-php-upload-max-filesize.ini \
    && echo "post_max_size = 500M" >> /usr/local/etc/php/conf.d/docker-php-post-max-size.ini

# Configure Apache
RUN a2enmod rewrite headers ssl
RUN sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf \
    && sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# Create a non-root user
RUN useradd -r -u 1000 -g www-data webuser

# Create PHP log directory and set permissions
RUN mkdir -p /var/log/php \
    && chown -R webuser:www-data /var/log/php \
    && chmod 755 /var/log/php
    
COPY  www/  /var/www/html
# Set proper permissions for web directory
RUN chown -R webuser:www-data /var/www/html \
    && chmod -R 777 /var/www/html 

# Switch to non-root user
USER webuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost/ || exit 1
