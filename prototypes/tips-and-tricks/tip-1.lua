---@diagnostic disable: undefined-global
require("__core__/lualib/story")

---@diagnostic disable-next-line: unknown-cast-variable
---@cast game LuaGameScript

game.simulation.active_quickbars = 1
local player = game.simulation.create_test_player{name = "Jurgy"}
player.character.teleport{0, 4}
player.force.research_all_technologies()
player.set_quick_bar_slot(1, 1, "cargo_ship")

game.simulation.camera_player = player
game.simulation.camera_position = {0, 0.5}
game.simulation.camera_player_cursor_position = player.position
game.simulation.camera_zoom = 1.25

local surface = game.surfaces[1]

local water_tiles = {}
for x = -30, 30, 1 do
  for y = -10, 2, 1 do
    table.insert(water_tiles, {name = "water", position={x, y}})
  end
end

surface.set_tiles(water_tiles, true)

---@return LuaItemPrototype
function get_first_fuel()
  local burner_prototype = prototypes.entity["cargo_ship_engine"].burner_prototype
  if burner_prototype then
    for _, prototype in pairs(prototypes.item) do
      local cat = next(burner_prototype.fuel_categories)
      if prototype.fuel_category == cat then
        return prototype
      end
    end
  end
  error("No fuel found for cargo ship")
end

local fuel = get_first_fuel()
player.set_quick_bar_slot(1, 2, fuel.name)


local waterway_height = -1

local bp = "0eNqVldtqhDAQhl9F5joLHQ/r4aa3fYdSSnZNt4E1kRhrRXz3xpV2oaWQ/8pDnC/i7zez0Ok6qt5p46lZSJ+tGah5XmjQFyOv2z0jO0UNTdIrN8mZVkHatOqTGl5fBCnjtddqr7pdzK9m7E7KhQfEd/XgndSXd3/4wQjq7RAqrdk2CbRDWguaw5HDDq126rwv5qv4A04xcBkNzjBwEQ3OMXAWDS4wMEeDjxCY48MrMXB8eBUGjg+vxsDx4fEDQkbAkHrAp2BIPSA8htQDfjeG1AMEYUg9QGmG1AOaEEPqAW2TIfWARs939Xrr/L+s3ygR3kPu5/Rkp6TVbTLbMXkLoyvp1CNto0t71YX1+wQU9KHccKsqjmld5Gle1WWVZ8W6fgHam2Mn"
surface.create_entities_from_blueprint_string
{
  string = bp,
  position = {0, waterway_height},
  force = player.force
}

local engine = nil

local story_table =
{
  {
    {
      name = "start",
      init = function() end,
      condition = story_elapsed_check(0),
      action = function()
        player.insert({name="cargo_ship", count=1})
        player.insert({name=fuel.name, count=fuel.stack_size})
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {0, waterway_height}})
      end,
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "give-waterway", notify = true}
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {-12.5, waterway_height}})
      end,
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = story_elapsed_check(0.25),
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {11, waterway_height}})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        player.clear_cursor()
      end
    },
    {
      condition = function()
        local target = game.simulation.get_widget_position({type = "quickbar-slot", filter = {name = "cargo_ship", quality = "normal"}})
        ---@cast target -?
        return game.simulation.move_cursor({position = target})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "pipette", notify = false}
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {0.5, waterway_height + 0.25}})
      end,
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = story_elapsed_check(0.25),
    },
    {
      condition = function()
        local target = game.simulation.get_widget_position({type = "quickbar-slot", filter = {name = fuel.name, quality = "normal"}})
        ---@cast target -?
        return game.simulation.move_cursor({position = target})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "pipette", notify = false}
      end
    },
    {
      condition = story_elapsed_check(0.25),
    },
    {
      condition = function()
        local engines = surface.find_entities_filtered{area = {{-15, -10}, {15, 10}}, name = "cargo_ship_engine"}
        if #engines == 0 then
          error("Cargo ship engine not found")
        end
        engine = engines[1]
        engine.train.manual_mode = false
        engine.train.schedule = {
          current = 1,
          records = {
            {station = "How did you find me?", wait_conditions = {{type = "time", ticks = 60}}}
          }
        }
        return game.simulation.move_cursor({position = engine.position})
      end,
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "fast-entity-transfer", notify = true}
      end
    },
    {
      condition = function() return game.simulation.move_cursor({position = player.position}) end
    },
    {
      condition = story_elapsed_check(3),
      action = function()
        player.character.clear_items_inside()

        ---@cast engine -?
        for _, entity in pairs(engine.train.carriages) do
          entity.destroy()
        end
        for _, entity in pairs (surface.find_entities_filtered{area = {{-11, waterway_height - 2}, {11, waterway_height + 2}}}) do
          if entity.name ~= "character" then
            entity.destroy()
          end
        end
      end
    },
    {
      condition = story_elapsed_check(0.5),
      action = function()
        story_jump_to(storage.story, "start")
      end
    },
  }
}

tip_story_init(story_table)