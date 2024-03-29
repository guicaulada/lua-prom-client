local client = require('prom-client')

local g = client.Gauge:new({
  name = 'test_gauge',
  help = 'Example of a gauge',
  labelNames = { 'code' },
});

g:set({ code = 200 }, 5);
print(client.register:metrics());
--[[
# HELP test_gauge Example of a gauge
# TYPE test_gauge gauge
test_gauge{code="200"} 5
]]

g:set(15);
print(client.register:metrics());
--[[
# HELP test_gauge Example of a gauge
# TYPE test_gauge gauge
test_gauge{code="200"} 5
test_gauge 15
]]

g:labels('200'):inc();
print(client.register:metrics());
--[[
# HELP test_gauge Example of a gauge
# TYPE test_gauge gauge
test_gauge{code="200"} 6
test_gauge 15
]]

g:inc();
print(client.register:metrics());
--[[
# HELP test_gauge Example of a gauge
# TYPE test_gauge gauge
test_gauge{code="200"} 6
test_gauge 16
]]

g:set(22);
print(client.register:metrics());
--[[
# HELP test_gauge Example of a gauge
# TYPE test_gauge gauge
test_gauge{code="200"} 6
test_gauge 22
]]

local stop = g:startTimer();
time = os.time()
wait = 5
newtime = time + wait
while (time < newtime)
do
  time = os.time()
end
stop({code = 500});
print(client.register:metrics());
--[[
# HELP test_gauge Example of a gauge
# TYPE test_gauge gauge
test_gauge{code="200"} 6
test_gauge{code="500"} 5
test_gauge 22
]]
