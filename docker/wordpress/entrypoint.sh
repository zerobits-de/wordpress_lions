#!/usr/bin/env bash
# Wrapper around the official WordPress entrypoint.
#
# The uploads directory lives in the `wp_data` volume and is created by Docker
# (or by WP-CLI running as root), so it ends up owned by root:root. Apache
# serves as www-data, which then cannot write into it and every media upload in
# wp-admin fails with "Die Datei ... konnte nicht geschrieben werden".
# Handing the directory to the web server user on every start keeps uploads
# working, including after `make install` has written into it as root.
set -Eeuo pipefail

if [ "$(id -u)" = '0' ]; then
	uploads='/var/www/html/wp-content/uploads'
	mkdir -p "$uploads"
	chown -R "${APACHE_RUN_USER:-www-data}:${APACHE_RUN_GROUP:-www-data}" "$uploads"
fi

exec docker-entrypoint.sh "$@"
