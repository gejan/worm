-- Worm
worm.register_worm("worm", "worm", {
  leftover = "mapgen_dirt", 
  face_texture = "worm_face.png", 
  side_texture = "worm_side.png", 
  tail_texture = "worm_tail.png",
  can_move = function(_, node)
    local name = node.name
    return minetest.registered_nodes[name].buildable_to or 
        minetest.get_node_group(name, "crumbly") >= 3
  end,
})

-- Snake
worm.register_worm("worm", "snake", {
  face_texture = "snake_face.png", 
  side_texture = "snake_side.png", 
  tail_texture = "snake_tail.png", 
  can_move = function(_, node)
    return minetest.registered_nodes[node.name].buildable_to
  end, 
})

-- Nyancat
worm.register_worm("worm", "nyancat", {
  face_texture = "nyancat_front.png", 
  side_texture = "nyancat_rainbow.png", 
  tail_texture = "nyancat_rainbow.png", 
  flying = true, 
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
