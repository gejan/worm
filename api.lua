local WALKING_PERIOD = worm.config.WALKING_PERIOD

-- Defines a "worm" (spawnitem and nodes)
-- @param modname   The name of the mod, which registers the nodes
-- @param name      The name of the creature; Has to be unique
-- @param data      A table containing:
--   - leftover       The node placed behind the tail when moving away 
--   - walking_steps  The number of steps to pass one node
--   - can_move       A function (Position * Node -> Boolean) defining which 
--                    nodes can be destroyed by the worm
--   - flying         Movement behaviour
--   - drop           drop of body parts; default: the spawn item
--   - node_damage    Damage done inside the head
--   - attack_damage  Damage groups for attacks; nil means no attack
--   - follow_objects Can be: false, "straight", "winding", true = "mixed" 
--   - *_texture      See examples, some values are indispensable
--     *_tile         
-- @return          True if successful
worm.register_worm = function (modname, name, data)
  -- Default values:
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
  -- Reusing textures
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
  if not data.attack_texture then
    data.attack_texture = data.face_texture
  end
  -- Complete tiles
  if not data.top_tile then
    data.top_tile = data.top_texture.."^[transform1"
  end
  if not data.bottem_tile then
    data.bottem_tile = data.bottem_texture.."^[transform3"
  end
  if not data.side_tile then
    data.side_tile = data.side_texture
  end
  if not data.left_tile then
    data.left_tile = data.left_texture.."^[transform2"
  end
  if not data.face_tile then
    data.face_tile = data.face_texture
  end
  if not data.tail_tile then
    data.tail_tile = data.tail_texture
  end  
  -- Spawn item related
  if not data.drop then
    data.drop = modname..":"..name.."_spawnegg"
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
      tailtimer:set(WALKING_PERIOD, 0)
      itemstack:take_item(i)
      return itemstack
    end,
  })
  
  -- Definition of head nodes
  for n = 1, data.walking_steps do
    -- Called on nodetimer
    -- Incomplete head -> Update the head
    local step = function(pos, node)
      node.name = modname..":"..name.."_head_"..(n+1)
      minetest.swap_node(pos, node)
    end
    -- Check for attack at first step
    if data.attack_damage and n == 1 then
      step = function(pos, node)    
        local dir = minetest.facedir_to_dir(node.param2)
        local bite_pos = vector.add(pos, dir)
        if data.can_move(bite_pos, minetest.get_node(bite_pos)) then
          local objects = minetest.get_objects_inside_radius(bite_pos, 1)
          if objects[1] then
            node.name = modname..":"..name.."_body"
            minetest.swap_node(pos, node)
            node.name = modname..":"..name.."_head_attack"
            minetest.set_node(bite_pos, node)
            objects[1]:punch(objects[1], nil,  -- This is a workaround, first argument should be nil
                {damage_groups = data.attack_damage,}, dir)
            return
          end
        end
        node.name = modname..":"..name.."_head_"..(n+1)
        minetest.swap_node(pos, node)
      end
    end
    -- Complete head -> Move head to a different position
    if n == data.walking_steps then
      step = function(pos, node)
        local facedir = node.param2
        local dirs         -- Hierarchy of preferred directions
        if data.follow_nodes then    -- follow food nodes
          local radius = data.follow_nodes_radius
          if not radius then radius = 5 end 
          local obj_pos = minetest.find_node_near(pos, radius, data.follow_nodes)
          if obj_pos then
            obj_pos = vector.subtract(obj_pos, pos)
            dirs = {}
            if not data.flying then
              dirs[1] = 4
            end
            if obj_pos.x > 0 then
              dirs[2] = 1           
              dirs[5] = 3           
            elseif obj_pos.x < 0 then
              dirs[2] = 3
              dirs[5] = 1
            else  
              dirs[5] = 1
              dirs[8] = 3
            end
            if obj_pos.z > 0 then
              dirs[3] = 0
              dirs[6] = 2
            elseif obj_pos.z < 0 then
              dirs[3] = 2
              dirs[6] = 0
            else  
              dirs[6] = 0
              dirs[9] = 2
            end
            if math.abs(obj_pos.z) > math.abs(obj_pos.x) then
              local tmp = dirs[2]
              dirs[2] = dirs[3]
              dirs[3] = tmp
            end
            if obj_pos.y > 0 then
              dirs[4] = 8
              dirs[7] = 4
            else
              dirs[4] = 4
              dirs[7] = 8
            end
          end
        end
        if data.follow_objects then -- follow objects
          local radius = data.follow_objects_radius
          if not radius then radius = 5 end 
          local objects = minetest.get_objects_inside_radius(pos, radius)
          if objects[1] then
            local obj_pos = objects[1]:getpos()
            obj_pos = vector.subtract(obj_pos, pos)
            dirs = {}
            if not data.flying then
              dirs[1] = 4
            end
            if obj_pos.x > 0 then    
              dirs[2] = 1           
              dirs[5] = 3           
            else
              dirs[2] = 3
              dirs[5] = 1
            end
            if obj_pos.z > 0 then
              dirs[3] = 0
              dirs[6] = 2
            else
              dirs[3] = 2
              dirs[6] = 0
            end
            if data.follow_objects == "straight" then
              if math.abs(obj_pos.z) > math.abs(obj_pos.x) then
                local tmp = dirs[2]
                dirs[2] = dirs[3]
                dirs[3] = tmp
              end
            elseif data.follow_objects == "winding" then
              if math.abs(obj_pos.z) < math.abs(obj_pos.x) then
                local tmp = dirs[2]
                dirs[2] = dirs[3]
                dirs[3] = tmp
              end
            end
            if obj_pos.y > 0 then
              dirs[4] = 8
              dirs[7] = 4
            else
              dirs[4] = 4
              dirs[7] = 8
            end
            if data.flying and (data.follow_objects == "straight") and (math.abs(obj_pos.z) < 1) and (math.abs(obj_pos.x) < 1) and (math.abs(obj_pos.y) > 1) then
              dirs[1] = dirs[4]
              dirs[4] = nil
            end
          end
        end
        -- default movement  
        if not dirs then
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
        end
        for i = 1, 9 do
          if dirs[i] then
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
              return
            elseif data.can_move(newpos, newnode) then
              minetest.set_node(newpos, {
                name = modname..":"..name.."_head_1", 
                param2 = dirs[i]
              })
              minetest.set_node(pos, {
                name = modname..":"..name.."_body",
                param2 = dirs[i]
              })
              return
            end
          end
        end
        -- Worm stuck
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
        data.top_tile,
        data.bottem_tile,
        data.side_tile,
        data.left_tile,
        data.face_tile,
        data.side_tile
      },
      groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
      damage_per_second = data.node_damage,
      wormstep = step,
      drop = "",
    }) 
  end
  
  -- Definition of the body node
  minetest.register_node(modname..":"..name.."_body", {
    description = name.." body part",
    paramtype = "light",
    paramtype2 = "facedir",
    tiles = {
      data.top_tile,
      data.bottem_tile,
      data.side_tile,
      data.left_tile,
      data.side_tile,
      data.side_tile
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
    drop = data.drop,
  })
  
  local call_head = function (pos, node)
    local dir
    repeat
      dir  = minetest.facedir_to_dir(node.param2)
      pos  = vector.add(pos, dir)
      node = minetest.get_node(pos)
    until node.name ~= modname..":"..name.."_body"
    if node.name:find(modname..":"..name.."_head") then
      minetest.registered_nodes[node.name].wormstep(pos, node)
    end
  end
  
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
      call_head(pos, node)
      return false
    end
    -- Empty tail -> Update the head
    if n == data.walking_steps then
    step =  function(pos, _)
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
        call_head(newpos, newnode)
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
        data.top_tile,
        data.bottem_tile,
        data.side_tile,
        data.left_tile,
        data.side_tile,
        data.tail_tile
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
  
  --Definition of the special attack head node
  if data.attack_damage then
    minetest.register_node(modname..":"..name.."_head_attack", {
      description = name.." attacking head",
      paramtype = "light",
      paramtype2 = "facedir",
      tiles = {
        data.top_tile,
        data.bottem_tile,
        data.side_tile,
        data.left_tile,
        data.attack_texture,
        data.side_tile
      },
      groups = {snappy = 1, level = 2, not_in_creative_inventory = 1},
      wormstep = function(pos, node)
        local pos_b = vector.subtract(pos, minetest.facedir_to_dir(node.param2)) 
        local node_b = minetest.get_node(pos_b)
        node.name = "air"
        minetest.swap_node(pos, node)
        if node_b.name == modname..":"..name.."_body" then 
          node_b.name = modname..":"..name.."_head_"..(math.min(3, data.walking_steps))
          minetest.swap_node(pos_b, node_b)
          local timer = minetest.get_node_timer(pos_b)
          timer:set(WALKING_PERIOD, 0)
        end
      end,
      drop = "",
    })
  end
  return true
end
