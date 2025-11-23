#!/bin/sh
set -e

echo "Running database migrations..."
php artisan migrate --force

echo "Starting PHP-FPM and Nginx..."
php-fpm -F & nginx -g 'daemon off;'
