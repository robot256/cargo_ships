---@diagnostic disable: undefined-global
require("__core__/lualib/story")

---@diagnostic disable-next-line: unknown-cast-variable
---@cast game LuaGameScript

game.simulation.active_quickbars = 1
local player = game.simulation.create_test_player{name = "Jurgy"}
player.teleport{0.5, 0.5}
player.force.research_all_technologies()
player.set_quick_bar_slot(1, 1, "boat")
player.color = {r = 20, g = 70, b = 255}

game.simulation.camera_player = player
game.simulation.camera_position = {0, 0}
game.simulation.camera_player_cursor_position = player.position
game.simulation.camera_zoom = 1.25

local surface = game.surfaces[1]

local water_tiles = {}
for x = -20, 20, 1 do
  for y = -20, 20, 1 do
    if (y > -2 and y < 2) and (x > -2 and x < 2) then
    else
      table.insert(water_tiles, {name = "water", position={x, y}})
    end
  end
end

surface.set_tiles(water_tiles, true)

local bp = "0eNqd1tuOwiAQBuB3mWtM5NCW9lU2mw0qcUlWaijqGtN3X7Seto4KXFnb8vXPTIEeYPaz0WtnrIfmAGbe2g6ajwN0ZmnVz/GcVSsNDeyU126n9tATMHahf6Gh/ScBbb3xRg+jTn/2X3azmmkXbiCX0fON2+rF5IJMFBBYt10Y2drjQ4I2oQWB/fFXhkcsjNPz4SrryYPMrnLnnTLLb3+1X8lFj1g8z+KYJfIsillFVvVGxZMIXD6FZxjMB5jx922psmT+PrJMgutz4uo/TLHIdYZMR65AXDpNap84R64jIlOaQfOYzInTCs+MyrdJtm6df4GNehbCd14Nx0ABo0VGaB4RuUhxU2pRvqlFTCkYWooqPXJMJWTK+/bkTS4xuE6HI/KyacqcfrJYYHkZTYdpRF6Wwt6tx5jFc6zx4jDFZJHSrLvNHLPS5tbL7ZuVWRZevSrLQrdvJnPqJR86Eb6xjNerwNw+1QhstetOdxQlqwvBhKwrKXio0B+uRj8U"


local indep_boat = nil
local engine = nil
---@cast indep_boat -?
---@cast engine -?

local story_table =
{
  {
    {
      name = "start",
      init = function() end,
      condition = story_elapsed_check(0),
      action = function()
        surface.create_entities_from_blueprint_string
        {
          string = bp,
          position = {8, 0},
          force = player.force
        }
        player.insert({name="boat", count=2})
        player.insert({name="coal", count=50})
      end
    },
    {
      condition = story_elapsed_check(0.25),
    },
    {
      condition = function()
        local target = game.simulation.get_widget_position({type = "quickbar-slot", filter = {name = "boat", quality = "normal"}})
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
      condition = story_elapsed_check(0.5),
    },

    {
      condition = function()
        return game.simulation.move_cursor({position = {-7, 0}})
      end,
    },
    {
      condition = story_elapsed_check(0.5),
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
      end
    },

    {
      condition = function()
        return game.simulation.move_cursor({position = {-3, 0}})
      end,
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        game.simulation.control_press{control = "build", notify = true}
        local engines = surface.find_entities_filtered{area = {{-15, -10}, {15, 10}}, name = "boat_engine"}
        if #engines == 0 then
          error("Boat engine not found")
        end
        engine = engines[1]
        engine.train.manual_mode = false
        engine.train.schedule = {
          current = 1,
          records = {
            {station = "1", wait_conditions = {{type = "time", ticks = 0}}},
            {station = "2", wait_conditions = {{type = "time", ticks = 0}}}
          }
        }
        local inventory = engine.get_fuel_inventory()
        inventory.insert{name="coal", count=50}
      end
    },
    {
      condition = story_elapsed_check(0.25),
      action = function()
        player.clear_cursor()
      end
    },
    {
      condition = story_elapsed_check(0.5),
      action = function()
        game.simulation.control_press{control = "toggle-driving", notify = true}
      end
    },
    {
      condition = story_elapsed_check(0.5),
      action = function()
        indep_boat = surface.find_entities_filtered{name = "indep-boat"}[1]
        indep_boat.riding_state = {acceleration = defines.riding.acceleration.accelerating, direction = defines.riding.direction.right}
      end
    },
    {
      condition = story_elapsed_check(5.8),
      action = function()
        game.simulation.control_press{control = "toggle-driving", notify = false}
      end
    },
    {
      condition = story_elapsed_check(0),
      action = function()
        player.teleport{0.5, 0.5}
        player.character.clear_items_inside()

        ---@cast engine -?
        for _, entity in pairs(engine.train.carriages) do
          entity.destroy()
        end
        for _, entity in pairs (surface.find_entities_filtered{}) do
          if entity.name ~= "character" then
            entity.destroy()
          end
        end
      end
    },
    {
      condition = story_elapsed_check(0),
      action = function()
        story_jump_to(storage.story, "start")
      end
    },
  }
}

tip_story_init(story_table)