-- Minetest Worm Mod
-- by Gerald

local WALKING_PERIOD = 1      -- seconds
local WALKING_STEPS = 4       -- needs to be bigger than 0
local TAIL_PROTECTION = false -- if false check for protection only at head position 

local MODNAME = "worm"

local register_worm = function(modname, name, leftover, face, side, tail, can_move)

minetest.register_craftitem(modname..":"..name.."_spawnegg", {
  description = "spawn "..name,
  inventory_image = face,
  on_use = function(itemstack, user, pointed_thing)
    if pointed_thing.type ~= "node" then
      return itemstack
    end
    local pos = pointed_thing.above 
    local player_name = user:get_player_name()
    if minetest.is_protected(pos, player_name) then
      return itemstack
    end
    if minetest.get_node(pos).name ~= "air" then
      return itemstack
    end
    
    local player_dir = vector.subtract({x = 0, y = 0, z = 0}, user:get_look_dir())
    local facedir = minetest.dir_to_facedir(player_dir)
    local dir = minetest.facedir_to_dir(facedir)
    
    local length = itemstack:get_count()
    minetest.set_node(pos, {name = modname..":"..name.."_head_1", param2 = facedir})
    local headtimer = minetest.get_node_timer(pos)
    pos = vector.subtract(pos, dir)
    local i = 0
    while i < length do
      if minetest.get_node(pos).name ~= "air" or (TAIL_PROTECTION and minetest.is_protected(pos, player_name)) then
        pos = vector.add(pos, dir)
        minetest.set_node(pos, {name = modname..":"..name.."_tail_1", param2 = facedir})
        break
      end
      minetest.set_node(pos, {name = modname..":"..name.."_body", param2 = facedir})
      pos = vector.subtract(pos, dir)
      i = i + 1
    end
    minetest.set_node(pos, {name = modname..":"..name.."_tail_1", param2 = facedir})
    local tailtimer = minetest.get_node_timer(pos)
    
    headtimer:set(WALKING_PERIOD, 0)
    tailtimer:set(WALKING_PERIOD, 0)
    
    itemstack:take_item(i)
    return itemstack
  end,
})

for n = 1, WALKING_STEPS do

  local step = function(pos, _)
    local node = minetest.get_node(pos)
    node.name = modname..":"..name.."_head_"..(n+1)
    minetest.set_node(pos, node)
    local timer = minetest.get_node_timer(pos)
    timer:set(WALKING_PERIOD, 0)
    return false
  end
  
  if n == WALKING_STEPS then
    step = function(pos, _)
      local node = minetest.get_node(pos)
      local facedir = node.param2
      local dirs = {
        4, 
        facedir % 4,  -- 4 -> 0 
        (facedir + 1) % 4,
        (facedir + 2) % 4,
        (facedir + 3) % 4,
        8 
      }
      for i = 1, 6 do
        local newpos = vector.add(pos, minetest.facedir_to_dir(dirs[i]))
        if can_move(newpos) then
          minetest.set_node(newpos, {name = modname..":"..name.."_head_1", param2 = dirs[i]})
          minetest.set_node(pos, {name = modname..":"..name.."_body", param2 = dirs[i]})
          local timer = minetest.get_node_timer(newpos)
          timer:set(WALKING_PERIOD, 0)
          return false
        end
      end
      -- worm stuck
      return true
    end
  end


  minetest.register_node(modname..":"..name.."_head_"..n, {
    description = name.." head",
    paramtype = "light",
    paramtype2 = "facedir",
    drawtype = "nodebox",
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5, -0.5, -0.5, 0.5, 0.5, -0.5 + (1 / WALKING_STEPS) * n},
      },
    },
    tiles = {
      side.."^[transform1",
      side.."^[transform3",
      side,
      side.."^[transform2",
      face,
      side
    },
    groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
    damage_per_second = 10,
    on_timer = step,
    drop = "",
  })
  
end

minetest.register_node(modname..":"..name.."_body", {
  description = name.." body part",
  paramtype = "light",
  paramtype2 = "facedir",
  tiles = {
    side.."^[transform1",
    side.."^[transform3",
    side,
    side.."^[transform2",
    side,
    side
  },
  groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
  after_dig_node = function(pos, node, _, _)
    local newpos = vector.add(pos, minetest.facedir_to_dir(node.param2))
    local newnode = minetest.get_node(newpos)
    if newnode.name == modname..":"..name.."_body" then
      newnode.name = modname..":"..name.."_tail_1"
      minetest.set_node(newpos, newnode)
      local timer = minetest.get_node_timer(newpos)
      timer:set(WALKING_PERIOD, 0)
    elseif newnode.name:find(modname..":"..name.."_head") == 1  then
      newnode.name = "air"
      minetest.set_node(newpos, newnode)
    end
  end,
  drop = "",
})

for n = 1, WALKING_STEPS do

  local step = function(pos, _)
    local node = minetest.get_node(pos)
    node.name = modname..":"..name.."_tail_"..(n+1)
    minetest.set_node(pos, node)
    local timer = minetest.get_node_timer(pos)
    timer:set(WALKING_PERIOD, 0)
    return false
  end
  
  if n == WALKING_STEPS then
  step =  function(pos, elapsed)
      local node = minetest.get_node(pos)
      local facedir = node.param2
      local newpos = vector.add(pos, minetest.facedir_to_dir(facedir))
      local newnode = minetest.get_node(newpos)
      if newnode.name == modname..":"..name.."_body" then
        newnode.name = modname..":"..name.."_tail_1"
        minetest.set_node(newpos, newnode)
        local timer = minetest.get_node_timer(newpos)
        timer:set(WALKING_PERIOD, 0)
      elseif newnode.name:find(modname..":"..name.."_head") == 1 then
        minetest.set_node(newpos, {name = "air"})
      end
      minetest.set_node(pos, {name = leftover})
      return false
    end
  end

  minetest.register_node(modname..":"..name.."_tail_"..n, {
    description = name.." tail",
    paramtype = "light",
    paramtype2 = "facedir",
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {
          { -0.5, -0.5, -0.5 + (1 / WALKING_STEPS) * (n - 1), 0.5, 0.5, 0.5},
        },
    },
    tiles = {
      side.."^[transform1",
      side.."^[transform3",
      side,
      side.."^[transform2",
      side,
      tail
    },
    on_timer = step,
    after_dig_node = function(pos, node, _, _)
      local newpos = vector.add(pos, minetest.facedir_to_dir(node.param2))
      local newnode = minetest.get_node(newpos)
      if newnode.name == modname..":"..name.."_body" then
        newnode.name = modname..":"..name.."_tail_1"
        minetest.set_node(newpos, newnode)
        local timer = minetest.get_node_timer(newpos)
        timer:set(WALKING_PERIOD, 0)
      elseif newnode.name:find(modname..":"..name.."_head") == 1  then
        newnode.name = "air"
        minetest.set_node(newpos, newnode)
      end
    end,
    groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
    drop = "",
  })

end

end


local worm_leftover = "default:dirt"

register_worm(MODNAME, "worm", 
  worm_leftover, 
  "worm_face.png", 
  "worm_side.png", 
  "worm_tail.png",
  function(pos)
    local name = minetest.get_node(pos).name
    return minetest.registered_nodes[name].buildable_to or minetest.get_node_group(name, "crumbly") >= 3
  end
  )

register_worm(MODNAME, "snake",
  "air", 
  "snake_face.png", 
  "snake_side.png", 
  "snake_tail.png", 
  function(pos)
    return minetest.registered_nodes[minetest.get_node(pos).name].buildable_to
  end 
)


