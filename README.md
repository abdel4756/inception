*This project has been created as part of the 42 curriculum by aait-laf.*

# Inception

## Description

This project builds a small web infrastructure using **Docker** and **Docker Compose**:

- **Nginx** is the only public entry point (HTTPS on port 443).
- **WordPress** runs as a PHP application served through **PHP-FPM**.
- **MariaDB** stores the WordPress data.

High-level data flow:

`Browser → Nginx:443 (TLS) → WordPress(PHP-FPM):9000 → MariaDB:3306`

The goal is to understand containerized infrastructure fundamentals: networking, TLS, persistence, and secret management.

---

## Key terms (quick glossary)

- **Docker image**: a packaged filesystem + metadata built from a `Dockerfile`.
- **Container**: a running instance of an image.
- **Docker Compose**: tool to define and run multiple containers together (`docker compose`).
- **Service**: one role in Compose (here: `nginx`, `wordpress`, `mariadb`).
- **Network**: virtual network that lets services reach each other by name (e.g. `mariadb`).
- **Volume / bind mount**: persistent host storage mounted into a container (data survives restarts).
- **Secret**: sensitive value mounted as a file (usually under `/run/secrets/...`).
- **Environment variables**: config values passed into a container.
- **`ports:` vs `expose:`**:
  - `ports:` publishes a container port to the host machine (browser can reach it).
  - `expose:` is internal-only (other containers in the same network can reach it).

---

## Services

### 1) Nginx (HTTPS reverse proxy)

**What it does**

- Listens on **443** with **TLS v1.2 / v1.3**
- Serves WordPress files from `/var/www/html`
- Forwards PHP requests to PHP-FPM at `wordpress:9000` (FastCGI)
- Uses the server name `inception.local`
- Uses a **self-signed certificate** (browser warning is expected)

**Main terms**

- **HTTPS / TLS**: encrypts traffic between the browser and Nginx.
- **Reverse proxy**: Nginx is the public entry point; it forwards dynamic requests to an upstream.
- **FastCGI**: protocol used by Nginx to send PHP requests to PHP-FPM.

### 2) WordPress (PHP-FPM)

**What it does**

- Runs **PHP-FPM** and listens on **9000** (internal)
- Generates `wp-config.php` (if missing)
- Connects to MariaDB using the service name `mariadb`
- Persists WordPress files via a bind mount

**Main terms**

- **WordPress**: PHP content management system (CMS).
- **PHP-FPM**: “PHP FastCGI Process Manager”, runs PHP and waits for FastCGI requests.
- **`wp-config.php`**: WordPress config file that stores DB host/name/user/password.

### 3) MariaDB

**What it does**

- MariaDB server listening on **3306** (internal)
- Initializes the database + user using the init script
- Persists database data via a bind mount

**Main terms**

- **MariaDB**: MySQL-compatible relational database server.
- **DB user + privileges**: credentials and permissions WordPress uses to read/write the database.
- **Bind address**: IP address MariaDB listens on; `0.0.0.0` means “all interfaces” (reachable from other containers).

---

## Instructions

### Prerequisites

- Docker + Docker Compose plugin
- `make` (optional but recommended)

On Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin make
```

### Configuration

#### 1) `.env`

Create a `.env` file at the project root:

```env
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wordpress_usr
```

#### 2) Secrets

Create the secrets files:

- `secrets/db_root_password.txt`
- `secrets/db_password.txt`

Example (generate strong random passwords):

```bash
mkdir -p secrets
openssl rand -base64 32 > secrets/db_root_password.txt
openssl rand -base64 32 > secrets/db_password.txt
```

### Environment variables (most important)

- `MYSQL_DATABASE`: database name that will be created in MariaDB.
- `MYSQL_USER`: database user that WordPress will use.
- `MYSQL_PASSWORD_FILE`: file containing the database user password (secret).
- `MYSQL_ROOT_PASSWORD_FILE`: file containing the MariaDB root password (secret).
- `WORDPRESS_DB_NAME`: database name used by WordPress (`wp-config.php`). In this project it is set from `MYSQL_DATABASE`.
- `WORDPRESS_DB_USER`: database user used by WordPress. In this project it is set from `MYSQL_USER`.
- `WORDPRESS_DB_PASSWORD_FILE`: password file used by WordPress (secret).
- `WORDPRESS_DB_HOST`: database host for WordPress (here: `mariadb`).

### Hostnames

Nginx is configured with `server_name inception.local`, so add this to your host machine:

```bash
echo "127.0.0.1 inception.local" | sudo tee -a /etc/hosts
```

If you are running Docker inside a VM, replace `127.0.0.1` with the VM IP.

### Run

Start:

```bash
make up
# or: docker compose up -d --build
```

Stop:

```bash
make down
```

Full reset (remove volumes + data):

```bash
make fclean
```

Status / logs:

```bash
make ps
make logs
```

### Test in the browser

1) Open:

- `https://inception.local`

2) Accept the self-signed certificate warning.

3) If WordPress is not installed yet, complete installation:

- `https://inception.local/wp-admin/install.php`

4) Admin dashboard:

- `https://inception.local/wp-admin`

---

## Design choices and comparisons

### Virtual Machines vs Docker

- **Virtual Machine (VM)**: runs a full guest OS on top of a hypervisor. Strong isolation but heavier (more RAM/CPU), slower boot, larger images.
- **Docker containers**: isolate processes using the host kernel (namespaces/cgroups). Lightweight, fast to start, easier to compose multiple services.

This project uses Docker to run multiple services consistently with less overhead than VMs.

### Secrets vs Environment Variables

- **Environment variables** are good for non-sensitive configuration, but they can be visible via inspection and sometimes logs.
- **Secrets** are mounted as files (here under `/run/secrets/`) and are not baked into images. This is better for passwords.

This project uses **secrets** for database passwords and **environment variables** for non-sensitive DB identifiers (name/user/host).

### Docker Network vs Host Network

- **Docker network (bridge)** provides isolation and automatic DNS-based service discovery (`mariadb`, `wordpress`). Only explicitly published ports are reachable from the host.
- **Host network** shares the host network stack (less isolation, higher risk of port conflicts, harder to restrict exposure).

This project uses a dedicated Docker bridge network so only Nginx is exposed publicly.

### Docker Volumes vs Bind Mounts

- **Docker volume**: managed by Docker, stored in Docker’s storage location, portable between setups.
- **Bind mount**: maps a specific host path into the container; easy to inspect on the host, but host-path-specific.

This project uses **bind mounts** under `/home/aait-laf/data/` to keep WordPress and MariaDB data persistent.

---

## Resources

### References

- Docker Compose documentation: https://docs.docker.com/compose/
- Docker volumes: https://docs.docker.com/storage/
- Nginx documentation: https://nginx.org/en/docs/
- PHP-FPM documentation: https://www.php.net/manual/en/install.fpm.php
- WordPress documentation: https://wordpress.org/documentation/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/

### AI usage

AI assistance (GitHub Copilot Chat) was used to:

- Diagnose HTTP errors (403/502/DB connection) by interpreting logs and container networking behavior.
- Propose minimal configuration fixes (Nginx index/volume mounts, Docker network reachability, env var alignment).
- Draft the Makefile and improve README documentation/definitions.

All changes were applied and validated locally with `docker compose` and `curl`.
# inception
