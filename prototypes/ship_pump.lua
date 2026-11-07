----------------------------------------------------------------
--------------------------- PUMP -------------------------------
----------------------------------------------------------------
local collision_mask_util = require("collision-mask-util")


local function shift_animation(offset, animation)
  if animation.layers then
    for _,layer in pairs(animation.layers) do
      layer.shift = layer.shift and (util.add_shift(layer.shift, offset)) or offset
    end
  else
    animation.shift = animation.shift and (util.add_shift(animation.shift, offset)) or offset
  end
  return animation
end


local function shift_animation4way(offset_rotated, animation4way, reverse_offset)
  for direction,animation in pairs(animation4way) do
    shift_animation(reverse_offset and {-offset_rotated[direction][1], -offset_rotated[direction][2]} or offset_rotated[direction], animation)
  end
end


local pump = data.raw["pump"]["pump"]
local loading_pump = table.deepcopy(data.raw["pump"]["pump"])
loading_pump.name = "ship-loading-pump"
loading_pump.minable = {mining_time = 0.2, result = "ship-loading-pump"}

-- Change collision mask so that it can be placed on water
loading_pump.collision_mask = collision_mask_util.get_default_mask("pump")
loading_pump.collision_mask.layers.water_tile = nil  -- Player collision with pump is handled in data-final-fixes.lua
loading_pump.collision_mask.layers.player = nil
loading_pump.collision_mask.layers.item = nil
-- In vanilla: shallow waters have object-layer, regular/deep waters have player-layer
-- Many mods that use shallow water remove object-layer from it anyway (e.g. Alien Biomes, Freight Forwarding)
-- Apparently some mods remove the mask entirely, which is fine with us, but don't try to index it!
if data.raw.tile["water-shallow"].collision_mask and data.raw.tile["water-shallow"].collision_mask.layers then
  data.raw.tile["water-shallow"].collision_mask.layers["object"] = nil
end
if data.raw.tile["water-mud"].collision_mask and data.raw.tile["water-mud"].collision_mask.layers then
  data.raw.tile["water-mud"].collision_mask.layers["object"] = nil
end

-- Add reflection sprite (TODO: Fix for 2.1?)
loading_pump.water_reflection = {
  pictures = {
    filename = GRAPHICSPATH .. "entity/pump/pump-water-reflection.png",
    line_length = 1,
    width = 19,
    height = 19,
    shift = util.by_pixel(0, 10),
    variation_count = 4,
    scale = 5
  },
  rotate = false,
  orientation_to_variation = true
}

-- Ship Pump is a 1x4 entity, output on the top and input on the bottom.
-- Fluidboxes at edges of the 1x3 entity
loading_pump.fluid_box =
{
  volume = 1000,
  pipe_covers = nil,  -- Can't make the covers disappear for just the output side, apparently, so delete both of them
  pipe_connections =
  {
    { direction = defines.direction.north, position = {0, -1.5}, flow_direction = "output", connection_category = "ship_pump" },
    { direction = defines.direction.south, position = {0, 1.5}, flow_direction = "input" }
  }
}

-- The selection box and base graphics need to shift to the right 0.5 tile
loading_pump.collision_box = {{-0.29, -1.9}, {0.29, 1.9}}
loading_pump.selection_box = {{-0.5, 0}, {0.5, 2}}
loading_pump.fluid_wagon_tank_valve_max_distance = 3.5
loading_pump.fast_replaceable_group = "ship_pump"

--log(serpent.block({wagon_connection_graphics=pump.wagon_connection_graphics}))

-- Shift all the animation graphics by Y+1
local offset = {0, 1}
local offset_rotated = {
    north = {offset[1], offset[2]},
    east = {-offset[2], offset[1]},
    south = {-offset[1], -offset[2]},
    west = {offset[2], -offset[1]}
  }
shift_animation4way(offset_rotated, loading_pump.animations)
shift_animation4way(offset_rotated, loading_pump.fluid_animation)
shift_animation4way(offset_rotated, loading_pump.glass_pictures)
shift_animation4way(offset_rotated, loading_pump.wagon_connection_graphics.base.output)  -- Output base shifts normally.  Arm part 1 shifts with it.
shift_animation4way(offset_rotated, loading_pump.wagon_connection_graphics.base.input, true)  -- Input base shifts in the opposite direction for some reason.  Arm part 1 shifts with it

-- top_pivot_shift changes the pivot location relative to center of the entity, NOT relative to the base shift.  This fixes it for the far (output) side but makes the near (input) side worse.
for direction,_ in pairs(loading_pump.wagon_connection_graphics.top_pivot_shift) do
  loading_pump.wagon_connection_graphics.top_pivot_shift[direction] = util.add_shift(loading_pump.wagon_connection_graphics.top_pivot_shift[direction], offset_rotated[direction])
end


-- The extending arm part 1 and 2 only have a 2D shift, for the sprite on the screen.  It won't help with a rotating offset.
--shift_animation(offset, pump.wagon_connection_graphics.part_1)
--shift_animation(offset, pump.wagon_connection_graphics.part_1_shadow)
--shift_animation(offset, pump.wagon_connection_graphics.part_2)
--shift_animation(offset, pump.wagon_connection_graphics.part_2_shadow)
-- Part 1 and Part 2 are the near and far halves of the horizontal extension arm.  Their relative alignment doesn't change.
--pump.wagon_connection_graphics.part1_to_2_shift = {0,0}

--log(serpent.block({wagon_connection_graphics=loading_pump.wagon_connection_graphics}))



local unloading_pump = table.deepcopy(loading_pump)
unloading_pump.name = "ship-unloading-pump"
unloading_pump.minable = {mining_time = 0.2, result = "ship-unloading-pump"}

unloading_pump.fluid_box.pipe_connections =
  {
    { direction = defines.direction.north, position = {0, -1.5}, flow_direction = "output" },
    { direction = defines.direction.south, position = {0, 1.5}, flow_direction = "input", connection_category = "ship_pump" }
  }

unloading_pump.selection_box = {{-0.5, -2}, {0.5, 0}}

local offset = {0, -2}  -- relative to loading_pump
local offset_rotated = {
    north = {offset[1], offset[2]},
    east = {-offset[2], offset[1]},
    south = {-offset[1], -offset[2]},
    west = {offset[2], -offset[1]}
  }
shift_animation4way(offset_rotated, unloading_pump.animations)
shift_animation4way(offset_rotated, unloading_pump.fluid_animation)
shift_animation4way(offset_rotated, unloading_pump.glass_pictures)
shift_animation4way(offset_rotated, unloading_pump.wagon_connection_graphics.base.output)  -- Output base shifts normally.  Arm part 1 shifts with it.
shift_animation4way(offset_rotated, unloading_pump.wagon_connection_graphics.base.input, true)  -- Input base shifts in the opposite direction for some reason.  Arm part 1 shifts with it

-- top_pivot_shift changes the pivot location relative to center of the entity, NOT relative to the base shift.  This fixes it for the far (output) side but makes the near (input) side worse.
--for direction,_ in pairs(unloading_pump.wagon_connection_graphics.top_pivot_shift) do
--  unloading_pump.wagon_connection_graphics.top_pivot_shift[direction] = util.add_shift(unloading_pump.wagon_connection_graphics.top_pivot_shift[direction], offset_rotated[direction])
--end



-------------
-- New Icons for pumps
local function get_icons(prototype)
  local icons = prototype.icons or {{icon=prototype.icon, icon_size=prototype.icon_size}}
  for _,icon in pairs(icons) do
    icon.icon_size = icon.icon_size or 64
  end
  return icons
end

local loading_icon =   util.combine_icons(get_icons(pump), 
        get_icons(data.raw["virtual-signal"]["up-arrow"]), 
        {tint={0.4,1,0.4}, scale=0.6, shift={7,-7}})
local unloading_icon = util.combine_icons(get_icons(pump), 
        get_icons(data.raw["virtual-signal"]["down-arrow"]), 
        {tint={1,0.4,0.4}, scale=0.6, shift={7,-7}})


loading_pump.icon = nil
loading_pump.icons = loading_icon
unloading_pump.icon = nil
unloading_pump.icons = unloading_icon


local loading_pump_item = table.deepcopy(data.raw["item"]["pump"])
loading_pump_item.name = "ship-loading-pump"
loading_pump_item.place_result = "ship-loading-pump"
loading_pump_item.icon = nil
loading_pump_item.icons = loading_icon

local loading_pump_recipe = table.deepcopy(data.raw["recipe"]["pump"])
loading_pump_recipe.name = "ship-loading-pump"
loading_pump_recipe.results[1].name = "ship-loading-pump"
loading_pump_recipe.ingredients = data.raw.recipe.pump.ingredients -- Linked table so changes by AAI etc. are reflected in both

local unloading_pump_item = table.deepcopy(data.raw["item"]["pump"])
unloading_pump_item.name = "ship-unloading-pump"
unloading_pump_item.place_result = "ship-unloading-pump"
unloading_pump_item.icon = nil
unloading_pump_item.icons = unloading_icon

local unloading_pump_recipe = table.deepcopy(data.raw["recipe"]["pump"])
unloading_pump_recipe.name = "ship-unloading-pump"
unloading_pump_recipe.results[1].name = "ship-unloading-pump"
unloading_pump_recipe.ingredients = data.raw.recipe.pump.ingredients -- Linked table so changes by AAI etc. are reflected in both


local function add_pipecover_layer(prototype, shifts)
  local frame_one_32 = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}

  for _, direction_data in pairs(shifts) do
    local pump_direction = direction_data[1]
    local pipe_direction = direction_data[2]
    local shift = direction_data[3]

    local animation = prototype.animations[pump_direction]
    if not animation.layers then
      animation[pump_direction] = {
        layers = {animation[pump_direction]}
      }
    end
    table.insert(animation.layers, {
      layers = {
        {
          filename = "__base__/graphics/entity/pipe-covers/pipe-cover-"..pipe_direction..".png",
          height = 128,
          priority = "extra-high",
          scale = 0.5,
          width = 128,
          frame_sequence = frame_one_32,
          shift = shift
        }
      }
    })
    table.insert(animation.layers, {
      draw_as_shadow = true,
      filename = "__base__/graphics/entity/pipe-covers/pipe-cover-"..pipe_direction.."-shadow.png",
      height = 128,
      priority = "extra-high",
      scale = 0.5,
      width = 128,
      frame_sequence = frame_one_32,
      shift = shift
    })
  end
end

add_pipecover_layer(loading_pump, {
  {"north", "north", {0, -0.5}},
  {"east", "east", {0.5, 0}},
  {"south", "south", {1/64, 0.5}},
  {"west", "west", {-0.5, 0}},
  -- Output side
  {"north", "south", {0, 2.5}},
})
add_pipecover_layer(unloading_pump, {
  {"north", "south", {0, 0.5}},
  {"east", "west", {-0.5, 0}},
  -- {"south", "north", {1/64, -0.5 - 4/64}}, -- Already has a fitting pipe cover
  {"west", "east", {0.5, 0}},
  -- Output side
  {"south", "south", {0, 2.5 - 1/64 }},
})


data:extend({loading_pump_recipe, loading_pump_item, loading_pump,
             unloading_pump_recipe, unloading_pump_item, unloading_pump})
