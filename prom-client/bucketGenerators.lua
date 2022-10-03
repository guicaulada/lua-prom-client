local bucketGenerators = {}

function bucketGenerators.linearBuckets(start, width, count)
  if count < 1 then
    error('Linear buckets need a positive count')
  end

  local buckets = {}
  for i = 0, count - 1 do
    table.insert(buckets, start + i * width)
  end
  return buckets
end

function bucketGenerators.exponentialBuckets(start, factor, count)
  if start < 1 then
    error('Exponential buckets need a positive start')
  end
  if count < 1 then
    error('Exponential buckets need a positive count')
  end
  if factor <= 1 then
    error('Exponential buckets need a factor grater than 1')
  end

  local buckets = {}
  for _ = 0, count - 1 do
    table.insert(buckets, start)
    start = start * factor
  end
  return buckets
end

return bucketGenerators
