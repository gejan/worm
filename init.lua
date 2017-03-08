-- Minetest Worm Mod
-- by Gerald

local walking_period = 1  -- seconds
local walking_steps = 4     -- needs to be bigger than 0

minetest.register_craftitem("worm:spawnegg", {
  description = "worm",
  inventory_image = "worm_face.png",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type ~= "node" then
      return itemstack
    end
    local pos = pointed_thing.above
    local dir = 0
    local length = itemstack:get_count()
    minetest.set_node(pos, {name = "worm:head_1", param2 = dir})
    local headtimer = minetest.get_node_timer(pos)
    pos.z = pos.z - 1
    for i = 0, length do
      minetest.set_node(pos, {name = "worm:body", param2 = dir})
      pos.z = pos.z - 1
    end
    minetest.set_node(pos, {name = "worm:tail_1", param2 = dir})
    local tailtimer = minetest.get_node_timer(pos)
    
    headtimer:set(walking_period, 0)
    tailtimer:set(walking_period, 0)
    
    itemstack:clear()
    return itemstack
  end,
})

for n = 1, walking_steps do

  local step = function(pos, _)
    local node = minetest.get_node(pos)
    node.name = "worm:head_"..(n+1)
    minetest.set_node(pos, node)
    local timer = minetest.get_node_timer(pos)
    timer:set(walking_period, 0)
    return false
  end
  
  if n == walking_steps then
    step = function(pos, _)
      local node = minetest.get_node(pos)
      local facedir = node.param2
      local dirs = {
        4, 
        facedir % 4,  -- 4 -> 0 
        (facedir + 1) % 4,
        (facedir + 2) % 4,
        (facedir + 3) % 4,
        5 
      }
      for i = 1, 6 do
        local newpos = vector.add(pos, minetest.facedir_to_dir(dirs[i]))
        if minetest.registered_nodes[minetest.get_node(newpos).name].buildable_to then
          minetest.set_node(newpos, {name = "worm:head_1", param2 = dirs[i]})
          minetest.set_node(pos, {name = "worm:body", param2 = dirs[i]})
          local timer = minetest.get_node_timer(newpos)
          timer:set(walking_period, 0)
          return false
        end
      end
      -- worm stuck
      return true
    end
  end


  minetest.register_node("worm:head_"..n, {
    description = "A worms head",
    paramtype = "light",
    paramtype2 = "facedir",
    drawtype = "nodebox",
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5, -0.5, -0.5, 0.5, 0.5, -0.5 + (1 / walking_steps) * n},
      },
    },
    tiles = {
      "worm_side.png^[transform1",
      "worm_side.png^[transform1",
      "worm_side.png",
      "worm_side.png",
      "worm_face.png",
      "worm_side.png"
    },
    groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
    damage_per_second = 10,
    on_timer = step,
    drop = "",
  })
  
end

minetest.register_node("worm:body", {
  description = "A worms body part",
  paramtype = "light",
  paramtype2 = "facedir",
  tiles = {
    "worm_side.png^[transform1",
    "worm_side.png^[transform1",
    "worm_side.png",
    "worm_side.png",
    "worm_side.png",
    "worm_side.png"
  },
  groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
  after_dig_node = function(pos, node, _, _)
    local newpos = vector.add(pos, minetest.facedir_to_dir(node.param2))
    local newnode = minetest.get_node(newpos)
    if newnode.name == "worm:body" then
      newnode.name = "worm:tail_1"
      minetest.set_node(newpos, newnode)
      local timer = minetest.get_node_timer(newpos)
      timer:set(walking_period, 0)
    elseif newnode.name:find("worm:head") == 1  then
      newnode.name = "air"
      minetest.set_node(newpos, newnode)
    end
  end,
  drop = "",
})

for n = 1, walking_steps do

  local step = function(pos, _)
    local node = minetest.get_node(pos)
    node.name = "worm:tail_"..(n+1)
    minetest.set_node(pos, node)
    local timer = minetest.get_node_timer(pos)
    timer:set(walking_period, 0)
    return false
  end
  
  if n == walking_steps then
  step =  function(pos, elapsed)
      local node = minetest.get_node(pos)
      local facedir = node.param2
      local newpos = vector.add(pos, minetest.facedir_to_dir(facedir))
      local newnode = minetest.get_node(newpos)
      if newnode.name == "worm:body" then
        newnode.name = "worm:tail_1"
        minetest.set_node(newpos, newnode)
        local timer = minetest.get_node_timer(newpos)
        timer:set(walking_period, 0)
      elseif newnode.name:find("worm:head") == 1 then
        minetest.set_node(newpos, {name = "air"})
      end
      minetest.set_node(pos, {name = "air"})
      return false
    end
  end

  minetest.register_node("worm:tail_"..n, {
    description = "A worms tail",
    paramtype = "light",
    paramtype2 = "facedir",
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
          { -0.5, -0.5, -0.5 + (1 / walking_steps) * (n - 1), 0.5, 0.5, 0.5},
        },
    },
    tiles = {
      "worm_side.png^[transform1",
      "worm_side.png^[transform1",
      "worm_side.png",
      "worm_side.png",
      "worm_side.png",
      "worm_tail.png"
    },
    on_timer = step,
    after_dig_node = function(pos, node, _, _)
      local newpos = vector.add(pos, minetest.facedir_to_dir(node.param2))
      local newnode = minetest.get_node(newpos)
      if newnode.name == "worm:body" then
        newnode.name = "worm:tail_1"
        minetest.set_node(newpos, newnode)
        local timer = minetest.get_node_timer(newpos)
        timer:set(walking_period, 0)
      elseif newnode.name:find("worm:head") == 1  then
        newnode.name = "air"
        minetest.set_node(newpos, newnode)
      end
    end,
    groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
    drop = "",
  })

end




