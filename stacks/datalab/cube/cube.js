// Cube.js Configuration
// This file configures database connections, caching, and other Cube.js settings

module.exports = {
  // Database connection is configured via environment variables:
  // CUBEJS_DB_TYPE, CUBEJS_DB_HOST, CUBEJS_DB_PORT, CUBEJS_DB_NAME,
  // CUBEJS_DB_USER, CUBEJS_DB_PASS

  // Semantic layer focuses on silver and gold schemas
  // You can query specific schemas in your cube definitions

  // Caching configuration
  // Cube.js uses built-in Cube Store for caching and pre-aggregations
  // (Redis is no longer supported as of Cube.js 1.x)

  // Query rewrite for schema routing
  queryRewrite: (query, { securityContext }) => {
    // You can add custom query rewriting logic here
    // For example, to enforce row-level security or schema routing
    return query;
  },

  // Context for security and multi-tenancy
  contextToAppId: ({ securityContext }) => {
    // Return a unique app ID for cache segregation if needed
    return 'CUBEJS_APP';
  },

  // Scheduled refresh for pre-aggregations (optional)
  scheduledRefreshTimer: 60, // Check every 60 seconds for refresh

  // Orchestra API settings
  orchestratorOptions: {
    queryCacheOptions: {
      // Query results cache (via Redis)
      refreshKeyRenewalThreshold: 120, // 2 minutes
    },
    preAggregationsOptions: {
      // Pre-aggregation refresh settings
      queueOptions: {
        concurrency: 2, // Number of parallel pre-agg builds
      },
    },
  },

  // Telemetry (set to false for privacy)
  telemetry: false,
};
