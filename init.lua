-- Minetest Worm Mod
-- by Gerald

worm = {}
worm.config = {}

worm.config.WALKING_PERIOD = 1      
-- Time of a step in seconds, values < 1 are not faster
worm.config.DEFAULT_WALKING_STEPS = 4       
-- Number of steps to pass one node, needs to be bigger than 0
worm.config.TAIL_PROTECTION = false 
-- If false check for protection on spawning only at head position

local path = minetest.get_modpath("worm")
dofile(path.."/api.lua")
dofile(path.."/examples.lua")
dofile(path.."/swallowable_nodes.lua")
dofile(path.."/mapgen.lua")
