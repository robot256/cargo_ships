local math2d = require("math2d")


local pole_offset = {0,0.1}

function UnlockOilProcessing(force)
  if force.technologies["oil-processing"] then
    force.technologies["oil-processing"].researched = true
  end
end

function CreateOilRig(entity, player, robot)
  local surface = entity.surface
  local force = entity.force
  local position = entity.position
  local quality = entity.quality
  
  -- Create component entities or revive ghosts
  local power = surface.create_entity{name="or_power_electric", quality=quality, position=position, force=force, create_build_effect_smoke=false}
  local radar = surface.create_entity{name="or_radar", quality=quality, position=position, force=force, create_build_effect_smoke=false}
  
  local pole,dummy
  local pole_ghost = surface.find_entities_filtered{ghost_name = "or_pole", position = position, radius = 1, limit = 1}[1]
  if pole_ghost then
    dummy,pole = pole_ghost.silent_revive()
    pole.teleport(math2d.position.add(position,pole_offset))
  end
  if not pole then
    pole = surface.create_entity{name = "or_pole", quality=quality, position = math2d.position.add(position,pole_offset), force = force, create_build_effect_smoke=false}
  end
  
  local tank
  local tank_ghost = surface.find_entities_filtered{ghost_name = "or_tank", position = position, radius = 1, limit = 1}[1]
  if tank_ghost then
    dummy,tank = tank_ghost.silent_revive()
    tank.teleport(position)
  end
  if not tank then
    tank = surface.create_entity{name = "or_tank", quality=quality, position = entity.position, force = entity.force, create_build_effect_smoke=false}
  end
  
  -- If there was a problem, cancel the construction
  if not (power and pole and radar and tank) then
    --game.print("Could not create all oil rig components.")
    if player then
      player.mine_entity(entity, true)
      player.create_local_flying_text{text={"cargo-ship-message.error-place-on-water", entity.localised_name}, create_at_cursor=true}
    elseif robot then
      entity.mine{inventory=robot.get_inventory(defines.inventory.robot_cargo), force=true, raise_destroyed=false, ignore_minable=true}
      game.print{"cargo-ship-message.error-place-on-water", entity.localised_name}
    end
    entity.destroy()
    if pole then pole.destroy() end
    if tank then tank.destroy() end
    if power then power.destroy() end
    if radar then radar.destroy() end
    return nil
  end
  
  -- Make components invincible
  power.destructible = false
  pole.destructible = false
  radar.destructible = false
  tank.destructible = false
  -- Link pumpjack and generator to tank
  entity.fluidbox.add_linked_connection(1, tank, 1)
  power.fluidbox.add_linked_connection(1, tank, 2)
  -- Prime the energy generator with some oil
  power.insert_fluid{name="crude-oil", amount=power.fluidbox.get_capacity(1)}
  local entry = {
      surface = surface,
      position = position,
      entity = entity,
      pole = pole,
      radar = radar,
      power = power,
      tank = tank
    }
  storage.oil_rigs[entity.unit_number] = entry
  script.register_on_object_destroyed(entity)

  UnlockOilProcessing(force)
  return entry
end

function DestroyOilRig(unit_number)
  if storage.oil_rigs and storage.oil_rigs[unit_number] then
    local data = storage.oil_rigs[unit_number]
    if data.pole and data.pole.valid then data.pole.destroy() end
    if data.radar and data.radar.valid then data.radar.destroy() end
    if data.power and data.power.valid then data.power.destroy() end
    if data.tank and data.tank.valid then data.tank.destroy() end
    storage.oil_rigs[unit_number] = nil
    return true
  end
end

function DestroyOilRigGhost(ghost)
  local poles = ghost.surface.find_entities_filtered{ghost_name = "or_pole", position = ghost.position, radius = 1}
  for _,pole in pairs(poles) do
    pole.destroy()
  end
  local tanks = ghost.surface.find_entities_filtered{ghost_name = "or_tank", position = ghost.position, radius = 1}
  for _,tank in pairs(tanks) do
    tank.destroy()
  end
end

function HandleOilRigPartGhost(ghost)
  local position = ghost.position
  local rigpos = {math.floor(ghost.position.x*2)/2, math.floor(ghost.position.y*2)/2}
  if storage.recent_oil_rig and storage.recent_oil_rig.valid and storage.recent_oil_rig.position.x == rigpos.x and storage.recent_oil_rig.position == y then
    -- Last function call was for the same oil_rig, we're good
    return
  end
  local rig = ghost.surface.find_entity("oil_rig", rigpos)
  if rig and rig.valid then
    -- Store this rig reference to use next time
    storage.recent_oil_rig = rig
    return
  end
  rig = ghost.surface.find_entities_filtered{ghost_name = "oil_rig", position = rigpos}[1]
  if rig and rig.valid then
    -- Store this rig reference to use next time
    storage.recent_oil_rig = rig
    return
  end
  -- No matching recent oil rig and none found, delete ghost
  ghost.destroy()
  storage.recent_oil_rig = nil
end
