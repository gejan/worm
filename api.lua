local WALKING_PERIOD = worm.config.WALKING_PERIOD

-- Defines a "worm" (spawnitem and nodes)
-- @param modname   The name of the mod, which registers the nodes
-- @param name      The name of the creature; Has to be unique
-- @param data      A table containing:
--   - leftover       The node placed behind the tail when moving away 
--   - walking_steps  The number of steps to pass one node
--   - can_move       A function (Position * Node -> Boolean) defining which nodes 
--                    can be destroyed by the worm
--   - flying         Movement behaviour
--   - *_textures     (See examples)
-- @return          True if successful
worm.register_worm = function (modname, name, data)
  -- default values:
  if not data.leftover then
    data.leftover = "air"
  end  
  if not data.walking_steps then
    data.walking_steps = worm.config.DEFAULT_WALKING_STEPS
  end 
  if not data.can_move then
    data.can_move = function(_, node)
      return node.name == "air"
    end
  end
  -- required values:
  if not (data.face_texture and data.side_texture and data.tail_texture) then
    print("[worm] register_worm of "..modname..":"..name.." failed because of incomplete data")
    return false
  end
  -- reusing textures
  if not data.bottem_texture then
    data.bottem_texture = data.side_texture
  end
  if not data.top_texture then
    data.top_texture = data.side_texture
  end
  if not data.left_texture then
    data.left_texture = data.side_texture
  end
  if not data.inventory_image then
    data.inventory_image = data.face_texture
  end
  if not data.spawn_in then
    data.spawn_in = "air"
  end
  -- Definition of the spawn item
  minetest.register_craftitem(modname..":"..name.."_spawnegg", {
    description = "spawn "..name,
    inventory_image = data.inventory_image,
    on_use = function(itemstack, user, pointed_thing)
      if pointed_thing.type ~= "node" then
        return itemstack
      end
      local pos = pointed_thing.above 
      local player_name = user:get_player_name()
      if minetest.is_protected(pos, player_name) then
        return itemstack
      end
      if minetest.get_node(pos).name ~= data.spawn_in then
        return itemstack
      end
      local zero = {x = 0, y = 0, z = 0}
      local player_dir = vector.subtract(zero, user:get_look_dir())
      local facedir = minetest.dir_to_facedir(player_dir)
      local dir = minetest.facedir_to_dir(facedir)
      local length = itemstack:get_count()
      minetest.set_node(pos, {
        name = modname..":"..name.."_head_1",
        param2 = facedir
      })
      local headtimer = minetest.get_node_timer(pos)
      pos = vector.subtract(pos, dir)
      local i = 0
      while i < length do
        if minetest.get_node(pos).name ~= data.spawn_in or 
            (worm.config.TAIL_PROTECTION and minetest.is_protected(pos, player_name)) then
          pos = vector.add(pos, dir)
          minetest.set_node(pos, {
            name = modname..":"..name.."_tail_1",
            param2 = facedir
          })
          break
        end
        minetest.set_node(pos, {
          name = modname..":"..name.."_body",
          param2 = facedir
        })
        pos = vector.subtract(pos, dir)
        i = i + 1
      end
      minetest.set_node(pos, {
        name = modname..":"..name.."_tail_1",
        param2 = facedir
      })
      local tailtimer = minetest.get_node_timer(pos)
      headtimer:set(WALKING_PERIOD, 0)
      tailtimer:set(WALKING_PERIOD, 0)
      itemstack:take_item(i)
      return itemstack
    end,
  })
  
  -- Definition of head nodes
  for n = 1, data.walking_steps do
    -- Called on nodetimer
    -- Incomplete head -> Update the head
    local step = function(pos, _)
      local node = minetest.get_node(pos)
      node.name = modname..":"..name.."_head_"..(n+1)
      minetest.set_node(pos, node)
      local timer = minetest.get_node_timer(pos)
      timer:set(WALKING_PERIOD, 0)
      return false
    end
    -- Complete head -> Move head to a different position
    if n == data.walking_steps then
      step = function(pos, _)
        local node = minetest.get_node(pos)
        local facedir = node.param2
        local dirs         -- Hierarchy of preferred directions
        if data.flying then
          dirs = {
            facedir % 4,  -- 4 -> 0 
            (facedir + 1) % 4,
            (facedir + 2) % 4,
            (facedir + 3) % 4,
            8,
            4 
          }
        else
          dirs = {
            4,
            facedir % 4,  -- 4 -> 0 
            (facedir + 1) % 4,
            (facedir + 2) % 4,
            (facedir + 3) % 4,
            8
          }
        end
        for i = 1, 6 do
          local newpos = vector.add(pos, minetest.facedir_to_dir(dirs[i]))
          local newnode = minetest.get_node(newpos)
          local grow = minetest.get_node_group(newnode.name, "swallowable")
          if grow > 0 then
            grow = grow + 1
            if grow > data.walking_steps then
              grow = data.walking_steps
            end
            minetest.set_node(newpos, {
              name = modname..":"..name.."_head_"..grow, 
              param2 = dirs[i]
            })
            minetest.set_node(pos, {
              name = modname..":"..name.."_body",
              param2 = dirs[i]
            })
            local timer = minetest.get_node_timer(newpos)
            timer:set(WALKING_PERIOD, 0)
            return false
          elseif data.can_move(newpos, newnode) then
            minetest.set_node(newpos, {
              name = modname..":"..name.."_head_1", 
              param2 = dirs[i]
            })
            minetest.set_node(pos, {
              name = modname..":"..name.."_body",
              param2 = dirs[i]
            })
            local timer = minetest.get_node_timer(newpos)
            timer:set(WALKING_PERIOD, 0)
            return false
          end
        end
        -- Worm stuck
        return true
      end
    end
    local drawtype
    if data.walking_steps > 1 then
      drawtype = "nodebox"
    end
    minetest.register_node(modname..":"..name.."_head_"..n, {
      description = name.." head",
      paramtype = "light",
      paramtype2 = "facedir",
      drawtype = drawtype,
      node_box = {
        type = "fixed",
        fixed = {
          {-0.5, -0.5, -0.5, 0.5, 0.5, -0.5 + (1 / data.walking_steps) * n},
        },
      },
      tiles = {
        data.top_texture.."^[transform1",
        data.bottem_texture.."^[transform3",
        data.side_texture,
        data.left_texture.."^[transform2",
        data.face_texture,
        data.side_texture
      },
      groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
      damage_per_second = 10,
      on_timer = step,
      drop = "",
    }) 
  end
  
  -- Definition of the body node
  minetest.register_node(modname..":"..name.."_body", {
    description = name.." body part",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
      data.top_texture.."^[transform1",
      data.bottem_texture.."^[transform3",
      data.side_texture,
      data.left_texture.."^[transform2",
      data.side_texture,
      data.side_texture
    },
    groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
    -- Add a new tail to keep demolition
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
    drop = modname..":"..name.."_spawnegg",
  })
  
  -- Definition of tail nodes
  for n = 1, data.walking_steps do
    -- Called on nodetimer
    -- Non empty tail -> update the tail
    local step = function(pos, _)
      local node = minetest.get_node(pos)
      node.name = modname..":"..name.."_tail_"..(n+1)
      minetest.set_node(pos, node)
      local timer = minetest.get_node_timer(pos)
      timer:set(WALKING_PERIOD, 0)
      return false
    end
    -- Empty tail -> Update the head
    if n == data.walking_steps then
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
        minetest.set_node(pos, {name = data.leftover})
        return false
      end
    end
    local drawtype
    if data.walking_steps > 1 then
      drawtype = "nodebox"
    end
    minetest.register_node(modname..":"..name.."_tail_"..n, {
      description = name.." tail",
      paramtype = "light",
      paramtype2 = "facedir",
      drawtype = drawtype,
      node_box = {
          type = "fixed",
          fixed = {
            { -0.5, -0.5, -0.5 + (1 / data.walking_steps) * (n - 1), 0.5, 0.5, 0.5},
          },
      },
      tiles = {
        data.top_texture.."^[transform1",
        data.bottem_texture.."^[transform3",
        data.side_texture,
        data.left_texture.."^[transform2",
        data.side_texture,
        data.tail_texture
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
  return true
end
