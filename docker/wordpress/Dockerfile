# WordPress development image for the Lions International theme.
#
# PHP 8.3 is the project's PHP version. Keep this in sync with:
#   - .github/workflows/*.yml   (php-version)
#   - theme/composer.json       (config.platform.php / require.php)
#   - README.md
FROM wordpress:6.9-php8.3-apache

# Composer (copied from the official image, no curl|sh) and WP-CLI for
# scripted installs / seeding inside the container.
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
ADD --chmod=755 https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip less default-mysql-client gettext \
    && rm -rf /var/lib/apt/lists/*

# Sensible PHP settings for local development.
RUN { \
      echo 'upload_max_filesize = 64M'; \
      echo 'post_max_size = 64M'; \
      echo 'memory_limit = 256M'; \
      echo 'max_execution_time = 120'; \
    } > /usr/local/etc/php/conf.d/lions-dev.ini \
    && mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

ENV COMPOSER_ALLOW_SUPERUSER=1
WORKDIR /var/www/html

# Keeps wp-content/uploads writable by the web server user before handing over
# to the official entrypoint, so media uploads work in wp-admin.
COPY --chmod=755 entrypoint.sh /usr/local/bin/lions-entrypoint.sh
ENTRYPOINT ["lions-entrypoint.sh"]
CMD ["apache2-foreground"]
