-- Marked mapgen nodes
local mapgen_node = {
  description = "worm mapgen node",
  paramtype = "light",
  paramtype2 = "facedir",
  drawtype = "airlike",
  groups = {not_in_creative_inventory = 1, worm_mapgen = 1},
}
minetest.register_node("worm:snake_head_1_mapgen", mapgen_node)
minetest.register_node("worm:snake_tail_1_mapgen", mapgen_node)
minetest.register_node("worm:worm_head_1_mapgen", mapgen_node)
minetest.register_node("worm:worm_tail_1_mapgen", mapgen_node)
minetest.register_node("worm:eel_head_1_mapgen", mapgen_node)
minetest.register_node("worm:eel_tail_1_mapgen", mapgen_node)

-- Replace mapgen nodes by real ones and initialize the node timer.
minetest.register_lbm({
  name = "worm:init_nodetimers_mapgen",
  nodenames = "group:worm_mapgen",
  run_at_every_load = true,
  action = function(pos, node)
    node.name = node.name:sub(1, -8)
    print("[worm]"..node.name.." spawned at "..pos.x..", "..pos.y..", "..pos.z)
    minetest.swap_node(pos, node)
    local timer = minetest.get_node_timer(pos)
    timer:set(worm.config.WALKING_PERIOD, 0)
  end,
})

-- Snake
minetest.register_decoration({
  deco_type = "schematic",
  place_on = "mapgen_dirt_with_grass",
  sidelen = 16,
  fill_ratio = 0.0001,
  schematic = {
    size = {x=4, y=1, z=1},
    data = {
      {name="worm:snake_head_1_mapgen", param1=255, param2=3, force_place = true},
      {name="worm:snake_body",   param1=255, param2=3, force_place = true},
      {name="worm:snake_body",   param1=255, param2=3, force_place = true},
      {name="worm:snake_tail_1_mapgen", param1=255, param2=3, force_place = true},
    },
  },
})

-- Worm
minetest.register_decoration({
  deco_type = "schematic",
  place_on = "mapgen_dirt_with_grass",
  sidelen = 16,
  fill_ratio = 0.0001,
  schematic = {
    size = {x=4, y=1, z=1},
    data = {
      {name="worm:worm_head_1_mapgen", param1=255, param2=3, force_place = true},
      {name="worm:worm_body",   param1=255, param2=3, force_place = true},
      {name="worm:worm_body",   param1=255, param2=3, force_place = true},
      {name="worm:worm_tail_1_mapgen", param1=255, param2=3, force_place = true},
    },
  },
})

-- Eel
minetest.register_decoration({
  deco_type = "schematic",
  place_on = "mapgen_water_source",
  flags = "liquid_surface, place_center_y",
  sidelen = 16,
  fill_ratio = 0.0002,
  schematic = {
    size = {x=4, y=3, z=1},
    data = {
      {name="worm:eel_head_1_mapgen", param1=255, param2=3, force_place = true},
      {name="worm:eel_body",   param1=255, param2=3, force_place = true},
      {name="worm:eel_body",   param1=255, param2=3, force_place = true},
      {name="worm:eel_tail_1_mapgen", param1=255, param2=3, force_place = true},
      {name="ignore", param1=0, param2=0},
      {name="ignore", param1=0, param2=0},
      {name="ignore", param1=0, param2=0},
      {name="ignore", param1=0, param2=0},
      {name="ignore", param1=0, param2=0},
      {name="ignore", param1=0, param2=0},
      {name="ignore", param1=0, param2=0},
      {name="ignore", param1=0, param2=0},
    },
  },
  rotation = "random",
})
