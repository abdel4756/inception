FROM debian:bookworm-slim

RUN apt update && apt install -y \
    php-fpm \
    php-mysql \
    php-gd \
    php-zip \
    php-curl \
    php-mbstring \
    mariadb-client \
    curl \
    netcat-openbsd

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html

RUN cd /tmp && \
    curl -O https://wordpress.org/latest.tar.gz && \
    tar -xzf latest.tar.gz && \
    cp -r wordpress/* /var/www/html/ && \
    rm -rf wordpress latest.tar.gz

RUN chown -R www-data:www-data /var/www/html

COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY wordpress_entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wordpress_entrypoint.sh

EXPOSE 9000

CMD ["/usr/local/bin/wordpress_entrypoint.sh"]