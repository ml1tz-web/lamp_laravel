FROM php:8.2-apache

RUN a2enmod rewrite

RUN docker-php-ext-install pdo pdo_mysql mysqli

# Install Node.js and npm (Node.js 18.x)
RUN apt-get update && apt-get install -y curl gnupg git && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Remove default files to avoid conflicts
RUN rm -rf /var/www/html/*

WORKDIR /var/www/html

# Copy the entire application
COPY ./my-app/ .

# Ensure .env file exists
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Install Composer dependencies with progress
RUN composer install --no-interaction --no-dev --optimize-autoloader --prefer-dist

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html/storage

# Generate application key if not exists
RUN php artisan key:generate --force

# Clear and cache configuration
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

RUN echo '<Directory /var/www/html/public>\n\
    AllowOverride All\n\
</Directory>' >> /etc/apache2/apache2.conf

RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf
