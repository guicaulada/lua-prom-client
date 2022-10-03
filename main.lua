local globals = require('./lib/client/globals')
local validation = require('./lib/client/validation')
local bucketGenerators = require('./lib/client/bucketGenerators')
local metricAggregators = require('./lib/client/metricAggregators')

return {
  register = globals.globalRegistry,
  Registry = require('./lib/client/registry'),
  contentType = globals.globalRegistry.contentType,
  validateMetricName = validation.validateMetricName,

  Counter = require('./lib/client/Counter'),
  Gauge = require('./lib/client/Gauge'),
  Histogram = require('./lib/client/Histogram'),
  Summary = require('./lib/client/Summary'),

  linearBuckets = bucketGenerators.linearBuckets,
  exponentialBuckets = bucketGenerators.exponentialBuckets,

  collectDefaultMetrics = require('./lib/client/defaultMetrics'),

  aggregators = metricAggregators.aggregators,
  AggregatorRegistry = require('./lib/client/cluster'),
}
