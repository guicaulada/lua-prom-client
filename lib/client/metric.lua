local client = require('./client')
local util = require('./util')
local validation = require('./validation')
local Metric = {}

function Metric:new(config, defaults)
  if not util.isTable(config) then
    error('Metric config must be a table')
  end
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self.labelNames = {}
  self.registers = { client.globalRegistry }
  self.aggregator = 'sum'
  for k, v in pairs(defaults) do
    self[k] = v
  end
  for k, v in pairs(config) do
    self[k] = v
  end
  if not self.registers then
    self.registers = { client.globalRegistry }
  end
  if not self.help then
    error('Missing mandatory help parameter')
  end
  if not self.name then
    error('Missing mandatory name parameter')
  end
  if not validation.validateMetricName(self.name) then
    error(string.format('Invalid metric name: %s', self.name))
  end
  if not validation.validateLabelName(self.labelNames) then
    error('Invalid label name')
  end
  if self.collect and type(self.collect) ~= 'function' then
    error('Optional "collect" parameter must be a function')
  end
  self:reset()
  for _, register in ipairs(self.registers) do
    register:registerMetric(self)
  end
  return o
end

function Metric:reset()
  -- abstract
end

return Metric
