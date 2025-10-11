# Cube.js Semantic Layer Configuration

This directory contains Cube.js configuration and schema definitions for the DataLab semantic layer.

## Directory Structure

```
cube/
├── README.md           # This file
├── cube.js            # Main Cube.js configuration
└── model/             # Cube schema definitions (semantic models)
    └── DimDate.js     # Example: Date dimension cube
```

## What is Cube.js?

Cube.js is a semantic layer that sits between your data warehouse (PostgreSQL) and consumption tools (Superset, APIs, etc.). It provides:

- **Centralized metrics**: Define business logic once, use everywhere
- **Pre-aggregations**: Fast query performance via built-in Cube Store
- **REST/GraphQL API**: Standardized data access for any consumer
- **Access control**: Row-level security and permissions (optional)

## Architecture

```
Mage → PostgreSQL (datamart)
         ↓ (02_silver, 03_gold schemas)
       Cube.js (semantic layer)
         ↓ (REST/GraphQL API)
       Superset / API consumers
```

## Creating Cube Schemas

Each file in `model/` defines a **cube** - a semantic model for a table or view.

### Basic Structure

```javascript
cube('CubeName', {
  // SQL source
  sql: `SELECT * FROM "03_gold".table_name`,

  // Joins to other cubes
  joins: {
    OtherCube: {
      sql: `${CUBE}.foreign_key = ${OtherCube}.primary_key`,
      relationship: 'belongsTo' // or 'hasMany', 'hasOne'
    }
  },

  // Dimensions (attributes for grouping/filtering)
  dimensions: {
    id: {
      sql: `id`,
      type: 'number',
      primaryKey: true
    },
    name: {
      sql: `name`,
      type: 'string'
    },
    createdAt: {
      sql: `created_at`,
      type: 'time'
    }
  },

  // Measures (aggregations)
  measures: {
    count: {
      type: 'count'
    },
    total: {
      sql: `amount`,
      type: 'sum'
    }
  },

  // Pre-aggregations (optional, for performance)
  preAggregations: {
    main: {
      measures: [count, total],
      dimensions: [name],
      timeDimension: createdAt,
      granularity: 'day'
    }
  }
});
```

## Naming Conventions

- **Cube names**: PascalCase matching table name (e.g., `FactSales`, `DimCustomer`)
- **Dimensions**: camelCase (e.g., `customerId`, `orderDate`)
- **Measures**: camelCase (e.g., `totalRevenue`, `avgOrderValue`)
- **SQL columns**: snake_case as they appear in database (e.g., `customer_id`, `order_date`)

## Data Types

### Dimensions
- `string`: Text fields
- `number`: Numeric fields
- `boolean`: True/false
- `time`: Date/timestamp fields
- `geo`: Geospatial coordinates

### Measures
- `count`: Count of rows
- `sum`: Sum of values
- `avg`: Average of values
- `min`/`max`: Min/max values
- `countDistinct`: Count unique values
- `countDistinctApprox`: Approximate count (faster)

## Workflow

1. **Create schema file**: Add new `.js` file to `model/` directory
2. **Define cube**: Use structure above
3. **Commit & push**: Changes deploy via GitHub Actions and Portainer
4. **Wait for deployment**: Portainer polls Git every 5 minutes and redeploys
5. **Verify**: Access Cube.js Playground at http://cube.homenet24.lan

## Accessing Data

### Cube.js Playground (Dev Mode)
- URL: http://localhost:4000 or http://cube.homenet24.lan
- Visual query builder
- Only available when `CUBEJS_DEV_MODE=true`

### REST API
```bash
curl -H "Authorization: YOUR_CUBEJS_API_SECRET" \
     http://localhost:4000/cubejs-api/v1/load \
     -G -d 'query={"measures":["DimDate.count"],"dimensions":["DimDate.year"]}'
```

### GraphQL API
```bash
curl -H "Authorization: YOUR_CUBEJS_API_SECRET" \
     http://localhost:4000/cubejs-api/graphql \
     -d 'query { cube { DimDate { count year } } }'
```

### From Superset
Add Cube.js as a database connection:
- Type: PostgreSQL
- Host: `cube`
- Port: `5432`
- Use Cube.js SQL API to query semantic layer

## Troubleshooting

**Schema not loading:**
```bash
docker compose logs cube | grep -i error
```

**Syntax error:**
- Check JavaScript syntax in schema files
- Ensure all braces/parentheses are balanced
- Restart: `docker compose restart cube`

**Can't connect to database:**
```bash
docker compose exec cube nc -zv postgres 5432
```

**Pre-aggregations not building:**
- Check Cube Store status in logs: `docker compose logs cube | grep cubestore`
- Review logs: `docker compose logs cube`

## References

- [Cube.js Documentation](https://cube.dev/docs)
- [Schema Reference](https://cube.dev/docs/schema/reference/cube)
- [Data Schema](https://cube.dev/docs/schema/fundamentals/concepts)
- [Pre-Aggregations](https://cube.dev/docs/caching/pre-aggregations/getting-started)
