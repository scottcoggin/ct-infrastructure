#!/bin/bash
set -e;

# PostgreSQL initialization script for n8n
# Creates a non-root user with appropriate permissions (idempotent)

if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        -- Create user if it doesn't exist
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${POSTGRES_NON_ROOT_USER}') THEN
                CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
                RAISE NOTICE 'User ${POSTGRES_NON_ROOT_USER} created';
            ELSE
                ALTER USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
                RAISE NOTICE 'User ${POSTGRES_NON_ROOT_USER} already exists, password updated';
            END IF;
        END
        \$\$;

        -- Grant privileges (idempotent)
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_NON_ROOT_USER};
        GRANT CREATE ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
EOSQL
    echo "✓ User configured: ${POSTGRES_NON_ROOT_USER}"
else
    echo "⚠ WARNING: No non-root user credentials provided in environment variables!"
    echo "   n8n will not be able to connect to the database."
fi
