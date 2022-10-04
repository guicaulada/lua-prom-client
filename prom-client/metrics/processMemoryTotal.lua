local Gauge = require('prom-client.gauge')

local PROCESS_MEMORY_BYTES = 'process_memory_bytes_total'

local function processMemoryTotal(registry, config)
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
    name = namePrefix .. PROCESS_MEMORY_BYTES,
    help = 'Resident memory size in bytes.',
    registers = registers,
    labelNames = labelNames,
    aggregator = "omit",
    collect = function(self)
      self:set(labels, collectgarbage("count") * 1024)
    end
  })
end

return {
  processMemoryTotal = processMemoryTotal,
  metricNames = { PROCESS_MEMORY_BYTES }

}
