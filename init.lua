local globalRegistry = require('lib/client/registry').globalRegistry
local validation = require('lib/client/validation')
local bucketGenerators = require('lib/client/bucketGenerators')
local metricAggregators = require('lib/client/metricAggregators')

return {
  register = globalRegistry,
  Registry = require('lib/client/registry').Registry,
  contentType = globalRegistry.contentType,
  validateMetricName = validation.validateMetricName,

  Counter = require('lib/client/Counter'),
  Gauge = require('lib/client/Gauge'),
  Histogram = require('lib/client/Histogram'),
  Summary = require('lib/client/Summary'),
  -- PushGateway = require('lib/client/PushGateway'), -- needs implementation

  linearBuckets = bucketGenerators.linearBuckets,
  exponentialBuckets = bucketGenerators.exponentialBuckets,

  -- collectDefaultMetrics = require('lib/client/defaultMetrics'), -- needs implementation

  aggregators = metricAggregators.aggregators,
  -- AggregatorRegistry = require('lib/client/cluster'), -- needs implementation
}
