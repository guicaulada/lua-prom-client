local Iterator = require('./iterator')
local TreeBase = {}

function TreeBase:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- removes all nodes from the tree
function TreeBase:clear()
  self.root = nil
  self.size = 0
end

-- returns node data if found, nil otherwise
function TreeBase:find(data)
  local node = self.root
  while node ~= nil do
    local cmp = self.comparator(data, node.data)
    if cmp == 0 then
      return node
    else
      node = node:getChild(cmp > 0)
    end
  end
  return nil
end

-- returns iterator to node if found, nil otherwise
function TreeBase:findIter(data)
  local node = self.root
  local iter = self:iterator()
  while node ~= nil do
    local cmp = self.comparator(data, node.data)
    if cmp == 0 then
      iter.cursor = node
      return iter
    else
      table.insert(iter.ancestors, node)
      node = node:getChild(cmp > 0)
    end
  end
  return nil
end

-- returns an iterator to the tree node at or immediately after the item
function TreeBase:lowerBound(item)
  local node = self.root
  local iter = self:iterator()
  while node ~= nil do
    local cmp = self.comparator(item, node.data)
    if cmp == 0 then
      iter.cursor = node
      return iter
    end
    table.insert(iter.ancestors, node)
    node = node:getChild(cmp > 0)
  end

  for i = #iter.ancestors, 1, -1 do
    local ancestor = table.remove(iter.ancestors)
    if self.comparator(item, ancestor.data) < 0 then
      iter.cursor = ancestor
      return iter
    end
  end

  iter.ancestors = {}
  return iter
end

-- returns an iterator to the tree node immediately after the item
function TreeBase:upperBound(item)
  local iter = self.lowerBound(item)
  while (iter.data ~= nil and self.comparator(iter.data, item) == 0) do
    iter:next()
  end

  return iter
end

-- returns nil if tree is empty
function TreeBase:min()
  local node = self.root
  if node == nil then
    return nil
  end
  while node.left ~= nil do
    node = node.left
  end
  return node.data
end

-- returns nil if tree is empty
function TreeBase:max()
  local node = self.root
  if node == nil then
    return nil
  end
  while node.right ~= nil do
    node = node.right
  end
  return node.data
end

function TreeBase:iterator()
  return Iterator:new(self)
end

function TreeBase:each(cb)
  local iter = self:iterator()
  local data = iter:next()
  while data ~= nil do
    if cb(data) == false then
      return
    end
    data = iter:next()
  end
end

function TreeBase:reach(cb)
  local iter = self:iterator()
  local data = iter:prev()
  while data ~= nil do
    if cb(data) == false then
      return
    end
    data = iter:prev()
  end
end

return TreeBase
