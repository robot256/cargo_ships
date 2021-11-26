

local function updateProgress(frame, oilrig)
	local oil_rig_capacity = settings.startup["oil_rig_capacity"].value
	local amount = oilrig.fluidbox[1] and oilrig.fluidbox[1]["amount"] or 0
	frame.oily_progress.value = amount/(oil_rig_capacity*1000)
	frame.oily_caption.caption = {"cargo-ship-gui.oil-rig-progress",math.floor(amount/1000),oil_rig_capacity}
end

function onOilrickGuiOpened(e)
	if e.entity ~= nil and e.entity.name == "oil_rig" then
		local gui = game.players[e.player_index].gui
		if not gui.top.oilStorageFrame then 
			local frame = gui.top.add{type="frame", name="oilStorageFrame", caption={"cargo-ship-gui.oil-rig-storage"}, direction="vertical"}
			--frame.add{type="line", name="line1"}
			frame.add{type="progressbar", name="oily_progress"}
			frame.add{type="label", name="oily_caption", caption={"cargo-ship-gui.oil-rig-progress",0,100}}
			updateProgress(frame, e.entity)
		end
		global.gui_oilrigs[e.player_index] = e.entity
	end
end

function onOilrickGuiClosed(e)
	if e.entity ~= nil and e.entity.name == "oil_rig" then
		deleteOilGui(e.player_index)
	end
end

function deleteOilGui(player_index)
	if not game.players[player_index].gui.top.oilStorageFrame then return end
	game.players[player_index].gui.top.oilStorageFrame.destroy()	
	global.gui_oilrigs[player_index] = nil
end

function UpdateOilRigGui(e)

	if e.tick%5 ~= 0 then return end

	if global.gui_oilrigs == nil then
		global.gui_oilrigs = {}
	end
	
	for i, oilrig in ipairs(global.gui_oilrigs) do
		if not oilrig.valid then
			deleteOilGui(i)
			break
		end
	end
	for i, oilrig in ipairs(global.gui_oilrigs) do
		if oilrig ~= nil then
			local ourframe = game.players[i].gui.top.oilStorageFrame
			if not ourframe then return end
			updateProgress(ourframe, oilrig)
		end
	end
end
