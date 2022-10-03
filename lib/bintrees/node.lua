local Node = {}

function Node:new(data)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.data = data
  o.left = nil
  o.right = nil
  return o
end

function Node:getChild(dir)
  if dir then
    return self.right
  else
    return self.left
  end
end

function Node:setChild(dir, node)
  if dir then
    self.right = node
  else
    self.left = node
  end
end

return Node
