// Date Dimension Cube
// This cube provides a semantic layer for the dim_date table in the gold schema
// It enables time-based analytics with pre-defined dimensions and measures

cube('DimDate', {
  // SQL source - references the gold layer dimension table
  sql: `SELECT * FROM "03_gold".dim_date`,

  // Joins - define relationships to fact tables here
  // Example:
  // joins: {
  //   FactSales: {
  //     sql: `${CUBE}.date_key = ${FactSales}.date_key`,
  //     relationship: 'belongsTo'
  //   }
  // },

  // Dimensions - attributes that can be used for grouping and filtering
  dimensions: {
    // Primary key
    dateKey: {
      sql: `date_key`,
      type: 'number',
      primaryKey: true,
      shown: false, // Hide from UI by default
    },

    // Natural date
    date: {
      sql: `date`,
      type: 'time',
      title: 'Date',
    },

    // Year dimensions
    year: {
      sql: `year`,
      type: 'number',
      title: 'Year',
    },

    // Quarter dimensions
    quarter: {
      sql: `quarter`,
      type: 'number',
      title: 'Quarter',
    },

    quarterName: {
      sql: `CONCAT('Q', quarter::text, ' ', year::text)`,
      type: 'string',
      title: 'Quarter Name',
    },

    // Month dimensions
    month: {
      sql: `month`,
      type: 'number',
      title: 'Month Number',
    },

    monthName: {
      sql: `month_name`,
      type: 'string',
      title: 'Month Name',
    },

    yearMonth: {
      sql: `CONCAT(year::text, '-', LPAD(month::text, 2, '0'))`,
      type: 'string',
      title: 'Year-Month',
    },

    // Week dimensions
    week: {
      sql: `week`,
      type: 'number',
      title: 'Week Number',
    },

    // Day dimensions
    dayOfMonth: {
      sql: `day_of_month`,
      type: 'number',
      title: 'Day of Month',
    },

    dayOfWeek: {
      sql: `day_of_week`,
      type: 'number',
      title: 'Day of Week Number',
    },

    dayName: {
      sql: `day_name`,
      type: 'string',
      title: 'Day Name',
    },

    // Boolean flags
    isWeekend: {
      sql: `is_weekend`,
      type: 'boolean',
      title: 'Is Weekend',
    },

    isHoliday: {
      sql: `is_holiday`,
      type: 'boolean',
      title: 'Is Holiday',
    },

    // Fiscal period dimensions
    fiscalYear: {
      sql: `fiscal_year`,
      type: 'number',
      title: 'Fiscal Year',
    },

    fiscalQuarter: {
      sql: `fiscal_quarter`,
      type: 'number',
      title: 'Fiscal Quarter',
    },
  },

  // Measures - aggregations and calculations
  measures: {
    // Count of date records (useful for validation)
    count: {
      type: 'count',
      title: 'Date Count',
    },

    // Min/Max dates (useful for date range queries)
    minDate: {
      sql: `date`,
      type: 'min',
      title: 'Earliest Date',
    },

    maxDate: {
      sql: `date`,
      type: 'max',
      title: 'Latest Date',
    },
  },

  // Pre-aggregations for performance (optional)
  // Uncomment and customize as needed
  // preAggregations: {
  //   main: {
  //     measures: [count],
  //     dimensions: [year, quarter, month, dayName],
  //     timeDimension: date,
  //     granularity: 'day',
  //     refreshKey: {
  //       // Refresh every 24 hours (date dimension is relatively static)
  //       every: '24 hour',
  //     },
  //   },
  // },
});
