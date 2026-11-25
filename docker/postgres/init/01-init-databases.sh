#!/usr/bin/env bash
set -euo pipefail

DW_DB="${POSTGRES_DW_DB:-pulsecheck_dw}"

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    SELECT 'CREATE DATABASE ${DW_DB}'
    WHERE NOT EXISTS (
        SELECT FROM pg_database WHERE datname = '${DW_DB}'
    )\gexec
    GRANT ALL PRIVILEGES ON DATABASE "${DW_DB}" TO "${POSTGRES_USER}";
EOSQL

