local util = require('prom-client.util')
local validation = require('prom-client.validation')
local Metric = require('prom-client.metric')
local TimeWindowQuantiles = require('prom-client.timeWindowQuantiles')
local metricType = 'summary'
local Summary = {}

local DEFAULT_COMPRESS_COUNT = 1000

local function extractSummariesForExport(summaryOfLabels, percentiles)
  summaryOfLabels.td:compress()
  local result = {}
  for i, percentile in ipairs(percentiles) do
    local value = summaryOfLabels.td:percentile(percentile)
    local labels = summaryOfLabels.labels
    labels.quantile = percentile
    if value then
      result[i] = {
        labels = labels,
        value = value or 0,
      }
    end
  end
  return result
end

local function getCountForExport(value, summary)
  return {
    metricName = string.format('%s_count', summary.name),
    labels = value.labels,
    value = value.count
  }
end

local function getSumForExport(value, summary)
  return {
    metricName = string.format('%s_sum', summary.name),
    labels = value.labels,
    value = value.sum
  }
end

local function startTimer(summary, startLabels)
  return function()
    local start = os.time()
    return function(endLabels)
      local delta = os.time() - start
      local labels = {}
      for k, v in pairs(startLabels) do
        labels[k] = v
      end
      for k, v in pairs(endLabels) do
        labels[k] = v
      end
      summary:observe(labels, delta)
      return delta
    end
  end
end

local function convertLabelAndValues(labels, value)
  if value == nil then
    return {
      value = labels,
      labels = {}
    }
  end
  return {
    labels = labels,
    value = value
  }
end

local function observe(summary, labels)
  return function(value)
    local labelValuePair = convertLabelAndValues(labels, value)

    validation.validateLabel(summary.labelNames, labels)
    if type(labelValuePair.value) ~= 'number' then
      error(string.format('Value is not a valid number: %s', labelValuePair.value))
    end

    local hash = util.hashTable(labelValuePair.labels)
    local summaryOfLabel = summary.hashMap[hash]
    if not summaryOfLabel then
      summaryOfLabel = {
        labels = labelValuePair.labels,
        td = TimeWindowQuantiles.new(summary.maxAgeSeconds, summary.ageBuckets),
        count = 0,
        sum = 0
      }
    end

    summaryOfLabel.td:push(labelValuePair.value)
    summaryOfLabel.count = summaryOfLabel.count + 1
    if summaryOfLabel.count % summary.compressCount == 0 then
      summaryOfLabel.td:compress()
    end
    summaryOfLabel.sum = summaryOfLabel.sum + labelValuePair.value
    summary.hashMap[hash] = summaryOfLabel
  end
end

function Summary:new(config)
  local o = Metric:new(config, {
    percentiles = { 0.01, 0.05, 0.5, 0.9, 0.95, 0.99, 0.999 },
    compressCount = DEFAULT_COMPRESS_COUNT,
  })
  setmetatable(o, self)
  self.__index = self
  for _, label in ipairs(o.labelNames) do
    if label == 'quantile' then
      error('Label name "quantile" is a reserved label keyword')
    end
  end
  if #o.labelNames == 0 then
    o.hashMap = {
      [util.hashTable({})] = {
        labels = {},
        td = TimeWindowQuantiles:new(o.maxAgeSeconds, o.ageBuckets),
        count = 0,
        sum = 0
      }
    }
  end
  return o
end

function Summary:observe(labels, value)
  if labels ~= 0 then
    labels = labels or {}
  end
  observe(self, labels)(value)
end

function Summary:get()
  if self.collect then
    self:collect()
  end
  local data = {}
  for _, value in pairs(self.hashMap) do
    table.insert(data, value)
  end
  local values = {}
  for _, s in ipairs(data) do
    for _, v in ipairs(extractSummariesForExport(s, self.percentiles)) do
      table.insert(values, v)
    end
    table.insert(values, getSumForExport(s, self))
    table.insert(values, getCountForExport(s, self))
  end
  return {
    name = self.name,
    help = self.help,
    type = metricType,
    values = values,
    aggregator = self.aggregator
  }
end

function Summary:reset()
  for _, value in pairs(self.hashMap) do
    value.td:reset()
    value.count = 0
    value.sum = 0
  end
end

function Summary:startTimer(labels)
  return startTimer(self, labels)()
end

function Summary:labels(...)
  local labels = util.getLabels(self.labelNames, { ... })
  validation.validateLabel(self.labelNames, labels)
  return {
    observe = function(_, value) observe(self, labels)(value) end,
    startTimer = function(_) startTimer(self, labels)() end
  }
end

function Summary:remove(...)
  local labels = util.getLabels(self.labelNames, { ... })
  validation.validateLabel(self.labelNames, labels)
  util.removeLabels(self.hashMap, labels)
end

return Summary
