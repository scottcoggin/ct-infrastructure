-- DataLab Database Initialization Script
-- This script runs automatically when PostgreSQL starts for the first time
-- It creates the required databases and sets up the medallion architecture

-- =============================================================================
-- Create Databases
-- =============================================================================

-- Mage metadata database
CREATE DATABASE mage_db;

-- Superset metadata database
CREATE DATABASE superset_db;

-- Data warehouse with medallion architecture
CREATE DATABASE datamart;

-- =============================================================================
-- Configure datamart database
-- =============================================================================

\c datamart

-- Create medallion architecture schemas
CREATE SCHEMA IF NOT EXISTS "01_bronze";
CREATE SCHEMA IF NOT EXISTS "02_silver";
CREATE SCHEMA IF NOT EXISTS "03_gold";

-- Add schema descriptions
COMMENT ON SCHEMA "01_bronze" IS 'Bronze Layer: Raw data landing zone with minimal processing';
COMMENT ON SCHEMA "02_silver" IS 'Silver Layer: Cleaned, validated, and conformed data';
COMMENT ON SCHEMA "03_gold" IS 'Gold Layer: Business-ready data optimized for analytics';

-- =============================================================================
-- Create Roles and Permissions
-- =============================================================================

-- Note: In a production environment, you should create separate users
-- For home lab purposes, we'll use the default postgres user with full access
-- and create roles for future use

-- Role for Superset (read-only access to silver and gold)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'superset_reader') THEN
        CREATE ROLE superset_reader;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE datamart TO superset_reader;
GRANT USAGE ON SCHEMA "02_silver", "03_gold" TO superset_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA "02_silver", "03_gold" TO superset_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA "02_silver", "03_gold" GRANT SELECT ON TABLES TO superset_reader;

-- Role for Mage (read-write access to all schemas)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'mage_writer') THEN
        CREATE ROLE mage_writer;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE datamart TO mage_writer;
GRANT USAGE, CREATE ON SCHEMA "01_bronze", "02_silver", "03_gold" TO mage_writer;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA "01_bronze", "02_silver", "03_gold" TO mage_writer;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA "01_bronze", "02_silver", "03_gold" TO mage_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA "01_bronze", "02_silver", "03_gold" GRANT ALL PRIVILEGES ON TABLES TO mage_writer;
ALTER DEFAULT PRIVILEGES IN SCHEMA "01_bronze", "02_silver", "03_gold" GRANT ALL PRIVILEGES ON SEQUENCES TO mage_writer;

-- =============================================================================
-- Create Example Metadata Tables (Optional)
-- =============================================================================

-- Pipeline run tracking table (example for audit/lineage)
CREATE TABLE IF NOT EXISTS public.pipeline_runs (
    run_id SERIAL PRIMARY KEY,
    pipeline_name VARCHAR(255) NOT NULL,
    pipeline_layer VARCHAR(50) NOT NULL, -- bronze, silver, or gold
    status VARCHAR(50) NOT NULL, -- running, success, failed
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    records_processed INTEGER,
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.pipeline_runs IS 'Tracks all pipeline execution runs for monitoring and lineage';

-- Data quality metrics table (example)
CREATE TABLE IF NOT EXISTS public.data_quality_metrics (
    metric_id SERIAL PRIMARY KEY,
    table_schema VARCHAR(100) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    metric_type VARCHAR(100) NOT NULL, -- row_count, null_count, duplicate_count, etc.
    metric_value NUMERIC,
    check_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    pipeline_run_id INTEGER REFERENCES public.pipeline_runs(run_id)
);

COMMENT ON TABLE public.data_quality_metrics IS 'Stores data quality metrics for monitoring';

-- =============================================================================
-- Create Sample Dimension Table (Gold Layer)
-- =============================================================================

-- Example: Date dimension table (useful for all time-series analysis)
CREATE TABLE IF NOT EXISTS "03_gold".dim_date (
    date_key INTEGER PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INTEGER NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE,
    fiscal_year INTEGER,
    fiscal_quarter INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "03_gold".dim_date IS 'Date dimension table for time-based analysis';

-- Populate with basic date range (you can extend this via Mage pipelines)
INSERT INTO "03_gold".dim_date (date_key, date, year, quarter, month, month_name, week, day_of_month, day_of_week, day_name, is_weekend)
SELECT
    TO_CHAR(date, 'YYYYMMDD')::INTEGER as date_key,
    date,
    EXTRACT(YEAR FROM date)::INTEGER as year,
    EXTRACT(QUARTER FROM date)::INTEGER as quarter,
    EXTRACT(MONTH FROM date)::INTEGER as month,
    TO_CHAR(date, 'Month') as month_name,
    EXTRACT(WEEK FROM date)::INTEGER as week,
    EXTRACT(DAY FROM date)::INTEGER as day_of_month,
    EXTRACT(DOW FROM date)::INTEGER as day_of_week,
    TO_CHAR(date, 'Day') as day_name,
    CASE WHEN EXTRACT(DOW FROM date) IN (0, 6) THEN TRUE ELSE FALSE END as is_weekend
FROM generate_series(
    '2020-01-01'::DATE,
    '2030-12-31'::DATE,
    '1 day'::INTERVAL
) as date
ON CONFLICT (date) DO NOTHING;

-- =============================================================================
-- Create Indexes for Performance
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_pipeline_runs_pipeline_name ON public.pipeline_runs(pipeline_name);
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_status ON public.pipeline_runs(status);
CREATE INDEX IF NOT EXISTS idx_pipeline_runs_started_at ON public.pipeline_runs(started_at);

CREATE INDEX IF NOT EXISTS idx_data_quality_table ON public.data_quality_metrics(table_schema, table_name);
CREATE INDEX IF NOT EXISTS idx_data_quality_timestamp ON public.data_quality_metrics(check_timestamp);

CREATE INDEX IF NOT EXISTS idx_dim_date_date ON "03_gold".dim_date(date);
CREATE INDEX IF NOT EXISTS idx_dim_date_year_month ON "03_gold".dim_date(year, month);

-- =============================================================================
-- Completion Message
-- =============================================================================

\echo '=========================================='
\echo 'DataLab Database Initialization Complete!'
\echo '=========================================='
\echo 'Databases created:'
\echo '  - mage_db (Mage metadata)'
\echo '  - superset_db (Superset metadata)'
\echo '  - datamart (Data warehouse)'
\echo ''
\echo 'Schemas created in datamart:'
\echo '  - 01_bronze (raw data)'
\echo '  - 02_silver (cleaned data)'
\echo '  - 03_gold (analytics-ready data)'
\echo ''
\echo 'Roles created:'
\echo '  - superset_reader (read-only to silver/gold)'
\echo '  - mage_writer (read-write to all schemas)'
\echo ''
\echo 'Sample tables created:'
\echo '  - public.pipeline_runs (audit tracking)'
\echo '  - public.data_quality_metrics (DQ monitoring)'
\echo '  - 03_gold.dim_date (date dimension, 2020-2030)'
\echo '=========================================='
