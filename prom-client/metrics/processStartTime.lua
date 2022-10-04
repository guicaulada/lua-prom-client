local Gauge = require('prom-client.gauge')

local startInSeconds = math.floor(0.5 + os.time() - os.clock())

local PROCESS_START_TIME = 'process_start_time_seconds'

local function processStartTime(registry, config)
  config = config or {}
  local namePrefix = config.prefix or ''
  local labels = config.labels or {}
  local labelNames = {}
  local registers = nil
  for k, _ in pairs(labels) do
    table.insert(labelNames, k)
  end

  if registry then
    registers = { registry }
  end

  return Gauge:new({
    name = namePrefix .. PROCESS_START_TIME,
    help = 'Start time of the process since unix epoch in seconds.',
    registers = registers,
    labelNames = labelNames,
    aggregator = "omit",
    collect = function(self)
      self:set(labels, startInSeconds)
    end
  })
end

return {
  processStartTime = processStartTime,
  metricNames = { PROCESS_START_TIME }
}
