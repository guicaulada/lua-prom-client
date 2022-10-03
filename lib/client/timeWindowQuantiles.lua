local TDigest = require('lib/tdigest/tdigest')
local TimeWindowQuantiles = {}

function TimeWindowQuantiles:new(maxAgeSeconds, ageBuckets)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.maxAgeSeconds = maxAgeSeconds or 0
  o.ageBuckets = ageBuckets or 0
  o.shouldRotate = maxAgeSeconds and ageBuckets
  o.ringBuffer = {}
  for i = 1, ageBuckets do
    o.ringBuffer[i] = TDigest:new()
  end
  o.currentBuffer = 0
  o.lastRotateTimestamp = os.clock()
  o.durationBetweenRotates = maxAgeSeconds / ageBuckets or math.huge
  return o
end

function TimeWindowQuantiles:percentile(quantile)
  local bucket = self:rotate()
  return bucket:percentile(quantile)
end

function TimeWindowQuantiles:push(value)
  self:rotate()
  for i = 1, #self.ringBuffer do
    self.ringBuffer[i]:push(value)
  end
end

function TimeWindowQuantiles:reset()
  for i = 1, #self.ringBuffer do
    self.ringBuffer[i]:reset()
  end
end

function TimeWindowQuantiles:compress()
  for i = 1, #self.ringBuffer do
    self.ringBuffer[i]:compress()
  end
end

function TimeWindowQuantiles:rotate()
  local timeSinceLastRotate = os.clock() - self.lastRotateTimestamp
  while timeSinceLastRotate > self.durationBetweenRotates and self.shouldRotate do
    self.ringBuffer[self.currentBuffer] = TDigest:new()
    self.currentBuffer = self.currentBuffer + 1
    if self.currentBuffer >= #self.ringBuffer then
      self.currentBuffer = 1
    end
    timeSinceLastRotate = timeSinceLastRotate - self.durationBetweenRotates
    self.lastRotateTimestamp = self.lastRotateTimestamp + self.durationBetweenRotates
  end
  return self.ringBuffer[self.currentBuffer]
end

return TimeWindowQuantiles
