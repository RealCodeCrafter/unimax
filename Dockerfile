FROM wordpress:6.5-php8.2-fpm

ENV PHP_FPM_LISTEN=9000

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx supervisor gettext-base ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/php /var/log/supervisor

# Copy project into the web root
COPY . /var/www/html

# Ensure correct ownership for WordPress to write to wp-content
RUN chown -R www-data:www-data /var/www/html

# Nginx config (use envsubst to inject $PORT on container start)
COPY docker/nginx.conf.template /etc/nginx/nginx.conf.template

# Supervisor config to run php-fpm and nginx together
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Railway will set PORT; default to 8080 if not provided
ENV PORT=8080
EXPOSE 8080

# Start supervisor which will render nginx.conf from template and start services
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

