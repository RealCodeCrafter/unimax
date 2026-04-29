FROM wordpress:6.5-php8.2-fpm

# Internal only — must NOT match Railway $PORT (often 8080; users sometimes set 9000 for HTTP).
ENV PHP_FPM_LISTEN=9001
ARG CACHEBUST=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx supervisor gettext-base ca-certificates default-mysql-client && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/php /var/log/supervisor

# Install WP-CLI for safe serialized search-replace after SQL import.
RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

RUN echo "cachebust=${CACHEBUST}"

# The fpm image keeps WordPress source under /usr/src/wordpress.
# Copy it into the web root so index.php and core files always exist.
RUN cp -a /usr/src/wordpress/. /var/www/html/

# Keep a clean core snapshot used by entrypoint for restoring vendor polyfills if missing.
RUN mkdir -p /opt/base-core/wp-includes && cp -a /var/www/html/wp-includes/. /opt/base-core/wp-includes/

# Copy only the parts we actually want to override:
# - wp-content (plugins/themes/uploads)
# - wp-config.php (DB config)
# - DB dump for first-run import
COPY wp-content /var/www/html/wp-content
COPY wp-config.php /var/www/html/wp-config.php
COPY unimaxtecdbs.sql /var/www/html/unimaxtecdbs.sql

# Seed snapshot for cases where Railway mounts an empty disk over wp-content.
RUN mkdir -p /opt/www-seed && cp -a /var/www/html/wp-content/. /opt/www-seed/wp-content/

# Ensure correct ownership for WordPress to write to wp-content
RUN chown -R www-data:www-data /var/www/html

# Nginx config (use envsubst to inject $PORT on container start)
COPY docker/nginx.conf.template /etc/nginx/nginx.conf.template


# Supervisor config to run php-fpm and nginx together
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# PHP-FPM on loopback:9001 so Railway can set PORT=9000 for nginx HTTP without bind conflicts.
# clear_env=no so PHP sees Railway vars (e.g. RAILWAY_PUBLIC_DOMAIN) in wp-config.php.
RUN if [ -f /usr/local/etc/php-fpm.d/www.conf ]; then \
      sed -i 's|^listen = .*|listen = 127.0.0.1:9001|' /usr/local/etc/php-fpm.d/www.conf; \
      sed -i 's/^clear_env = yes/clear_env = no/' /usr/local/etc/php-fpm.d/www.conf; \
      sed -i 's/^;clear_env = no/clear_env = no/' /usr/local/etc/php-fpm.d/www.conf || true; \
      grep -q '^clear_env[[:space:]]*=' /usr/local/etc/php-fpm.d/www.conf || \
        echo 'clear_env = no' >> /usr/local/etc/php-fpm.d/www.conf; \
    fi

# Startup script: imports SQL dump into DB on first boot (idempotent)
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Railway will set PORT; default to 8080 if not provided
ENV PORT=8080
EXPOSE 8080

# Run entrypoint, then start supervisor (CMD)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

