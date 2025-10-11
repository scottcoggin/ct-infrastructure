#!/bin/bash
# Superset Initialization Script
# This script initializes Superset on first startup
# Note: The main initialization is handled in docker-compose.yml
# This file is provided as reference for manual initialization if needed

set -e

echo "=========================================="
echo "Superset Initialization Script"
echo "=========================================="

# Check if Superset has already been initialized
if [ -f /app/superset_home/.init_done ]; then
    echo "Superset already initialized, skipping..."
    exit 0
fi

echo "Step 1: Upgrading Superset database..."
superset db upgrade

echo "Step 2: Creating admin user..."
superset fab create-admin \
    --username "${SUPERSET_ADMIN_USERNAME:-admin}" \
    --firstname "${SUPERSET_ADMIN_FIRSTNAME:-Admin}" \
    --lastname "${SUPERSET_ADMIN_LASTNAME:-User}" \
    --email "${SUPERSET_ADMIN_EMAIL:-admin@datalab.local}" \
    --password "${SUPERSET_ADMIN_PASSWORD:-admin}"

echo "Step 3: Initializing Superset (creating default roles and permissions)..."
superset init

# Optionally load example data
if [ "${SUPERSET_LOAD_EXAMPLES}" = "yes" ]; then
    echo "Step 4: Loading example data..."
    superset load_examples
fi

# Mark initialization as complete
touch /app/superset_home/.init_done

echo "=========================================="
echo "Superset initialization complete!"
echo "=========================================="
echo "Access Superset at: http://localhost:${SUPERSET_PORT:-8088}"
echo "Default credentials:"
echo "  Username: ${SUPERSET_ADMIN_USERNAME:-admin}"
echo "  Password: ${SUPERSET_ADMIN_PASSWORD:-admin}"
echo ""
echo "IMPORTANT: Change the default password after first login!"
echo "=========================================="
