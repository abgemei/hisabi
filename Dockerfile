# --- Build stage ---
FROM composer:2.5 AS build

# Install system dependencies for Laravel
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev zip curl \
    && docker-php-ext-install pdo pdo_mysql zip

WORKDIR /app
COPY . .

# Run composer install with PHP 8.2
RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction

# --- Production stage ---
FROM php:8.2-apache-buster AS production

ENV APP_ENV=production
ENV APP_DEBUG=false

# Install PHP extensions and Apache modules
RUN apt-get update && apt-get install -y libzip-dev zip \
    && docker-php-ext-install pdo pdo_mysql zip \
    && a2enmod rewrite

# Add Laravel-specific configs
COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy app from build stage
COPY --from=build /app /var/www/html

# Set correct file permissions
RUN chown -R www-data:www-data /var/www/html/storage \
    && chmod -R 775 /var/www/html/storage

# Artisan commands moved to post-deploy (to avoid `.env` issues during build)
