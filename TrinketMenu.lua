
--[[ TrinketMenu 4.0 ]]--

function TrinketMenu.LoadDefaults()

	TrinketMenuOptions = TrinketMenuOptions or {
		IconPos = -100,				-- angle of initial minimap icon position
		ShowIcon = "ON",			-- whether to show the minimap button
		SquareMinimap = "OFF",		-- whether the minimap is square instead of circular
		CooldownCount = "OFF",		-- whether to display numerical cooldown counters
		LargeCooldown = "ON",		-- whether cooldown numbers are large or small
		TooltipFollow = "OFF",		-- whether tooltips follow the mouse
		KeepOpen = "OFF",			-- whether menu hides after use
		KeepDocked = "ON",			-- whether to keep menu docked at all times
		Notify = "OFF",				-- whether a message appears when a trinket is ready
		DisableToggle="OFF",		-- whether minimap button toggles trinkets
		NotifyUsedOnly="OFF",		-- whether notify happens only on trinkets used
		NotifyChatAlso="OFF",		-- whether to send notify to chat also
		Locked = "OFF",				-- whether windows can be moved/scaled/rotated
		ShowTooltips = "ON",		-- whether to display tooltips at all
		NotifyThirty = "OFF",		-- whether to notify cooldowns at 30 seconds instead of 0
		MenuOnShift = "OFF",		-- whether menu requires Shift to display
		TinyTooltips = "OFF",		-- whether tooltips display only name and cooldown
		SetColumns = "OFF",			-- whether number of columns in menu is chosen automatically
		Columns = 4,				-- if SetColumns "ON", number of columns before menu wraps
		ShowHotKeys = "OFF",		-- whether hotkeys show on trinkets
		StopOnSwap = "OFF",			-- whether to stop auto queue on all manual swaps
		MenuSorting = "Bag Position",	-- how to sort trinkets in menu
		MenuShowHiddenOnShift = "ON",	-- whether to show hidden trinkets when shift is held
		ProfileZoneWarnings = "ON"		-- whether to show profile zone change warnings
	}

	TrinketMenuPerOptions = TrinketMenuPerOptions or {
		MainDock = "BOTTOMRIGHT",	-- corner of main window docked to
		MenuDock = "BOTTOMLEFT",	-- corner menu window is docked from
		MainOrient = "HORIZONTAL",	-- direction of main window
		MenuOrient = "VERTICAL",	-- direction of menu window
		XPos = 400,					-- left edge of main window
		YPos = 400,					-- top edge of main window
		MainScale = 1,				-- scaling of main window
		MenuScale = 1,				-- scaling of menu window
		Visible="ON",				-- whether to display the trinkets
		FirstUse = true,			-- whether this is the first time this user has used the mod
		ItemsUsed = {},				-- table of trinkets used and their cooldown status
	}
end

--[[ Misc Variables ]]--

TrinketMenu_Version = 4.0
BINDING_HEADER_TRINKETMENU = "TrinketMenu"

TrinketMenu.MaxTrinkets = 30 -- add more to TrinketMenu_MenuFrame if this changes
TrinketMenu.BaggedTrinkets = {} -- indexed by number, 1-30 of trinkets in the menu
TrinketMenu.NumberOfTrinkets = 0 -- number of trinkets in the menu
TrinketMenu.CombatQueue = {} -- [0] or [1] = name of trinket queued for slot 0 or 1
TrinketMenu.Corners = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }
TrinketMenu.WatchItem = {} -- table of items being watched for cooldowns
TrinketMenu.IconPath = "Interface\\Icons\\"

--[[ Helpers for new API ]]--

function TrinketMenu.UpdateTrinketList()
	local trinkets = GetTrinkets and GetTrinkets() or {}
	local equipped = TrinketMenu.EquippedTrinkets or {}

	if type(trinkets) ~= "table" then
		TrinketMenu.TrinketListSize = 0
		TrinketMenu.TrinketList = {}
		TrinketMenu.EquippedTrinketListSize = 0
		for i = 1, table.getn(equipped) do
			equipped[i] = nil
		end
		TrinketMenu.EquippedTrinkets = equipped
		return TrinketMenu.TrinketList
	end

	TrinketMenu.TrinketListSize = table.getn(trinkets)
	TrinketMenu.TrinketList = trinkets
	for _, trinket in ipairs(trinkets) do
		trinket.icon = "Interface\\Icons\\" .. trinket.texture
		if trinket.bagIndex == nil then
			equipped[trinket.slotIndex] = trinket
		end
	end
	TrinketMenu.EquippedTrinkets = equipped
	return trinkets
end

function TrinketMenu.GetTrinketList()
	return TrinketMenu.TrinketList or {}
end

function TrinketMenu.SlotIndexToInv(slotIndex)
	if slotIndex == 1 or slotIndex == 13 then
		return 13
	elseif slotIndex == 2 or slotIndex == 14 then
		return 14
	end
end

function TrinketMenu.GetEquippedTrinket(slot)
	if TrinketMenu.EquippedTrinkets and TrinketMenu.EquippedTrinkets[slot] then
		return TrinketMenu.EquippedTrinkets[slot]
	end
	return nil
end

-- returns start, duration, enable
function TrinketMenu.GetTrinketCooldownForSlot(bag, slot)
	if bag then
		return GetContainerItemCooldown(bag, slot)
	else
		return GetInventoryItemCooldown("player", slot)
	end
end

--[[ Local functions ]]--

-- dock-dependant offset and directions: MainDock..MenuDock
-- x/yoff   = offset MenuFrame is positioned to MainFrame
-- x/ydir   = direction trinkets are added to menu
-- x/ystart = starting offset when building a menu, relativePoint MenuDock
TrinketMenu.DockStats = { ["TOPRIGHTTOPLEFT"] =		 { xoff=-4, yoff=0,  xdir=1,  ydir=-1, xstart=8,   ystart=-8 },
					 ["BOTTOMRIGHTBOTTOMLEFT"] = { xoff=-4, yoff=0,  xdir=1,  ydir=1,  xstart=8,   ystart=44 },
					 ["TOPLEFTTOPRIGHT"] =		 { xoff=4,  yoff=0,  xdir=-1, ydir=-1, xstart=-44, ystart=-8 },
					 ["BOTTOMLEFTBOTTOMRIGHT"] = { xoff=4,  yoff=0,  xdir=-1, ydir=1,  xstart=-44, ystart=44 },
					 ["TOPRIGHTBOTTOMRIGHT"] =   { xoff=0,  yoff=-4, xdir=-1, ydir=1,  xstart=-44,  ystart=44 },
					 ["BOTTOMRIGHTTOPRIGHT"] =   { xoff=0,  yoff=4,	 xdir=-1, ydir=-1, xstart=-44,  ystart=-8 },
					 ["TOPLEFTBOTTOMLEFT"] =	 { xoff=0,  yoff=-4, xdir=1,  ydir=1,  xstart=8,   ystart=44 },
					 ["BOTTOMLEFTTOPLEFT"] =	 { xoff=0,  yoff=4,  xdir=1,  ydir=-1, xstart=8,   ystart=-8 } }

-- returns offset and direction depending on current docking. ie: TrinketMenu.DockInfo("xoff")
function TrinketMenu.DockInfo(arg1)
	local anchor = TrinketMenuPerOptions.MainDock..TrinketMenuPerOptions.MenuDock
	if TrinketMenu.DockStats[anchor] and arg1 and TrinketMenu.DockStats[anchor][arg1] then
		return TrinketMenu.DockStats[anchor][arg1]
	else
		return 0
	end
end

-- hide the docking markers
function TrinketMenu.ClearDocking()
	for i=1,4 do
		getglobal("TrinketMenu_MainDock_"..TrinketMenu.Corners[i]):Hide()
		getglobal("TrinketMenu_MenuDock_"..TrinketMenu.Corners[i]):Hide()
	end
end

-- returns true if the two values are close to each other
function TrinketMenu.Near(arg1,arg2)
	return (math.max(arg1,arg2)-math.min(arg1,arg2))<15
end

-- moves the MenuFrame to the dock position against MainFrame
function TrinketMenu.DockWindows()
	TrinketMenu.ClearDocking()
	if TrinketMenuOptions.KeepDocked=="ON" then
		TrinketMenu_MenuFrame:ClearAllPoints()
		if TrinketMenuOptions.Locked=="OFF" then
			TrinketMenu_MenuFrame:SetPoint(TrinketMenuPerOptions.MenuDock,"TrinketMenu_MainFrame",TrinketMenuPerOptions.MainDock,TrinketMenu.DockInfo("xoff"),TrinketMenu.DockInfo("yoff"))
		else
			TrinketMenu_MenuFrame:SetPoint(TrinketMenuPerOptions.MenuDock,"TrinketMenu_MainFrame",TrinketMenuPerOptions.MainDock,TrinketMenu.DockInfo("xoff")*3,TrinketMenu.DockInfo("yoff")*3)
		end
	end
	if TrinketMenu_MenuFrame:IsVisible() then
		TrinketMenu.BuildMenu()
	end
end

-- displays windows vertically or horizontally
function TrinketMenu.OrientWindows()
	if TrinketMenuPerOptions.MainOrient=="HORIZONTAL" then
		TrinketMenu_MainFrame:SetWidth(92)
		TrinketMenu_MainFrame:SetHeight(52)
	else
		TrinketMenu_MainFrame:SetWidth(52)
		TrinketMenu_MainFrame:SetHeight(92)
	end
end

-- scan inventory and build MenuFrame
function TrinketMenu.BuildMenu()
	if not IsShiftKeyDown() and TrinketMenuOptions.MenuOnShift=="ON" then
		return
	end

	local idx,i,j,k,texture = 1
	local trinkets = TrinketMenu.GetTrinketList()
	local baggedTrinkets = {}

	-- go through bags and gather trinkets into temporary table
	for _, trinket in ipairs(trinkets) do
		if trinket.bagIndex ~= nil then
			-- Check if trinket is hidden
			local stats = TrinketMenuQueue and TrinketMenuQueue.Stats and TrinketMenuQueue.Stats[trinket.itemId]
			local isHidden = stats and stats.hide
			local showHidden = IsShiftKeyDown() and TrinketMenuOptions.MenuShowHiddenOnShift == "ON"

			if not isHidden or showHidden then
				local entry = {}
				entry.bag = trinket.bagIndex
				entry.slot = trinket.slotIndex
				entry.name = trinket.trinketName or "Unknown"
				entry.itemId = trinket.itemId
				entry.icon = trinket.icon
				entry.itemLevel = trinket.itemLevel or 0
				table.insert(baggedTrinkets, entry)
			end
		end
	end

	-- Sort trinkets based on MenuSorting option
	if TrinketMenuOptions.MenuSorting == "Alphabetical" then
		table.sort(baggedTrinkets, function(a, b)
			return a.name < b.name
		end)
	elseif TrinketMenuOptions.MenuSorting == "Item Level" then
		table.sort(baggedTrinkets, function(a, b)
			if a.itemLevel == b.itemLevel then
				return a.name < b.name
			end
			return a.itemLevel > b.itemLevel
		end)
	end
	-- If "Bag Position", no sorting needed - already in bag order

	-- Copy sorted trinkets into .BaggedTrinkets
	for i, entry in ipairs(baggedTrinkets) do
		if not TrinketMenu.BaggedTrinkets[i] then
			TrinketMenu.BaggedTrinkets[i] = {}
		end
		TrinketMenu.BaggedTrinkets[i].bag = entry.bag
		TrinketMenu.BaggedTrinkets[i].slot = entry.slot
		TrinketMenu.BaggedTrinkets[i].name = entry.name
		TrinketMenu.BaggedTrinkets[i].itemId = entry.itemId
		TrinketMenu.BaggedTrinkets[i].icon = entry.icon
	end
	TrinketMenu.NumberOfTrinkets = math.min(table.getn(baggedTrinkets),TrinketMenu.MaxTrinkets)

	if TrinketMenu.NumberOfTrinkets<1 then
		-- user has no bagged trinkets :(
		TrinketMenu_MenuFrame:Hide()
	else
		-- display trinkets outward from docking point
		local col,row,xpos,ypos = 0,0,TrinketMenu.DockInfo("xstart"),TrinketMenu.DockInfo("ystart")
		local max_cols = 1

		if TrinketMenu.NumberOfTrinkets>24 then
			max_cols = 5
		elseif TrinketMenu.NumberOfTrinkets>18 then
			max_cols = 4
		elseif TrinketMenu.NumberOfTrinkets>12 then
			max_cols = 3
		elseif TrinketMenu.NumberOfTrinkets>4 then
			max_cols = 2
		end
		if TrinketMenuOptions.SetColumns=="ON" and TrinketMenuOptions.Columns then
			max_cols = TrinketMenuOptions.Columns
		end

		for i=1,TrinketMenu.NumberOfTrinkets do
			local item = getglobal("TrinketMenu_Menu"..i)
			getglobal("TrinketMenu_Menu" .. i .. "Icon"):SetTexture(TrinketMenu.BaggedTrinkets[i].icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			item:SetPoint("TOPLEFT","TrinketMenu_MenuFrame",TrinketMenuPerOptions.MenuDock,xpos,ypos)

			if TrinketMenuPerOptions.MenuOrient=="VERTICAL" then
				xpos = xpos + TrinketMenu.DockInfo("xdir")*40
				col = col + 1
				if col==max_cols then
					xpos = TrinketMenu.DockInfo("xstart")
					col = 0
					ypos = ypos + TrinketMenu.DockInfo("ydir")*40
					row = row + 1
				end
				item:Show()
			else
				ypos = ypos + TrinketMenu.DockInfo("ydir")*40
				col = col + 1
				if col==max_cols then
					ypos = TrinketMenu.DockInfo("ystart")
					col = 0
					xpos = xpos + TrinketMenu.DockInfo("xdir")*40
					row = row + 1
				end
				item:Show()
			end
		end
		for i=(TrinketMenu.NumberOfTrinkets+1),TrinketMenu.MaxTrinkets do
			getglobal("TrinketMenu_Menu"..i):Hide()
		end
		if col==0 then
			row = row-1
		end

		if TrinketMenuPerOptions.MenuOrient=="VERTICAL" then
			TrinketMenu_MenuFrame:SetWidth(12+(max_cols*40))
			TrinketMenu_MenuFrame:SetHeight(12+((row+1)*40))
		else
			TrinketMenu_MenuFrame:SetWidth(12+((row+1)*40))
			TrinketMenu_MenuFrame:SetHeight(12+(max_cols*40))
		end
		TrinketMenu.UpdateMenuCooldowns()
		TrinketMenu_MenuFrame:Show()
		TrinketMenu.StartTimer("MenuMouseover")
	end

end

function TrinketMenu.Initialize()

	local options = TrinketMenuOptions
	options.KeepDocked = options.KeepDocked or "ON" -- new option for 2.1
	options.Notify = options.Notify or "OFF" -- 2.1
	options.DisableToggle = options.DisableToggle or "OFF" -- new option for 2.2
	options.NotifyUsedOnly = options.NotifyUsedOnly or "OFF" -- 2.2
	options.NotifyChatAlso = options.NotifyChatAlso or "OFF" -- 2.2
	options.ShowTooltips = options.ShowTooltips or "ON" -- 2.3
	options.NotifyThirty = options.NotifyThirty or "OFF" -- 2.5
	options.SquareMinimap = options.SquareMinimap or "OFF" -- 2.6
	options.MenuOnShift = options.MenuOnShift or "OFF" -- 2.6
	options.TinyTooltips = options.TinyTooltips or "OFF" -- 3.0
	options.SetColumns = options.SetColumns or "OFF" -- 3.0
	options.Columns = options.Columns or 4 -- 3.0
	options.LargeCooldown = options.LargeCooldown or "OFF" -- 3.0
	options.ShowHotKeys = options.ShowHotKeys or "OFF" -- 3.0
	TrinketMenuPerOptions.ItemsUsed = TrinketMenuPerOptions.ItemsUsed or {} -- 3.0
	options.StopOnSwap = options.StopOnSwap or "OFF" -- 3.2
	options.HideOnLoad = options.HideOnLoad or "OFF" -- 3.4
	options.HideProfileText = options.HideProfileText or "OFF" -- 4.0
	options.MenuSorting = options.MenuSorting or "Bag Position" -- 4.0
	options.MenuShowHiddenOnShift = options.MenuShowHiddenOnShift or "ON" -- 4.0
	options.ProfileZoneWarnings = options.ProfileZoneWarnings or "ON" -- 4.0

	if TrinketMenuPerOptions.XPos and TrinketMenuPerOptions.YPos then
		TrinketMenu_MainFrame:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",TrinketMenuPerOptions.XPos,TrinketMenuPerOptions.YPos)
	end
	if TrinketMenuPerOptions.MainScale then
		TrinketMenu_MainFrame:SetScale(TrinketMenuPerOptions.MainScale)
	end
	if TrinketMenuPerOptions.MenuScale then
		TrinketMenu_MenuFrame:SetScale(TrinketMenuPerOptions.MenuScale)
	end

	TrinketMenu.InitTimers()
	TrinketMenu.CreateTimer("UpdateWornTrinkets",TrinketMenu.UpdateWornTrinkets,.75)
	TrinketMenu.CreateTimer("DockingMenu",TrinketMenu.DockingMenu,.2,1)
	TrinketMenu.CreateTimer("MenuMouseover",TrinketMenu.MenuMouseover,.25,1)
	TrinketMenu.CreateTimer("Scaling",TrinketMenu.Scaling,.1,1)
	TrinketMenu.CreateTimer("TooltipUpdate",TrinketMenu.TooltipUpdate,1,1)
	TrinketMenu.CreateTimer("CooldownUpdate",TrinketMenu.CooldownUpdate,1,1)
	TrinketMenu.CreateTimer("AutoSwapQueueOff0",TrinketMenu.AutoSwapQueueOff0,1)
	TrinketMenu.CreateTimer("AutoSwapQueueOff1",TrinketMenu.AutoSwapQueueOff1,1)

	TrinketMenu.CreateTimer("UpdateTrinketList", TrinketMenu.UpdateTrinketList, .2)
	TrinketMenu.CreateTimer("DebouncedInventoryChanged", TrinketMenu.DebouncedInventoryChanged, .25)

	TrinketMenu.AutoSwapQueuePending = TrinketMenu.AutoSwapQueuePending or {}

	TrinketMenu.InitOptions()

	TrinketMenu.UpdateWornTrinkets()
	TrinketMenu.DockWindows()
	TrinketMenu.OrientWindows()

	TrinketMenu.StartTimer("CooldownUpdate")

	if TrinketMenuPerOptions.Visible=="ON" and (GetInventoryItemLink("player",13) or GetInventoryItemLink("player",14)) then
		TrinketMenu_MainFrame:Show()
	end
end

-- returns true if the player is really dead or ghost, not merely FD
function TrinketMenu.IsPlayerReallyDead()
	local dead = UnitIsDeadOrGhost("player")
	for i=1,32 do
		if UnitBuff("player", i) == TrinketMenu.IconPath .. "Ability_Rogue_FeignDeath" then
			dead = nil
		end
	end
	return dead
end

function TrinketMenu.FindPlayerItemSlot(itemIdOrName, bagsOnly)
	if not itemIdOrName or not FindPlayerItemSlot then
		return
	end
	local bag, slot = FindPlayerItemSlot(itemIdOrName)
	if bagsOnly and bag == nil then
		return
	end
	return bag, slot
end

function TrinketMenu.FindItem(name,includeInventory)
	local bag, slot = TrinketMenu.FindPlayerItemSlot(name, not includeInventory)
	return bag, slot
end

--[[ Frame Scripts ]]--

function TrinketMenu.OnLoad()

	SlashCmdList["TrinketMenuCOMMAND"] = TrinketMenu.SlashHandler
	SLASH_TrinketMenuCOMMAND1 = "/trinketmenu";
	SLASH_TrinketMenuCOMMAND2 = "/trinket";
	
	this:RegisterEvent("ADDON_LOADED")
end

function TrinketMenu.OnEvent()
	if event=="BAG_UPDATE" then
		if arg1>=0 and arg1<=4 then
			TrinketMenu.BagsNeedUpdating[arg1] = 1
		end
		TrinketMenu.StartTimer("UpdateTrinketList")
		TrinketMenu.StartTimer("UpdateBaggedTrinkets")
	elseif event=="UNIT_INVENTORY_CHANGED" and arg1=="player" then
		TrinketMenu.StartTimer("UpdateTrinketList")
		TrinketMenu.StartTimer("DebouncedInventoryChanged")
	elseif event=="ACTIONBAR_UPDATE_COOLDOWN" then
		TrinketMenu.UpdateWornCooldowns(1)
	elseif (event=="PLAYER_REGEN_ENABLED" or event=="PLAYER_UNGHOST" or event=="PLAYER_ALIVE") and not TrinketMenu.IsPlayerReallyDead() then
		-- trinkets can now be swapped after combat/death
		if TrinketMenu.CombatQueue[0] or TrinketMenu.CombatQueue[1] then
			TrinketMenu.EquipTrinketByName(TrinketMenu.CombatQueue[0],13)
			TrinketMenu.EquipTrinketByName(TrinketMenu.CombatQueue[1],14)
			TrinketMenu.CombatQueue[0] = nil
			TrinketMenu.CombatQueue[1] = nil
			TrinketMenu.UpdateCombatQueue()
		end
		if event == "PLAYER_REGEN_ENABLED" then
			TrinketMenu.AutoSwapQueueScheduleOff()
		end
	elseif event=="UPDATE_BINDINGS" then
		TrinketMenu.ReflectKeyBindings()
	elseif event == "SPELL_CAST_EVENT" then
		local success, spellId, castType, targetGuid, itemId = arg1, arg2, arg3, arg4, arg5
		if success == 1 and itemId and itemId > 0 then
			-- Check cached equipped trinkets
			local trinket13 = TrinketMenu.GetEquippedTrinket(13)
			local trinket14 = TrinketMenu.GetEquippedTrinket(14)

			if trinket13 and trinket13.itemId == itemId then
				TrinketMenu.ReflectTrinketUse(13)
			elseif trinket14 and trinket14.itemId == itemId then
				TrinketMenu.ReflectTrinketUse(14)
			end
		end
	elseif event == "UNIT_DIED" then
		local guid = arg1
		if guid and TrinketMenu.PackProfileGuidTrinkets and TrinketMenuQueue and TrinketMenuQueue.PackProfileActive then
			local trinketData = TrinketMenu.PackProfileGuidTrinkets[guid]
			if trinketData then
				if trinketData.trinket1 == "autoswap" then
					TrinketMenu.EnableAutoSwapQueue(0)
				elseif trinketData.trinket1 then
					TrinketMenu.EquipTrinketByName(trinketData.trinket1, 13)
				end
				if trinketData.trinket2 == "autoswap" then
					TrinketMenu.EnableAutoSwapQueue(1)
				elseif trinketData.trinket2 then
					TrinketMenu.EquipTrinketByName(trinketData.trinket2, 14)
				end
			end
		end
	elseif event=="ADDON_LOADED" then
		TrinketMenu.LoadDefaults()
		TrinketMenu.UpdateTrinketList()

		TrinketMenu.Initialize()
		if TrinketMenuQueue and TrinketMenuQueue.PackProfileActive and TrinketMenuQueue.PackProfiles then
			local profile = TrinketMenuQueue.PackProfiles[TrinketMenuQueue.PackProfileActive]
			if profile then
				TrinketMenu.ApplyPackProfileActivation(profile)
			end
		end
		this:RegisterEvent("PLAYER_REGEN_ENABLED")
		this:RegisterEvent("PLAYER_UNGHOST")
		this:RegisterEvent("PLAYER_ALIVE")
		this:RegisterEvent("UNIT_INVENTORY_CHANGED")
		this:RegisterEvent("UPDATE_BINDINGS")
		this:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		this:RegisterEvent("SPELL_CAST_EVENT")
		this:RegisterEvent("UNIT_DIED")
		this:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		this:RegisterEvent("PLAYER_TARGET_CHANGED")
	elseif event=="ZONE_CHANGED_NEW_AREA" then
		TrinketMenu.CheckZoneProfile()
  elseif event=="PLAYER_TARGET_CHANGED" then
		if not TrinketMenuQueue or not TrinketMenuQueue.PackProfileActive then
			return
		end
		local trinketData = nil
		if UnitGUID then
			local guid = UnitGUID("target")
			if guid and TrinketMenu.PackProfileTargetGuidTrinkets then
				trinketData = TrinketMenu.PackProfileTargetGuidTrinkets[guid]
			end
		end
		if trinketData then
			if trinketData.trinket1 == "autoswap" then
				TrinketMenu.EnableAutoSwapQueue(0)
			elseif trinketData.trinket1 then
				TrinketMenu.EquipTrinketByName(trinketData.trinket1, 13)
			end
			if trinketData.trinket2 == "autoswap" then
				TrinketMenu.EnableAutoSwapQueue(1)
			elseif trinketData.trinket2 then
				TrinketMenu.EquipTrinketByName(trinketData.trinket2, 14)
			end
		end
	end
end

function TrinketMenu.UpdateActiveProfileText()
	if not TrinketMenu_ProfileText then
		return
	end
	if TrinketMenuOptions.HideProfileText == "ON" then
		TrinketMenu_ProfileText:Hide()
		if TrinketMenu_ProfileTextButton then
			TrinketMenu_ProfileTextButton:Hide()
		end
		return
	end
	local text = "No Profile"
	if TrinketMenuQueue and TrinketMenuQueue.PackProfileActive and TrinketMenuQueue.PackProfiles then
		local profile = TrinketMenuQueue.PackProfiles[TrinketMenuQueue.PackProfileActive]
		if profile and profile.name then
			text = profile.name
		end
	end
	TrinketMenu_ProfileText:SetText(text)
	TrinketMenu_ProfileText:Show()
	if TrinketMenu_ProfileTextButton then
		TrinketMenu_ProfileTextButton:Show()
	end
end

function TrinketMenu.ProfileText_OnClick()
	if arg1 == "RightButton" then
		if TrinketMenu_OptFrame:IsVisible() and TrinketMenu_ProfilesTabFrame and TrinketMenu_ProfilesTabFrame:IsVisible() then
			TrinketMenu_OptFrame:Hide()
		else
			if not TrinketMenu_OptFrame:IsVisible() then
				TrinketMenu_OptFrame:Show()
			end
			TrinketMenu.Tab_OnClick(4)
		end
	end
end

function TrinketMenu.CheckZoneProfile()
	if not TrinketMenuQueue or not TrinketMenuQueue.PackProfiles then
		return
	end

	local currentZone = GetRealZoneText()
	if not currentZone or currentZone == "" then
		return
	end

	if currentZone == "Outland" or currentZone =="The Rock of Desolation" then
		currentZone = "Tower of Karazhan"
	end

	-- Helper to strip " -.*" suffix from profile raid names for comparison
	local function stripRaidSuffix(name)
		if not name then return name end
		return name:gsub(" %-.*", "")
	end

	-- Check if we already have an active profile
	local currentActiveProfile = TrinketMenuQueue.PackProfileActive

	-- First check if the current active profile matches the zone
	if currentActiveProfile and TrinketMenuQueue.PackProfiles[currentActiveProfile] then
		local activeProfile = TrinketMenuQueue.PackProfiles[currentActiveProfile]
		if stripRaidSuffix(activeProfile.raid) == currentZone then
			TrinketMenu.ApplyOnEnterPack(activeProfile, currentZone)
			-- Current active profile matches zone, no need to suggest anything
			return
		end
	end

	-- Check if warnings are enabled
	if TrinketMenuOptions.ProfileZoneWarnings ~= "ON" then
		return
	end

	-- Look for a profile matching the current zone
	for i, profile in ipairs(TrinketMenuQueue.PackProfiles) do
		if profile and profile.raid and stripRaidSuffix(profile.raid) == currentZone then
			-- Found a matching profile that's not currently active
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TrinketMenu:|r Your current profile does not match this raid.  Found profile '" .. profile.name .. "' for " .. currentZone .. ". Type |cffff8800/trinket activate " .. profile.name .. "|r to activate it.")
			return
		end
	end
end

function TrinketMenu.ApplyOnEnterPack(profile, zone)
	if not profile or not profile.packDeathTrinkets then
		return
	end
	local onEnter = profile.packDeathTrinkets["on_enter"]
	if not onEnter or (not onEnter.trinket1 and not onEnter.trinket2) then
		return
	end
	TrinketMenu.OnEnterUsed = TrinketMenu.OnEnterUsed or {}
	if TrinketMenu.OnEnterUsed[zone] then
		return
	end
	TrinketMenu.OnEnterUsed[zone] = true
	if onEnter.trinket1 == "autoswap" then
		TrinketMenu.EnableAutoSwapQueue(0)
	elseif onEnter.trinket1 then
		TrinketMenu.EquipTrinketByName(onEnter.trinket1, 13)
	end
	if onEnter.trinket2 == "autoswap" then
		TrinketMenu.EnableAutoSwapQueue(1)
	elseif onEnter.trinket2 then
		TrinketMenu.EquipTrinketByName(onEnter.trinket2, 14)
	end
end

function TrinketMenu.UpdatePackProfileUI()
	TrinketMenu.PackProfileScrollFrameUpdate()
	if TrinketMenu.PackProfileValidateButtons then
		TrinketMenu.PackProfileValidateButtons()
	end
end

function TrinketMenu.SetActivePackProfile(idx)
	if not TrinketMenuQueue or not TrinketMenuQueue.PackProfiles then
		return
	end
	local profile = TrinketMenuQueue.PackProfiles[idx]
	if not profile then
		return
	end
	if TrinketMenuQueue.PackProfileActive and TrinketMenuQueue.PackProfileActive ~= idx then
		TrinketMenuQueue.PackProfileLast = TrinketMenuQueue.PackProfileActive
	end
	TrinketMenuQueue.PackProfileActive = idx
	TrinketMenu.ApplyPackProfileActivation(profile)
	TrinketMenu.UpdatePackProfileUI()
end

function TrinketMenu.ClearActivePackProfile()
	if not TrinketMenuQueue or not TrinketMenuQueue.PackProfileActive then
		return
	end
	TrinketMenuQueue.PackProfileLast = TrinketMenuQueue.PackProfileActive
	TrinketMenuQueue.PackProfileActive = nil
	TrinketMenu.PackProfileGuidTrinkets = {}
	TrinketMenu.PackProfileTargetGuidTrinkets = {}
	TrinketMenu.UpdateActiveProfileText()
	TrinketMenu.UpdatePackProfileUI()
end

function TrinketMenu.AdjustPackProfileIndexesAfterDelete(idx)
	if not TrinketMenuQueue or not idx then
		return
	end
	if TrinketMenuQueue.PackProfileActive == idx then
		TrinketMenuQueue.PackProfileActive = nil
		TrinketMenu.PackProfileGuidTrinkets = {}
	elseif TrinketMenuQueue.PackProfileActive and TrinketMenuQueue.PackProfileActive > idx then
		TrinketMenuQueue.PackProfileActive = TrinketMenuQueue.PackProfileActive - 1
	end
	if TrinketMenuQueue.PackProfileLast == idx then
		TrinketMenuQueue.PackProfileLast = nil
	elseif TrinketMenuQueue.PackProfileLast and TrinketMenuQueue.PackProfileLast > idx then
		TrinketMenuQueue.PackProfileLast = TrinketMenuQueue.PackProfileLast - 1
	end
end

function TrinketMenu.ToggleActivePackProfile()
	if not TrinketMenuQueue then
		return
	end
	if TrinketMenuQueue.PackProfileActive then
		TrinketMenu.ClearActivePackProfile()
		return
	end
	if TrinketMenuQueue.PackProfileLast then
		TrinketMenu.SetActivePackProfile(TrinketMenuQueue.PackProfileLast)
	end
end

function TrinketMenu.ReactivateLastPackProfile()
	if not TrinketMenuQueue or not TrinketMenuQueue.PackProfileLast then
		return
	end
	if TrinketMenuQueue.PackProfileActive == TrinketMenuQueue.PackProfileLast then
		return
	end
	TrinketMenu.SetActivePackProfile(TrinketMenuQueue.PackProfileLast)
end

function TrinketMenu.ToggleLastPackProfile()
	if not TrinketMenuQueue or not TrinketMenuQueue.PackProfileLast then
		return
	end
	if TrinketMenuQueue.PackProfileActive == TrinketMenuQueue.PackProfileLast then
		TrinketMenu.ClearActivePackProfile()
	else
		TrinketMenu.SetActivePackProfile(TrinketMenuQueue.PackProfileLast)
	end
end

function TrinketMenu.EditActivePackProfile()
	if not TrinketMenuQueue or not TrinketMenuQueue.PackProfiles then
		return
	end
	local idx = TrinketMenuQueue.PackProfileActive
	if not idx or not TrinketMenuQueue.PackProfiles[idx] then
		return
	end
	if TrinketMenu_OptFrame then
		TrinketMenu_OptFrame:Show()
	end
	if TrinketMenu.Tab_OnClick then
		TrinketMenu.Tab_OnClick(4)
	end
	TrinketMenu.PackProfileSelected = idx
	TrinketMenu.UpdatePackProfileUI()
	TrinketMenu.ProfileEditIndex = idx
	if TrinketMenu_ProfileCreateFrame then
		TrinketMenu_ProfileCreateFrame:Show()
	end
end

function TrinketMenu.EnableAutoSwapQueue(which)
	if not TrinketMenuQueue then
		return
	end
	TrinketMenuQueue.Enabled[which] = 1
	TrinketMenu.AutoSwapQueuePending = TrinketMenu.AutoSwapQueuePending or {}
	TrinketMenu.AutoSwapQueuePending[which] = true
	TrinketMenu.ReflectQueueEnabled()
	TrinketMenu.UpdateCombatQueue()
	if not UnitAffectingCombat("player") then
		TrinketMenu.StartTimer("AutoSwapQueueOff" .. which, 1)
	end
end

function TrinketMenu.ToggleAutoSwapQueue(which)
	if TrinketMenu.QueueInit then
		TrinketMenu.QueueInit()
	end
	if not TrinketMenuQueue then
		return
	end
	if TrinketMenuQueue.Enabled[which] then
		TrinketMenu.CombatQueue[which] = nil
		TrinketMenuQueue.Enabled[which] = nil
	else
		TrinketMenuQueue.Enabled[which] = 1
	end
	TrinketMenu.ReflectQueueEnabled()
	TrinketMenu.UpdateCombatQueue()
end

function TrinketMenu.AutoSwapQueueOff(which)
	if TrinketMenu.AutoSwapQueuePending and TrinketMenu.AutoSwapQueuePending[which] then
		TrinketMenu.AutoSwapQueuePending[which] = nil
		if TrinketMenuQueue then
			TrinketMenuQueue.Enabled[which] = nil
			TrinketMenu.ReflectQueueEnabled()
			TrinketMenu.UpdateCombatQueue()
		end
	end
end

function TrinketMenu.AutoSwapQueueOff0()
	TrinketMenu.AutoSwapQueueOff(0)
end

function TrinketMenu.AutoSwapQueueOff1()
	TrinketMenu.AutoSwapQueueOff(1)
end

function TrinketMenu.AutoSwapQueueScheduleOff()
	if UnitAffectingCombat("player") then
		return
	end
	for which in pairs(TrinketMenu.AutoSwapQueuePending or {}) do
		TrinketMenu.StartTimer("AutoSwapQueueOff" .. which, 1)
	end
end

function TrinketMenu.DebouncedInventoryChanged()
	TrinketMenu.UpdateWornTrinkets()
end

function TrinketMenu.UpdateWornTrinkets()
	local trinket13 = TrinketMenu.GetEquippedTrinket(13)
	local trinket14 = TrinketMenu.GetEquippedTrinket(14)

	if trinket13 then
		local texture13 = trinket13.icon or GetInventoryItemTexture("player", 13)
		TrinketMenu_Trinket0Icon:SetTexture(texture13 or "Interface\\Icons\\INV_Misc_QuestionMark")
		TrinketMenu.AddWatchItem(trinket13.trinketName, trinket13.slotIndex)

    local cdData1 = GetTrinketCooldown(1)
    if cdData1 and cdData1.cooldownRemainingMs and cdData1.itemActiveSpellId > 0 then
      TrinketMenuPerOptions.ItemsUsed[trinket13.trinketName] = cdData1.cooldownRemainingMs
    end
	else
		texture13 = nil
	end

	if trinket14 then
		local texture14 = trinket14.icon or GetInventoryItemTexture("player", 14)
		TrinketMenu_Trinket1Icon:SetTexture(texture14 or "Interface\\Icons\\INV_Misc_QuestionMark")
		TrinketMenu.AddWatchItem(trinket14.trinketName, trinket14.slotIndex)

    local cdData2 = GetTrinketCooldown(2)
    if cdData2 and cdData2.cooldownRemainingMs and cdData2.itemActiveSpellId > 0 then
      TrinketMenuPerOptions.ItemsUsed[trinket14.trinketName] = cdData2.cooldownRemainingMs
    end
	else
		texture14 = nil
	end

	TrinketMenu_Trinket0Icon:SetDesaturated(0)
	TrinketMenu_Trinket0:SetChecked(0)
	TrinketMenu_Trinket1Icon:SetDesaturated(0)
	TrinketMenu_Trinket1:SetChecked(0)
	TrinketMenu.UpdateWornCooldowns()

	if TrinketMenu_MenuFrame:IsVisible() then
		TrinketMenu.BuildMenu()
	end
end

function TrinketMenu.SlashHandler(msg)

	local _,_,which,profile = string.find(msg,"load (.+) (.+)")

	if profile and TrinketMenu.SetQueue then
		which = string.lower(which)
		if which=="top" or which=="0" then
			which = 0
		elseif which=="bottom" or which=="1" then
			which = 1
		end
		if type(which)=="number" then
			TrinketMenu.SetQueue(which,"SORT",profile)
			local slot = which == 0 and "top" or "bottom"
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TrinketMenu:|r Loaded autoswap profile '" .. profile .. "' for " .. slot .. " trinket")
			return
		end
	end

	msg = string.lower(msg)

	if not msg or msg=="" then
		TrinketMenu.ToggleFrame(TrinketMenu_MainFrame)
	elseif string.find(msg,"^opt") or string.find(msg,"^config") then
		TrinketMenu.ToggleFrame(TrinketMenu_OptFrame)
	elseif msg=="lock" then
		TrinketMenuOptions.Locked="ON"
		TrinketMenu.DockWindows()
		TrinketMenu.ReflectLock()
	elseif msg=="unlock" then
		TrinketMenuOptions.Locked="OFF"
		TrinketMenu.DockWindows()
		TrinketMenu.ReflectLock()
	elseif msg=="reset" then
		TrinketMenu.ResetSettings()
	elseif string.find(msg,"scale") then
		local _,_,menuscale = string.find(msg,"scale menu (.+)")
		if tonumber(menuscale) then
			TrinketMenu.FrameToScale = TrinketMenu_MenuFrame
			TrinketMenu.ScaleFrame(menuscale)
		end
		local _,_,mainscale = string.find(msg,"scale main (.+)")
		if tonumber(mainscale) then
			TrinketMenu.FrameToScale = TrinketMenu_MainFrame
			TrinketMenu.ScaleFrame(mainscale)
		end
		if not tonumber(menuscale) and not tonumber(mainscale) then
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00TrinketMenu scale:")
			DEFAULT_CHAT_FRAME:AddMessage("/trinket scale main (number) : set exact main scale")
			DEFAULT_CHAT_FRAME:AddMessage("/trinket scale menu (number) : set exact menu scale")
			DEFAULT_CHAT_FRAME:AddMessage("ie, /trinket scale menu 0.85")
			DEFAULT_CHAT_FRAME:AddMessage("Note: You can drag the lower-right corner of either window to scale.  This slash command is for those who want to set an exact scale.")
		end
		TrinketMenu.FrameToScale = nil
		TrinketMenuPerOptions.MainScale = TrinketMenu_MainFrame:GetScale()
		TrinketMenuPerOptions.MenuScale = TrinketMenu_MenuFrame:GetScale()
	elseif string.find(msg,"^activate") then
		local _,_,name = string.find(msg,"^activate%s+(.+)")
		if name and name ~= "" then
			name = string.gsub(name, "^%s*(.-)%s*$", "%1")
			if name == "" then
				TrinketMenu.ReactivateLastPackProfile()
				return
			end
			local target = string.lower(name)
			local foundIndex = nil
			local foundProfile = nil
			if TrinketMenuQueue and TrinketMenuQueue.PackProfiles then
				for i, prof in ipairs(TrinketMenuQueue.PackProfiles) do
					if prof and prof.name and string.lower(prof.name) == target then
						foundIndex = i
						foundProfile = prof
						break
					end
				end
			end
			if foundIndex and foundProfile then
				TrinketMenuQueue.PackProfileActive = foundIndex
				TrinketMenu.ApplyPackProfileActivation(foundProfile)
				DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TrinketMenu:|r Activated profile '" .. foundProfile.name .. "'")
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TrinketMenu:|r Profile '" .. name .. "' not found")
			end
		else
			TrinketMenu.ReactivateLastPackProfile()
		end
	elseif msg=="deactivate" then
		TrinketMenu.ClearActivePackProfile()
	elseif msg=="edit" then
		TrinketMenu.EditActivePackProfile()
	elseif msg=="profiles raid" then
		if TrinketMenuQueue and TrinketMenuQueue.PackProfiles then
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00TrinketMenu Raid Profiles:")
			for i, prof in ipairs(TrinketMenuQueue.PackProfiles) do
				if prof and prof.name then
					local activeMarker = (TrinketMenuQueue.PackProfileActive == i) and " |cff00ff00(Active)|r" or ""
					DEFAULT_CHAT_FRAME:AddMessage(i .. ". " .. prof.name .. activeMarker)
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TrinketMenu:|r No raid profiles found")
		end
	elseif msg=="profiles autoswap" then
		if TrinketMenuQueue and TrinketMenuQueue.Profiles then
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00TrinketMenu Autoswap Profiles:")
			for i, prof in ipairs(TrinketMenuQueue.Profiles) do
				if prof and prof[1] then
					DEFAULT_CHAT_FRAME:AddMessage(i .. ". " .. prof[1])
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TrinketMenu:|r No autoswap profiles found")
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00TrinketMenu useage:")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket or /trinketmenu : toggle the window")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket reset : reset all settings")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket opt : summon options window")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket lock|unlock : toggles window lock")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket scale main|menu (number) : sets an exact scale")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket activate <profilename> : activate raid profile (last used or by name)")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket deactivate : deactivate current raid profile")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket edit : edit active raid profile")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket profiles raid : list all raid profiles")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket profiles autoswap : list all autoswap profiles")
		DEFAULT_CHAT_FRAME:AddMessage("/trinket load top|bottom profilename : load autoswap profile")
	end
end

function TrinketMenu.ResetSettings()
	StaticPopupDialogs["TRINKETMENURESET"] = {
		text = "Are you sure you want to reset TrinketMenu to default state and reload the UI?",
		button1 = "Yes", button2 = "No", showAlert=1, timeout = 0, whileDead = 1,
		OnAccept = function() TrinketMenuOptions=nil TrinketMenuPerOptions=nil TrinketMenuQueue=nil ReloadUI() end,
	}
	StaticPopup_Show("TRINKETMENURESET")
end

--[[ Window Movement ]]--

function TrinketMenu.MainFrame_OnMouseUp()
	if arg1=="LeftButton" then
		this:StopMovingOrSizing()
		TrinketMenuPerOptions.XPos = TrinketMenu_MainFrame:GetLeft()
		TrinketMenuPerOptions.YPos = TrinketMenu_MainFrame:GetTop()
	elseif TrinketMenuOptions.Locked=="OFF" then
		if TrinketMenuPerOptions.MainOrient=="VERTICAL" then
			TrinketMenuPerOptions.MainOrient = "HORIZONTAL"
		else
			TrinketMenuPerOptions.MainOrient = "VERTICAL"
		end
		TrinketMenu.OrientWindows()
	end

end

function TrinketMenu.MainFrame_OnMouseDown(arg1)
	if arg1=="LeftButton" and TrinketMenuOptions.Locked=="OFF" then
		this:StartMoving()
	end
end

--[[ Timers ]]

function TrinketMenu.InitTimers()
	TrinketMenu.TimerPool = {}
	TrinketMenu.Timers = {}
end

function TrinketMenu.CreateTimer(name,func,delay,rep)
	TrinketMenu.TimerPool[name] = { func=func,delay=delay,rep=rep,elapsed=delay }
end

function TrinketMenu.IsTimerActive(name)
	for i,j in ipairs(TrinketMenu.Timers) do
		if j==name then
			return i
		end
	end
	return nil
end

function TrinketMenu.StartTimer(name,delay)
	TrinketMenu.TimerPool[name].elapsed = delay or TrinketMenu.TimerPool[name].delay
	if not TrinketMenu.IsTimerActive(name) then
		table.insert(TrinketMenu.Timers,name)
		TrinketMenu_TimersFrame:Show()
	end
end

function TrinketMenu.StopTimer(name)
	local idx = TrinketMenu.IsTimerActive(name)
	if idx then
		table.remove(TrinketMenu.Timers,idx)
		if table.getn(TrinketMenu.Timers)<1 then
			TrinketMenu_TimersFrame:Hide()
		end
	end
end

function TrinketMenu.TimersFrame_OnUpdate()
	local timerPool
	for _,name in ipairs(TrinketMenu.Timers) do
		timerPool = TrinketMenu.TimerPool[name]
		timerPool.elapsed = timerPool.elapsed - arg1
		if timerPool.elapsed < 0 then
			timerPool.func()
			if timerPool.rep then
				timerPool.elapsed = timerPool.delay
			else
				TrinketMenu.StopTimer(name)
			end
		end
	end
end

function TrinketMenu.TimerDebug()
	local on = "|cFF00FF00On"
	local off = "|cFFFF0000Off"
	DEFAULT_CHAT_FRAME:AddMessage("|cFF44AAFFTrinketMenu_TimersFrame is "..(TrinketMenu_TimersFrame:IsVisible() and on or off))
	for i in TrinketMenu.TimerPool do
		DEFAULT_CHAT_FRAME:AddMessage(i.." is "..(TrinketMenu.IsTimerActive(i) and on or off))
	end
end

--[[ OnClicks ]]

function TrinketMenu.MainTrinket_OnClick()
	if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
		this:SetChecked(0)
		ChatFrameEditBox:Insert(GetInventoryItemLink("player",this:GetID()))
	elseif IsAltKeyDown() and TrinketMenu.QueueInit then
		this:SetChecked(0)
		local which = this:GetID()-13
		if TrinketMenuQueue.Enabled[which] then
			TrinketMenu.CombatQueue[this:GetID()-13]=nil
			TrinketMenuQueue.Enabled[which] = nil
		else
			TrinketMenuQueue.Enabled[which] = 1
		end
--		TrinketMenuQueue.Enabled[which] = not TrinketMenuQueue.Enabled[which]
		TrinketMenu.ReflectQueueEnabled()
		TrinketMenu.UpdateCombatQueue()
		-- toggle queue
	else
		UseTrinket(this:GetID())
	end
end

function TrinketMenu.MenuTrinket_OnClick()
	this:SetChecked(0)
	if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
		ChatFrameEditBox:Insert(GetContainerItemLink(TrinketMenu.BaggedTrinkets[this:GetID()].bag,TrinketMenu.BaggedTrinkets[this:GetID()].slot))
	else
		local slot = (arg1=="LeftButton") and 13 or 14
		if TrinketMenu.QueueInit then
			local _,_,canCooldown = GetContainerItemCooldown(TrinketMenu.BaggedTrinkets[this:GetID()].bag,TrinketMenu.BaggedTrinkets[this:GetID()].slot)
			if canCooldown==0 or TrinketMenuOptions.StopOnSwap=="ON" then -- if incoming trinket can't go on cooldown
				TrinketMenuQueue.Enabled[slot-13]=nil -- turn off autoqueue
				TrinketMenu.ReflectQueueEnabled()
			end
		end
		TrinketMenu.EquipTrinketByName(TrinketMenu.BaggedTrinkets[this:GetID()].name,slot)
		if not IsShiftKeyDown() and TrinketMenuOptions.KeepOpen=="OFF" then
			TrinketMenu_MenuFrame:Hide()
		end
	end
end

--[[ Docking ]]

function TrinketMenu.MenuFrame_OnMouseDown()
	if arg1=="LeftButton" and TrinketMenuOptions.Locked=="OFF" then
		TrinketMenu_MenuFrame:StartMoving()

		if TrinketMenuOptions.KeepDocked=="ON" then
			TrinketMenu.StartTimer("DockingMenu")
		end
	end
end

function TrinketMenu.MenuFrame_OnMouseUp()
	if arg1=="LeftButton" then
		TrinketMenu.StopTimer("DockingMenu")
		TrinketMenu_MenuFrame:StopMovingOrSizing()
		if TrinketMenuOptions.KeepDocked=="ON" then
			TrinketMenu.DockWindows()
		end
	elseif TrinketMenuOptions.Locked=="OFF" then
		if TrinketMenuPerOptions.MenuOrient=="VERTICAL" then
			TrinketMenuPerOptions.MenuOrient="HORIZONTAL"
		else
			TrinketMenuPerOptions.MenuOrient="VERTICAL"
		end
		TrinketMenu.BuildMenu()
	end
end

function TrinketMenu.DockingMenu()

	local main = TrinketMenu_MainFrame
	local menu = TrinketMenu_MenuFrame
	local mainscale = TrinketMenu_MainFrame:GetScale()
	local menuscale = TrinketMenu_MenuFrame:GetScale()
	local near = TrinketMenu.Near

	if near(main:GetRight()*mainscale,menu:GetLeft()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetTop()*menuscale) then
			TrinketMenuPerOptions.MainDock = "TOPRIGHT"
			TrinketMenuPerOptions.MenuDock = "TOPLEFT"
		elseif near(main:GetBottom()*mainscale,menu:GetBottom()*menuscale) then
			TrinketMenuPerOptions.MainDock = "BOTTOMRIGHT"
			TrinketMenuPerOptions.MenuDock = "BOTTOMLEFT"
		end
	elseif near(main:GetLeft()*mainscale,menu:GetRight()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetTop()*menuscale) then
			TrinketMenuPerOptions.MainDock = "TOPLEFT"
			TrinketMenuPerOptions.MenuDock = "TOPRIGHT"
		elseif near(main:GetBottom()*mainscale,menu:GetBottom()*menuscale) then
			TrinketMenuPerOptions.MainDock = "BOTTOMLEFT"
			TrinketMenuPerOptions.MenuDock = "BOTTOMRIGHT"
		end
	elseif near(main:GetRight()*mainscale,menu:GetRight()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetBottom()*menuscale) then
			TrinketMenuPerOptions.MainDock = "TOPRIGHT"
			TrinketMenuPerOptions.MenuDock = "BOTTOMRIGHT"
		elseif near(main:GetBottom()*mainscale,menu:GetTop()*menuscale) then
			TrinketMenuPerOptions.MainDock = "BOTTOMRIGHT"
			TrinketMenuPerOptions.MenuDock = "TOPRIGHT"
		end
	elseif near(main:GetLeft()*mainscale,menu:GetLeft()*menuscale) then
		if near(main:GetTop()*mainscale,menu:GetBottom()*menuscale) then
			TrinketMenuPerOptions.MainDock = "TOPLEFT"
			TrinketMenuPerOptions.MenuDock = "BOTTOMLEFT"
		elseif near(main:GetBottom()*mainscale,menu:GetTop()*menuscale) then
			TrinketMenuPerOptions.MainDock = "BOTTOMLEFT"
			TrinketMenuPerOptions.MenuDock = "TOPLEFT"
		end
	end
	TrinketMenu.ClearDocking()
	getglobal("TrinketMenu_MainDock_"..TrinketMenuPerOptions.MainDock):Show()
	getglobal("TrinketMenu_MenuDock_"..TrinketMenuPerOptions.MenuDock):Show()
end

function TrinketMenu.MenuMouseover()
	if (not MouseIsOver(TrinketMenu_MainFrame)) and (not MouseIsOver(TrinketMenu_MenuFrame)) and not IsShiftKeyDown() and (TrinketMenuOptions.KeepOpen=="OFF") and not TrinketMenu.IsTimerActive("Scaling") then
		TrinketMenu.StopTimer("MenuMouseover")
		TrinketMenu_MenuFrame:Hide()
	end
end

--[[ Scaling ]]

function TrinketMenu.StartScaling()
	if arg1=="LeftButton" and TrinketMenuOptions.Locked=="OFF" then
		this:LockHighlight()
		TrinketMenu.FrameToScale = this:GetParent()
		TrinketMenu.ScalingWidth = this:GetParent():GetWidth()
		TrinketMenu.StartTimer("Scaling")
	end
end

function TrinketMenu.StopScaling()
	if arg1=="LeftButton" then
		TrinketMenu.StopTimer("Scaling")
		TrinketMenu.FrameToScale = nil
		this:UnlockHighlight()
		if this:GetParent():GetName() == "TrinketMenu_MainFrame" then
			TrinketMenuPerOptions.MainScale = TrinketMenu_MainFrame:GetScale()
		else
			TrinketMenuPerOptions.MenuScale = TrinketMenu_MenuFrame:GetScale()
		end
	end
end

function TrinketMenu.ScaleFrame(scale)
	local frame = TrinketMenu.FrameToScale
	local oldscale = frame:GetScale() or 1
	local framex = (frame:GetLeft() or TrinketMenuPerOptions.XPos)* oldscale
	local framey = (frame:GetTop() or TrinketMenuPerOptions.YPos)* oldscale

	frame:SetScale(scale)
	if frame:GetName() == "TrinketMenu_MainFrame" then
		TrinketMenu_MainFrame:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",framex/scale,framey/scale)
		TrinketMenuPerOptions.XPos = TrinketMenu_MainFrame:GetLeft()
		TrinketMenuPerOptions.YPos = TrinketMenu_MainFrame:GetTop()
	elseif TrinketMenuOptions.KeepDocked=="OFF" then
		TrinketMenu_MenuFrame:ClearAllPoints()
		TrinketMenu_MenuFrame:SetPoint("TOPLEFT","UIParent","BOTTOMLEFT",framex/scale,framey/scale)
	end
end

function TrinketMenu.Scaling()
	local frame = TrinketMenu.FrameToScale
	local oldscale = frame:GetEffectiveScale()
	local framex, framey, cursorx, cursory = frame:GetLeft()*oldscale, frame:GetTop()*oldscale, GetCursorPosition()
	if (cursorx-framex)>32 then
		local newscale = (cursorx-framex)/TrinketMenu.ScalingWidth
		TrinketMenu.ScaleFrame(newscale)
	end
end

--[[ Cooldowns ]]

function TrinketMenu.UpdateWornCooldowns(maybeGlobal)
	local start,duration,enable = GetInventoryItemCooldown("player",13)
	CooldownFrame_SetTimer(TrinketMenu_Trinket0Cooldown,start,duration,enable)
	start,duration,enable = GetInventoryItemCooldown("player",14)
	CooldownFrame_SetTimer(TrinketMenu_Trinket1Cooldown,start,duration,enable)
	if not maybeGlobal then
		TrinketMenu.WriteWornCooldowns()
	end
end

function TrinketMenu.UpdateMenuCooldowns()
	local start,duration,enable
	for i=1,TrinketMenu.NumberOfTrinkets do
		start,duration,enable = GetContainerItemCooldown(TrinketMenu.BaggedTrinkets[i].bag,TrinketMenu.BaggedTrinkets[i].slot)
		CooldownFrame_SetTimer(getglobal("TrinketMenu_Menu"..i.."Cooldown"),start,duration,enable)
	end
	TrinketMenu.WriteMenuCooldowns()
end

--[[ Item use ]]

function TrinketMenu.ReflectTrinketUse(slot)
	getglobal("TrinketMenu_Trinket"..(slot-13)):SetChecked(1)
	TrinketMenu.StartTimer("UpdateWornTrinkets")
	local trinket = TrinketMenu.GetEquippedTrinket(slot)
	if trinket and trinket.trinketName then
		TrinketMenuPerOptions.ItemsUsed[trinket.trinketName] = 0 -- 0 is an indeterminate state, cooldown will figure if it's worth watching
		TrinketMenu.AddWatchItem(trinket.trinketName, slot)
	end
end

function TrinketMenu.FindEquippedTrinketSlot(itemIdOrName)
	if itemIdOrName == 1 or itemIdOrName == 13 then
		return 13
	elseif itemIdOrName == 2 or itemIdOrName == 14 then
		return 14
	end
	local bag, slot = TrinketMenu.FindPlayerItemSlot(itemIdOrName)
	if bag == nil and (slot == 13 or slot == 14) then
		return slot
	end
end

--[[ Tooltips ]]

function TrinketMenu.WornTrinketTooltip()
	local id = this:GetID()
	if TrinketMenu.IsTimerActive("Scaling") or TrinketMenuOptions.ShowTooltips=="OFF" then
		return
	end
	TrinketMenu.TooltipOwner = this
	TrinketMenu.TooltipType = "INVENTORY"
	TrinketMenu.TooltipSlot = id
	TrinketMenu.TooltipBag = TrinketMenu.CombatQueue[id-13]
	TrinketMenu.StartTimer("TooltipUpdate",0)
end

function TrinketMenu.MenuTrinketTooltip()
	local id = this:GetID()
	if TrinketMenu.IsTimerActive("Scaling") or TrinketMenuOptions.ShowTooltips=="OFF" then
		return
	end
	TrinketMenu.TooltipOwner = this
	TrinketMenu.TooltipType = "BAG"
	TrinketMenu.TooltipBag = TrinketMenu.BaggedTrinkets[id].bag
	TrinketMenu.TooltipSlot = TrinketMenu.BaggedTrinkets[id].slot
	TrinketMenu.StartTimer("TooltipUpdate",0)
end

function TrinketMenu.ClearTooltip()
	GameTooltip:Hide()
	TrinketMenu.StopTimer("TooltipUpdate")
	TrinketMenu.TooltipType = nil
end

function TrinketMenu.AnchorTooltip(owner)
	owner = owner or this
	if TrinketMenuOptions.TooltipFollow=="ON" then
		if owner.GetLeft and owner:GetLeft() and owner:GetLeft()<400 then
			GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
		else
			GameTooltip:SetOwner(owner,"ANCHOR_LEFT")
		end
	else
		GameTooltip_SetDefaultAnchor(GameTooltip,owner)
	end
end

-- updates the tooltip created in the functions above
function TrinketMenu.TooltipUpdate()
	if TrinketMenu.TooltipType then
		local cooldown
		TrinketMenu.AnchorTooltip(TrinketMenu.TooltipOwner)
		if TrinketMenu.TooltipType=="BAG" then
			GameTooltip:SetBagItem(TrinketMenu.TooltipBag,TrinketMenu.TooltipSlot)
			cooldown = GetContainerItemCooldown(TrinketMenu.TooltipBag,TrinketMenu.TooltipSlot)
		else
			GameTooltip:SetInventoryItem("player",TrinketMenu.TooltipSlot)
			cooldown = GetInventoryItemCooldown("player",TrinketMenu.TooltipSlot)
		end
		TrinketMenu.ShrinkTooltip(TrinketMenu.TooltipOwner) -- if TinyTooltips on, shrink it
		if TrinketMenu.TooltipType=="INVENTORY" and TrinketMenu.TooltipBag then
			GameTooltip:AddLine("Queued: "..TrinketMenu.TooltipBag)
		end
		GameTooltip:Show()
		if cooldown==0 then
			-- stop updates if this trinket has no cooldown
			TrinketMenu.TooltipType = nil
			TrinketMenu.StopTimer("TooltipUpdate")
		end
	end

end

-- normal tooltip for options
function TrinketMenu.OnTooltip(line1,line2)
	if TrinketMenuOptions.ShowTooltips=="ON" then
		TrinketMenu.AnchorTooltip()
		if line1 then
			GameTooltip:AddLine(line1)
			GameTooltip:AddLine(line2,.8,.8,.8,1)
			GameTooltip:Show()
		else
			local name = this:GetName() or ""
			for i=1,table.getn(TrinketMenu.CheckOptInfo) do
				if name=="TrinketMenu_Opt"..TrinketMenu.CheckOptInfo[i][1] and TrinketMenu.CheckOptInfo[i][3] then
					TrinketMenu.OnTooltip(TrinketMenu.CheckOptInfo[i][3],TrinketMenu.CheckOptInfo[i][4])
				end
			end
			for i=1,table.getn(TrinketMenu.TooltipInfo) do
				if TrinketMenu.TooltipInfo[i][1]==name and TrinketMenu.TooltipInfo[i][2] then
					TrinketMenu.OnTooltip(TrinketMenu.TooltipInfo[i][2],TrinketMenu.TooltipInfo[i][3])
				end
			end
		end
	end
end

-- strip format reordering in global strings
TrinketMenu.ITEM_SPELL_CHARGES = string.gsub(ITEM_SPELL_CHARGES,"%%%d%$d","%%d")
TrinketMenu.ITEM_SPELL_CHARGES_P1 = string.gsub(ITEM_SPELL_CHARGES_P1,"%%%d%$d","%%d")

function TrinketMenu.ShrinkTooltip(owner)
	if TrinketMenuOptions.TinyTooltips=="ON" then
		local r,g,b = GameTooltipTextLeft1:GetTextColor()
		local name = GameTooltipTextLeft1:GetText()
		local line,cooldown,charge
		for i=2,12 do
			line = getglobal("GameTooltipTextLeft"..i)
			if line:IsVisible() then
				line = line:GetText() or ""
				if string.find(line,COOLDOWN_REMAINING) then
					cooldown = line
				end
				if string.find(line,TrinketMenu.ITEM_SPELL_CHARGES_P1) or string.find(line,TrinketMenu.ITEM_SPELL_CHARGES) then
					charge = line
				end
			end
		end
		TrinketMenu.AnchorTooltip(owner or this)
		GameTooltip:AddLine(name,r,g,b)
		GameTooltip:AddLine(charge,1,1,1)
		GameTooltip:AddLine(cooldown,1,1,1)
	end
end

--[[ Combat Queue ]]

function TrinketMenu.EquipTrinketByName(nameOrId, slot)
	if not nameOrId then return end
	if UnitAffectingCombat("player") or TrinketMenu.IsPlayerReallyDead() then
		-- queue trinket
		local queue = TrinketMenu.CombatQueue
		local which = slot-13 -- 0 or 1
		if queue[1-which]== nameOrId then
			queue[1-which] = nil
			queue[which] = nameOrId
		else
			queue[which] = nameOrId
		end
	elseif not CursorHasItem() and not SpellIsTargeting() then
		local bag, slotIndex = TrinketMenu.FindItem(nameOrId, 1)
		if bag then
			local _,_,isLocked = GetContainerItemInfo(bag,slotIndex)
			if not isLocked and not IsInventoryItemLocked(slot) then
				-- neither container item nor inventory item locked, perform swap
				PickupContainerItem(bag,slotIndex)
				PickupInventoryItem(slot)
				getglobal("TrinketMenu_Trinket"..(slot-13).."Icon"):SetDesaturated(1)
				TrinketMenu.StartTimer("UpdateWornTrinkets") -- in case it's not equipped (stunned, etc)
			end
		elseif slotIndex and slotIndex >= 0 then
			print("|cff00ff00TrinketMenu:|r Trinket " .. nameOrId .. " is already equipped")
		else
			print("|cff00ff00TrinketMenu:|r Unable to find trinket " .. nameOrId .. " in your bags")
		end
	end
	TrinketMenu.UpdateCombatQueue()
end	

function TrinketMenu.UpdateCombatQueue()
	local bag,slot
	for which=0,1 do
		local trinket = TrinketMenu.CombatQueue[which]
		local icon = getglobal("TrinketMenu_Trinket"..which.."Queue")
		icon:Hide()
		if trinket then
			bag,slot = TrinketMenu.FindItem(trinket)
			if bag then
				icon:SetTexture(GetContainerItemInfo(bag,slot))
				icon:Show()
			end
		elseif TrinketMenu.QueueInit and TrinketMenuQueue and TrinketMenuQueue.Enabled[which] then
			icon:SetTexture("Interface\\AddOns\\TrinketMenu\\TrinketMenu-Gear")
			icon:Show()
		end
	end
end

--[[ Notify ]]

function TrinketMenu.Notify(msg)
	if SCT_Display then -- send via SCT if it exists
		SCT_Display(msg,{r=.2,g=.7,b=.9})
	elseif SHOW_COMBAT_TEXT=="1" then
		CombatText_AddMessage(msg, CombatText_StandardScroll, .2, .7, .9) -- or default UI's SCT
	else
		-- send vis UIErrorsFrame if neither SCT exists
		UIErrorsFrame:AddMessage(msg,.2,.7,.9,1,UIERRORS_HOLD_TIME)
	end
	if TrinketMenuOptions.NotifyChatAlso=="ON" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33b2e5"..msg)
	end
end

-- adds location of the name to a watch table for fast lookups
-- pass inv bag slot to override the search
function TrinketMenu.AddWatchItem(name,inv,bag,slot)
	TrinketMenu.WatchItem[name] = TrinketMenu.WatchItem[name] or {}

	-- Only search if location not provided
	if not inv and not bag then
		bag, slot = TrinketMenu.FindItem(name, 1)
		if not bag and slot then
			inv = slot
			slot = nil
		end
	end

	TrinketMenu.WatchItem[name].inv = inv
	TrinketMenu.WatchItem[name].bag = bag
	TrinketMenu.WatchItem[name].slot = slot
end

function TrinketMenu.CooldownUpdate()
  local inv, bag, slot, name, remain
	local watch = TrinketMenu.WatchItem
  for usedName in TrinketMenuPerOptions.ItemsUsed do
    name = nil
    if not watch[usedName] then
      TrinketMenu.AddWatchItem(usedName)
    end -- if not on watch table, add it
    inv, bag, slot = watch[usedName].inv, watch[usedName].bag, watch[usedName].slot
		if inv then -- if it was last seen in an inv slot, get name in that slot
			_,_,name = string.find(GetInventoryItemLink("player",inv) or "","%[(.+)%]")
		end
		if bag then -- if it was last seen in a container slot, get name in that slot
			_,_,name = string.find(GetContainerItemLink(bag,slot) or "","%[(.+)%]")
		end
    if name ~= usedName then
      -- item has moved
      bag, slot = TrinketMenu.FindItem(usedName, 1)
			if not bag and slot then
				inv = slot
				slot = nil
			else
				inv = nil
			end
      watch[usedName].inv, watch[usedName].bag, watch[usedName].slot = inv, bag, slot
		end

    if TrinketMenuPerOptions.ItemsUsed[usedName] > 35000 then
      -- subtract 1 and continue
      TrinketMenuPerOptions.ItemsUsed[usedName] = TrinketMenuPerOptions.ItemsUsed[usedName] - 1000
    else
      local cdData = GetTrinketCooldown(usedName)

      if cdData and cdData.itemActiveSpellId > 0 then
        local cd = cdData.cooldownRemainingMs
        TrinketMenuPerOptions.ItemsUsed[usedName] = cd
        if cd > 30000 and cd < 31000 then
          if TrinketMenuOptions.NotifyThirty == "ON" then
            TrinketMenu.Notify(usedName .. " ready soon!")
          end
        elseif cd > 0 and cd < 1000 then
          if TrinketMenuOptions.Notify == "ON" then
            if inv then
              TrinketMenu.PlayNotifySound()
            end
            TrinketMenu.Notify(usedName .. " ready!")
          end
        end
        if cdData.cooldownRemainingMs == 0 then
          TrinketMenuPerOptions.ItemsUsed[usedName] = nil
        end
      end
    end
	end

	-- update cooldown numbers
	if TrinketMenuOptions.CooldownCount=="ON" then
		if TrinketMenu_MainFrame:IsVisible() then
			TrinketMenu.WriteWornCooldowns()
		end
		if TrinketMenu_MenuFrame:IsVisible() then
			TrinketMenu.WriteMenuCooldowns()
		end
	end

	if TrinketMenu.PeriodicQueueCheck then
		TrinketMenu.PeriodicQueueCheck()
	end
end

function TrinketMenu.WriteWornCooldowns()
	local start, duration
	start, duration = GetInventoryItemCooldown("player",13)
	TrinketMenu.WriteCooldown(TrinketMenu_Trinket0Time,start,duration)
	start, duration = GetInventoryItemCooldown("player",14)
	TrinketMenu.WriteCooldown(TrinketMenu_Trinket1Time,start,duration)
end

function TrinketMenu.WriteMenuCooldowns()
	local start, duration
	for i=1,TrinketMenu.NumberOfTrinkets do
		start, duration = GetContainerItemCooldown(TrinketMenu.BaggedTrinkets[i].bag,TrinketMenu.BaggedTrinkets[i].slot)
		TrinketMenu.WriteCooldown(getglobal("TrinketMenu_Menu"..i.."Time"),start,duration)
	end
end

function TrinketMenu.WriteCooldown(where,start,duration)
	local cooldown = duration - (GetTime()-start)
	if start==0 or TrinketMenuOptions.CooldownCount=="OFF" then
		where:SetText("")
	elseif cooldown<3 and not where:GetText() then
		-- this is a global cooldown. don't display it. not accurate but at least not annoying
	else
		where:SetText((cooldown<60 and math.floor(cooldown+.5).." s") or (cooldown<3600 and math.ceil(cooldown/60).." m") or math.ceil(cooldown/3600).." h")
	end
end

function TrinketMenu.OnShow()
	TrinketMenuPerOptions.Visible = "ON"
	if TrinketMenuOptions.KeepOpen=="ON" then
		TrinketMenu.BuildMenu()
	end
end

function TrinketMenu.OnHide()
	TrinketMenuPerOptions.Visible = "OFF"
	TrinketMenu_MenuFrame:Hide()
end

--[[ Key bindings ]]

function TrinketMenu.ReflectKeyBindings()
	if TrinketMenuOptions.ShowHotKeys=="ON" then
		TrinketMenu_Trinket0HotKey:SetText(GetBindingText(GetBindingKey("Use Top Trinket"),"KEY_",1))
		TrinketMenu_Trinket1HotKey:SetText(GetBindingText(GetBindingKey("Use Bottom Trinket"),"KEY_",1))
	else
		TrinketMenu_Trinket0HotKey:SetText("")
		TrinketMenu_Trinket1HotKey:SetText("")
	end
end
