-- Stone eater

-- Definition
-------------

local drop = ""
if default then
  drop = {  
    max_items = 2,
    items = {
      {
        items = {"default:coal_lump"},
        rarity = 1,
      },
      {
        items = {"default:gold_lump"},
        rarity = 2,
      },
      {
        items = {"default:iron_lump"},
        rarity = 2,
      },
      {
        items = {"default:copper_lump"},
        rarity = 2,
      },
    },
  }
end
local anm = {
  type = "vertical_frames",
  aspect_w = 16,
  aspect_h = 16,
  length = 3.0,
}
worm.register_worm("worm", "stone_eater", {
  leftover = "mapgen_stone", 
  inventory_image = "stone_eater_face.png",
  face_tile   = {name = "stone_eater_face_animated.png", animation = anm},
  side_tile   = {name = "stone_eater_side_animated.png", animation = anm},
  left_tile   = {name = "stone_eater_side_animated.png^[transform62", animation = anm},
  top_tile    = {name = "stone_eater_top_animated.png", animation = anm},
  bottem_tile = {name = "stone_eater_bottem_animated.png", animation = anm},
  tail_tile   = "stone_eater_tail.png",
  node_damage = 4,
  attack_damage  = {fleshy = 8},
  follow_nodes = {"group:swallowable"},
  follow_objects = "straight",
  follow_objects_radius = 8,
  flying = true,
  can_move = function(_, node)
    local name = node.name
    return minetest.registered_nodes[name].buildable_to or 
        minetest.get_node_group(name, "cracky") >= 3
  end,
  drop = drop,
})


-- Mapgen
---------

minetest.register_node("worm:stone_eater_head_1_mapgen", {
  description = "worm mapgen node",
  paramtype = "light",
  paramtype2 = "facedir",
  drawtype = "airlike",
  groups = {not_in_creative_inventory = 1},
})

-- Place nodes and initialize the node timer.
minetest.register_lbm({
  name = "worm:init_nodetimers_mapgen_underground",
  nodenames = "worm:stone_eater_head_1_mapgen",
  run_at_every_load = true,
  action = function(pos, node)
    node.name = "worm:stone_eater_head_1"
    node.param2 = 0 -- TODO make random
    local dir = minetest.facedir_to_dir(node.param2)
    --local dir4 = vector.multiply(dir, 4)
    --minetest.emerge_area(pos, vector.add(pos, dir4))
    print("[worm]"..node.name.." spawned at "..pos.x..", "..pos.y..", "..pos.z)
    minetest.swap_node(pos, node)
    local headtimer = minetest.get_node_timer(pos)
    node.name = "worm:stone_eater_body"
    pos = vector.subtract(pos, dir)
    minetest.set_node(pos, node)
    pos = vector.subtract(pos, dir)
    minetest.set_node(pos, node)
    pos = vector.subtract(pos, dir)
    minetest.set_node(pos, node)
    node.name = "worm:stone_eater_tail_1"
    pos = vector.subtract(pos, dir)
    minetest.set_node(pos, node)
    local tailtimer = minetest.get_node_timer(pos)
    headtimer:set(worm.config.WALKING_PERIOD, 0)
    tailtimer:set(worm.config.WALKING_PERIOD, 0)
    print("tail at "..pos.x..", "..pos.y..", "..pos.z)
  end,
})
minetest.register_ore({
  oretype = "",
  ore            = "worm:stone_eater_head_1_mapgen",
  wherein        = "default:stone",
  clust_scarcity = 16*16*16,
  clust_num_ores = 1,
  clust_size     = 3,
  height_min     = -31000,
  height_max     = -100,
})