local util = require('lib/client/util')
local validation = require('lib/client/validation')
local Metric = require('lib/client/metric')
local metricType = 'counter'
local Counter = {}

local function setValue(hashMap, value, labels, hash)
  hash = hash or ''
  labels = labels or {}
  if hashMap[hash] ~= nil then
    hashMap[hash].value = hashMap[hash].value + value
  else
    hashMap[hash] = {
      labels = labels,
      value = value
    }
  end
  return hashMap
end

function Counter:new(config)
  local o = Metric:new(config)
  setmetatable(o, self)
  self.__index = self
  return o
end

function Counter:inc(labels, value)
  local hash = nil
  if util.isTable(labels) then
    hash = util.hashTable(labels)
    validation.validateLabel(self.labelNames, labels)
  else
    value = labels
    labels = {}
  end

  if value and type(value) ~= 'number' then
    error('Value is not a valid number: ' .. value)
  end
  if value == nil then value = 1 end
  if value < 0 then
    error('It is not possible to decrease a counter')
  end
  setValue(self.hashMap, value, labels, hash)
end

function Counter:reset()
  self.hashMap = {}
  if #self.labelNames == 0 then
    setValue(self.hashMap, 0)
  end
end

function Counter:get()
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

function Counter:labels(...)
  local labels = util.getLabels(self.labelNames, { ... }) or {}
  return {
    inc = function(value) self:inc(labels, value) end
  }
end

function Counter:remove(...)
  local labels = util.getLabels(self.labelNames, { ... }) or {}

  validation.validateLabel(self.labelNames, labels)
  return util.removeLabels(self.hashMap, labels)
end

return Counter
