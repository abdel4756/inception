#!/bin/bash

#lire secrets 

DB_ROOT_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)
DB_PASSWORD=$(cat $MYSQL_PASSWORD_FILE)

#Verifiere si DB est deja initailisee 
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initialisation MaraiDB..."

    #creation fichier systeme
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

fi 

#Demarage temporaire 
mysqld_safe --datadir=/var/lib/mysql &

until mysqladmin ping -h localhost --silent; do
    sleep 1
done

#creation SQL 
mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${WORDPRESS_DB_NAME};
CREATE USER IF NOT EXISTS '${WORDPRESS_DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${WORDPRESS_DB_NAME}.* TO '${WORDPRESS_DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

#stop propre 
mysqladmin -u root -p${DB_ROOT_PASSWORD} shutdown

echo "Starting MariaDB..."
exec mysqld_safe --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3306