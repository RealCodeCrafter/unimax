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
}

echo "Waiting for MySQL..."
wait_for_mysql
import_sql_every_start

exec "$@"

