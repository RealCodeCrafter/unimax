FROM wordpress:6.5-php8.2-fpm

ENV PHP_FPM_LISTEN=9000
ARG CACHEBUST=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx supervisor gettext-base ca-certificates default-mysql-client && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/php /var/log/supervisor

RUN echo "cachebust=${CACHEBUST}"

# Take a reliable copy of WordPress core (wp-includes) from the base image.
# We probe possible paths because the official image layout can vary by tag.
RUN set -eu; \
    mkdir -p /opt/base-core; \
    if [ -d /var/www/html/wp-includes ]; then \
      cp -a /var/www/html/wp-includes/. /opt/base-core/wp-includes/; \
    elif [ -d /usr/src/wordpress/wp-includes ]; then \
      cp -a /usr/src/wordpress/wp-includes/. /opt/base-core/wp-includes/; \
    elif [ -d /var/www/wordpress/wp-includes ]; then \
      cp -a /var/www/wordpress/wp-includes/. /opt/base-core/wp-includes/; \
    else \
      echo "wp-includes not found in known locations. Listing /var/www/html:"; \
      ls -la /var/www/html || true; \
      exit 1; \
    fi

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

# Ensure php-fpm listens on TCP 9000 (so nginx can reach it consistently)
RUN if [ -f /usr/local/etc/php-fpm.d/www.conf ]; then \
      sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /usr/local/etc/php-fpm.d/www.conf; \
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

