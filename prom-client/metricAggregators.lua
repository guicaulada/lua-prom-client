local util = require('prom-client.util')

function AggregatorFactory(aggregatorFn)
  return function(metrics)
    if #metrics == 0 then
      return
    end
    local result = {
      help = metrics[1].help,
      name = metrics[1].name,
      type = metrics[1].type,
      values = {},
      aggregator = metrics[1].aggregator,
    }

    local byLabels = util.Grouper:new()
    for _, metric in ipairs(metrics) do
      for _, value in ipairs(metric.values) do
        local key = util.hashTable(value.labels)
        byLabels:add(string.format('%s_%s', value.metricName, key), value)
      end
    end

    for _, values in pairs(byLabels.groups) do
      if #values == 0 then
        return
      end
      local valObj = {
        value = aggregatorFn(values),
        labels = values[1].labels,
      }
      if values[1].metricName then
        valObj.metricName = values[1].metricName
      end
      table.insert(result.values, valObj)
    end
    return result
  end
end

return {
  AggregatorFactory = AggregatorFactory,
  aggregators = {
    sum = AggregatorFactory(function(values)
      local sum = 0
      for _, value in ipairs(values) do
        sum = sum + value.value
      end
      return sum
    end),
    first = AggregatorFactory(function(values)
      return values[1].value
    end),
    omit = function() return {} end,
    average = AggregatorFactory(function(values)
      local sum = 0
      for _, value in ipairs(values) do
        sum = sum + value.value
      end
      return sum / #values
    end),
    min = AggregatorFactory(function(values)
      local min = values[1].value
      for _, value in ipairs(values) do
        if value.value < min then
          min = value.value
        end
      end
      return min
    end),
    max = AggregatorFactory(function(values)
      local max = values[1].value
      for _, value in ipairs(values) do
        if value.value > max then
          max = value.value
        end
      end
      return max
    end),
  }
}
