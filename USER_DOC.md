# USER_DOC — Inception (User / Admin Guide)

This document is written for end users and administrators.

## 1) What services are provided

This stack provides a simple WordPress website behind an HTTPS reverse proxy:

- **Nginx** (public entry point)
  - Exposes **HTTPS on port 443**
  - Terminates TLS (self-signed certificate)
  - Forwards PHP requests to the WordPress PHP-FPM service
- **WordPress (PHP-FPM)**
  - Runs the WordPress application
  - Handles admin + content management
- **MariaDB**
  - Stores WordPress data (users, posts, settings, etc.)

Data flow:

`Browser → Nginx:443 → WordPress(PHP-FPM):9000 → MariaDB:3306`

## 2) Start / stop the project

From the project root:

- Start (build + run):

```bash
make up
```

- Stop containers:

```bash
make down
```

- Show status:

```bash
make ps
```

- Follow logs:

```bash
make logs
```

## 3) Access the website and the admin panel

### Website

Open:

- `https://$DOMAIN_NAME/`

Because the certificate is self-signed, the browser will show a warning — this is expected for this project.

### Admin panel

Open:

- `https://$DOMAIN_NAME/wp-admin/`

Login page:

- `https://$DOMAIN_NAME/wp-login.php`

## 4) Locate and manage credentials

### Where credentials are stored (host)

Credentials are stored as **files** under the `secrets/` directory:

- `secrets/db_root_password.txt` — MariaDB root password
- `secrets/db_password.txt` — MariaDB password for the WordPress DB user
- `secrets/wp_admin_password.txt` — WordPress admin password (used at first install)
- `secrets/wp_user_password.txt` — WordPress normal user password (used at first install)

These files must **not** be committed to git.

### Where credentials are mounted (containers)

Inside containers, secrets are mounted under:

- `/run/secrets/`

Example:

```bash
docker exec wordpress ls -1 /run/secrets
```

### Changing passwords (important)

- Changing a secret file and restarting containers **does not necessarily update WordPress users** if WordPress is already installed.
- WordPress user passwords are stored (hashed) in the database after installation.

To change a WordPress password on an existing installation, use `wp-cli`:

```bash
docker exec wordpress sh -lc 'cd /var/www/html && wp user update <login> --user_pass="NEW_PASSWORD" --allow-root'
```

If you want secrets to be reapplied automatically, you typically need a **full reset** (database + WordPress data):

```bash
make fclean
make up
```

## 5) Check that services are running correctly

### 1) Containers are up

```bash
make ps
```

Expected:

- `nginx` is **Up** and publishes `443:443`
- `wordpress` is **Up** (no published port, only internal)
- `mariadb` is **Up** (no published port, only internal)

### 2) HTTPS endpoint responds

```bash
curl -kI https://$DOMAIN_NAME
```

Expected: `HTTP/2 200` or a `30x` redirect.

### 3) WordPress is installed

```bash
docker exec wordpress sh -lc 'cd /var/www/html && wp core is-installed --allow-root'
```

### 4) Database responds

```bash
docker exec wordpress sh -lc 'cd /var/www/html && wp db check --allow-root'
```
