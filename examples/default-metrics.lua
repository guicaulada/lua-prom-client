local client = require('prom-client')

client.collectDefaultMetrics({
  timeout = 10000,
  gcDurationBuckets = { 0.001, 0.01, 0.1, 1, 2, 5 }, -- default buckets
})

print(client.register:metrics())

--[[
Output from metrics():

# HELP lua_version_info Lua version info.
# TYPE lua_version_info gauge
lua_version_info{patch="0",minor="4",major="5",version="5.4.0"} 1


# HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
process_start_time_seconds 1664845828


# HELP lua_gc_duration_seconds Garbage collection duration in seconds.
# TYPE lua_gc_duration_seconds histogram
lua_gc_duration_seconds_bucket{le="0.005"} 1
lua_gc_duration_seconds_bucket{le="0.01"} 1
lua_gc_duration_seconds_bucket{le="0.025"} 1
lua_gc_duration_seconds_bucket{le="0.05"} 1
lua_gc_duration_seconds_bucket{le="0.1"} 1
lua_gc_duration_seconds_bucket{le="0.25"} 1
lua_gc_duration_seconds_bucket{le="0.5"} 1
lua_gc_duration_seconds_bucket{le="1"} 1
lua_gc_duration_seconds_bucket{le="2.5"} 1
lua_gc_duration_seconds_bucket{le="5"} 1
lua_gc_duration_seconds_bucket{le="10"} 1
lua_gc_duration_seconds_bucket{le="+Inf"} 1
lua_gc_duration_seconds_sum 5.7000000000001e-05
lua_gc_duration_seconds_count 1


# HELP process_memory_bytes_total Resident memory size in bytes.
# TYPE process_memory_bytes_total gauge
process_memory_bytes_total 161793.0


# HELP process_cpu_seconds_total Total process CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0.000162
]]
