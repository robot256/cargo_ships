local GRAPHICSPATH = "__cargo-ships-oil-rig__/graphics/"

local function unlock(recipe)
  return {
    type = "unlock-recipe",
    recipe = recipe
  }
end


data:extend{
  {
    type = "technology",
    name = "deep_sea_oil_extraction",
    icon = GRAPHICSPATH .. "technology/deep_sea_oil_extraction.png",
    icon_size = 256,
    effects = {
      unlock("oil_rig"),
    },
    prerequisites = {"oil-processing"},
    unit = {
      count = 200,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1}
      },
      time = 30
    },
    order = "c-g-b",
  },
}

-- Change technology requirement if oil is not available on land
if settings.startup["no_oil_for_oil_rig"].value then
  data.raw.technology["deep_sea_oil_extraction"].unit = {
    count = 300,
    ingredients = {
      {"automation-science-pack", 1},
      {"logistic-science-pack", 1},
    },
    time = 30
  }
  data.raw.technology["deep_sea_oil_extraction"].prerequisites = {"fluid-handling"}
  
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

end
