require("util")
require("__cargo-ships__/logic/ship_api")
require("__cargo-ships__/logic/ship_placement")
require("__cargo-ships__/logic/rail_placement")
require("__cargo-ships__/logic/long_reach")
require("__cargo-ships__/logic/bridge_logic")
require("__cargo-ships__/logic/pump_placement")
require("__cargo-ships__/logic/blueprint_logic")
require("__cargo-ships__/logic/ship_enter")
require("__cargo-ships__/logic/oil_rig_logic")
require("__cargo-ships__/logic/mapgen")
--require("__cargo-ships__/logic/crane_logic")


is_waterway = util.list_to_map{
  "straight-waterway",
  "half-diagonal-waterway",
  "curved-waterway-a",
  "curved-waterway-b",
  "legacy-straight-waterway",
  "legacy-curved-waterway"
}

is_rail = util.list_to_map{
  "straight-rail",
  "half-diagonal-rail",
  "curved-rail-a",
  "curved-rail-b",
  "legacy-straight-rail",
  "legacy-curved-rail",
  "rail-ramp",
}


-- spawn additional invisible entities
local function OnEntityBuilt(event)

  local entity = event.entity or event.destination
  local surface = entity.surface
  local quality = entity.quality
  local force = entity.force
  local player = (event.player_index and game.players[event.player_index]) or nil

  --log("Event happened:"..serpent.block(event))

  -- check ghost entities first
  if entity.name == "entity-ghost" then
    if is_waterway[entity.ghost_name] then
      if not entity.silent_revive{raise_revive = true} then
        entity.destroy()
      end
    elseif entity.ghost_name == "bridge_gate" then
      -- Replace with proper bridge_base ghost
      HandleBridgeGhost(entity)
    elseif entity.ghost_name == "or_tank" or entity.ghost_name == "or_pole" then
      -- Delete oil rig parts if placed without an oil_rig
      HandleOilRigPartGhost(entity)
    end

  elseif storage.boat_bodies[entity.name] then
    CheckBoatPlacement(entity, player)

  elseif (entity.type == "cargo-wagon" or entity.type == "fluid-wagon" or
          entity.type == "locomotive" or entity.type == "artillery-wagon") then
    local engine = nil
    if storage.ship_bodies[entity.name] then
      local ship_data = storage.ship_bodies[entity.name]
      if ship_data.engine then
        local engine_loc = localizeEngine(entity)
        --game.print("looking for engine ghost at "..util.positiontostr(engine_loc.pos).." pointing "..tostring(engine_loc.dir))
        -- see if there is an engine ghost from a blueprint behind us
        local ghost = surface.find_entities_filtered{ghost_name=ship_data.engine, position=engine_loc.pos, force=force, limit=1}[1]
        if ghost then
          --game.print("found ghost at "..util.positiontostr(ghost.position).." pointing "..tostring(ghost.orientation)..", reviving")
          local dummy
          dummy, engine = ghost.revive()
          -- If couldn't revive engine, destroy ghost
          if not engine then
            --game.print("couldn't revive ghost at "..util.positiontostr(newghost.position))
            ghost.destroy()
          end
        end
        if not engine then
          --game.print("Creating "..ship_data.engine.." for "..entity.name)
          engine = surface.create_entity{
            name = ship_data.engine,
            quality = quality,
            position = engine_loc.pos,
            direction = engine_loc.dir,
            force = force
          }
        end
      end
    end
    -- check placement in next tick after wagons connect
    table.insert(storage.check_placement_queue, {entity=entity, engine=engine, player=player, robot=event.robot})
    RegisterPlacementOnTick()
  -- add oilrig component entities
  elseif entity.name == "oil_rig" then
    CreateOilRig(entity, player, event.robot)

  -- create bridge
  elseif entity.name == "bridge_base" then
    CreateBridge(entity, player, event.robot)

  -- make waterway not collide with boats by replacing it with entity that does not have "ground-tile" in its collision mask
  elseif is_rail[entity.type] then
    CheckRailPlacement(entity, player, event.robot)

  --elseif entity.name == "crane" then
  --  OnCraneCreated(entity)
  end
end

local function OnMarkedForDeconstruction(event)
  local entity = event.entity
  if is_waterway[entity.name] then
    -- Instantly deconstruct waterways
    entity.destroy()
  elseif storage.ship_bodies[entity.name] or storage.ship_engines[entity.name] then
    -- If a ship or ship engine is marked for deconstruction, make sure its coupled pair is too
    if entity.train then
      local otherstock
      -- Find attached engine or body
      otherstock = entity.get_connected_rolling_stock(defines.rail_direction.front) or 
                   entity.get_connected_rolling_stock(defines.rail_direction.back)
      if otherstock and not otherstock.to_be_deconstructed() then
        -- Copy deconstruction order
        local player = game.players[event.player_index]
        local force = (player and player.force) or entity.force
        otherstock.order_deconstruction(force, player)
      end
    end
  end
end

local function OnCancelledDeconstruction(event)
  local entity = event.entity
  if storage.ship_bodies[entity.name] or storage.ship_engines[entity.name] then
    -- If a ship or ship engine is cancelled for deconstruction, make sure its coupled pair is too
    if entity.train then
      local otherstock
      -- Find attached engine or body
      otherstock = entity.get_connected_rolling_stock(defines.rail_direction.front) or 
                   entity.get_connected_rolling_stock(defines.rail_direction.back)
      if otherstock and otherstock.to_be_deconstructed() then
        -- Copy deconstruction order
        local player = game.players[event.player_index]
        local force = (player and player.force) or entity.force
        otherstock.cancel_deconstruction(force, player)
      end
    end
  end
end

local function OnGiveWaterway(event)
  local player = game.get_player(event.player_index)
  local cleared = player.clear_cursor()
  if cleared then
    player.cursor_ghost = {name="waterway"}
  end
end

-- delete invisible entities if master entity is destroyed
local function OnEntityDeleted(event)
  local entity = event.entity
  if(entity and entity.valid) then
    if storage.ship_bodies[entity.name] then
      if entity.train then
        if entity.train.back_stock then
          if storage.ship_engines[entity.train.back_stock.name] then
            entity.train.back_stock.destroy()
          end
        end
        if entity.train.front_stock then
          if storage.ship_engines[entity.train.front_stock.name] then
            entity.train.front_stock.destroy()
          end
        end
      end

    elseif storage.ship_engines[entity.name] then
      if entity.train then
        if entity.train.front_stock then
          if storage.ship_bodies[entity.train.front_stock.name] then
            entity.train.front_stock.destroy()
          end
        end
        if entity.train.back_stock then
          if storage.ship_bodies[entity.train.back_stock.name]  then
            entity.train.back_stock.destroy()
          end
        end
      end
    
    elseif entity.name == "entity-ghost" then
      if entity.ghost_name == "oil_rig" then
        -- Delete any or_tank or or_pole ghosts in the area
        DestroyOilRigGhost(entity)
      elseif storage.ship_bodies[entity.ghost_name] then
        -- Delete any ship engine ghost in the area
        DestroyShipGhost(entity)
      end
    end
  end
end


-- Perform the destroyed action for this unit_number
-- Each method checks if it applies
function OnObjectDestroyed(event)
  local unit_number = event.useful_id
  -- Oil Rigs
  if DestroyOilRig(unit_number) then return end
  -- Bridges
  if HandleBridgeDestroyed(unit_number) then return end
end


-- Robots can try to mine it, but get sent away with something else if there is still cargo
local function OnRobotPreMined(event)
  if(event.entity and event.entity.valid) then
    local entity = event.entity
    if storage.ship_bodies[entity.name] or storage.ship_engines[entity.name] then
      -- Find attached engine or body
      local otherstock = entity.get_connected_rolling_stock(defines.rail_direction.front) or 
                         entity.get_connected_rolling_stock(defines.rail_direction.back)
      if otherstock then
        local save_inventory
        -- Get the correct inventory from the attached engine or body
        -- Ignore engines with recover_fuel=false because they don't have fuel items to recover
        if storage.ship_engines[otherstock.name] and storage.ship_engines[otherstock.name].recover_fuel then
          save_inventory = otherstock.get_fuel_inventory()
        -- If not an engine, then it must be a body because we already checked it's one or the other
        elseif otherstock.type == "cargo-wagon" then
          save_inventory = otherstock.get_inventory(defines.inventory.cargo_wagon)
        elseif otherstock.type == "artillery-wagon" then
          save_inventory = otherstock.get_inventory(defines.inventory.artillery_wagon_ammo)
        end
        if save_inventory and not save_inventory.is_empty() then
          -- Give contents of inventory to robot
          local robotInventory = event.robot.get_inventory(defines.inventory.robot_cargo)
          local robotSize = 1 + event.robot.force.worker_robots_storage_bonus
          if robotInventory.is_empty() then
            -- Find something to give to the robot. Otherwise the robot remains empty when the event returns, and it will finish mining the entity
            for index=1, #save_inventory do
              local stack = save_inventory[index]
              if stack.valid_for_read then
                --game.print("Giving robot cargo stack: "..stack.name.." : "..stack.count)
                local inserted = robotInventory.insert{name=stack.name, count=math.min(stack.count, robotSize)}
                save_inventory.remove{name=stack.name, count=inserted}
                if not robotInventory.is_empty() then
                  break
                end
              end
            end
          end
        end
      end
    end
  end
end

-- Robot mining the actually ship/engine (after both are empty).
-- If one half of a ship is mined, also mine the other half into the same robot. Only one of them will be the actual item.
local function OnRobotMinedEntity(event)
  if event.entity and event.entity.valid then
    local entity = event.entity
    if storage.ship_bodies[entity.name] or storage.ship_engines[entity.name] then
      -- Find attached engine or body to mine
      local otherstock = entity.get_connected_rolling_stock(defines.rail_direction.front) or 
                         entity.get_connected_rolling_stock(defines.rail_direction.back)
      if otherstock then
        otherstock.mine{inventory=event.robot.get_inventory(defines.inventory.robot_cargo), force=true, raise_destroyed=false, ignore_minable=true}
      end
    end
  end
end

-- When the player mines a ship or engine, also make the player mine the coupled entity
-- Unfortunately the API won't let us combine them into one undo action yet
local function OnPlayerMinedEntity(event)
  local entity = event.entity
  local player = game.players[event.player_index]
  if entity and entity.valid then
    storage.currently_mining = storage.currently_mining or {}
    if not storage.currently_mining[entity.unit_number] then
      if storage.ship_bodies[entity.name] or storage.ship_engines[entity.name] then
        -- Find attached engine or body to mine
        local otherstock = entity.get_connected_rolling_stock(defines.rail_direction.front) or 
                           entity.get_connected_rolling_stock(defines.rail_direction.back)
        if otherstock then
          storage.currently_mining[otherstock.unit_number] = entity
          player.mine_entity(otherstock, true)
          -- This mining operation completes before returning
          -- Now merge the undo actions.  Most recent is entity, second-most-recent is otherstock
          local item1 = player.undo_redo_stack.get_undo_item(1)
          if #item1 == 1 and item1[1].type == "removed-entity" and storage.ship_engines[item1[1].target.name] then
            -- otherstock was an engine that we can safely remove from the undo stack
            --game.print("Removing engine from undo stack")
            player.undo_redo_stack.remove_undo_item(1)
          end
        end
      end
    else
      -- This mining operation was started by script, don't start another one and clear the flag
      storage.currently_mining[entity.unit_number] = nil
    end
  end
end

-- Check if this undo created a lone ship engine ghost, because that's not allowed
local function OnUndoApplied(event)
  local actions = event.actions
  local action = actions[1]
  --game.print(serpent.block(action))
  if #actions == 1 and action.type == "removed-entity" and storage.ship_engines[action.target.name] then
    -- Find the ghost at the action coordinates
    local surface = game.surfaces[action.surface_index]
    local found = surface and surface.find_entities_filtered{ghost_name=action.target.name, position=action.target.position, limit=1}
    
    if found and found[1] then
      found[1].destroy()
      --game.print("Destroyed engine ghost from undo action")
    else
      --game.print("Couldn't find ghost engine from undo action")
    end
  end
end

local function OnModSettingsChanged(event)
  if event.setting == "waterway_reach_increase" then
    storage.current_distance_bonus = settings.global["waterway_reach_increase"].value
    applyReachChanges()
  end
end

local function OnStackChanged(event)
  increaseReach(event)
  PumpVisualisation(event)
end

-- Register conditional events based on mod settting
function init_events()
  -- entity created, check placement and create invisible elements
  local entity_filters = {
      {filter="ghost", ghost_name="bridge_gate"},
      {filter="ghost", ghost_name="straight-waterway"},
      {filter="ghost", ghost_name="half-diagonal-waterway"},
      {filter="ghost", ghost_name="curved-waterway-a"},
      {filter="ghost", ghost_name="curved-waterway-b"},
      {filter="ghost", ghost_name="legacy-straight-waterway"},
      {filter="ghost", ghost_name="legacy-curved-waterway"},
      {filter="name", name="oil_rig"},
      {filter="name", name="bridge_base"},
      {filter="rolling-stock"},
      {filter="rail"}
    }
  if storage.boat_bodies then
    for name,_ in pairs(storage.boat_bodies) do
      table.insert(entity_filters, {filter="name", name=name})
    end
  end
  script.on_event(defines.events.on_built_entity, OnEntityBuilt, entity_filters)
  script.on_event(defines.events.on_robot_built_entity, OnEntityBuilt, entity_filters)
  script.on_event(defines.events.on_entity_cloned, OnEntityBuilt, entity_filters)
  script.on_event(defines.events.script_raised_built, OnEntityBuilt, entity_filters)
  script.on_event(defines.events.script_raised_revive, OnEntityBuilt, entity_filters)

  -- delete invisible oil rig, bridge, and ship elements
  local deleted_filters = {{filter="ghost_name", name="oil_rig"}}
  if storage.ship_bodies then
    for name,_ in pairs(storage.ship_bodies) do
      table.insert(deleted_filters, {filter="name", name=name})
      table.insert(deleted_filters, {filter="ghost_name", name=name})
    end
  end
  if storage.ship_engines then
    for name,_ in pairs(storage.ship_engines) do
      table.insert(deleted_filters, {filter="name", name=name})
    end
  end
  script.on_event(defines.events.on_entity_died, OnEntityDeleted, deleted_filters)
  script.on_event(defines.events.script_raised_destroy, OnEntityDeleted, deleted_filters)
  
  -- Handle Oil Rig and Bridge components
  script.on_event(defines.events.on_object_destroyed, OnObjectDestroyed)

  -- recover fuel from mined ships
  local mined_filters = {}
  if storage.ship_bodies then
    for name,_ in pairs(storage.ship_bodies) do
      table.insert(mined_filters, {filter="name", name=name})
    end
  end
  if storage.ship_engines then
    for name,_ in pairs(storage.ship_engines) do
      table.insert(mined_filters, {filter="name", name=name})
    end
  end
  script.on_event(defines.events.on_robot_pre_mined, OnRobotPreMined, mined_filters)
  script.on_event(defines.events.on_player_mined_entity, OnPlayerMinedEntity, mined_filters)
  script.on_event(defines.events.on_robot_mined_entity , OnRobotMinedEntity, mined_filters)
  
  script.on_event(defines.events.on_undo_applied, OnUndoApplied)
  script.on_event(defines.events.on_redo_applied, OnUndoApplied)
  
  local deconstructed_filters = {
    {filter="name", name="straight-waterway"},
    {filter="name", name="half-diagonal-waterway"},
    {filter="name", name="curved-waterway-a"},
    {filter="name", name="curved-waterway-b"},
    {filter="name", name="legacy-straight-waterway"},
    {filter="name", name="legacy-curved-waterway"},
  }
  if storage.ship_bodies then
    for name,_ in pairs(storage.ship_bodies) do
      table.insert(deconstructed_filters, {filter="name", name=name})
    end
  end
  if storage.ship_engines then
    for name,_ in pairs(storage.ship_engines) do
      table.insert(deconstructed_filters, {filter="name", name=name})
    end
  end
  script.on_event(defines.events.on_marked_for_deconstruction, OnMarkedForDeconstruction, deconstructed_filters)
  
  local cancel_decon_filters = {}
  if storage.ship_bodies then
    for name,_ in pairs(storage.ship_bodies) do
      table.insert(cancel_decon_filters, {filter="name", name=name})
    end
  end
  if storage.ship_engines then
    for name,_ in pairs(storage.ship_engines) do
      table.insert(cancel_decon_filters, {filter="name", name=name})
    end
  end
  script.on_event(defines.events.on_cancelled_deconstruction, OnCancelledDeconstruction, cancel_decon_filters)
  
  -- update ship placement
  RegisterPlacementOnTick()
  
  -- bridge queue
  RegisterBridgeNthTick()
  
  -- update visuals
  RegisterVisualsNthTick()
  
  -- long reach
  script.on_event(defines.events.on_player_cursor_stack_changed, OnStackChanged)
  script.on_event(defines.events.on_pre_player_died, deadReach)

  -- pipette
  script.on_event(defines.events.on_player_pipette, FixPipette)
  
  -- bridge blueprint
  script.on_event({defines.events.on_player_setup_blueprint,
                   defines.events.on_player_configured_blueprint}, HandleBridgeBlueprint)
  

  -- rolling stock connect (this logic was too buggy to use)
  script.on_event(defines.events.on_train_created, OnTrainCreated)

  script.on_event(defines.events.on_runtime_mod_setting_changed, OnModSettingsChanged)

  -- custom-input and shortcut button
  script.on_event({defines.events.on_lua_shortcut, "give-waterway"},
    function(event)
      if event.prototype_name and event.prototype_name ~= "give-waterway" then return end
      OnGiveWaterway(event)
    end
  )
  
  -- Compatibility with AAI Vehicles (Modify this whenever the list of boats changes)
  remote.remove_interface("aai-sci-burner")
  remote.add_interface("aai-sci-burner", {
    hauler_types = function(data)
      local types={}
      if storage.boat_bodies then
        for name,_ in pairs(storage.boat_bodies) do
          table.insert(types, name)
        end
      end
      return types
    end,
  })

end


local function init()
  -- Init storage variables
  storage.check_placement_queue = storage.check_placement_queue or {}
  storage.oil_rigs = storage.oil_rigs or {}
  storage.bridges = storage.bridges or {}
  storage.bridge_destroyed_queue = storage.bridge_destroyed_queue or {}
  storage.ship_pump_selected = storage.ship_pump_selected or {}
  storage.pump_markers = storage.pump_markers or {}
  storage.disable_this_tick = storage.disable_this_tick or {}
  storage.driving_state_locks = storage.driving_state_locks or {}
  storage.currently_mining = storage.currently_mining or {}

  init_ship_globals()  -- Init database of ship parameters

  -- Initialize or migrate long reach state
  storage.last_cursor_stack_name =
    ((type(storage.last_cursor_stack_name) == "table") and storage.last_cursor_stack_name)
      or {}
  storage.last_distance_bonus =
    ((type(storage.last_distance_bonus) == "number") and storage.last_distance_bonus)
      or settings.global["waterway_reach_increase"].value
  storage.current_distance_bonus = settings.global["waterway_reach_increase"].value

  -- Enable oil-processing tech on migration from v1.0.12
  for _, oil_rig in pairs(storage.oil_rigs) do
    if oil_rig.entity and oil_rig.entity.valid then
      UnlockOilProcessing(oil_rig.entity.force)
    end
  end

  -- Enable offshore oil generation if it has been added to a save
  oil_generation_migration()

  -- Register conditional events
  init_events()
end

---- Register Default Events ----
-- init
script.on_load(function()
  init_events()
end)
script.on_init(function()
  init()
end)
script.on_configuration_changed(function()
  init()
end)

-- Console commands
commands.add_command("cargo-ships-dump", "Dump storage to log", function() log(serpent.block(storage)) end)

------------------------------------------------------------------------------------
--                    FIND LOCAL VARIABLES THAT ARE USED GLOBALLY                 --
--                              (Thanks to eradicator!)                           --
------------------------------------------------------------------------------------
setmetatable(_ENV,{
  __newindex=function (self,key,value) --locked_global_write
    error('\n\n[ER Global Lock] Forbidden global *write*:\n'
      .. serpent.line{key=key or '<nil>',value=value or '<nil>'}..'\n')
    end,
  --[[__index   =function (self,key) --locked_global_read
    error('\n\n[ER Global Lock] Forbidden global *read*:\n'
      .. serpent.line{key=key or '<nil>'}..'\n')
    end ,]]
  })

