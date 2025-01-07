#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create databases
    CREATE DATABASE n8n_database;
    CREATE DATABASE evolution;

    -- Grant privileges
    GRANT ALL PRIVILEGES ON DATABASE n8n_database TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE evolution TO $POSTGRES_USER;
EOSQL
