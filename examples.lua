-- Not animated
---------------

-- Green Snake
worm.register_worm("worm", "snake", {
  face_texture   = "snake_face.png", 
  side_texture   = "snake_side.png", 
  tail_texture   = "snake_tail.png", 
  attack_texture = "snake_attack.png",
  attack_damage  = {fleshy = 8},
  follow_objects = "winding",
  follow_nodes   = "group:swallowable",
  can_move = function(_, node)
    return minetest.registered_nodes[node.name].buildable_to
  end, 
})

-- Black Snake
worm.register_worm("worm", "black_snake", {
  face_texture   = "snake_face_black.png", 
  side_texture   = "snake_side_yellow_black.png", 
  tail_texture   = "snake_tail_black.png", 
  attack_texture = "snake_face_black.png",
  attack_damage  = {fleshy = 8},
  follow_objects = "straight",
  can_move = function(_, node)
    return minetest.registered_nodes[node.name].buildable_to
  end, 
})

-- Eel
local spawn_in = "air"
if default then
  spawn_in = "default:water_source"
end
worm.register_worm("worm", "eel", {
  leftover = "mapgen_water_source", 
  spawn_in = spawn_in,
  walking_steps  = 1,
  face_texture   = "eel_face.png", 
  side_texture   = "eel_side.png", 
  left_texture   = "eel_side.png^[transform6",
  tail_texture   = "eel_tail.png", 
  top_texture    = "eel_top.png",
  bottem_texture = "eel_bottem.png",
  can_move = function(_, node)
    return minetest.get_node_group(node.name, "water") > 0
  end,
  flying = true, 
})

-- Animated
-----------
local anm = {
  type = "vertical_frames",
  aspect_w = 16,
  aspect_h = 16,
  length = 3.0,
}

-- Nyancat
worm.register_worm("worm", "nyancat", {
  inventory_image = "nyancat_front.png", 
  side_tile   = {name = "nyancat_rainbow_animated.png", animation = anm},
  left_tile   = {name = "nyancat_rainbow_animated.png", animation = anm},
  top_tile    = {name = "nyancat_rainbow_animated_b.png", animation = anm},
  bottem_tile = {name = "nyancat_rainbow_animated_b.png", animation = anm},
  face_tile   = {name = "nyancat_front_animated.png", animation = anm},
  tail_tile   = {name = "nyancat_rainbow_animated.png", animation = anm},
  flying = true, 
})

-- Worm
worm.register_worm("worm", "worm", {
  leftover = "mapgen_dirt", 
  inventory_image = "worm_face.png",
  side_tile   = {name = "worm_side_animated.png", animation = anm},
  left_tile   = {name = "worm_side_animated.png^[transform62", animation = anm},
  top_tile    = {name = "worm_top_animated.png", animation = anm},
  bottem_tile = {name = "worm_bottem_animated.png", animation = anm},
  face_tile   = {name = "worm_face_animated.png", animation = anm},
  tail_tile   = "worm_tail.png",
  attack_damage  = {fleshy = 8},
  can_move = function(_, node)
    local name = node.name
    return minetest.registered_nodes[name].buildable_to or 
        minetest.get_node_group(name, "crumbly") >= 3
  end,
})

-- Worm
worm.register_worm("worm", "caterpillar", {
  face_texture = "caterpillar_face.png",
  side_tile   = {name = "caterpillar_side_animated.png", animation = anm},
  left_tile   = {name = "caterpillar_side_animated.png^[transform62", animation = anm},
  top_tile    = {name = "caterpillar_top_animated.png", animation = anm},
  bottem_tile = {name = "caterpillar_bottem_animated.png", animation = anm},
  tail_tile   = "caterpillar_tail.png",
  follow_nodes = {"group:swallowable", "group:leaves"},
  can_move = function(_, node)
    local name = node.name
    return minetest.registered_nodes[name].buildable_to or 
        minetest.get_node_group(name, "snappy") >= 3
  end,
})

-- Worm
worm.register_worm("worm", "maggot", {
  face_texture = "maggot_face.png",
  side_tile   = {name = "maggot_side_animated.png", animation = anm},
  left_tile   = {name = "maggot_side_animated.png^[transform62", animation = anm},
  top_tile    = {name = "maggot_top_animated.png", animation = anm},
  bottem_tile = {name = "maggot_bottem_animated.png", animation = anm},
  tail_tile   = "maggot_tail.png",
  walking_steps = 8,
  follow_nodes = {"group:swallowable", "group:wood"},
  node_damage = 4,
  can_move = function(_, node)
    local name = node.name
    return minetest.registered_nodes[name].buildable_to or 
        minetest.get_node_group(name, "choppy") >= 2
  end,
})