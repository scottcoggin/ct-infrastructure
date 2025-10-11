-- OpenWebUI PostgreSQL Initialization Script
-- This script sets up the litellm database with proper permissions

-- The litellm database is already created by the postgres container
-- via POSTGRES_DB environment variable, so we just need to set up
-- any additional configuration or tables if needed

-- Grant all privileges on the litellm database to the litellm user
GRANT ALL PRIVILEGES ON DATABASE litellm TO litellm;

-- Connect to the litellm database
\c litellm

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO litellm;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO litellm;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO litellm;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO litellm;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO litellm;

-- LiteLLM will create its own tables on first startup
-- This script just ensures proper permissions are in place
