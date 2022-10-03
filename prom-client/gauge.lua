local util = require('prom-client.util')
local validation = require('prom-client.validation')
local Metric = require('prom-client.metric')
local metricType = 'gauge'
local Gauge = {}

local function set(gauge, labels, value)
  if type(value) ~= 'number' then
    error('Gauge value must be a number')
  end
  validation.validateLabel(gauge.labelNames, labels)
  util.setValue(gauge.hashMap, value, labels)
end

local function getLabelArg(labels)
  if util.isTable(labels) then
    return labels
  end
  return {}
end

local function getValueArg(labels, value)
  if util.isTable(labels) then
    return value
  end
  return labels
end

function Gauge:new(config)
  local o = Metric:new(config)
  setmetatable(o, self)
  self.__index = self
  return o
end

function Gauge:set(labels, value)
  local value = getValueArg(labels, value)
  local labels = getLabelArg(labels)
  set(self, labels, value)
end

function Gauge:reset()
  self.hashMap = {}
  if #self.labelNames == 0 then
    util.setValue(self.hashMap, 0, {})
  end
end

function Gauge:inc(labels, value)
  local value = getValueArg(labels, value)
  local labels = getLabelArg(labels)
  if value == nil then
    value = 1
  end
  set(self, labels, self:getValue(labels) + value)
end

function Gauge:dec(labels, value)
  local value = getValueArg(labels, value)
  local labels = getLabelArg(labels)
  if value == nil then
    value = 1
  end
  set(self, labels, self:getValue(labels) - value)
end

function Gauge:setToCurrentTime(labels)
  local now = os.time()
  if labels == nil then
    self:set(now)
  else
    self:set(labels, now)
  end
end

function Gauge:startTimer(startLabels)
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
    self:set(labels, delta)
    return delta
  end
end

function Gauge:get()
  if self.collect then
    self:collect()
  end
  local values = {}
  for _, v in pairs(self.hashMap) do
    table.insert(values, v)
  end
  return {
    help = self.help,
    name = self.name,
    type = metricType,
    values = values,
    aggregator = self.aggregator
  }
end

function Gauge:getValue(labels)
  local hash = util.hashTable(labels or {})
  if self.hashMap[hash] then
    return self.hashMap[hash].value
  end
  return 0
end

function Gauge:labels(...)
  local labels = util.getLabels(self.labelNames, { ... })
  validation.validateLabel(self.labelNames, labels)
  return {
    inc = function(_, value) self:inc(labels, value) end,
    dec = function(_, value) self:dec(labels, value) end,
    set = function(_, value) self:set(labels, value) end,
    setToCurrentTime = function(_) self:setToCurrentTime(labels) end,
    startTimer = function(_) self:startTimer(labels) end
  }
end

function Gauge:remove(...)
  local labels = util.getLabels(self.labelNames, { ... })
  validation.validateLabel(self.labelNames, labels)
  util.removeLabels(self.hashMap, labels)
end

return Gauge
