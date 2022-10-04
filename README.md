# Prometheus client for Lua

A Prometheus client for Lua that supports histogram, summaries, gauges and
counters.

This is an adaptation of the JavaScript version created by [Simon Nyberg](https://github.com/siimon/prom-client).

## Usage

See example folder for a sample usage. The library does not bundle any web
framework. To expose the metrics, respond to Prometheus's scrape requests with
the result of `registry:metrics()`.

## API

### Default metrics

There are some default metrics recommended by Prometheus
[itself](https://prometheus.io/docs/instrumenting/writing_clientlibs/#standard-and-runtime-collectors).
To collect these, call `collectDefaultMetrics`. In addition, some
Lua-specific metrics are included, such as Lua version. 
See [prom-client/metrics](lib/metrics) for a list of all
metrics.

Pull requests to help implement more recommended metrics are welcome.

`collectDefaultMetrics` optionally accepts a config object with following entries:

- `prefix` an optional prefix for metric names. Default: no prefix.
- `register` to which metrics should be registered. Default: the global default registry.
- `gcDurationBuckets` with custom buckets for GC duration histogram. Default buckets of GC duration histogram are `[0.001, 0.01, 0.1, 1, 2, 5]` (in seconds).

To register metrics to another registry, pass it in as `register`:

```lua
local client = require('prom-client');
local collectDefaultMetrics = client.collectDefaultMetrics;
local Registry = client.Registry;
local register = Registry:new();
collectDefaultMetrics({ register = register });
```

To use custom buckets for GC duration histogram, pass it in as `gcDurationBuckets`:

```lua
local client = require('prom-client');
local collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ gcDurationBuckets = {0.1, 0.2, 0.3} });
```

To prefix metric names with your own arbitrary string, pass in a `prefix`:

```lua
local client = require('prom-client');
local collectDefaultMetrics = client.collectDefaultMetrics;
local prefix = 'my_application_';
collectDefaultMetrics({ prefix = prefix });
```

To apply generic labels to all default metrics, pass an object to the `labels` property (useful if you're working in a clustered environment):

```lua
local client = require('prom-client');
local collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({
  labels = { address = '0.0.0.0' },
});
```

You can get the full list of metrics by inspecting
`client.collectDefaultMetrics.metricsList`.

Default metrics are collected on scrape of metrics endpoint,
not on an interval.

```lua
local client = require('prom-client');

local collectDefaultMetrics = client.collectDefaultMetrics;

collectDefaultMetrics();
```

### Custom Metrics

All metric types have two mandatory parameters: `name` and `help`. Refer to
<https://prometheus.io/docs/practices/naming/> for guidance on naming metrics.

For metrics based on point-in-time observations (e.g. current memory usage, as
opposed to HTTP request durations observed continuously in a histogram), you
should provide a `collect()` function, which will be invoked when Prometheus
scrapes your metrics endpoint. `collect()` can either be synchronous or return a
promise. See **Gauge** below for an example.

See [**Labels**](#labels) for information on how to configure labels for all
metric types.

#### Counter

Counters go up, and reset when the process restarts.

```lua
local client = require('prom-client');
local counter = client.Counter:new({
  name = 'metric_name',
  help = 'metric_help',
});
counter:inc(); -- Increment by 1
counter:inc(10); -- Increment by 10
```

#### Gauge

Gauges are similar to Counters but a Gauge's value can be decreased.

```lua
local client = require('prom-client');
local gauge = client.Gauge:new({ name = 'metric_name', help = 'metric_help'});
gauge:set(10); -- Set to 10
gauge:inc(); -- Increment 1
gauge:inc(10); -- Increment 10
gauge:dec(); -- Decrement by 1
gauge:dec(10); -- Decrement by 10
```

##### Configuration

If the gauge is used for a point-in-time observation, you should provide a
`collect` function:

```lua
local client = require('prom-client');
client.Gauge:new({
  name = 'metric_name',
  help = 'metric_help',
  collect = function()
    -- Invoked when the registry collects its metrics' values.
    -- This can be synchronous or it can return a promise/be an function.
    self:set(/* the current value */);
  end,
});
```

```lua
-- Async version:
local client = require('prom-client');
client.Gauge:new({
  name = 'metric_name',
  help = 'metric_help',
  collect = function()
    -- Invoked when the registry collects its metrics' values.
    local currentValue = somethingToGetValue();
    self:set(currentValue);
  end,
});
```

Note that you should not use arrow functions for `collect` because arrow
functions will not have the correct value for `this`.

##### Utility Functions

```lua
-- Set value to current time:
gauge:setToCurrentTime();

-- Record durations:
local stop = gauge:startTimer();
http.get('url', function(res)
  stop();
end);
```

#### Histogram

Histograms track sizes and frequency of events.

##### Configuration

The defaults buckets are intended to cover usual web/RPC requests, but they can
be overridden. (See also [**Bucket Generators**](#bucket-generators).)

```lua
local client = require('prom-client');
client.Histogram:new({
  name = 'metric_name',
  help = 'metric_help',
  buckets = {0.1, 5, 15, 50, 100, 500},
});
```

##### Examples

```lua
local client = require('prom-client');
local histogram = client.Histogram:new({
  name = 'metric_name',
  help = 'metric_help',
});
histogram:observe(10); -- Observe value in histogram
```

##### Utility Methods

```lua
local stop = histogram.startTimer();
xhrRequest(function(err, res)
  local seconds = stop(); -- Observes and returns the value to xhrRequests duration in seconds
end);
```

#### Summary

Summaries calculate percentiles of observed values.

##### Configuration

The default percentiles are: 0.01, 0.05, 0.5, 0.9, 0.95, 0.99, 0.999. But they
can be overridden by specifying a `percentiles` array. (See also
[**Bucket Generators**](#bucket-generators).)

```lua
local client = require('prom-client');
client.Summary:new({
  name = 'metric_name',
  help = 'metric_help',
  percentiles = {0.01, 0.1, 0.9, 0.99},
});
```

To enable the sliding window functionality for summaries you need to add
`maxAgeSeconds` and `ageBuckets` to the config like self:

```lua
local client = require('prom-client');
client.Summary:new({
  name = 'metric_name',
  help = 'metric_help',
  maxAgeSeconds = 600,
  ageBuckets = 5,
});
```

The `maxAgeSeconds` will tell how old a bucket can be before it is reset and
`ageBuckets` configures how many buckets we will have in our sliding window for
the summary.

##### Examples

```lua
local client = require('prom-client');
local summary = client.Summary:new({
  name = 'metric_name',
  help = 'metric_help',
});
summary:observe(10);
```

##### Utility Methods

```lua
local end = summary:startTimer();
xhrRequest(function (err, res) {
  end(); -- Observes the value to xhrRequests duration in seconds
});
```

### Labels

All metrics can take a `labelNames` property in the configuration object. All
label names that the metric support needs to be declared here. There are two
ways to add values to the labels:

```lua
local client = require('prom-client');
local gauge = client.Gauge:new({
  name = 'metric_name',
  help = 'metric_help',
  labelNames = {'method', 'statusCode'},
});

-- 1st version: Set value to 100 with "method" set to "GET" and "statusCode" to "200"
gauge:set({ method = 'GET', statusCode = '200' }, 100);
-- 2nd version: Same effect as above
gauge:labels({ method = 'GET', statusCode = '200' }).set(100);
-- 3rd version: And again the same effect as above
gauge:labels('GET', '200').set(100);
```

It is also possible to use timers with labels, both before and after the timer
is created:

```lua
local stop = startTimer({ method = 'GET' }); -- Set method to GET, we don't know statusCode yet
xhrRequest(function (err, res) {
  if (err) {
    stop({ statusCode = '500' }); -- Sets value to xhrRequest duration in seconds with statusCode 500
  } else {
    stop({ statusCode = '200' }); -- Sets value to xhrRequest duration in seconds with statusCode 200
  }
});
```

#### Zeroing metrics with Labels

Metrics with labels can not be exported before they have been observed at least
once since the possible label values are not known before they're observed.

For histograms, this can be solved by explicitly zeroing all expected label values:

```lua
local histogram = client.Histogram:new({
  name = 'metric_name',
  help = 'metric_help',
  buckets = {0.1, 5, 15, 50, 100, 500},
  labels = {'method'},
});
histogram:zero({ method = 'GET' });
histogram:zero({ method = 'POST' });
```

#### Default Labels (segmented by registry)

Static labels may be applied to every metric emitted by a registry:

```lua
local client = require('prom-client');
local defaultLabels = { serviceName = 'api-v1' };
client.register:setDefaultLabels(defaultLabels);
```

This will output metrics in the following way:

```
# HELP process_resident_memory_bytes Resident memory size in bytes.
# TYPE process_resident_memory_bytes gauge
process_resident_memory_bytes{serviceName="api-v1"} 33853440 1498510040309
```

Default labels will be overridden if there is a name conflict.

`register:clear()` will clear default labels.

### Multiple registries

By default, metrics are automatically registered to the global registry (located
at `require('prom-client').register`). You can prevent this by specifying
`registers = {}` in the metric constructor configuration.

Using non-global registries requires creating a Registry instance and passing it
inside `registers` in the metric configuration object. Alternatively you can
pass an empty `registers` array and register it manually.

Registry has a `merge` function that enables you to expose multiple registries
on the same endpoint. If the same metric name exists in both registries, an
error will be thrown.

```lua
local client = require('prom-client');
local registry = client.Registry:new();
local counter = client.Counter:new({
  name = 'metric_name',
  help = 'metric_help',
  registers = {registry}, -- specify a non-default registry
});
local histogram = client.Histogram:new({
  name = 'metric_name',
  help = 'metric_help',
  registers = {}, -- don't automatically register this metric
});
registry:registerMetric(histogram); -- register metric manually
counter:inc();

local mergedRegistries = client.Registry.merge({registry, client.register});
```

### Register

You can get all metrics by running `register:metrics()`, which will return
a string in the Prometheus exposition format.

#### Getting a single metric value in Prometheus exposition format

If you need to output a single metric in the Prometheus exposition format, you
can use `register:getSingleMetricAsString(*name of metric*)`, which will
return a string for Prometheus to consume.

#### Getting a single metric

If you need to get a reference to a previously registered metric, you can use
`register:getSingleMetric(*name of metric*)`.

#### Removing metrics

You can remove all metrics by calling `register:clear()`. You can also remove a
single metric by calling `register:removeSingleMetric(*name of metric*)`.

#### Resetting metrics

If you need to reset all metrics, you can use `register:resetMetrics()`. The
metrics will remain present in the register and can be used without the need to
instantiate them again, like you would need to do after `register:clear()`.

### Bucket Generators

For convenience, there are two bucket generator functions - linear and
exponential.

```lua
local client = require('prom-client');
client.Histogram:new({
  name = 'metric_name',
  help = 'metric_help',
  buckets = client.linearBuckets(0, 10, 20), -- Create 20 buckets, starting on 0 and a width of 10
});

client.Histogram:new({
  name = 'metric_name',
  help = 'metric_help',
  buckets = client.exponentialBuckets(1, 2, 5), -- Create 5 buckets, starting on 1 and with a factor of 2
});
```

The content-type prometheus expects is also exported as a constant, both on the
`register` and from the main file of this project, called `contentType`.
