local util = require('prom-client.util')
local validation = require('prom-client.validation')
local Metric = require('prom-client.metric')
local metricType = 'histogram'
local Histogram = {}

local function startTimer(histogram, startLabels)
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
      histogram:observe(labels, delta)
      return delta
    end
  end
end

local function setValuePair(labels, value, metricName)
  return {
    labels = labels,
    value = value,
    metricName = metricName
  }
end

local function findBound(upperBounds, value)
  for _, bound in ipairs(upperBounds) do
    if value <= bound then
      return bound
    end
  end
  return -1
end

local function convertLabelAndValues(labels, value)
  if not util.isTable(labels) then
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

local function createBaseValues(labels, bucketValues)
  return {
    labels = labels,
    bucketValues = bucketValues,
    sum = 0,
    count = 0
  }
end

local function observe(histogram, labels)
  return function(value)
    local labelValuePair = convertLabelAndValues(labels, value)

    validation.validateLabel(histogram.labelNames, labels)
    if type(labelValuePair.value) ~= 'number' then
      error(string.format('Value is not a valid number: %s', labelValuePair.value))
    end

    local hash = util.hashTable(labelValuePair.labels)
    local valueFromMap = histogram.hashMap[hash]
    if not valueFromMap then
      valueFromMap = createBaseValues(labelValuePair.labels, histogram.bucketValues)
    end

    local b = findBound(histogram.upperBounds, labelValuePair.value)
    valueFromMap.sum = valueFromMap.sum + labelValuePair.value
    valueFromMap.count = valueFromMap.count + 1

    if valueFromMap.bucketValues[b] ~= nil then
      valueFromMap.bucketValues[b] = valueFromMap.bucketValues[b] + 1
    end

    histogram.hashMap[hash] = valueFromMap
  end
end

local function extractBucketValuesForExport(bucketData, histogram)
  local buckets = {}
  local bucketLabelNames = {}
  for k, _ in pairs(bucketData.labels) do
    table.insert(bucketLabelNames, k)
  end
  local acc = 0
  for _, upperBound in ipairs(histogram.upperBounds) do
    acc = acc + (bucketData.bucketValues[upperBound] or 0)
    local lbls = { le = upperBound }
    for _, labelName in ipairs(bucketLabelNames) do
      lbls[labelName] = bucketData.labels[labelName]
    end
    table.insert(buckets, setValuePair(lbls, acc, histogram.name .. '_bucket'))
  end
  return { buckets = buckets, data = bucketData }
end

local function addSumAndCountForExport(list, bucketValues, histogram)
  for _, b in ipairs(bucketValues.buckets) do
    table.insert(list, b)
  end

  local infLabel = { le = '+Inf' }
  for k, v in pairs(bucketValues.data.labels) do
    infLabel[k] = v
  end
  table.insert(list, setValuePair(infLabel, bucketValues.data.count, histogram.name .. '_bucket'))
  table.insert(list, setValuePair(bucketValues.data.labels, bucketValues.data.sum, histogram.name .. '_sum'))
  table.insert(list, setValuePair(bucketValues.data.labels, bucketValues.data.count, histogram.name .. '_count'))
end

function Histogram:new(config)
  local o = Metric:new(config, {
    bukcets = { 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10 },
  })
  setmetatable(o, self)
  self.__index = self
  for _, label in ipairs(o.labelNames) do
    if label == 'le' then
      error('Label name "le" is a reserved label keyword')
    end
  end
  o.upperBounds = o.bukcets
  o.bucketValues = {}
  for _, upperBound in ipairs(o.upperBounds) do
    o.bucketValues[upperBound] = 0
  end

  if #o.labelNames == 0 then
    o.hashMap = {
      [util.hashTable({})] = createBaseValues({}, o.bucketValues)
    }
  end
  return o
end

function Histogram:observe(labels, value)
  if labels ~= 0 then
    labels = labels or {}
  end
  observe(self, labels)(value)
end

function Histogram:get()
  if self.collect then
    self:collect()
  end
  local data = {}
  for _, value in pairs(self.hashMap) do
    table.insert(data, value)
  end
  local values = {}
  for _, d in ipairs(data) do
    local v = extractBucketValuesForExport(d, self)
    addSumAndCountForExport(values, v, self)
  end
  return {
    name = self.name,
    help = self.help,
    type = metricType,
    values = values,
    aggregator = self.aggregator
  }
end

function Histogram:reset()
  self.hashMap = {}
end

function Histogram:zero(labels)
  local hash = util.hashTable(labels)
  self.hashMap[hash] = createBaseValues(labels, self.bucketValues)
end

function Histogram:startTimer(labels)
  return startTimer(self, labels)()
end

function Histogram:labels(...)
  local labels = util.getLabels(self.labelNames, { ... })
  validation.validateLabel(self.labelNames, labels)
  return {
    observe = function(_, value) observe(self, labels)(value) end,
    startTimer = function(_) startTimer(self, labels)() end,
  }
end

function Histogram:remove(...)
  local labels = util.getLabels(self.labelNames, { ... })
  validation.validateLabel(self.labelNames, labels)
  util.removeLabels(self.hashMap, labels)
end

return Histogram
