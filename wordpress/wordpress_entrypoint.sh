#!/bin/bash

# Attendre MariaDB
while ! nc -z mariadb 3306; do
    sleep 1
done

cd /var/www/html

# Créer wp-config.php
if [ ! -f wp-config.php ]; then
    wp core config \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$WORDPRESS_DB_USER \
        --dbpass=$(cat /run/secrets/db_password) \
        --dbhost=mariadb \
        --allow-root
fi

# attendre que DB réponde vraiment
until wp db check --allow-root 2>/dev/null; do
    echo "waiting database..."
    sleep 2
done



# Installer WordPress seulement si pas installé
if ! wp core is-installed --allow-root; then

    # créer admin
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="Inception" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$(cat /run/secrets/wp_admin_password) \
        --admin_email=$WP_ADMIN_EMAIL \
        --allow-root

    # créer user normal
    wp user create \
        $USER_LOGIN \
        $WP_USER_EMAIL \
        --user_pass=$(cat /run/secrets/wp_user_password) \
        --role=author \
        --allow-root
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F