FROM wordpress:6.5-php8.2-apache

# Enable Apache rewrite (usually enabled in the base image, this is safe to repeat)
RUN a2enmod rewrite \
 && a2dismod mpm_event mpm_worker || true \
 && a2enmod mpm_prefork

# Copy project into the web root
COPY . /var/www/html

# Ensure correct ownership for WordPress to write to wp-content
RUN chown -R www-data:www-data /var/www/html

# The base image exposes port 80 and runs Apache by default

