# DriftLine

DriftLine is a local-first cryptocurrency market data engineering project.

## Current Project Scope

**Milestone P1 (Local Infrastructure & Docker Setup)** is currently implemented:
- Containerized PostgreSQL 15 instance with Airflow metadata DB (`airflow`) and analytics warehouse DB (`pulsecheck_dw`).
- Custom Apache Airflow 2.10.5 Docker image (`LocalExecutor`) pre-packaged with core Python dependencies (`boto3`, `requests`, `pandas`, `dbt-postgres`).
- Foundational repository layout (`dags/`, `src/`, `dbt/`, `config/`, `logs/`, `docker/`).

Not yet implemented (planned for future milestones):
- Extraction scripts or CoinGecko API integration
- S3 upload/download logic
- Airflow ingestion DAGs or warehouse tables
- dbt project initialization, models, or tests

## Current Architecture

```text
+---------------------------------------------------------------+
| Docker Compose (macOS / Apple Silicon compatible)             |
|                                                               |
|  +-----------------------+     +---------------------------+  |
|  | airflow-webserver     |     | airflow-scheduler         |  |
|  | (LocalExecutor, :8080)|     | (LocalExecutor)           |  |
|  +-----------+-----------+     +-------------+-------------+  |
|              |                               |                |
|              +---------------+---------------+                |
|                              |                                |
|                              v                                |
|              +-------------------------------+                |
|              | postgres:15 (:5432)           |                |
|              |  - airflow (metadata DB)      |                |
|              |  - pulsecheck_dw (future DW)  |                |
|              +-------------------------------+                |
+---------------------------------------------------------------+
```

- **Orchestrator**: Apache Airflow `2.10.5` (`LocalExecutor`), split into `airflow-webserver` and `airflow-scheduler`, plus a one-shot `airflow-init` container for database migrations and admin user creation.
- **Database**: PostgreSQL `15` storing both the Airflow metadata database (`airflow`) and an isolated warehouse database (`pulsecheck_dw`) created at first startup via `docker/postgres/init/01-init-databases.sh`.
- **Custom Image**: Built from `apache/airflow:2.10.5-python3.11` with `boto3`, `requests`, `pandas`, and `dbt-postgres` constrained against the official Airflow constraints file.

## Prerequisites

- macOS (Apple Silicon / Intel) with **Docker Desktop** installed and running
- Docker Compose v2+ (`docker compose`)
- At least 4 GB RAM allocated to Docker Desktop

## Local Setup

1. Create a local `.env` file from the template (optional, as `docker-compose.yml` provides local development defaults, or recommended so you can customize values):

   ```bash
   cp .env.example .env
   ```

2. Review `.env` and update any placeholders (for example `AIRFLOW__CORE__FERNET_KEY`, `AIRFLOW__WEBSERVER__SECRET_KEY`, or AWS placeholders when needed in later milestones). Never commit `.env` to version control.

3. Validate the Compose configuration and build the custom Airflow image:

   ```bash
   docker compose config -q
   docker compose build
   ```

## Start the Containers

Start PostgreSQL, run Airflow DB initialization, and launch the webserver and scheduler in detached mode:

```bash
docker compose up -d
```

Check container status and health:

```bash
docker compose ps
```

Wait until `driftline-postgres`, `driftline-airflow-webserver`, and `driftline-airflow-scheduler` all report `(healthy)`, and `driftline-airflow-init` has exited with status `0`.

## Access Airflow

- **Web UI**: [http://localhost:8080](http://localhost:8080)
- **Default credentials** (unless overridden in `.env`):
  - Username: `admin`
  - Password: `admin`

You can also check the Airflow health endpoint directly:

```bash
curl -f http://localhost:8080/health
```

And verify the active executor inside the webserver or scheduler container:

```bash
docker compose exec airflow-webserver airflow config get-value core executor
```

## Verify PostgreSQL

Check PostgreSQL readiness and list databases (confirming both `airflow` and `pulsecheck_dw` exist):

```bash
docker compose exec postgres pg_isready -U airflow -d airflow
docker compose exec postgres psql -U airflow -d airflow -c "\l"
```

Verify direct connection to `pulsecheck_dw`:

```bash
docker compose exec postgres psql -U airflow -d pulsecheck_dw -c "SELECT current_database(), version();"
```

## Stop the Infrastructure

Stop and remove the running containers while preserving the `postgres_data` volume:

```bash
docker compose down
```

To stop and also remove the PostgreSQL volume (wipes local databases so init scripts will re-run on next startup):

```bash
docker compose down -v
```

