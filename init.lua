-- Minetest Worm Mod
-- by Gerald






local walking_period = 2  -- seconds

minetest.register_craftitem("worm:spawnegg", {
  description = "worm",
  inventory_image = "worm_face.png",
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type ~= "node" then
      return itemstack
    end
    local pos = pointed_thing.above
    local dir = 0
    local length = 6
    minetest.set_node(pos, {name = "worm:head", param2 = dir})
    local headtimer = minetest.get_node_timer(pos)
    pos.z = pos.z - 1
    for i = 0, length do
      minetest.set_node(pos, {name = "worm:body", param2 = dir})
      pos.z = pos.z - 1
    end
    minetest.set_node(pos, {name = "worm:tail", param2 = dir})
    local tailtimer = minetest.get_node_timer(pos)
    
    headtimer:set(walking_period, 0)
    tailtimer:set(walking_period, 0)
    
    --itemstack:take_item()
    return itemstack
  end,
})


minetest.register_node("worm:head", {
  description = "A worms head",
  paramtype = "light",
  paramtype2 = "facedir",
  tiles = {
    "worm_side.png^[transform1",
    "worm_side.png^[transform1",
    "worm_side.png",
    "worm_side.png",
    "worm_face.png",
    "worm_side.png"
  },
  groups = {snappy = 3},
  damage_per_second = 10,
  on_timer = function(pos, elapsed)
    local node = minetest.get_node(pos)
    local facedir = node.param2
    local dirs = {
      4, 
      facedir,
      (facedir + 1) % 4,
      (facedir + 2) % 4,
      (facedir + 3) % 4,
      5 
    }
    for i = 1, 6 do
      local newpos = vector.add(pos, minetest.facedir_to_dir(dirs[i]))
      if minetest.registered_nodes[minetest.get_node(newpos).name].buildable_to then
        minetest.set_node(newpos, {name = "worm:head", param2 = dirs[i]})
        minetest.set_node(pos, {name = "worm:body", param2 = dirs[i]})
        local timer = minetest.get_node_timer(newpos)
        timer:set(walking_period, 0)
        return false
      end
    end
    -- worm stuck
    return true
  end,
  drop = "",
})

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
  groups = {snappy = 3},
  after_dig_node = function(pos, node, _, _)
    local newpos = vector.add(pos, minetest.facedir_to_dir(node.param2))
    local newnode = minetest.get_node(newpos)
    if newnode.name == "worm:body" then
      newnode.name = "worm:tail"
      minetest.set_node(newpos, newnode)
      local timer = minetest.get_node_timer(newpos)
      timer:set(walking_period, 0)
    elseif newnode.name == "worm:head"  then
      newnode.name = "air"
      minetest.set_node(newpos, newnode)
    end
  end,
  drop = "",
})

minetest.register_node("worm:tail", {
  description = "A worms tail",
  paramtype = "light",
  paramtype2 = "facedir",
  tiles = {
    "worm_side.png^[transform1",
    "worm_side.png^[transform1",
    "worm_side.png",
    "worm_side.png",
    "worm_side.png",
    "worm_tail.png"
  },
  on_timer = function(pos, elapsed)
    local node = minetest.get_node(pos)
    local facedir = node.param2
    local newpos = vector.add(pos, minetest.facedir_to_dir(facedir))
    local newnode = minetest.get_node(newpos)
    if newnode.name == "worm:body" then
      newnode.name = "worm:tail"
      minetest.set_node(newpos, newnode)
      local timer = minetest.get_node_timer(newpos)
      timer:set(walking_period, 0)
    elseif newnode.name == "worm:head" then
      minetest.set_node(newpos, {name = "air"})
    end
    minetest.set_node(pos, {name = "air"})
    return false
  end,
  after_dig_node = function(pos, node, _, _)
    local newpos = vector.add(pos, minetest.facedir_to_dir(node.param2))
    local newnode = minetest.get_node(newpos)
    if newnode.name == "worm:body" then
      newnode.name = "worm:tail"
      minetest.set_node(newpos, newnode)
      local timer = minetest.get_node_timer(newpos)
      timer:set(walking_period, 0)
    elseif newnode.name == "worm:head"  then
      newnode.name = "air"
      minetest.set_node(newpos, newnode)
    end
  end,
  groups = {snappy = 3},
  drop = "",
})




