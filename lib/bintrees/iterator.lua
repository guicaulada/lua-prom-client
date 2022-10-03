local Iterator = {}

function Iterator:new(tree)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.tree = tree
  o.ancestors = {}
  o.cursor = nil
  return o
end

function Iterator:data()
  if self.cursor ~= nil then
    return self.cursor.data
  else
    return nil
  end
end

-- if nil-iterator, returns first node
-- otherwise, returns next node
function Iterator:next()
  if self.cursor == nil then
    local root = self.tree.root
    if root ~= nil then
      self:minNode(root)
    end
  else
    if self.cursor.right == nil then
      local save = nil
      repeat
        save = self.cursor
        if #self.ancestors > 0 then
          self.cursor = table.remove(self.ancestors)
        else
          self.cursor = nil
          break
        end
      until self.cursor.right == save
    else
      table.insert(self.ancestors, self.cursor)
      self:minNode(self.cursor.right)
    end
  end

  if self.cursor ~= nil then
    return self.cursor.data
  else
    return nil
  end
end

-- if nil-iterator, returns last node
-- otherwise, returns previous node
function Iterator:prev()
  if self.cursor == nil then
    local root = self.tree.root
    if root ~= nil then
      self:maxNode(root)
    end
  else
    if self.cursor.left ~= nil then
      local save = nil
      repeat
        save = self.cursor
        if #self.ancestors > 0 then
          self.cursor = table.remove(self.ancestors)
        else
          self.cursor = nil
          break
        end
      until self.cursor.left == save
    else
      table.insert(self.ancestors, self.cursor)
      self:maxNode(self.cursor.left)
    end
  end

  if self.cursor ~= nil then
    return self.cursor.data
  else
    return nil
  end
end

function Iterator:minNode(start)
  while start.left ~= nil do
    table.insert(self.ancestors, start)
    start = start.left
  end
  self.cursor = start
end

function Iterator:maxNode(start)
  while start.right ~= nil do
    table.insert(self.ancestors, start)
    start = start.right
  end
  self.cursor = start
end

return Iterator
