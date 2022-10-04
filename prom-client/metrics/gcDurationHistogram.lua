local Histogram = require('prom-client.histogram')

local LUA_GC_DURATION_SECONDS = 'lua_gc_duration_seconds'
local DEFAULT_GC_DURATION_BUCKETS = { 0.001, 0.01, 0.1, 1, 2, 5 }

local function gcDurationHistogram(registry, config)
  config = config or {}
  local namePrefix = config.prefix or ''
  local labels = config.labels or {}
  local labelNames = {}
  local registers = nil
  local buckets = config.buckets or DEFAULT_GC_DURATION_BUCKETS

  for k, _ in pairs(labels) do
    table.insert(labelNames, k)
  end

  if registry then
    registers = { registry }
  end

  return Histogram:new({
    name = namePrefix .. LUA_GC_DURATION_SECONDS,
    help = 'Garbage collection duration in seconds.',
    registers = registers,
    labelNames = labelNames,
    buckets = buckets,
    collect = function(self)
      local start = os.clock()
      collectgarbage("collect")
      self:observe(labels, os.clock() - start)
    end
  })
end

return {
  gcDurationHistogram = gcDurationHistogram,
  metricNames = { LUA_GC_DURATION_SECONDS }



}
