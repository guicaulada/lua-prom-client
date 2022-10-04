local Gauge = require('prom-client.gauge')

local version = _VERSION
local major = version:match('Lua (%d+)')
local minor = version:match('Lua %d+%.(%d+)')
local patch = version:match('Lua %d+%.%d+%.?(%d*)')

if #patch == 0 then
  patch = 0
end

local luaVersion = major .. '.' .. minor .. '.' .. patch

local LUA_VERSION_INFO = 'lua_version_info'

local function processVersion(registry, config)
  config = config or {}
  local namePrefix = config.prefix or ''
  local labelNames = {}
  local labels = { version = luaVersion, major = major, minor = minor, patch = patch }
  local registers = nil
  if config.labels then
    for k, v in pairs(config.labels) do
      labels[k] = v
    end
  end

  for k, _ in pairs(labels) do
    table.insert(labelNames, k)
  end

  if registry then
    registers = { registry }
  end

  return Gauge:new({
    name = namePrefix .. LUA_VERSION_INFO,
    help = 'Lua version info.',
    registers = registers,
    labelNames = labelNames,
    aggregator = "first",
    collect = function(self)
      self:labels(labels):set(1)
    end
  })
end

return {
  processVersion = processVersion,
  metricNames = { LUA_VERSION_INFO }
}
