local util = require('prom-client.util')
local Registry = {}

local function escapeString(str)
  return str:gsub('\n', '\\n'):gsub('\\[?!n]', '\\\\')
end

local function escapeLabelValue(str)
  if type(str) ~= 'string' then
    return str
  end
  return escapeString(str):gsub('"', '\\"')
end

function Registry:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o._metrics = {}
  o.collectors = {}
  o.defaultLabels = {}
  o.contentType = 'text/plain; version=0.0.4; charset=utf-8'
  return o
end

function Registry:getMetricsAsArray()
  local metrics = {}
  for _, metric in pairs(self._metrics) do
    table.insert(metrics, metric)
  end
  return metrics
end

function Registry:getMetricAsPrometheusString(metric)
  local item = metric:get()
  local name = escapeString(item.name)
  local help = string.format('# HELP %s %s', name, escapeString(item.help))
  local metricType = string.format('# TYPE %s %s', name, escapeString(item.type))
  local defaultLabelNames = {}
  for k, _ in pairs(self.defaultLabels) do
    table.insert(defaultLabelNames, k)
  end

  local values = ''
  for _, val in ipairs(item.values) do
    val.labels = val.labels or {}
    if #defaultLabelNames > 0 then
      for _, labelName in ipairs(defaultLabelNames) do
        val.labels[labelName] = val.labels[labelName] or self.defaultLabels[labelName]
      end
    end

    local metricName = val.metricName or item.name
    local keys = {}
    for k, _ in pairs(val.labels) do
      table.insert(keys, k)
    end
    local size = #keys
    if size > 0 then
      local labels = ''
      local i = 1
      while i < size do
        labels = string.format('%s%s="%s",', labels, keys[i], escapeLabelValue(val.labels[keys[i]]))
        i = i + 1
      end
      labels = string.format('%s%s="%s"', labels, keys[i], escapeLabelValue(val.labels[keys[i]]))
      metricName = string.format('%s{%s}', metricName, labels)
    end
    values = string.format('%s%s %s\n', values, metricName, util.getValueAsString(val.value))
  end
  return string.format('%s\n%s\n%s', help, metricType, values)
end

function Registry:metrics()
  local metrics = {}
  for _, metric in ipairs(self:getMetricsAsArray()) do
    table.insert(metrics, self:getMetricAsPrometheusString(metric))
  end
  return string.format('%s\n', table.concat(metrics, '\n\n'))
end

function Registry:registerMetric(metric)
  if self._metrics[metric.name] and self._metrics[metric.name] ~= metric then
    error(string.format('A metric with the name %s has already been registered.', metric.name))
  end
  self._metrics[metric.name] = metric
end

function Registry:clear()
  self._metrics = {}
  self.defaultLabels = {}
end

function Registry:getMetricsAsJSON()
  local metrics = {}
  local defaultLabelNames = {}
  for k, _ in pairs(self.defaultLabels) do
    table.insert(defaultLabelNames, k)
  end

  local metrics = {}
  for _, metric in ipairs(self:getMetricsAsArray()) do
    if metric.values and #defaultLabelNames > 0 then
      for _, val in ipairs(metric.values) do
        val.labels = val.labels or {}
        for _, labelName in ipairs(defaultLabelNames) do
          val.labels[labelName] = val.labels[labelName] or self.defaultLabels[labelName]
        end
      end
    end
    table.insert(metrics, metric)
  end
  return metrics
end

function Registry:removeSingleMetric(name)
  self._metrics[name] = nil
end

function Registry:getSingleMetricAsString(name)
  return self:getMetricAsPrometheusString(self._metrics[name])
end

function Registry:getSingleMetric(name)
  return self._metrics[name]
end

function Registry:setDefaultLabels(labels)
  self.defaultLabels = labels
end

function Registry:resetMetrics()
  for _, metric in pairs(self._metrics) do
    metric:reset()
  end
end

function Registry.merge(registers)
  local mergedRegistry = Registry:new()
  for _, register in ipairs(registers) do
    for _, metric in pairs(register._metrics) do
      mergedRegistry:registerMetric(metric)
    end
  end
  return mergedRegistry
end

return Registry
