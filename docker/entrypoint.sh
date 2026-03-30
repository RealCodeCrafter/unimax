#!/bin/sh
set -eu

SQL_FILE="/var/www/html/unimaxtecdbs.sql"

# Read DB credentials from wp-config.php without bootstrapping WordPress.
# (wp-config.php in this project ends with wp-settings.php include, which would emit warnings in CLI)
extract_wp_config() {
  php -r '
    $f = file_get_contents("/var/www/html/wp-config.php");
    $key = $argv[1];
    $re = "/define\\(\\s*[\\x27\\\"]".preg_quote($key,"/")."[\\x27\\\"]\\s*,\\s*[\\x27\\\"]([^\\x27\\\"]*)[\\x27\\\"]\\s*\\)/";
    if (preg_match($re, $f, $m)) { echo $m[1]; }
  ' "$1"
}

DB_NAME="$(extract_wp_config DB_NAME || true)"
DB_USER="$(extract_wp_config DB_USER || true)"
DB_PASSWORD="$(extract_wp_config DB_PASSWORD || true)"
DB_HOST_STR="$(extract_wp_config DB_HOST || true)"

DB_HOST_ONLY="$(printf '%s' "$DB_HOST_STR" | cut -d: -f1)"
DB_PORT_ONLY="$(printf '%s' "$DB_HOST_STR" | cut -s -d: -f2)"
if [ -z "$DB_PORT_ONLY" ]; then
  DB_PORT_ONLY="3306"
fi

TABLE_PREFIX="hihqh_" # $table_prefix in your wp-config is "hihqh_"
TARGET_SITE_URL="https://unimax-production-c86b.up.railway.app"

wait_for_mysql() {
  # Wait a bit for Railway MySQL to be reachable
  i=0
  while [ $i -lt 60 ]; do
    if mysqladmin ping -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" --silent >/dev/null 2>&1; then
      return 0
    fi
    i=$((i + 1))
    sleep 2
  done
  return 1
}

ensure_wp_core_files() {
  # Guard against empty/overwritten web root (can happen with bad mounts/copy order).
  if [ ! -f /var/www/html/index.php ] || [ ! -f /var/www/html/wp-blog-header.php ]; then
    echo "WordPress core files missing in /var/www/html; restoring from /usr/src/wordpress ..."
    cp -a /usr/src/wordpress/. /var/www/html/
    chown -R www-data:www-data /var/www/html/ 2>/dev/null || true
  fi
}

drop_all_tables() {
  # Drops ALL tables in the target database. This is destructive (as requested).
  tables="$(mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" \
    -N -s -e "SELECT table_name FROM information_schema.tables WHERE table_schema='$DB_NAME';" 2>/dev/null || true)"

  if [ -z "$tables" ]; then
    return 0
  fi

  for t in $tables; do
    mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" \
      -e "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS \`${t}\`; SET FOREIGN_KEY_CHECKS=1;" >/dev/null 2>&1 || true
  done
}

import_sql_every_start() {
  if [ ! -f "$SQL_FILE" ]; then
    echo "SQL file not found at $SQL_FILE. Cannot import."
    return 1
  fi

  echo "Resetting database '${DB_NAME}' and importing '${SQL_FILE}'..."
  drop_all_tables

  mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE"
  echo "SQL import finished."

  # Keep WordPress canonical URL fixed on Railway after each destructive reset/import.
  mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "
    UPDATE ${TABLE_PREFIX}options
    SET option_value='${TARGET_SITE_URL}'
    WHERE option_name IN ('siteurl','home');
  " >/dev/null 2>&1 || true
  echo "Updated siteurl/home to ${TARGET_SITE_URL}"
}

disable_broken_aio_security_plugin() {
  # If the plugin's PHP vendor files are missing, WP will fatally crash.
  AIO_PLUGIN_DIR="/var/www/html/wp-content/plugins/all-in-one-wp-security-and-firewall"
  AIO_VENDOR_FILE="/var/www/html/wp-content/plugins/all-in-one-wp-security-and-firewall/vendor/team-updraft/common-libs/src/updraft-semaphore/class-updraft-semaphore.php"
  if [ ! -f "$AIO_VENDOR_FILE" ]; then
    if [ -d "$AIO_PLUGIN_DIR" ]; then
      echo "AIOWPS vendor files are missing; disabling plugin to prevent 500 crash."
      mv "$AIO_PLUGIN_DIR" "${AIO_PLUGIN_DIR}.disabled"
    fi
  fi
}

seed_wordpress_files_if_missing() {
  # If Railway mounts empty disk, files disappear -> seed them back from image copy.
  UPLOADS_MARKER="/var/www/html/wp-content/uploads/elementor/css/global.css"
  # Logs show missing polyfill files under wp-includes/js/dist/vendor/.
  WP_VENDOR_MARKER="/var/www/html/wp-includes/js/dist/vendor/wp-polyfill-inert.min.js"

  echo "Seed check: uploads marker exists? $( [ -f "$UPLOADS_MARKER" ] && echo yes || echo no ); wp vendor marker exists? $( [ -f "$WP_VENDOR_MARKER" ] && echo yes || echo no )"

  if [ -f "$UPLOADS_MARKER" ] && [ -f "$WP_VENDOR_MARKER" ]; then
    echo "Seed not needed."
    return 0
  fi

  # Restore uploads/wp-content if missing.
  if [ ! -f "$UPLOADS_MARKER" ]; then
    if [ -d "/opt/www-seed/wp-content" ]; then
      echo "Seeding missing wp-content/uploads from /opt/www-seed ..."
      cp -a /opt/www-seed/wp-content/. /var/www/html/wp-content/
      chown -R www-data:www-data /var/www/html/wp-content/ 2>/dev/null || true
    else
      echo "No /opt/www-seed/wp-content found; cannot seed uploads."
    fi
  fi

  # Restore wp-includes JS vendor if missing (from base-core snapshot).
  if [ ! -f "$WP_VENDOR_MARKER" ]; then
    if [ -d "/opt/base-core/wp-includes" ]; then
      echo "Seeding missing wp-includes/js/dist/vendor from /opt/base-core ..."
      cp -a /opt/base-core/wp-includes/. /var/www/html/wp-includes/
      chown -R www-data:www-data /var/www/html/wp-includes/ 2>/dev/null || true
    else
      echo "No /opt/base-core/wp-includes found; cannot seed core vendor."
    fi
    echo "After seed: wp vendor marker exists? $( [ -f "$WP_VENDOR_MARKER" ] && echo yes || echo no )"
  fi

  echo "Seed result: uploads marker exists? $( [ -f "$UPLOADS_MARKER" ] && echo yes || echo no ); wp vendor marker exists? $( [ -f "$WP_VENDOR_MARKER" ] && echo yes || echo no )"
  if [ ! -f "$UPLOADS_MARKER" ]; then
    echo "Uploads directory snapshot:"
    ls -la /var/www/html/wp-content/uploads/elementor/css 2>/dev/null || true
  fi
}

rewrite_old_asset_urls() {
  # Elementor-generated CSS may still contain absolute old-domain links.
  # Rewrite those links so background images load from this Railway app.
  CSS_DIR="/var/www/html/wp-content/uploads/elementor/css"
  if [ ! -d "$CSS_DIR" ]; then
    return 0
  fi

  echo "Rewriting old absolute URLs inside Elementor CSS..."
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|https://unimaxtec.uz|${TARGET_SITE_URL}|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|http://unimaxtec.uz|${TARGET_SITE_URL}|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|https://www.unimaxtec.uz|${TARGET_SITE_URL}|g" {} + || true
  find "$CSS_DIR" -type f -name "*.css" \
    -exec sed -i "s|http://www.unimaxtec.uz|${TARGET_SITE_URL}|g" {} + || true
}

rewrite_old_urls_in_database() {
  # Update old-domain URLs in DB safely (handles serialized arrays/objects).
  if ! command -v wp >/dev/null 2>&1; then
    echo "wp-cli not found, skipping DB URL rewrite."
    return 0
  fi

  echo "Running wp search-replace for old domain URLs..."
  wp search-replace 'https://unimaxtec.uz' "${TARGET_SITE_URL}" \
    --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'http://unimaxtec.uz' "${TARGET_SITE_URL}" \
    --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'https://www.unimaxtec.uz' "${TARGET_SITE_URL}" \
    --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
  wp search-replace 'http://www.unimaxtec.uz' "${TARGET_SITE_URL}" \
    --all-tables --allow-root --path=/var/www/html --skip-columns=guid >/dev/null 2>&1 || true
}

echo "Waiting for MySQL..."
wait_for_mysql
ensure_wp_core_files
seed_wordpress_files_if_missing
disable_broken_aio_security_plugin
import_sql_every_start
rewrite_old_urls_in_database
rewrite_old_asset_urls

exec "$@"

