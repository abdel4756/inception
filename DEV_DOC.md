# DEV_DOC — Inception (Developer Guide)

This document is written for developers who want to set up, build, and maintain the stack.

## 1) Prerequisites

- Linux host (or a VM) with:
  - Docker Engine
  - Docker Compose plugin
  - `make`

Typical Debian/Ubuntu install:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin make
```

## 2) Repository structure (overview)

- `docker-compose.yml` — defines services, network, volumes, secrets
- `Makefile` — convenience commands (`make up`, `make down`, `make fclean`, ...)
- `nginx/` — Nginx image (TLS termination + reverse proxy)
- `wordpress/` — WordPress PHP-FPM image (includes wp-cli, auto-provisioning)
- `mariadb/` — MariaDB image (init script creates DB + user)
- `secrets/` — secret files mounted into containers (gitignored)

## 3) Configuration from scratch

### 3.1 Create required host directories (persistent data)

This project uses bind-mounted volumes under `/home/<login>/data/`.

Create them:

```bash
mkdir -p "$HOME/data/wordpress" "$HOME/data/mariadb"
```

### 3.2 Create `.env`

Create a `.env` file at the project root (it must not be committed).

Minimal example:

```env
# Domain used by Nginx certificate / WordPress URLs
DOMAIN_NAME=aait-laf.42.fr

# MariaDB / WordPress database
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress_usr

# WordPress users
WP_ADMIN_USER=aait-laf42
WP_ADMIN_EMAIL=aait-laf@42.fr

USER_LOGIN=aait-laf
WP_USER_EMAIL=aait-laf.user@42.fr
```

Adjust values as needed.

### 3.3 Create secrets

Create these files (one line each):

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

Example generation:

```bash
mkdir -p secrets
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt
openssl rand -base64 32 > secrets/wp_admin_password.txt
openssl rand -base64 32 > secrets/wp_user_password.txt
```

Important:

- `secrets/` and `.env` are gitignored (do not commit them).

### 3.4 Hostname resolution

Your browser must resolve `$DOMAIN_NAME` to the machine running Docker.

If Docker runs on your local host, map it to `127.0.0.1`:

```bash
echo "127.0.0.1 $DOMAIN_NAME" | sudo tee -a /etc/hosts
```

If Docker runs inside a VM, map it to the VM IP instead.

## 4) Build and launch

From the project root:

- Build + run:

```bash
make up
```

Equivalent command:

```bash
docker compose up -d --build
```

- Stop:

```bash
make down
```

- Full reset (removes volumes and deletes bind-mounted data directories):

```bash
make fclean
```

## 5) Useful operational commands

### 5.1 Status / logs

```bash
docker compose ps
docker compose logs -f --tail=100
```

### 5.2 Enter containers

```bash
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
```

### 5.3 WordPress management (wp-cli)

```bash
docker exec wordpress sh -lc 'cd /var/www/html && wp user list --allow-root'
```

### 5.4 Volumes and persistent data

The stack persists data via bind mounts:

- WordPress files: `/home/<login>/data/wordpress/`
  - WordPress core files, uploads, `wp-config.php`, etc.
- MariaDB data: `/home/<login>/data/mariadb/`
  - database files under `/var/lib/mysql`

Because data is persisted on the host, rebuilding images does not wipe the site.

To wipe everything and re-provision from secrets, use:

```bash
make fclean
make up
```

## 6) Quick validation checklist

- Only Nginx publishes a port:

```bash
docker compose ps
```

Expected: `nginx` publishes `443:443`, WordPress/MariaDB do not publish ports.

- HTTPS responds:

```bash
curl -kI https://$DOMAIN_NAME
```

- WordPress URLs are set to HTTPS:

```bash
docker exec wordpress sh -lc 'cd /var/www/html && wp option get home --allow-root && wp option get siteurl --allow-root'
```
