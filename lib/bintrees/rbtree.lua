local TreeBase = require('./treebase')
local Node = require('./node')
local RBNode = {}
local RBTree = {}

local function isRed(node)
  return node ~= nil and node.red
end

local function singleRotate(root, dir)
  local save = root:getChild(not dir)
  root:setChild(not dir, save:getChild(dir))
  save:setChild(dir, root)
  root.red = true
  save.red = false
  return save
end

local function doubleRotate(root, dir)
  root:setChild(not dir, singleRotate(root:getChild(not dir), not dir))
  return singleRotate(root, dir)
end

function RBNode:new(data)
  local o = Node:new(data)
  setmetatable(o, self)
  self.__index = self
  o.red = true
  return o
end

function RBTree:new(comparator)
  local o = TreeBase:new()
  setmetatable(o, self)
  self.__index = self
  self.root = nil
  self.comparator = comparator
  self.size = 0
  return o
end

-- returns true if inserted, false if duplicate
function RBTree:insert(data)
  local ret = false

  if self.root == nil then
    self.root = RBNode:new(data)
    ret = true
    self.size = self.size + 1
  else
    local head = RBNode:new(nil) -- fake root
    local dir = false
    local last = false

    -- setup
    local gp = nil -- grandparent
    local ggp = head -- great-grand-parent
    local p = nil -- parent
    local node = self.root
    ggp.right = self.root

    -- search down
    while true do
      if node == nil then
        -- insert new node at the bottom
        node = RBNode:new(data)
        p:setChild(dir, node)
        ret = true
        self.size = self.size + 1
      elseif isRed(node.left) and isRed(node.right) then
        -- color flip
        node.red = true
        node.left.red = false
        node.right.red = false
      end

      -- fix red violation
      if isRed(node) and isRed(p) then
        local dir2 = ggp.right == gp

        if node == p:getChild(last) then
          ggp:setChild(dir2, singleRotate(gp, not last))
        else
          ggp:setChild(dir2, doubleRotate(gp, not last))
        end
      end

      local cmp = self.comparator(node.data, data)

      -- stop if found
      if cmp == 0 then
        break
      end

      last = dir
      dir = cmp < 0

      -- update helpers
      if gp ~= nil then
        ggp = gp
      end
      gp = p
      p = node
      node = node:getChild(dir)
    end

    -- update root
    self.root = head.right
  end

  -- make root black
  self.root.red = false
  return ret
end

-- returns true if removed, false if not found
function RBTree:remove(data)
  if self.root == nil then
    return false
  end

  local head = RBNode:new(nil) -- fake root
  local node = head
  node.right = self.root
  local p = nil -- parent
  local gp = nil -- grand parent
  local found = nil -- found item
  local dir = true

  while node:getChild(dir) ~= nil do
    local last = dir

    -- update helpers
    gp = p
    p = node
    node = node:getChild(dir)

    local cmp = self.comparator(data, node.data)

    dir = cmp > 0

    -- save found node
    if cmp == 0 then
      found = node
    end

    -- push the red node down
    if not isRed(node) and not isRed(node:getChild(dir)) then
      if isRed(node:getChild(not dir)) then
        local sr = singleRotate(node, dir)
        p:setChild(last, sr)
        p = sr
      elseif not isRed(node:getChild(not dir)) then
        local sibling = p:getChild(not last)
        if sibling ~= nil then
          if not isRed(sibling:getChild(not last)) and not isRed(sibling:getChild(last)) then
            -- color flip
            p.red = false
            sibling.red = true
            node.red = true
          else
            local dir2 = gp.right == p

            if isRed(sibling:getChild(last)) then
              gp:setChild(dir2, doubleRotate(p, last))
            elseif isRed(sibling:getChild(not last)) then
              gp:setChild(dir2, singleRotate(p, last))
            end

            -- ensure correct coloring
            local gpc = gp:getChild(dir2)
            gpc.red = true
            node.red = true
            gpc.left.red = false
            gpc.right.red = false
          end
        end
      end
    end
  end

  -- replace and remove if found
  if found ~= nil then
    found.data = node.data
    p:setChild(p.right == node, node:getChild(node.left == nil))
    self.size = self.size - 1
  end

  -- update root and make it black
  self.root = head.right
  if self.root ~= nil then
    self.root.red = false
  end

  return found ~= nil
end

return RBTree
