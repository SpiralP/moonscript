module("moonscript.compile", package.seeall)
local util = require("moonscript.util")
local data = require("moonscript.data")
local ntype = data.ntype
local t = { }
local node_types = {
  fndef = {
    {
      "args",
      t
    },
    {
      "whitelist",
      t
    },
    {
      "arrow",
      "slim"
    },
    {
      "body",
      t
    }
  }
}
local build_table
build_table = function()
  local key_table = { }
  for name, args in pairs(node_types) do
    local index = { }
    for i, tuple in ipairs(args) do
      local name = tuple[1]
      index[name] = i + 1
    end
    key_table[name] = index
  end
  return key_table
end
local key_table = build_table()
local make_builder
make_builder = function(name)
  local spec = node_types[name]
  if not spec then
    error("don't know how to build node: " .. name)
  end
  return function(props)
    if props == nil then
      props = { }
    end
    local node = {
      name
    }
    for i, arg in ipairs(spec) do
      local default_value
      name, default_value = unpack(arg)
      local val
      if props[name] then
        val = props[name]
      else
        val = default_value
      end
      if val == t then
        val = { }
      end
      node[i + 1] = val
    end
    return node
  end
end
build = setmetatable({ }, {
  __index = function(self, name)
    self[name] = make_builder(name)
    return rawget(self, name)
  end
})
smart_node = function(node)
  local index = key_table[ntype(node)]
  if not index then
    return node
  end
  return setmetatable(node, {
    __index = function(node, key)
      if index[key] then
        return rawget(node, index[key])
      elseif type(key) == "string" then
        return error("unknown key: `" .. key .. "` on node type: `" .. ntype(node) .. "`")
      end
    end,
    __newindex = function(node, key, value)
      if index[key] then
        key = index[key]
      end
      return rawset(node, key, value)
    end
  })
end
