FROM wordpress:6.5-php8.2-apache

# Enable Apache rewrite (usually enabled in the base image, this is safe to repeat)
RUN a2enmod rewrite

# Copy project into the web root
COPY . /var/www/html

# Ensure correct ownership for WordPress to write to wp-content
RUN chown -R www-data:www-data /var/www/html

# Optional: healthcheck to ensure Apache is serving
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD curl -f http://localhost/ || exit 1

# The base image exposes port 80 and runs Apache by default

