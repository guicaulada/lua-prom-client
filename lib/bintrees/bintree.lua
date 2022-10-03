local TreeBase = require('lib/bintrees/treebase')
local Node = require('lib/bintrees/node')
local BinTree = {}

function BinTree:new(comparator)
  local o = TreeBase:new()
  setmetatable(o, self)
  self.__index = self
  o.root = nil
  o.comparator = comparator
  o.size = 0
  return o
end

-- returns true if inserted, false if duplicate
function BinTree:insert(data)
  if self.root == nil then
    self.root = Node:new(data)
    self.size = self.size + 1
    return true
  end

  local dir = false

  -- setup
  local p = nil -- parent
  local node = self.root

  -- search down
  while true do
    if node == nil then
      -- insert new node at the bottom
      node = Node:new(data)
      p:setChild(dir, node)
      self.size = self.size + 1
      return true
    end

    if self.comparator(node.data, data) == 0 then
      return false
    end

    dir = self.comparator(node.data, data) < 0

    -- update helpers
    p = node
    node = node:getChild(dir)
  end
end

-- returns true if removed, false if not found
function BinTree:remove(data)
  if self.root == nil then
    return false
  end

  local head = Node:new(nil) -- fake root
  local node = head
  node.right = self.root
  local p = nil -- parent
  local found = nil
  local dir = true

  while node:getChild(dir) ~= nil do
    p = node
    node = node:getChild(dir)
    local cmp = self.comparator(data, node.data)
    dir = cmp > 0

    if cmp == 0 then
      found = node
    end
  end

  if found ~= nil then
    found.data = node.data
    p:setChild(p.right == node, node:getChild(node.left == nil))
    self.root = head.right
    self.size = self.size - 1
    return true
  else
    return false
  end
end

return BinTree
