local resource_autoplace = require("resource-autoplace")

if not settings.startup["offshore_oil_enabled"].value then return end
----------------------------------------------------------------
------------------------- OFFSHORE OIL --------------------------
----------------------------------------------------------------
data:extend{
  {
    type = "autoplace-control",
    name = "offshore-oil",
    localised_name = {"", "[entity=offshore-oil] ", {"entity-name.offshore-oil"}},
    richness = true,
    can_be_disabled = true,
    order = "b-g",
    category = "resource"
  },
}
resource_autoplace.initialize_patch_set("offshore-oil", false)

data:extend{
  {
    type = "resource-category",
    name = "offshore-fluid"
  },
  {
    type = "resource",
    name = "offshore-oil",
    icon = "__base__/graphics/icons/crude-oil-resource.png",
    flags = {"placeable-neutral"},
    category = "offshore-fluid",
    subgroup = "mineable-fluids",
    order="a-b-a",
    infinite = true,
    highlight = true,
    minimum = 60000,
    normal = 300000,
    infinite_depletion_amount = 25,
    resource_patch_search_radius = 50,
    minable =
    {
      mining_time = 1,
      results =
      {
        {
          type = "fluid",
          name = "crude-oil",
          amount_min = 10,
          amount_max = 10,
          probability = 1
        }
      }
    },
    walking_sound = data.raw.resource["crude-oil"].walking_sound,
    driving_sound = data.raw.resource["crude-oil"].driving_sound,
    collision_mask = {layers = {resource = true}},
    protected_from_tile_building = false,
    --collision_box = {{-2.4, -2.4}, {2.4, 2.4}},
    --selection_box = {{-1.0, -1.0}, {1.0, 1.0}},
    collision_box = data.raw.resource["crude-oil"].collision_box,
    selection_box = data.raw.resource["crude-oil"].selection_box,
    autoplace = resource_autoplace.resource_autoplace_settings
    {
      name = "offshore-oil",
      order = "a",
      base_density = 10,          -- amount of stuff, on average, to be placed per tile
      base_spots_per_km2 = 1.8,     -- number of patches per square kilometer near the starting area
      random_probability = 1/75, -- probability of placement at any given tile within a patch (set low to ensure space between deposits for rigs to be placed)
      random_spot_size_minimum = 1,
      random_spot_size_maximum = 1, -- don't randomize spot size (so single entities are placed alone)
      additional_richness = 350000, -- this increases the total everywhere, so base_density needs to be decreased to compensate
      has_starting_area_placement = false,
      regular_rq_factor_multiplier = 1 -- rq_factor is the ratio of the radius of a patch to the cube root of its quantity,
                                       -- i.e. radius of a quantity=1 patch; higher values = fatter, shallower patches
    },
    stage_counts = {0},
    stages =
    {
      sheet = {
        filename = GRAPHICSPATH .. "entity/crude-oil/hr-water-crude-oil.png",
        priority = "extra-high",
        width = 148,
        height = 120,
        frame_count = 4,
        variation_count = 1,
        shift = util.by_pixel(0, -2),
        scale = 0.7
      }
    },
    map_color = {0.8, 0.1, 1},
    map_grid = false
  },
}

if mods["angelspetrochem"] then
  data.raw.resource["offshore-oil"].minable = {
    hardness = 1,
    mining_time = 1,
    results =
    {
      {
        type = "fluid",
        name = "liquid-multi-phase-oil",
        amount_min = 10,
        amount_max = 10,
        probability = 1
      }
    }
  }
end

-- Add to Nauvis planet definition
data.raw.planet.nauvis.map_gen_settings.autoplace_controls["offshore-oil"] = {}
-- TODO: Add other Space Age planets
