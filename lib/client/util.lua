local util = {}
util.Grouper = {}

function util.getValueAsString(value)
  if type(value) == 'string' then
    return value
  elseif type(value) == 'number' then
    return tostring(value)
  elseif type(value) == 'boolean' then
    return tostring(value)
  elseif type(value) == 'table' then
    return table.concat(value, ', ')
  else
    error(string.format('Unsupported value type: %s', type(value)))
  end
end

function util.removeLabels(hashMap, labels)
  local hash = util.hashTable(labels);
  hashMap[hash] = nil
end

function util.setValue(hashMap, value, labels)
  local hash = util.hashTable(labels);
  hashMap[hash] = {
    value = value,
    labels = labels
  }
  return hashMap
end

function util.setValueDelta(hashMap, deltaValue, labels, hash)
  hash = hash or ''
  if hashMap[hash] then
    hashMap[hash].value = hashMap[hash].value + deltaValue
  else
    hashMap[hash] = {
      value = deltaValue,
      labels = labels
    }
  end
end

function util.getLabels(labelNames, args)
  if type(args[1]) == 'table' then
    return args[1]
  end

  if #labelNames ~= #args then
    error(string.format('Label count mismatch: expected %d, got %d', #labelNames, #args))
  end

  local acc = {}
  for i, labelName in ipairs(labelNames) do
    acc[labelName] = args[i]
  end
  return acc
end

function util.hashTable(labels)
  local keys = {}
  for k, _ in pairs(labels) do
    table.insert(keys, k)
  end

  if #keys == 0 then
    return ''
  end

  if #keys == 1 then
    table.sort(keys)
  end

  local hash = ''
  local i = 1
  local size = #keys
  while i <= size do
    hash = string.format('%s%s:%s,', hash, keys[i], labels[keys[i]])
    i = i + 1
  end
  hash = string.format('%s%s:%s', hash, keys[i], labels[keys[i]])
  return hash
end

function util.isTable(t)
  return type(t) == 'table'
end

function util.Grouper:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self.groups = {}
  return o
end

function util.Grouper:add(key, value)
  if self.groups[key] == nil then
    self.groups[key] = {}
  end
  table.insert(self.groups[key], value)
end

return util
