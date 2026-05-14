#!/bin/bash

# Étape 1 : Générer le certificat SSL si absent
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    echo "🔐 Generating SSL certificate..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}"
    echo "✅ SSL certificate generated!"
fi

# Étape 2 : Lancer Nginx en foreground
echo "🚀 Starting Nginx..."
exec nginx -g "daemon off;"