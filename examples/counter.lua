local client = require('prom-client')

local c = client.Counter:new({
  name = 'test_counter',
  help = 'Example of a counter',
  labelNames = { 'code' }
})

c:inc({ code = 200 });
print(client.register:metrics());

--[[
# HELP test_counter Example of a counter
# TYPE test_counter counter
test_counter{code="200"} 1
]]

c:inc({ code = 200 });
print(client.register:metrics());

--[[
# HELP test_counter Example of a counter
# TYPE test_counter counter
test_counter{code="200"} 2
]]

c:inc();
print(client.register:metrics());

--[[
# HELP test_counter Example of a counter
# TYPE test_counter counter
test_counter{code="200"} 2
test_counter 1
]]

c:reset();
print(client.register:metrics());

--[[
# HELP test_counter Example of a counter
# TYPE test_counter counter
]]

c:inc(15);
print(client.register:metrics());

--[[
# HELP test_counter Example of a counter
# TYPE test_counter counter
test_counter 15
]]

c:inc({ code = 200 }, 12);
print(client.register:metrics());

--[[
# HELP test_counter Example of a counter
# TYPE test_counter counter
test_counter 15
test_counter{code="200"} 12
]]

c:labels('200'):inc(12);
print(client.register:metrics());

--[[
# HELP test_counter Example of a counter
# TYPE test_counter counter
test_counter 15
test_counter{code="200"} 24
]]
