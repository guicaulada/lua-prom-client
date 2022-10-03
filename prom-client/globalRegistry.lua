local Registry = require('prom-client.registry')
local globalRegistry = Registry:new()
return globalRegistry
