local Counter = require('prom-client.counter')

local PROCESS_CPU_SECONDS = 'process_cpu_seconds_total'

local function processCpuTotal(registry, config)
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

  local lastCpuUsage = os.clock()

  return Counter:new({
    name = namePrefix .. PROCESS_CPU_SECONDS,
    help = 'Total process CPU time spent in seconds.',
    registers = registers,
    labelNames = labelNames,
    aggregator = "omit",
    collect = function(self)
      local cpuUsage = os.clock()
      self:inc(labels, cpuUsage - lastCpuUsage)
      lastCpuUsage = cpuUsage
    end
  })
end

return {
  processCpuTotal = processCpuTotal,
  metricNames = { PROCESS_CPU_SECONDS }

}
