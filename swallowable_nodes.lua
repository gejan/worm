if default then
  local groups = minetest.registered_nodes["default:apple"].groups
  groups.swallowable = 1
  minetest.override_item("default:apple", {
    groups = groups,
  })
end

if flowers then
  local groups = minetest.registered_nodes["flowers:mushroom_brown"].groups
  groups.swallowable = 1
  minetest.override_item("flowers:mushroom_brown", {
    groups = groups,
  })
end
