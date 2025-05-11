# --- Build stage (composer only, no apt-get) ---
FROM composer:2.5 as build

WORKDIR /app
COPY . .

RUN composer install --prefer-dist --no-dev --optimize-autoloader --no-interaction

# --- Production stage (Apache + PHP 8.2) ---
FROM php:8.2-apache-buster as production

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    unzip git libzip-dev zip curl \
    && docker-php-ext-install pdo pdo_mysql zip \
    && a2enmod rewrite

WORKDIR /var/www/html

# Copy app and composer output
COPY --from=build /app /var/www/html
COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/000-default.conf /etc/apache2/sites-available/000-default.conf

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage

EXPOSE 80
