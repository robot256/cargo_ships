local math2d = require("math2d")
local GRAPHICSPATH = "__cargo-ships-oil-rig__/graphics/"

local external_power = settings.startup["oil_rigs_require_external_power"].value

-- Make collision layers so the oil-rig sub-entities can't be placed on top of each other.
data:extend{{type="collision-layer", name="or_pole"}, {type="collision-layer", name="or_tank"}}

----------------------------------------------------------------
--------------------------- OIL RIG ----------------------------
----------------------------------------------------------------
local oil_rig_capacity = settings.startup["oil_rig_capacity"].value

circuit_connector_definitions["oil_rig"] = circuit_connector_definitions.create_vector
(
  universal_connector_template,
  {
    { variation = 26, main_offset = util.by_pixel(25.5, -57), shadow_offset = util.by_pixel(25.5, -57), show_shadow = true },
    { variation = 26, main_offset = util.by_pixel(25.5, -57), shadow_offset = util.by_pixel(25.5, -57), show_shadow = true },
    { variation = 26, main_offset = util.by_pixel(25.5, -57), shadow_offset = util.by_pixel(25.5, -57), show_shadow = true },
    { variation = 26, main_offset = util.by_pixel(25.5, -57), shadow_offset = util.by_pixel(25.5, -57), show_shadow = true },
  }
)

local oil_rig_graphics_set = 
{
  animation =
  {
    north =
    {
      layers =
      {
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-pipe-n.png",
          width = 704,
          height = 896,
          scale = 0.5,
          frames = 1,
          repeat_count = 20,
          animation_speed = 0.25,
        },
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-pipe-e.png",
          width = 704,
          height = 896,
          scale = 0.5,
          frames = 1,
          repeat_count = 20,
        },
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-pipe-s.png",
          width = 704,
          height = 896,
          scale = 0.5,
          frames = 1,
          repeat_count = 20,
        },
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-pipe-w.png",
          width = 704,
          height = 896,
          scale = 0.5,
          frames = 1,
          repeat_count = 20,
        },
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-base.png",
          width = 704,
          height = 896,
          scale = 0.5,
          frames = 1,
          repeat_count = 20,
        },
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-base-shadow.png",
          width = 704,
          height = 896,
          scale = 0.5,
          draw_as_shadow = true,
          frames = 1,
          repeat_count = 20,
        },
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-base-light.png",
          width = 704,
          height = 896,
          scale = 0.5,
          draw_as_light = true,
          frames = 1,
          repeat_count = 20,
        },
        {
          filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-anim.png",
          width = 358,
          height = 486,
          scale = 0.5,
          line_length = 5,
          frame_count = 20,
          
        }
      }
    }
  }
}

local oil_rig = {
  type = "mining-drill",
  name = "oil_rig",
  icons = {{icon=GRAPHICSPATH .. "icons/oil_rig.png", icon_size= 64}},
  flags = {"placeable-neutral", "player-creation"},
  minable = {mining_time = 1.5, result = "oil_rig"},
  resource_categories = {"offshore-fluid"},
  max_health = 1000,
  dying_explosion = "big-explosion",
  collision_mask = {layers = {object = true, train = true}},
  collision_box = {{-3.2, -3.2}, {3.2, 3.2}},
  selection_box = {{-3.5, -3.5}, {3.5, 3.5}},
  damaged_trigger_effect = data.raw["mining-drill"]["pumpjack"].damaged_trigger_effect,
  drawing_box_vertical_extension = 1,
  energy_source =
  {
    type = "electric",
    emissions_per_minute = { pollution = 25 },
    usage_priority = "secondary-input"
  },
  output_fluid_box =
  {
    volume = 50 * oil_rig_capacity,
    hide_connection_info = true,
    pipe_connections =
    {
      {
        connection_type = "linked",
        linked_connection_id = 1,
        flow_direction = "output",
      }
    }
  },
  energy_usage = "750kW",
  mining_speed = 1,
  resource_searching_radius = 2.4, -- enlarged from 1.4 to allow off-center patch collection
  vector_to_place_result = {0, 0},  -- Disables the output arrow for fluid miners
  module_slots = 3,
  radius_visualisation_picture =
  {
    filename = "__base__/graphics/entity/pumpjack/pumpjack-radius-visualization.png",
    width = 12,
    height = 12
  },
  monitor_visualization_tint = {78, 173, 255},
  graphics_set = oil_rig_graphics_set,
  water_reflection = {
    pictures = {
      filename = GRAPHICSPATH .. "entity/oil_rig/oil-rig-water-reflection.png",
      width = 70,
      height = 89,
      shift = util.by_pixel(0, 0),
      variation_count = 1,
      scale = 5
    },
    rotate = false,
    orientation_to_variation = false
  },
  open_sound = {filename = "__base__/sound/open-close/pumpjack-open.ogg", volume = 0.5},
  close_sound = {filename = "__base__/sound/open-close/pumpjack-close.ogg", volume = 0.5},
  working_sound =
  {
    sound = {filename = "__base__/sound/pumpjack.ogg", volume = 0.85},
    max_sounds_per_type = 3,
    audible_distance_modifier = 0.6,
    fade_in_ticks = 4,
    fade_out_ticks = 10
  },

  circuit_connector = circuit_connector_definitions["oil_rig"],
  circuit_wire_max_distance = default_circuit_wire_max_distance,
  rotated_sound = data.raw["utility-sounds"]["default"]["cannot_build"],
}



if external_power == "disabled" then
  oil_rig.energy_source.type = "void"
end


----------------------------------------------------------------
----------- OIL PLATFORM COMPONENT ENTITES--------------------------
----------------------------------------------------------------
local smoke1shift = util.by_pixel(-85 + 2, -115 + 2)
local smoke2shift = util.by_pixel(53 + 2, -167 + 2)

local function get_icons(prototype)
  local icons = prototype.icons or {{icon=prototype.icon, icon_size=prototype.icon_size}}
  for _,icon in pairs(icons) do
    icon.icon_size = icon.icon_size or 64
  end
  return icons
end
local icon_inputs = {tint={0.4,0.4,1}, scale=0.6, shift={7,-7}}

---- Oil Rig Generator
local or_power_electric = {
  type = "generator",
  name = "or_power_electric",
  icons = util.combine_icons(oil_rig.icons, 
        get_icons(data.raw["generator"]["steam-engine"]), 
        icon_inputs),
  flags = {"not-deconstructable", "not-blueprintable", "not-rotatable", "placeable-off-grid"},
  hidden = true,
  max_health = oil_rig.max_health,
  effectivity = 5,
  fluid_usage_per_tick = 0.1,
  destroy_non_fuel_fluid = false,
  scale_fluid_usage = true,
  maximum_temperature = 25,
  burns_fluid = true,
  icon_draw_specification = {scale=0},
  selectable_in_game = false,
  collision_mask = {layers={}},
  selection_box = oil_rig.selection_box,
  fluid_box =
  {
    volume = 500,
    pipe_connections =
    {
      {
        flow_direction = "input",
        connection_type = "linked",
        linked_connection_id = 1
      },
    },
    production_type = "input",
    filter = "crude-oil",
    hide_connection_info = true
  },
  energy_source =
  {
    type = "electric",
    usage_priority = "secondary-output",
    render_no_power_icon = false
  },
  smoke =
  {
    {
      name = "light-smoke",
      north_position = smoke1shift,
      east_position = smoke1shift,
      south_position = smoke1shift,
      west_position = smoke1shift,
      frequency = 0.25,
      starting_vertical_speed = 0.05,
      starting_frame_deviation = 60
    },
    {
      name = "smoke",
      north_position = smoke2shift,
      east_position = smoke2shift,
      south_position = smoke2shift,
      west_position = smoke2shift,
      frequency = 0.5,
      starting_vertical_speed = 0.05,
      starting_frame_deviation = 60
    },
  },
  working_sound =
  {
    sound =
    {
      filename = "__base__/sound/steam-engine-90bpm.ogg",
      volume = 0.2,
      speed_smoothing_window_size = 60,
      advanced_volume_control = {attenuation = "exponential"},
    },
    match_speed_to_activity = true,
    audible_distance_modifier = 0.5,
    max_sounds_per_type = 3,
    fade_in_ticks = 4,
    fade_out_ticks = 20
  }
}
-- Set the generator power output based on the setting
if external_power == "disabled" then
  or_power_electric.max_power_output = "300kW"  -- Just enough for surrounding pumps and heating
  or_power_electric.energy_source.output_flow_limit = "300kW"
elseif external_power == "enabled" then
  or_power_electric.max_power_output = "0kW"
  or_power_electric.energy_source.output_flow_limit = "0kW"
  or_power_electric.fluid_usage_per_tick = 0
  or_power_electric.fluid_box.volume = 100
  or_power_electric.working_sound = nil  -- Disable steam engine sound when no generator on rig
elseif external_power == "only-when-moduled" then
  or_power_electric.max_power_output = "1050kW"  -- 750kW for the rig, 100kW for surrounding pumps, 200kW for heating
  or_power_electric.energy_source.output_flow_limit = "1050kW"
end


----------------------------------------
---- Oil Rig Power Pole
local psx = -22
local psy = 96
or_pole = {
  type = "electric-pole",
  name = "or_pole",
  icons = util.combine_icons(oil_rig.icons, get_icons(data.raw["electric-pole"]["medium-electric-pole"]),
                                  icon_inputs),
  flags = {"not-deconstructable", "placeable-neutral", "player-creation", "placeable-off-grid"},
  hidden = true,
  max_health = oil_rig.max_health,
  collision_mask = {layers={or_pole=true}},
  collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
  selection_box = {{-0.9, 1.1}, {0.1, 2.1}},
  drawing_box_vertical_extension = 3,
  selection_priority = 56,
  maximum_wire_distance = 20,
  supply_area_distance = 4.5,
  open_sound = data.raw["electric-pole"]["medium-electric-pole"].open_sound,
  close_sound = data.raw["electric-pole"]["medium-electric-pole"].close_sound,
  pictures =
  {
    layers =
    {
      {
        filename = "__base__/graphics/entity/medium-electric-pole/medium-electric-pole.png",
        priority = "extra-high",
        width = 84,
        height = 252,
        direction_count = 1,
        shift = util.by_pixel(3.5+psx/2, -44+psy/2),
        scale = 0.5
      },
      {
        filename = "__base__/graphics/entity/medium-electric-pole/medium-electric-pole-shadow.png",
        priority = "extra-high",
        width = 280,
        height = 64,
        direction_count = 1,
        shift = util.by_pixel(56.5+psx/2, -1+psy/2),
        draw_as_shadow = true,
        scale = 0.5
      }
    }
  },
  connection_points =
  {
    {
      shadow =
      {
        copper = util.by_pixel_hr(229+psx, -13+psy),
        red = util.by_pixel_hr(246+psx, -2+psy),
        green = util.by_pixel_hr(201+psx, -2+psy)
      },
      wire =
      {
        copper = util.by_pixel_hr(15+psx, -199+psy),
        red = util.by_pixel_hr(43+psx, -179+psy),
        green = util.by_pixel_hr(-15+psx, -185+psy)
      }
    },
  },
  radius_visualisation_picture =
  {
    filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
    width = 12,
    height = 12,
    priority = "extra-high-no-scale"
  },
  water_reflection =
  {
    pictures =
    {
      filename = "__base__/graphics/entity/medium-electric-pole/medium-electric-pole-reflection.png",
      priority = "extra-high",
      width = 12,
      height = 28,
      shift = util.by_pixel(0+psx/2, 55+psy/2),
      variation_count = 1,
      scale = 5
    },
    rotate = false,
    orientation_to_variation = false
  }
}
if external_power == "disabled" then
  or_pole.maximum_wire_distance = 0
end


----------------------------------------
---- Oil Rig Radar
local or_radar = {
  type = "radar",
  name = "or_radar",
  icons = util.combine_icons(oil_rig.icons, get_icons(data.raw["radar"]["radar"]),
                                    icon_inputs),
  flags = {"not-blueprintable", "not-deconstructable", "placeable-off-grid"},
  hidden = true,
  fast_replaceable_group = "radar",
  max_health = oil_rig.max_health,
  selectable_in_game = false,
  allow_copy_paste = false,
  collision_mask = {layers = {}},
  selection_box = oil_rig.selection_box,
  energy_per_sector = "10MJ",
  max_distance_of_sector_revealed = 0,
  max_distance_of_nearby_sector_revealed = 3,
  energy_per_nearby_scan = "250kJ",
  energy_source =
  {
    type = "electric",
    usage_priority = "secondary-input"
  },
  energy_usage = "30kW",
  radius_minimap_visualisation_color = {0.059, 0.092, 0.235, 0.275},
  is_military_target = false
}


----------------------------------------
-- Oil Rig Storage Tank
local or_tank_box = {left_top={0.3, -0.1}, right_bottom={3.3, 2.9}}
local or_tank_center = math2d.bounding_box.get_centre(or_tank_box)
local or_tank_shift = {or_tank_center.x, or_tank_center.y-0.3}
local or_tank_connector_point = util.add_shift(util.by_pixel(33.5, 18.5), or_tank_shift)
local or_tank_window = {util.add_shift({-0.125, 0.6875+0.2},or_tank_shift), util.add_shift({0.1875, 1.1875+0.2},or_tank_shift)}

circuit_connector_definitions["or_tank"] = circuit_connector_definitions.create_vector
(
  universal_connector_template,
  {
    { variation = 27, main_offset = or_tank_connector_point, shadow_offset = or_tank_connector_point, show_shadow = false },
    { variation = 27, main_offset = or_tank_connector_point, shadow_offset = or_tank_connector_point, show_shadow = false },
    { variation = 27, main_offset = or_tank_connector_point, shadow_offset = or_tank_connector_point, show_shadow = false },
    { variation = 27, main_offset = or_tank_connector_point, shadow_offset = or_tank_connector_point, show_shadow = false },
  }
)

local or_tank =
{
  type = "storage-tank",
  name = "or_tank",
  icons = util.combine_icons( oil_rig.icons, get_icons(data.raw["storage-tank"]["storage-tank"]),
                              icon_inputs),
  max_health = oil_rig.max_health,
  flags = {"not-deconstructable", "placeable-neutral", "player-creation"},
  hidden = true,
  selectable_in_game = true,
  allow_copy_paste = true,
  collision_box = oil_rig.collision_box,
  collision_mask = {layers = {or_tank=true}},
  selection_box = or_tank_box,
  selection_priority = 56,
  drawing_box_vertical_extension = 0.5,
  icon_draw_specification = {scale = 1.2, shift = or_tank_shift},
  fluid_box =
  {
    volume = 1000 * oil_rig_capacity,
    pipe_covers = pipecoverspictures(),
    always_draw_covers = true,
    hide_connection_info = true,
    pipe_connections =
    {
      { direction = defines.direction.north, position = {0, -3}},
      { direction = defines.direction.east,  position = {3,  0}},
      { direction = defines.direction.south, position = {0,  3}},
      { direction = defines.direction.west,  position = {-3, 0}},
      { connection_type = "linked", linked_connection_id = 1 },
      { connection_type = "linked", linked_connection_id = 2 },
    },
  },
  window_bounding_box = or_tank_window,
  pictures =
  {
    picture = {
      sheet =
      {
        filename = GRAPHICSPATH .. "entity/oil_rig/hr-oil-rig-tank.png",
        width = 704,
        height = 896,
        scale = 0.5,
        frames = 1,
      }
    },
    fluid_background =
    {
      filename = "__base__/graphics/entity/storage-tank/fluid-background.png",
      priority = "extra-high",
      width = 32,
      height = 15,
    },
    window_background =
    {
      filename = "__base__/graphics/entity/storage-tank/window-background.png",
      priority = "extra-high",
      width = 34,
      height = 48,
      scale = 0.5,
    },
    flow_sprite =
    {
      filename = "__base__/graphics/entity/pipe/fluid-flow-low-temperature.png",
      priority = "extra-high",
      width = 160,
      height = 20,
    },
    gas_flow =
    {
      filename = "__base__/graphics/entity/pipe/steam.png",
      priority = "extra-high",
      line_length = 10,
      width = 48,
      height = 30,
      frame_count = 60,
      animation_speed = 0.25,
      scale = 0.5,
    }
  },
  flow_length_in_ticks = 360,
  impact_category = "metal-large",
  open_sound = data.raw['storage-tank']['storage-tank'].open_sound,
  close_sound = data.raw['storage-tank']['storage-tank'].close_sound,
  working_sound =
  {
    sound = { filename = "__base__/sound/storage-tank.ogg", volume = 0.6 },
    match_volume_to_activity = true,
    audible_distance_modifier = 0.5,
    max_sounds_per_type = 3
  },
  circuit_connector = circuit_connector_definitions["or_tank"],
  circuit_wire_max_distance = default_circuit_wire_max_distance,
  default_fluid_temperature_signal = {type = "virtual", name = "signal-T"},
  rotated_sound = data.raw["utility-sounds"]["default"]["cannot_build"],
}


if feature_flags.freezing then
  local heat_sprite = data.raw["utility-sprites"].default.heat_exchange_indication
  local heat_icon = {{icon=heat_sprite.filename, icon_size=heat_sprite.width}}
  local heat_icon_inputs = {tint={1,0.4,0.4}, scale=0.6, shift={7,-7}}
  data:extend{
    {
      type = "reactor",
      name = "or_reactor",
      icons = util.combine_icons(oil_rig.icons, heat_icon, heat_icon_inputs),
      flags = {"not-blueprintable", "not-deconstructable", "placeable-off-grid"},
      hidden = true,
      max_health = oil_rig.max_health,
      selectable_in_game = false,
      allow_copy_paste = false,
      collision_mask = {layers = {}},
      selection_box = oil_rig.selection_box,
      scale_energy_usage = true,
      energy_source = {
        type = "electric",
        usage_priority = "secondary-input",
      },
      consumption = "200kW",
      heating_radius = 4.5,
      heat_buffer = 
      {
        max_temperature = 100,
        specific_heat = "200kJ",
        max_transfer = "200kW",
      },
    }
  }
end

data:extend{oil_rig, or_power_electric, or_pole, or_radar, or_tank}
