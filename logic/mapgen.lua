
-- Enable offshore oil generation if it has been added to a save
function oil_generation_migration()
  if not prototypes.entity["offshore-oil"] then return end
  local map_gen_settings = game.planets.nauvis.surface.map_gen_settings
  if map_gen_settings.autoplace_settings.entity.settings["offshore-oil"] == nil then
    map_gen_settings.autoplace_controls["offshore-oil"] = {}
    map_gen_settings.autoplace_settings.entity.settings["offshore-oil"] = {}
    game.planets.nauvis.surface.map_gen_settings = map_gen_settings
    game.planets.nauvis.surface.regenerate_entity("offshore-oil")
  end
  if game.planets.aquilo and game.planets.aquilo.surface then
    local aquilo_map_gen_settings = game.planets.aquilo.surface.map_gen_settings
    if aquilo_map_gen_settings.autoplace_settings.entity.settings["offshore-oil"] == nil then
      aquilo_map_gen_settings.autoplace_controls["aquilo_offshore_oil"] = {}
      aquilo_map_gen_settings.autoplace_settings.entity.settings["offshore-oil"] = {}
      game.planets.aquilo.surface.map_gen_settings = aquilo_map_gen_settings
      game.planets.aquilo.surface.regenerate_entity("offshore-oil")
    end
  end
end

local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local usage_string_get = "Usage: /cargo-ships-get-oil-settings <planet>"
commands.add_command("cargo-ships-get-oil-settings", "Get oil settings\n" .. usage_string_get, function(command)
  if not command.parameter or not game.planets[command.parameter] then
    game.print(usage_string_get)
    return
  end
  local planet = game.planets[command.parameter]
  if not planet.surface then
    game.print("Planet " .. planet.name .. " has not been generated yet")
    return
  end
  if not prototypes.entity["offshore-oil"] then
    game.print("Offshore oil has been disabled in mod settings")
    -- Don't return as may still want to see crude-oil settings
  end
  local crude_control_name = "crude-oil"
  local offshore_control_name = "offshore-oil"
  if planet.name == "aquilo" then
    crude_control_name = "aquilo_crude_oil"
    offshore_control_name = "aquilo_offshore_oil"
  end
  local map_gen_settings = planet.surface.map_gen_settings
  local crude_autoplace_controls = map_gen_settings.autoplace_controls[crude_control_name]
  game.print(planet.name .. " crude-oil settings: " .. serpent.line(crude_autoplace_controls))
  local offshore_autoplace_controls = map_gen_settings.autoplace_controls[offshore_control_name]
  game.print(planet.name .. " offshore-oil settings: " .. serpent.line(offshore_autoplace_controls))
end)

local usage_string = "Usage: /cargo-ships-set-oil-settings <planet> <offshore-oil/crude-oil> <default/off/{frequency=X,richness=Y,size=Z}>"
commands.add_command("cargo-ships-set-oil-settings", "Set oil configuration\n" .. usage_string, function(command)
  if not command.parameter then
    game.print(usage_string)
    return
  end
  local params = split(command.parameter, " ")
  if #params ~= 3 then
    game.print("Wrong number of parameters")
    game.print(usage_string)
    return
  end
  local planet_name = params[1]
  local resource_name = params[2]
  local settings_string = params[3]

  if not game.planets[planet_name] then
    game.print("Planet " .. planet_name .. " does not exist")
    return
  end
  local planet = game.planets[planet_name]
  if not planet.surface then
    game.print("Planet " .. planet_name .. " has not been generated yet")
    return
  end

  if resource_name == "offshore-oil" and not prototypes.entity["offshore-oil"] then
    game.print("Offshore oil has been disabled in mod settings")
    return
  end

  local control_name
  if resource_name == "crude-oil" then
    control_name = "crude-oil"
    if planet_name == "aquilo" then
      control_name = "aquilo_crude_oil"
    end
  elseif resource_name == "offshore-oil" then
    control_name = "offshore-oil"
    if planet_name == "aquilo" then
      control_name = "aquilo_offshore_oil"
    end
  else
    game.print("Unknown resource name: " .. resource_name)
    return
  end
  local map_gen_settings = planet.surface.map_gen_settings

  if settings_string == "default" then
    map_gen_settings.autoplace_controls[control_name] = {}
  elseif settings_string == "off" then
    map_gen_settings.autoplace_controls[control_name] = {frequency = 1, size = 0, richness = 1}
  else
    local ok, res = serpent.load(settings_string)
    if not ok then
      game.print("Error parsing settings: " .. settings_string)
      return
    end
    map_gen_settings.autoplace_controls[control_name] = res
  end
  planet.surface.map_gen_settings = map_gen_settings
  --[[local entities = planet.surface.find_entities_filtered{type="resource", name=resource_name}
  for _, entity in pairs(entities) do
    entity.destroy()
  end]]

  -- Doesn't delete entities, doesn't create entities if they've already been autoplaced
  planet.surface.regenerate_entity(resource_name)
  game.print("Set " .. planet_name .. " " .. resource_name .. " settings to " .. settings_string)
end)