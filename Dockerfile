FROM php:8.2-fpm-alpine AS base

# System packages and PHP extensions for Laravel + Postgres
RUN apk add --no-cache \
    nginx \
    curl \
    git \
    bash \
    postgresql-dev \
    postgresql-client \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    zlib-dev \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) pdo_pgsql bcmath opcache zip intl gd exif fileinfo

WORKDIR /var/www/html

# Builder: install vendors with Composer
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress --no-scripts

# Final image
FROM base AS final
WORKDIR /var/www/html

# Copy app code and vendor deps
COPY --from=vendor /app/vendor /var/www/html/vendor
COPY --from=vendor /app/composer.lock /var/www/html/composer.lock
COPY . .

# Install Composer to run post-install scripts
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer run-script post-autoload-dump --no-interaction || true

# Nginx config
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Startup script
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Permissions
RUN mkdir -p storage bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

ENV APP_ENV=production
EXPOSE 8080

# Run migrations and start services
CMD ["/usr/local/bin/start.sh"]
