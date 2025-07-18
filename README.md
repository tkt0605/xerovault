# Xero Vault

Xero Vault is a sample project consisting of a **Django** backend and a **Nuxt** frontend.  The services are orchestrated using Docker Compose along with a Postgres database and an Nginx reverse proxy.

## Directory Overview

- `backend/` – Django project containing the API and admin site.
- `frontend/` – Nuxt application. The main source lives in `frontend/xerofront`.
- `nginx/` – Nginx configuration that proxies requests to the frontend and backend containers.
- `postgres/` – Initialization scripts for the Postgres container.
- `docker-compose.yml` – Compose file used to run the development environment.

## Running the Stack

1. Ensure Docker and Docker Compose are installed.
2. From the repository root run:

   ```bash
   docker-compose up --build
   ```

   This command builds the images (if necessary) and starts the containers.

## Accessing Services

- **Frontend**: [http://localhost:3000](http://localhost:3000) – Nuxt development server.
- **Backend API**: [http://localhost:8000](http://localhost:8000) – Django server.
- **Nginx Proxy**: [http://localhost:8080](http://localhost:8080) – Nginx forwards `/api/` and `/admin/` to the backend and serves the frontend at the root path.

Use the Nginx endpoint for an integrated experience or access the individual services directly on their respective ports.
