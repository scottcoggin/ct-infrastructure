# DataLab - Home Data Engineering Lab

A complete containerized data engineering and analytics environment featuring ETL/ELT pipelines, data warehousing, and business intelligence visualization.

## Architecture

- **Mage** - Data pipeline orchestration and transformation
- **PostgreSQL** - Data warehouse with medallion architecture (01_bronze/02_silver/03_gold)
- **Cube.js** - Semantic layer for metrics and business logic
- **Apache Superset** - Business intelligence and data visualization
- **Redis** - Caching and message broker

## Features

- **Medallion Architecture**: Industry-standard bronze/silver/gold data layers with ordered schemas
- **Complete ETL/ELT Stack**: From raw data ingestion to visualization
- **Pre-configured Database**: Multiple databases with proper roles and permissions
- **Date Dimension**: Pre-populated date dimension table (2020-2030)
- **Audit & Lineage**: Built-in pipeline tracking and data quality monitoring

## Requirements

- Docker Engine 20.10+
- Docker Compose v2.0+
- Minimum 8GB RAM (16GB recommended)
- 20GB available disk space

## Quick Start

### 1. Clone and Setup

```bash
# Navigate to the project directory
cd datalab

# Copy environment template
cp .env.example .env

# Edit .env file with your preferences
nano .env
```

**Important:** Generate secure secret keys:
```bash
# For Superset
openssl rand -base64 42

# For Cube.js
openssl rand -base64 42
```
Copy the outputs and set them as `SUPERSET_SECRET_KEY` and `CUBEJS_API_SECRET` in your `.env` file.

### 2. Start the Services

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### 3. Wait for Initialization

First startup takes 2-5 minutes:
- PostgreSQL initializes databases and schemas
- Superset runs database migrations and creates admin user
- Mage starts up and connects to PostgreSQL

### 4. Access the Services

| Service    | URL                        | Default Credentials      |
|------------|----------------------------|--------------------------|
| Mage       | http://localhost:6789      | No authentication        |
| Cube.js    | http://localhost:4000      | API key (see .env)       |
| Superset   | http://localhost:8088      | admin / admin            |
| PostgreSQL | localhost:5432             | postgres / (see .env)    |
| Redis      | localhost:6379             | No authentication        |

**WARNING: Change default passwords after first login!**

## Database Structure

### PostgreSQL Databases

1. **mage_db** - Mage metadata and pipeline configurations
2. **superset_db** - Superset dashboards and charts
3. **datamart** - Data warehouse with medallion architecture

### Medallion Architecture (datamart)

```
01_bronze schema → Raw data landing zone
  ├─ Minimal transformations
  ├─ 1:1 mapping with sources
  └─ Full historical retention

02_silver schema → Cleaned and validated data
  ├─ Data quality checks applied
  ├─ Business rules applied
  └─ Deduplicated and conformed

03_gold schema → Analytics-ready data
  ├─ Dimensional models (facts & dimensions)
  ├─ Pre-aggregated metrics
  └─ Optimized for reporting
```

**Note:** Schemas use numeric prefixes to ensure consistent ordering in database tools.

### Pre-configured Tables

- `public.pipeline_runs` - Audit log for all pipeline executions
- `public.data_quality_metrics` - Data quality monitoring
- `03_gold.dim_date` - Date dimension (2020-2030)

## Superset Setup

### Connect to DataMart

1. Log in to Superset (http://localhost:8088)
2. Go to **Settings** → **Database Connections**
3. Click **+ Database**
4. Select **PostgreSQL**
5. Enter connection details:

**For Silver Layer (Ad-hoc Analysis):**
```
Host: postgres
Port: 5432
Database: datamart
Username: postgres
Password: (from .env)
Display Name: DataMart - Silver
SQL Lab: ✓ Expose in SQL Lab
```

**For Gold Layer (Dashboards):**
```
Host: postgres
Port: 5432
Database: datamart
Username: postgres
Password: (from .env)
Display Name: DataMart - Gold
```

### Advanced Settings

In the **Advanced** tab:
- **SQL Lab** → Enable "Expose in SQL Lab"
- **Security** → Set appropriate permissions per your needs

## Cube.js Semantic Layer

Cube.js provides a semantic layer between your data warehouse and analytics tools, defining reusable metrics and business logic.

### Access the Playground

Visit **http://localhost:4000** to access the Cube.js Playground (development mode only).

### Schema Development

Cube schemas are defined in `cube/model/` directory:

```javascript
// Example: cube/model/FactSales.js
cube('FactSales', {
  sql: `SELECT * FROM "03_gold".fact_sales`,

  dimensions: {
    saleId: { sql: `sale_id`, type: 'number', primaryKey: true },
    customerId: { sql: `customer_id`, type: 'number' },
  },

  measures: {
    count: { type: 'count' },
    totalRevenue: { sql: `revenue`, type: 'sum' },
  },

  joins: {
    DimDate: {
      sql: `${CUBE}.date_key = ${DimDate}.date_key`,
      relationship: 'belongsTo'
    }
  }
});
```

### Configuration

- **Config file**: `cube/cube.js`
- **Schema path**: `cube/model/` (Cube.js default)
- **Database**: Connects to `datamart` database
- **Schemas**: Access `02_silver` and `03_gold` schemas

### API Usage

Query Cube.js via REST API:

```bash
curl -H "Authorization: YOUR_API_SECRET" \
  http://localhost:4000/cubejs-api/v1/load \
  -G -d 'query={"measures":["DimDate.count"]}'
```

### Pre-aggregations

Define pre-aggregations for faster queries:

```javascript
preAggregations: {
  main: {
    measures: [count, totalRevenue],
    dimensions: [DimDate.year, DimDate.month],
    timeDimension: DimDate.date,
    granularity: 'day'
  }
}
```

## Mage Pipeline Development

### Project Structure

```
mage_data/
└── datalab/                    # Your Mage project
    ├── pipelines/
    │   ├── 01_bronze/         # Extraction pipelines
    │   ├── 02_silver/         # Transformation pipelines
    │   └── 03_gold/           # Mart building pipelines
    ├── data_loaders/
    ├── transformers/
    └── exporters/
```

### Database Connections in Mage

Mage has access to the following databases via environment variables:

**Metadata Database:**
- Host: `postgres`
- Database: `mage_db`
- Credentials: From environment

**DataMart (for pipelines):**
- Host: `postgres`
- Database: `datamart`
- Schemas: `01_bronze`, `02_silver`, `03_gold`

### Example Pipeline Flow

1. **Bronze Pipeline**: Extract from source → Load to `01_bronze.bronze_source_table`
2. **Silver Pipeline**: Read from bronze → Transform → Load to `02_silver.silver_entity`
3. **Gold Pipeline**: Read from silver → Aggregate → Load to `03_gold.fact_sales`

## Common Operations

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f mage
docker compose logs -f superset
docker compose logs -f postgres
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart mage
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes (⚠️ deletes all data)
docker compose down -v
```

### Access PostgreSQL CLI

```bash
docker compose exec postgres psql -U postgres -d datamart
```

Useful commands:
```sql
-- List all schemas
\dn

-- List tables in a schema
\dt "01_bronze".*
\dt "02_silver".*
\dt "03_gold".*

-- Switch database
\c datamart

-- Describe table
\d "03_gold".dim_date
```

### Access Mage Container

```bash
docker compose exec mage bash
```

### Backup Database

```bash
# Backup datamart
docker compose exec postgres pg_dump -U postgres datamart > datamart_backup.sql

# Restore datamart
docker compose exec -T postgres psql -U postgres datamart < datamart_backup.sql
```

## Development Workflow

### 1. Data Ingestion (Bronze)

Create a Mage pipeline to extract data from sources:
- APIs
- CSV files
- External databases
- Web scraping

Load raw data into `01_bronze` schema with minimal transformation.

### 2. Data Transformation (Silver)

Create transformation pipelines:
- Clean and validate data
- Apply business rules
- Join related datasets
- Implement data quality checks

Load processed data into `02_silver` schema.

### 3. Analytics Preparation (Gold)

Build dimensional models:
- Create fact tables
- Build dimension tables
- Generate aggregations
- Optimize for query performance

Load analytics-ready data into `03_gold` schema.

### 4. Visualization (Superset)

- Create datasets from silver/gold tables
- Build charts and dashboards
- Share with stakeholders

## Troubleshooting

### Superset fails to start

```bash
# Check if databases are initialized
docker compose exec postgres psql -U postgres -c "\l"

# Restart superset
docker compose restart superset
```

### Mage can't connect to database

```bash
# Check environment variables
docker compose exec mage env | grep POSTGRES

# Verify database exists
docker compose exec postgres psql -U postgres -c "\l"
```

### Port conflicts

If ports are already in use, modify them in `.env`:
```bash
MAGE_PORT=6790
SUPERSET_PORT=8089
POSTGRES_PORT=5433
REDIS_PORT=6380
```

Then restart:
```bash
docker compose down
docker compose up -d
```

## Maintenance

### Update Images

```bash
docker compose pull
docker compose up -d
```

### Clean Up Unused Resources

```bash
# Remove stopped containers
docker compose down

# Clean up Docker system
docker system prune -a
```

## Project Structure

```
datalab/
├── docker-compose.yml          # Service orchestration
├── .env                        # Environment variables (not in git)
├── .env.example               # Environment template
├── init-db.sql                # Database initialization
├── superset-init.sh           # Superset setup script
├── cube/                       # Cube.js semantic layer
│   ├── cube.js                # Cube.js configuration
│   ├── model/                 # Cube schema definitions
│   │   └── DimDate.js         # Example: Date dimension cube
│   └── README.md              # Cube.js documentation
├── mage_data/                 # Mage project files (bind mount)
├── DATALAB_SPEC.md           # Detailed architecture specification
└── README.md                  # This file
```

## Security Considerations

- Change all default passwords
- Use strong `SUPERSET_SECRET_KEY` and `CUBEJS_API_SECRET`
- Don't commit `.env` to version control
- Limit exposed ports in production
- Use separate users for Mage and Superset in production
- Implement row-level security in Superset for multi-user scenarios
- Disable Cube.js dev mode in production (`CUBEJS_DEV_MODE=false`)

## Next Steps

1. Start the environment
2. Access Superset and change default password
3. Configure database connections in Superset
4. Access Cube.js Playground and verify DimDate cube loads
5. Create your first Mage pipeline
6. Build sample data in bronze/silver/gold
7. Define Cube.js schemas for your fact and dimension tables
8. Create your first dashboard in Superset

## Resources

- [Mage Documentation](https://docs.mage.ai)
- [Superset Documentation](https://superset.apache.org/docs/intro)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Medallion Architecture](https://www.databricks.com/glossary/medallion-architecture)

## License

This is a home lab setup for learning and experimentation. Modify and use as needed.

## Contributing

This is a personal home lab project. Feel free to fork and customize for your own use!
