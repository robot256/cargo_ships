local collision_mask_util = require("__core__/lualib/collision-mask-util")

-- Ensure no collision with FISH when Space Exploration is installed
data.raw["mining-drill"]["oil_rig"].collision_mask.layers.space_tile = nil

-- Update technology triggers
for name, tech in pairs(data.raw.technology) do
  -- Check if each technology has "mine crude-oil" as a trigger, and add "offshore-oil"
  
  if tech.research_trigger and tech.research_trigger.type == "mine-entity" then
    if tech.research_trigger.entity and tech.research_trigger.entity == "crude-oil" then
      tech.research_trigger.entity = nil
      tech.research_trigger.entities = {"crude-oil", "offshore-oil"}
    elseif tech.research_trigger.entities then
      for _, ent in pairs(tech.research_trigger.entities) do
        if ent == "crude-oil" then
          tech.research_trigger.entities[#tech.research_trigger.entities+1] = "offshore-oil"
          break
        end
      end
    end
  end
end

-- Add Deep Sea Oil Extraction as a prerequisite to Oil Processing
-- This is okay because Oil Processing is unlocked by trigger (mining oil from anywhere)
-- and won't actually require you to extract both offshore and onshore oil.    
local oil_proc = data.raw.technology["oil-processing"]
if oil_proc and oil_proc.prerequisites then
  for _, tech in pairs(oil_proc.prerequisites) do
    if tech == "oil-gathering" then
      oil_proc.prerequisites[#oil_proc.prerequisites+1] = "deep_sea_oil_extraction"
      break
    end
  end
end

-- Compatibility with Simple Seablock and others
-- Changes Oil rig recipe if pumpjacks are unavailable
if not data.raw.technology["oil-gathering"] or data.raw.technology["oil-gathering"].hidden or 
   not data.raw.recipe.pumpjack or data.raw.recipe.pumpjack.hidden or
   not data.raw.item.pumpjack or data.raw.item.pumpjack.hidden then
  data.raw.recipe["oil_rig"].ingredients = {
      {type="item", name="boiler", amount=1},
      {type="item", name="steam-engine", amount=1},
      {type="item", name="steel-plate", amount=175},
      {type="item", name="electronic-circuit", amount=100},
      {type="item", name="iron-gear-wheel", amount=50},
      {type="item", name="pipe", amount=125}
    }
end

-----------------------------
---- DEEP OIL GENERATION ----
-----------------------------

-- Add new "water_resource" collision layer to all the tiles that have "ground_tile"
local count = 0
for name, tile in pairs(data.raw.tile) do
  local collision_mask = tile.collision_mask
  if collision_mask.layers["ground_tile"] then
    --log("Adding collision layer 'water_resource' to tile '"..name.."'")
    collision_mask.layers["water_resource"] = true
    count = count + 1
  end
end
if count > 0 then
  log("Added collision layer 'water_resource' to "..tostring(count).." ground tiles.")
end

-- Add new "water_resource" collision layer to all non-deep water tiles if "Offshore oil on Deep Water only" is enabled
count = 0
if settings.startup["no_shallow_oil"].value then
  for _, name in pairs({"water", "water-green", "water-shallow", "water-mud"}) do
    if data.raw.tile[name] then
      local collision_mask = data.raw.tile[name].collision_mask
      --log("Adding collision layer 'water_resource' to tile '"..name.."'")
      collision_mask.layers["water_resource"] = true
      count = count + 1
    end
  end
end
if count > 0 then
  log("Added collision layer 'water_resource' to "..tostring(count).." shallow water tiles.")
end

-- Make sure the oil rig can mine deep oil:
data.raw["mining-drill"]["oil_rig"].resource_categories = {data.raw.resource["offshore-oil"].category}

if settings.startup["oil_rigs_require_external_power"].value ~= "enabled" then
  -- Make sure the oil rig can burn crude-oil
  data.raw.fluid["crude-oil"].fuel_value = data.raw.fluid["crude-oil"].fuel_value or "20MJ"
end

-- Make offshore-oil match crude-oil infinite setting (Krastorio2 compat)
data.raw.resource["offshore-oil"].infinite = data.raw.resource["crude-oil"].infinite
data.raw.resource["offshore-oil"].minimum = data.raw.resource["crude-oil"].minimum
data.raw.resource["offshore-oil"].normal = data.raw.resource["crude-oil"].normal
data.raw.resource["offshore-oil"].map_color = data.raw.resource["crude-oil"].map_color

