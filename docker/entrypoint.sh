#!/bin/sh
set -eu

SQL_FILE="/var/www/html/unimaxtecdbs.sql"

# Read DB credentials from wp-config.php (so we don't duplicate logic)
DB_NAME="$(php -r "require '/var/www/html/wp-config.php'; echo DB_NAME;")"
DB_USER="$(php -r "require '/var/www/html/wp-config.php'; echo DB_USER;")"
DB_PASSWORD="$(php -r "require '/var/www/html/wp-config.php'; echo DB_PASSWORD;")"
DB_HOST_STR="$(php -r "require '/var/www/html/wp-config.php'; echo DB_HOST;")"

DB_HOST_ONLY="$(printf '%s' "$DB_HOST_STR" | cut -d: -f1)"
DB_PORT_ONLY="$(printf '%s' "$DB_HOST_STR" | cut -s -d: -f2)"
if [ -z "$DB_PORT_ONLY" ]; then
  DB_PORT_ONLY="3306"
fi

TABLE_PREFIX="hihqh_" # $table_prefix in your wp-config is "hihqh_"

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

mysql_table_exists() {
  # Returns 0 if any WP table with the configured prefix exists, 1 otherwise.
  mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" \
    -e "SELECT 1 FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_name LIKE '${TABLE_PREFIX}%' LIMIT 1;" >/dev/null 2>&1
}

import_sql_if_needed() {
  if mysql_table_exists; then
    echo "DB already initialized (found tables with prefix '${TABLE_PREFIX}'). Skipping SQL import."
    return 0
  fi

  if [ ! -f "$SQL_FILE" ]; then
    echo "SQL file not found at $SQL_FILE. Skipping SQL import."
    return 0
  fi

  echo "Importing SQL dump into ${DB_NAME}..."
  mysql -h "$DB_HOST_ONLY" -P "$DB_PORT_ONLY" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE"
  echo "SQL import finished."
}

echo "Waiting for MySQL..."
wait_for_mysql
import_sql_if_needed

exec "$@"

