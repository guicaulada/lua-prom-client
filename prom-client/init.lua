local validation = require('prom-client.validation')
local globalRegistry = require('prom-client.globalRegistry')
local bucketGenerators = require('prom-client.bucketGenerators')
local metricAggregators = require('prom-client.metricAggregators')
local defaultMetrics = require('prom-client.defaultMetrics')

return {
  register = globalRegistry,
  Registry = require('prom-client.registry'),
  contentType = globalRegistry.contentType,
  validateMetricName = validation.validateMetricName,

  Counter = require('prom-client.counter'),
  Gauge = require('prom-client.gauge'),
  Histogram = require('prom-client.histogram'),
  Summary = require('prom-client.summary'),

  linearBuckets = bucketGenerators.linearBuckets,
  exponentialBuckets = bucketGenerators.exponentialBuckets,
  collectDefaultMetrics = defaultMetrics.collectDefaultMetrics,


  aggregators = metricAggregators.aggregators,
}
