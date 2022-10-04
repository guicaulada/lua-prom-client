local util = require('prom-client.util');

-- Default metrics.
local processStartTime = require('prom-client.metrics.processStartTime');
local processCpuTotal = require('prom-client.metrics.processCpuTotal');
local processMemoryTotal = require('prom-client.metrics.processMemoryTotal');
local gcDurationHistogram = require('prom-client.metrics.gcDurationHistogram');
local version = require('prom-client.metrics.version');

local metrics = {
  gcDurationHistogram = gcDurationHistogram.gcDurationHistogram,
  processMemoryTotal = processMemoryTotal.processMemoryTotal,
  processCpuTotal = processCpuTotal.processCpuTotal,
  processStartTime = processStartTime.processStartTime,
  version = version.processVersion,
};

local metricsList = {}
for k, _ in pairs(metrics) do
  table.insert(metricsList, k)
end

local function collectDefaultMetrics(config)
  if config ~= nil and not util.isTable(config) then
    error('config must be null, undefined, or an object');
  end

  local conf = { eventLoopMonitoringPrecision = 10 };
  for k, v in pairs(config) do
    conf[k] = v
  end

  for _, metric in pairs(metrics) do
    metric(config.register, conf);
  end
end

return {
  collectDefaultMetrics = collectDefaultMetrics,
  metricsList = metricsList
}
