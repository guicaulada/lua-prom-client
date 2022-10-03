local globalRegistry = require('prom-client.globalRegistry')
local util = require('prom-client.util')
local validation = require('prom-client.validation')
local Metric = {}

function Metric:new(config, defaults)
  if not util.isTable(config) then
    error('Metric config must be a table')
  end
  defaults = defaults or {}
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.hashMap = {}
  o.labelNames = {}
  o.registers = { globalRegistry }
  o.aggregator = 'sum'
  for k, v in pairs(defaults) do
    o[k] = v
  end
  for k, v in pairs(config) do
    o[k] = v
  end
  if not o.registers then
    o.registers = { globalRegistry }
  end
  if not o.help then
    error('Missing mandatory help parameter')
  end
  if not o.name then
    error('Missing mandatory name parameter')
  end
  if not validation.validateMetricName(o.name) then
    error(string.format('Invalid metric name: %s', o.name))
  end
  if not validation.validateLabelName(o.labelNames) then
    error('Invalid label name')
  end
  if o.collect and type(o.collect) ~= 'function' then
    error('Optional "collect" parameter must be a function')
  end
  o:reset()
  for _, register in ipairs(o.registers) do
    register:registerMetric(o)
  end
  return o
end

function Metric:reset()
  -- abstract
end

return Metric
