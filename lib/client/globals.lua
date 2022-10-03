local Registry = require('./registry')
local globalRegistry = Registry:new()

return {
  globalRegistry = globalRegistry
}
