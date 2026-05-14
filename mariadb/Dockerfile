FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    apt-get clean

COPY init.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 3306

CMD ["/setup.sh"]