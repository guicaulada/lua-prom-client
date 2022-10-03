local RBTree = require('../bintrees/rbtree')
local TDigest = {}

local function compareCentroidMeans(a, b)
  if a.mean > b.mean then
    return 1
  elseif a.mean < b.mean then
    return -1
  end
  return 0
end

local function compareCentroidMeanCumns(a, b)
  if a.meanCumn > b.meanCumn then
    return 1
  elseif a.meanCumn < b.meanCumn then
    return -1
  end
  return 0
end

local function popRandom(choices)
  local index = math.random(#choices)
  return table.remove(choices, index)
end

function TDigest:new(delta, K, CX)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self.discrete = delta == false
  self.delta = delta or 0.01
  self.K = K or 25
  self.CX = CX or 1.1
  self.centroids = RBTree:new(compareCentroidMeans)
  self.nreset = 0
  self:reset()
  return o
end

function TDigest:reset()
  self.centroids:clear()
  self.n = 0
  self.nreset = self.nreset + 1
  self.lastCumulate = 0
end

function TDigest:size()
  return self.centroids.size
end

function TDigest:toTable(everything)
  local result = {}
  if everything then
    self:cumulate(true)
    self.centroids:each(function(c)
      table.insert(result, c)
    end)
  else
    self.centroids:each(function(c)
      table.insert(result, { mean = c.mean, n = c.n })
    end)
  end
  return result
end

function TDigest:summary()
  local approx = 'approximating'
  if self.discrete then
    approx = 'exact'
  end
  local s = {
    approx + self.n + ' samples using ' + self:size() + ' centroids',
    'min = ' + self:percentile(0),
    'Q1 = ' + self:percentile(0.25),
    'Q2 = ' + self:percentile(0.5),
    'Q3 = ' + self:percentile(0.75),
    'max = ' + self:percentile(1.0),
  }
  return table.concat(s, '\n')
end

function TDigest:push(x, n)
  n = n or 1
  if type(x) ~= 'table' then
    x = { x }
  end
  for i = 1, #x, 1 do
    self:digest(x[i], n)
  end
end

function TDigest:pushCentroid(c)
  if type(c) ~= 'table' then
    c = { c }
  end
  for i = 1, #c, 1 do
    self:digest(c[i].mean, c[i].n)
  end
end

function TDigest:cumulate(exact)
  if self.n == self.lastCumulate or (not exact and self.CX and self.CX > (self.n / self.lastCumulate)) then
    return
  end

  local cumn = 0
  self.centroids:each(function(c)
    c.meanCumn = cumn + c.n / 2
    cumn = cumn + c.n
    c.cumn = cumn
  end)
  self.lastCumulate = cumn
  self.n = self.lastCumulate
end

function TDigest:findNearest(x)
  if self:size() == 0 then
    return nil
  end
  local iter = self.centroids:lowerBound({ mean = x })
  local c = iter:data()
  if c == nil then
    c = iter:prev()
  end
  if c.mean == x or self.discrete then
    return c
  end
  local prev = iter:prev()
  if prev and math.abs(prev.mean - x) < math.abs(c.mean - x) then
    return prev
  else
    return c
  end
end

function TDigest:newCentroid(x, n, cumn)
  local c = { mean = x, n = n, cumn = cumn }
  self.centroids:insert(c)
  self.n = self.n + n
  return c
end

function TDigest:addWeight(nearest, x, n)
  if x ~= nearest.mean then
    nearest.mean = nearest.mean + n * (x - nearest.mean) / (nearest.n + n)
  end
  nearest.cumn = nearest.cumn + n
  nearest.meanCumn = nearest.meanCumn + n / 2
  nearest.n = nearest.n + n
  self.n = self.n + n
end

function TDigest:digest(x, n)
  local min = self.centroids:min()
  local max = self.centroids:max()
  local nearest = self:findNearest(x)
  if nearest and nearest.mean == x then
    self:addWeight(nearest, x, n)
  elseif nearest == min then
    self:newCentroid(x, n, 0)
  elseif nearest == max then
    self:newCentroid(x, n, self.n)
  elseif nearest and self.discrete then
    self:newCentroid(x, n, nearest.cumn)
  elseif nearest then
    local p = nearest.meanCumn / self.n
    local maxN = math.floor(4 * self.n * self.delta * p * (1 - p))
    if maxN - nearest.n >= n then
      self:addWeight(nearest, x, n)
    else
      self:newCentroid(x, n, nearest.cumn)
    end
  end
  self:cumulate(false)
  if not self.discrete and self.K and self:size() > self.K / self.delta then
    self:compress()
  end
end

function TDigest:boundMean(x)
  local iter = self.centroids:upperBound({ mean = x })
  local lower = iter:prev()
  local upper = lower
  if lower.mean ~= x then
    upper = iter:next()
  end
  return { lower, upper }
end

function TDigest:pRank(x)
  local xs = x
  if type(x) ~= 'table' then
    xs = { x }
  end
  local result = {}
  for i = 1, #xs, 1 do
    result[i] = self:_pRank(x)
  end
  if type(x) ~= 'table' then
    return result[1]
  else
    return result
  end
end

function TDigest:_pRank(x)
  if self:size() == 0 then
    return nil
  elseif x < self.centroids:min().mean then
    return 0.0
  elseif x > self.centroids:max().mean then
    return 1.0
  end

  self:cumulate(true)
  local bound = self:boundMean(x)
  local lower = bound[1]
  local upper = bound[2]
  if self.discrete then
    return lower.cumn / self.n
  else
    local cumn = lower.meanCumn
    if lower ~= upper then
      cumn = cumn + (x - lower.mean) * (upper.meanCumn - lower.meanCumn) / (upper.mean - lower.mean)
    end
    return cumn / self.n
  end
end

function TDigest:boundMeanCumn(cumn)
  self.centroids.comparator = compareCentroidMeanCumns
  local iter = self.centroids:upperBound({ meanCumn = cumn })
  self.centroids.comparator = compareCentroidMeans
  local lower = iter:prev()
  local upper = lower
  if not (lower and lower.meanCumn == cumn) then
    upper = iter:next()
  end
  return { lower, upper }
end

function TDigest:percentile(p)
  local ps = p
  if type(p) ~= 'table' then
    ps = { p }
  end
  local result = {}
  for i = 1, #ps, 1 do
    result[i] = self:_percentile(p)
  end
  if type(p) ~= 'table' then
    return result[1]
  else
    return result
  end
end

function TDigest:_percentile(p)
  if self:size() == 0 then
    return nil
  end

  self:cumulate(true)
  local h = self.n * p
  local bound = self:boundMeanCumn(h)
  local lower = bound[1]
  local upper = bound[2]
  if lower == nil then
    return upper.mean
  elseif upper == nil then
    return lower.mean
  elseif lower == upper then
    return lower.mean
  elseif not self.discrete then
    return lower.mean + (h - lower.meanCumn) * (upper.mean - lower.mean) / (upper.meanCumn - lower.meanCumn)
  elseif h <= lower.cumn then
    return lower.mean
  else
    return upper.mean
  end
end

function TDigest:compress()
  if self.compressing then
    return
  end

  local points = self:toTable()
  self:reset()
  self.compressing = true
  while #points > 0 do
    self:pushCentroid(popRandom(points))
  end
  self:cumulate(true)
  self.compressing = false
end

return TDigest
