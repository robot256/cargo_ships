---@diagnostic disable: undefined-global
require("__core__/lualib/story")

---@diagnostic disable-next-line: unknown-cast-variable
---@cast game LuaGameScript

game.simulation.active_quickbars = 1
local player = game.simulation.create_test_player{name = "Jurgy"}
player.character.teleport{0, 4}
player.force.research_all_technologies()

game.simulation.camera_player = player
game.simulation.camera_position = {0, 0.5}
game.simulation.camera_player_cursor_position = player.position
game.simulation.camera_zoom = 1.25

---@type LuaSurface
local surface = game.surfaces[1]

local water_tiles = {}
for x = -32, 30, 1 do
  for y = -10, 2, 1 do
    if y > 1 and (x >= -6 and x < 6) then
    else
      table.insert(water_tiles, {name = "water", position={x, y}})
    end
  end
end

surface.set_tiles(water_tiles, true)

local bp = "0eNqlmF2PoyAUhv9Kw7VtBMWP3uzt/odJY6hSh4yCQZ1ud9L/vqAzbWdXCyfbTMZq4eFFzsvH+UDHZuSdFnJA+w8kSiV7tH/5QL2oJWvsM8lajvbozAauz+yCrgESsuK/0B5fg4WCSjTFwOQb1w9FyfUQIC4HMQg+NzDdXAo5tkdTco+Dr/r9oJmoX4ftrcUAdao3NZW0zRjaluQBupirUYAqoXk5/xhbQX+BCQyceoOjG7hkulZF/yq6gstaSL4ETnYZyTChdz6X7NjwolG16AdR9sX5VZj7Vr0LWaP9iTU9D5DSwjTMZla4s4BSNUpbsLZP8ji3nywL0zxMcRjHOcFZasoZSBig4/SfTcOFxMDb+f2L6mHM5Fg2nOntaeQNuhczpWQh5LsRoPRlrna/M0PWD6x8s+TD1fz9+45i2Mun3i+fwsCRNziBgbE3OAWBsX+AZzCwf4DnwYKlF4jJLs/COJlC7j9je0EFDmH9848hDJtzsH8QYdikg/2jCEcgsn8UYZhV/aMIw6wKGD6YVQGjd7dqJ7qlyRzvZpnxjl6XAEBL+ivLXcrC58pI6AC46t8t0/JKjO2WN0awFuW2U80THl3hgYzi/6JI5OinYwRJ7KhPHPVBQe8fmiT5pms7qG2t1SirBeiDwm9cTJbAqTc4XgMvCgZZwd/8xOUE+nyAIpcREkd90NoB2FQSh67UoSsCGjR9btDIZYTMoQdkBP/lKkocunKHLtccjx0zYQQKbMAKHz1EttLDKutv1LQZn7+jn+q8qUS1uahxczInsE3Lf6Cl7fnj3kppVhvjm23eQpvkeZjEIDsAdlKxyw/4a55LV5RFvoBsBRD7AvIVAPUF2JhbJCTeBLxCSL0JZIWQeROiFUIOnJpw/DzoKOhkADgY0Hs03yRyyXV92Qpp+CdWLslNPrtvGjiOpxPXRS9+czust89SYwT6WpLn8UZBRwTAeZCCjgiAEywFLRKAMzcFHREAWQIKOs1D8hqgZQWQraI5CLw2eAezzJSvvBqbzzReo0rVqkG8T/fRw+9TgoqXSlefGcXny1OAzkwMRalkNSmZKw2XbrJh2w1WpmmrY5oXn4+Z2Z9eD1PyyS5/qnyz9eUs96tVZTNUpj/HKVUVTTnL+aEZ75NWNvOZW8DZdNRWejERRgOzk6KH4MVeAjN12e/2Ehi/0sNhTpEZCff0aYDeue6nHtKE5DQmcZanWRwZl/4Bs+AChA=="

local load = false

local pumps = {
  "ship-unloading-pump",
  "ship-loading-pump"
}
player.set_quick_bar_slot(1, 1, pumps[1])
player.set_quick_bar_slot(1, 2, pumps[2])
local pump = nil
local engine = nil
---@cast engine -?

local story_table =
{
  {
    {
      name = "start",
      init = function() end,
      condition = story_elapsed_check(0),
      action = function()
        if load then pump = pumps[2] else pump = pumps[1] end

        surface.create_entities_from_blueprint_string
        {
          string = bp,
          position = {-4, 1},
          force = player.force
        }

        player.insert({name=pump, count=6})

        local engines = surface.find_entities_filtered{name = "cargo_ship_engine"}
        if #engines == 0 then
          error("Cargo ship engine not found")
        end
        engine = engines[1]

        if load then
          local tank = surface.find_entities_filtered{name = "storage-tank"}[1]
          tank.set_fluid(1, {name = "crude-oil", amount = 25000})
        else
          local tanker = engine.train.fluid_wagons[1]
          tanker.set_fluid(1, {name = "crude-oil", amount = 25000})
        end
      end
    },
    {
      condition = story_elapsed_check(0),
      action = function()
        engine.train.speed = 0.05
      end
    },
    {
      condition = story_elapsed_check(4),
    },
    {
      condition = function()
        local target = game.simulation.get_widget_position({type = "quickbar-slot", filter = {name = pump, quality = "normal"}})
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
        return game.simulation.move_cursor({position = {-5.5, 2}})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "rotate", notify = false}
        game.simulation.control_press{control = "rotate", notify = false}
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {-3.5, 2}})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {-1.5, 2}})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {1.5, 2}})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {3.5, 2}})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = function()
        return game.simulation.move_cursor({position = {5.5, 2}})
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },
    {
      condition = story_elapsed_check(3),
      action = function()
        player.character.clear_items_inside()

        -- Delete the boat before the waterway
        for _, entity in pairs(engine.train.carriages) do
          entity.destroy()
        end
        for _, entity in pairs (surface.find_entities_filtered{}) do
          if entity.name ~= "character" then
            entity.destroy()
          end
        end
        load = not load
        story_jump_to(storage.story, "start")
      end
    },
  }
}

tip_story_init(story_table)