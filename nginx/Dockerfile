FROM debian:bookworm-slim

# Installer Nginx et outils
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Créer les répertoires
RUN mkdir -p /var/www/html
RUN mkdir -p /etc/nginx/ssl

# Copier la configuration Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copier et rendre exécutable le script
COPY nginx_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/nginx_entrypoint.sh

# Exposer UNIQUEMENT le port 443 (HTTPS)
EXPOSE 443

# Lancer le script d'entrée
CMD ["/usr/local/bin/nginx_entrypoint.sh"]