--[[ TrinketMenuOpt.lua : Options and sort window for TrinketMenu ]]

TrinketMenu.CheckOptInfo = {
{"ShowIcon","ON","Minimap Button","Show or hide minimap button."},
{"SquareMinimap","OFF","Square Minimap","Move minimap button as if around a square minimap.","ShowIcon"},
{"CooldownCount","OFF","Cooldown Numbers","Display time remaining on cooldowns ontop of the button."},
{"TooltipFollow","OFF","At Mouse","Display all tooltips near the mouse.","ShowTooltips"},
{"KeepOpen","OFF","Keep Menu Open","Keep menu open at all times."},
{"KeepDocked","ON","Keep Menu Docked","Keep menu docked at all times."},
{"MenuShowHiddenOnShift","ON","Menu Show Hidden On Shift","Show trinkets marked 'Hide in Menu' when Shift is held."},
{"Notify","OFF","Notify When Ready","Sends an overhead notification when a trinket's cooldown is complete."},
{"DisableToggle","OFF","Disable Toggle","Disables the minimap button's ability to toggle the trinket frame.","ShowIcon"},
{"NotifyChatAlso","OFF","Notify Chat Also","Sends notifications through chat also."},
{"Locked","OFF","Lock Windows","Prevents the windows from being moved, resized or rotated."},
{"ShowTooltips","ON","Show Tooltips","Shows tooltips."},
{"NotifyThirty","ON","Notify At 30 sec","Sends an overhead notification when a trinket has 30 seconds left on cooldown."},
{"MenuOnShift","OFF","Menu On Shift","Check this to prevent the menu appearing unless Shift is held."},
{"TinyTooltips","OFF","Tiny Tooltips","Shrink trinket tooltips to only their name, charges and cooldown.","ShowTooltips"},
{"SetColumns","OFF","Set Menu Columns","Define how many trinkets before the menu will wrap to the next row.\n\nUncheck to let TrinketMenu choose how to wrap the menu."},
{"LargeCooldown","ON","Large Numbers","Display the cooldown time in a larger font.","CooldownCount"},
{"ShowHotKeys","ON","Show Key Bindings","Display the key bindings over the equipped trinkets."},
{"StopOnSwap","OFF","Stop Queue On Swap","Swapping a passive trinket stops an auto queue.  Check this to also stop the auto queue when a clickable trinket is manually swapped in via TrinketMenu.  This will have the most use to those with frequent trinkets marked Priority."},
{"HideOnLoad","OFF","Close On Profile Load","Check this to dismiss this window when you load a profile."},
{"HideProfileText","OFF","Hide Profile Text","Hide the current profile name displayed above the trinket frame."},
{"ProfileZoneWarnings","ON","Profile Zone Warnings","Show chat message when entering a zone with a matching profile."}
}

-- table.insert(TrinketMenu.CheckOptInfo,)

TrinketMenu.TooltipInfo = {
{"TrinketMenu_LockButton","Lock Windows","Prevents the windows from being moved, resized or rotated."},
{"TrinketMenu_Trinket0Check","Top Trinket Auto Queue","Check this to enable auto queue for this trinket slot.  You can also Alt+Click the trinket slot to toggle Auto Queue."},
{"TrinketMenu_Trinket1Check","Bottom Trinket Auto Queue","Check this to enable auto queue for this trinket slot.  You can also Alt+Click the trinket slot to toggle Auto Queue."},
{"TrinketMenu_SortPriority","High Priority","When checked, this trinket will be swapped in as soon as possible, whether the equipped trinket is on cooldown or not.\n\nWhen unchecked, this trinket will not equip over one already worn that's not on cooldown."},
{"TrinketMenu_SortDelay","Swap Delay","This is the time (in seconds) before a trinket will be swapped out.  ie, for Earthstrike you want 20 seconds to get the full 20 second effect of the buff."},
{"TrinketMenu_SortKeepEquipped","Pause Queue","Check this to suspend the auto queue while this trinket is equipped. ie, for Carrot on a Stick if you have a mod to auto-equip it to a slot with Auto Queue active."},
{"TrinketMenu_SortHideInMenu","Hide in Menu","Check this to hide this trinket from the menu. The trinket can still be equipped via auto queue, but won't appear in the menu window."},
{"TrinketMenu_Profiles","Profiles","Here you can load or save auto queue profiles."},
{"TrinketMenu_Delete","Delete","Remove this trinket from the list.  Trinkets further down the list don't affect performance at all.  This option is merely to keep the list managable. Note: Trinkets in your bags will return to end of the list."},
{"TrinketMenu_ProfilesDelete","Delete Profile","Remove this profile."},
{"TrinketMenu_ProfilesLoad","Load Profile","Load a queue order for the selected trinket slot.  You can double-click a profile to load it also."},
{"TrinketMenu_ProfilesSave","Save Profile","Save the queue order from the selected trinket slot.  Either trinket slot can use saved profiles."},
{"TrinketMenu_ProfileName","Profile Name","Enter a name to call the profile.  When saved, you can load this profile to either trinket slot."},
{ "TrinketMenu_PackTargetTrinket1ClearButton", "Clear Slot", "Clear the selected target trinket slot for this pack." },
{ "TrinketMenu_PackTargetTrinket2ClearButton", "Clear Slot", "Clear the selected target trinket slot for this pack." },
{ "TrinketMenu_PackTrinket1ClearButton", "Clear Slot", "Clear the selected trinket slot for this pack." },
{ "TrinketMenu_PackTrinket2ClearButton", "Clear Slot", "Clear the selected trinket slot for this pack." },
}

function TrinketMenu.InitOptions()
	TrinketMenu.CreateTimer("DragMinimapButton",TrinketMenu.DragMinimapButton,0,1)
	TrinketMenu.MoveMinimapButton()
	local item
	for i=1,table.getn(TrinketMenu.CheckOptInfo) do
		item = getglobal("TrinketMenu_Opt"..TrinketMenu.CheckOptInfo[i][1].."Text")
		if item then
			item:SetText(TrinketMenu.CheckOptInfo[i][3])
			item:SetTextColor(.95,.95,.95)
		end
	end
	TrinketMenu.Tab_OnClick(1)
	table.insert(UISpecialFrames,"TrinketMenu_OptFrame")
	TrinketMenu_Title:SetText("TrinketMenu "..TrinketMenu_Version)

	TrinketMenu_OptFrame:SetBackdropBorderColor(.3,.3,.3,1)
	TrinketMenu_SubOptFrame:SetBackdropBorderColor(.3,.3,.3,1)
	if TrinketMenu_ProfilesTabFrame then
		TrinketMenu_ProfilesTabFrame:SetBackdropBorderColor(.3, .3, .3, 1)
	end
	if TrinketMenu_ProfileCreateFrame then
		TrinketMenu_ProfileCreateFrame:SetBackdropBorderColor(.3, .3, .3, 1)
	end
	if TrinketMenu.QueueInit then
		TrinketMenu.QueueInit()
		TrinketMenu_Tab1:Show()
		TrinketMenu_OptFrame:SetHeight(326)
		TrinketMenu_SubOptFrame:SetPoint("TOPLEFT",TrinketMenu_OptFrame,"TOPLEFT",8,-50)
	else
		TrinketMenu_OptStopOnSwap:Hide() -- remove StopOnSwap option if queue not loaded
		TrinketMenu_Tab1:Hide() -- hide options tab if it's only tab
		TrinketMenu_OptFrame:SetHeight(300)
		TrinketMenu_SubOptFrame:SetPoint("TOPLEFT",TrinketMenu_OptFrame,"TOPLEFT",8,-24)
	end
	TrinketMenu_OptColumnsSlider:SetValue(TrinketMenuOptions.Columns)
	TrinketMenu.ReflectLock()
	TrinketMenu.ReflectCooldownFont()
	TrinketMenu.ReflectKeyBindings()
end

function TrinketMenu.ToggleFrame(frame)
	if frame:IsVisible() then
		frame:Hide()
	else
		frame:Show()
	end
end

function TrinketMenu.OptFrame_OnShow()
	TrinketMenu.ValidateChecks()
	if TrinketMenu.CurrentlySorting then
		TrinketMenu.PopulateSort(TrinketMenu.CurrentlySorting)
	end
end

--[[ Minimap button ]]

function TrinketMenu.MoveMinimapButton()
	local xpos,ypos
	if TrinketMenuOptions.SquareMinimap=="ON" then
		xpos = 110 * cos(TrinketMenuOptions.IconPos or 0)
		ypos = 110 * sin(TrinketMenuOptions.IconPos or 0)
		xpos = math.max(-82,math.min(xpos,84))
		ypos = math.max(-86,math.min(ypos,82))
	else
		xpos = 80*cos(TrinketMenuOptions.IconPos or 0)
		ypos = 80*sin(TrinketMenuOptions.IconPos or 0)
	end
	TrinketMenu_IconFrame:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-xpos,ypos-52)
	if TrinketMenuOptions.ShowIcon=="ON" then
		TrinketMenu_IconFrame:Show()
	else
		TrinketMenu_IconFrame:Hide()
	end
end

function TrinketMenu.DragMinimapButton()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft() or 400, Minimap:GetBottom() or 400
	xpos = xmin-xpos/Minimap:GetEffectiveScale()+70
	ypos = ypos/Minimap:GetEffectiveScale()-ymin-70
	TrinketMenuOptions.IconPos = math.deg(math.atan2(ypos,xpos))
	TrinketMenu.MoveMinimapButton()
end

function TrinketMenu.MinimapButton_OnClick()
	PlaySound("GAMEGENERICBUTTONPRESS")
	if arg1=="LeftButton" and TrinketMenuOptions.DisableToggle=="OFF" then
		TrinketMenu.ToggleFrame(TrinketMenu_MainFrame)
	else
		TrinketMenu.ToggleFrame(TrinketMenu_OptFrame)
	end
end

--[[ CheckButton ]]

function TrinketMenu.ValidateChecks()
	local check,button
	for i=1,table.getn(TrinketMenu.CheckOptInfo) do
		check = TrinketMenu.CheckOptInfo[i]
		button = getglobal("TrinketMenu_Opt"..check[1])
		if button then
			button:SetChecked(TrinketMenuOptions[check[1]]=="ON")
			if check[5] then
				if TrinketMenuOptions[check[5]]=="ON" then
					button:Enable()
					getglobal("TrinketMenu_Opt"..check[1].."Text"):SetTextColor(.95,.95,.95)
				else
					button:Disable()
					getglobal("TrinketMenu_Opt"..check[1].."Text"):SetTextColor(.5,.5,.5)
				end
			end
		end
	end
	TrinketMenu_OptColumnsSlider:SetAlpha((TrinketMenuOptions.SetColumns=="ON") and 1 or .5)
	TrinketMenu_OptColumnsSlider:EnableMouse((TrinketMenuOptions.SetColumns=="ON") and 1 or 0)
	TrinketMenu_OptColumnsSlider:SetValue(TrinketMenuOptions.Columns)
end

function TrinketMenu.OptColumnsSlider_OnValueChanged()
	if TrinketMenuOptions then
		TrinketMenuOptions.Columns = this:GetValue()
		TrinketMenu_OptColumnsSliderText:SetText(TrinketMenuOptions.Columns.." trinkets")
		if TrinketMenu_MenuFrame:IsVisible() then
			TrinketMenu.BuildMenu()
		end
	end
end

function TrinketMenu.CheckButton_OnClick()
	local _,_,var = string.find(this:GetName(),"TrinketMenu_Opt(.+)")
	if TrinketMenuOptions[var] then
		TrinketMenuOptions[var] = this:GetChecked() and "ON" or "OFF"
		PlaySound(this:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
		TrinketMenu.ValidateChecks()
	end

	if this==TrinketMenu_OptCooldownCount then
		TrinketMenu.WriteWornCooldowns()
		TrinketMenu.WriteMenuCooldowns()
	elseif this==TrinketMenu_OptLocked then
		TrinketMenu.DockWindows()
		TrinketMenu.ReflectLock()
	elseif this==TrinketMenu_OptKeepOpen or this==TrinketMenu_OptSetColumns then
		if TrinketMenuOptions.KeepOpen=="ON" then
			TrinketMenu.BuildMenu()
		end
	elseif this==TrinketMenu_OptKeepDocked then
		TrinketMenu.DockWindows()
	elseif this==TrinketMenu_OptLargeCooldown then
		TrinketMenu.ReflectCooldownFont()
	elseif this==TrinketMenu_OptSquareMinimap then
		TrinketMenu.MoveMinimapButton()
	elseif this==TrinketMenu_OptShowHotKeys then
		TrinketMenu.ReflectKeyBindings()
	elseif this==TrinketMenu_OptShowIcon then
		TrinketMenu.MoveMinimapButton()
	elseif this==TrinketMenu_OptHideProfileText then
		TrinketMenu.UpdateActiveProfileText()
	end
end

function TrinketMenu.ReflectLock()
	local c = TrinketMenuOptions.Locked=="ON" and 0 or .5
	TrinketMenu_OptFrame:SetBackdropBorderColor(c,c,c,1)
	TrinketMenu_MainFrame:SetBackdropColor(c,c,c,c)
	TrinketMenu_MainFrame:SetBackdropBorderColor(c,c,c,c*2)
	TrinketMenu_MenuFrame:SetBackdropColor(c,c,c,c)
	TrinketMenu_MenuFrame:SetBackdropBorderColor(c,c,c,c*2)
	TrinketMenu_MenuFrame:EnableMouse(c*2)
	TrinketMenu_OptLocked:SetChecked(1-c*2)
	local normalTexture = TrinketMenu_LockButton:GetNormalTexture()
	local pushedTexture = TrinketMenu_LockButton:GetPushedTexture()
	if c==0 then
		TrinketMenu_MainResizeButton:Hide()
		TrinketMenu_MenuResizeButton:Hide()
		normalTexture:SetTexCoord(.875,1,.125,.25)
		pushedTexture:SetTexCoord(.75,.875,.125,.25)
	else
		TrinketMenu_MainResizeButton:Show()
		TrinketMenu_MenuResizeButton:Show()
		normalTexture:SetTexCoord(.75,.875,.125,.25)
		pushedTexture:SetTexCoord(.875,1,.125,.25)
	end
end

function TrinketMenu.ReflectCooldownFont()
	TrinketMenu.SetCooldownFont("TrinketMenu_Trinket0")
	TrinketMenu.SetCooldownFont("TrinketMenu_Trinket1")
	for i=1,30 do
		TrinketMenu.SetCooldownFont("TrinketMenu_Menu"..i)
	end
end

function TrinketMenu.SetCooldownFont(button)
	local item = getglobal(button.."Time")
	if TrinketMenuOptions.LargeCooldown=="ON" then
		item:SetFont("Fonts\\FRIZQT__.TTF",16,"OUTLINE")
		item:SetTextColor(1,.82,0,1)
		item:ClearAllPoints()
		item:SetPoint("CENTER",button,"CENTER")
	else
		item:SetFont("Fonts\\ARIALN.TTF",14,"OUTLINE")
		item:SetTextColor(1,1,1,1)
		item:ClearAllPoints()
		item:SetPoint("BOTTOM",button,"BOTTOM")
	end
end


--[[ Titlebar buttons ]]

function TrinketMenu.SmallButton_OnClick()
	PlaySound("igMainMenuOptionCheckBoxOn")
	if this==TrinketMenu_CloseButton then
		TrinketMenu_OptFrame:Hide()
	elseif this==TrinketMenu_LockButton then
		TrinketMenuOptions.Locked = (TrinketMenuOptions.Locked=="ON") and "OFF" or "ON"
		TrinketMenu.DockWindows()
		TrinketMenu.ReflectLock()
  else
    local name = this and this.GetName and this:GetName()
    local clearMap = {
      TrinketMenu_PackTargetTrinket1ClearButton = { target = true, slot = "trinket1" },
      TrinketMenu_PackTargetTrinket2ClearButton = { target = true, slot = "trinket2" },
      TrinketMenu_PackTrinket1ClearButton = { target = false, slot = "trinket1" },
      TrinketMenu_PackTrinket2ClearButton = { target = false, slot = "trinket2" },
    }
    local clearInfo = name and clearMap[name]
    if clearInfo and TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.selectedPack then
      local packName = TrinketMenu.ProfileBuilder.selectedPack
      local trinketMap = clearInfo.target and TrinketMenu.ProfileBuilder.packTargetTrinkets or TrinketMenu.ProfileBuilder.packDeathTrinkets
      trinketMap[packName] = trinketMap[packName] or {}
      trinketMap[packName][clearInfo.slot] = nil
      TrinketMenu.ProfilePackScrollFrameUpdate()
      TrinketMenu.ProfileTrinketScrollFrameUpdate()
      TrinketMenu.ProfileUpdatePackTrinketDisplay()
    end
	end
end

--[[ Tabs ]]

function TrinketMenu.Tab_OnClick(override)
	PlaySound("GAMEGENERICBUTTONPRESS")
	local id = override or this:GetID()
	local tab
	if TrinketMenu_ProfilesFrame then
		TrinketMenu_ProfilesFrame:Hide()
	end
	for i = 1, 4 do
		tab = getglobal("TrinketMenu_Tab"..i)
		if tab then
			tab:UnlockHighlight()
		end
	end
	getglobal("TrinketMenu_Tab"..id):LockHighlight()
	if TrinketMenu_SubOptFrame then
		TrinketMenu_SubOptFrame:Hide()
	end
	if TrinketMenu_SubQueueFrame then
		TrinketMenu_SubQueueFrame:Hide()
	end
	if TrinketMenu_ProfilesTabFrame then
		TrinketMenu_ProfilesTabFrame:Hide()
	end
	if id==1 then
		if TrinketMenu_SubOptFrame then
			TrinketMenu_SubOptFrame:Show()
		end
	elseif id == 2 or id == 3 then
		if TrinketMenu_SubQueueFrame then
			TrinketMenu_SubQueueFrame:Show()
		end
		TrinketMenu.OpenSort(3 - id)
	elseif id == 4 then
		if TrinketMenu_ProfilesTabFrame then
			TrinketMenu_ProfilesTabFrame:Show()
			if TrinketMenu_ProfilesTabHelp then
				TrinketMenu_ProfilesTabHelp:SetText("Create raid profiles with pack and trinket selections.")
				TrinketMenu_ProfilesTabHelp:Show()
			end
			if TrinketMenu_ProfileCreateButton then
				TrinketMenu_ProfileCreateButton:Show()
			end
			if TrinketMenu_PackProfileListFrame then
				TrinketMenu_PackProfileListFrame:Show()
			end
			if TrinketMenu_PackProfileEdit then
				TrinketMenu_PackProfileEdit:Show()
			end
			if TrinketMenu_PackProfileDelete then
				TrinketMenu_PackProfileDelete:Show()
			end
			TrinketMenu.PackProfileScrollFrameUpdate()
			TrinketMenu.PackProfileValidateButtons()
		end
	end
end

--[[ Profiles tab ]]--

function TrinketMenu.ProfileCreateButton_OnClick()
	if TrinketMenu_ProfileCreateFrame then
		TrinketMenu_ProfileCreateFrame:Show()
	end
end

function TrinketMenu.ProfileCreateFrame_OnShow()
	if TrinketMenu.Escable then
		TrinketMenu.Escable("TrinketMenu_ProfileCreateFrame", "add")
	else
		table.insert(UISpecialFrames, "TrinketMenu_ProfileCreateFrame")
	end
	TrinketMenu.ProfileBuilder = {
		raid = nil,
		selectedPack = nil,
		selectedTrinket = nil,
    packDeathTrinkets = {},
    packTargetTrinkets = {},
		timings = {},
	}
	TrinketMenu.ProfileCreateBuildRaidList()
	if TrinketMenu.ProfileEditIndex and TrinketMenuQueue and TrinketMenuQueue.PackProfiles then
		local profile = TrinketMenuQueue.PackProfiles[TrinketMenu.ProfileEditIndex]
		if profile then
			TrinketMenu_ProfileNameEdit:SetText(profile.name or "")
			TrinketMenu.ProfileCreateSelectRaid(profile.raid)
      if profile.packDeathTrinkets then
        for pack, info in pairs(profile.packDeathTrinkets) do
          TrinketMenu.ProfileBuilder.packDeathTrinkets[pack] = { trinket1 = info.trinket1, trinket2 = info.trinket2 }
				end
			elseif profile.packs then
				for _, pack in ipairs(profile.packs) do
          TrinketMenu.ProfileBuilder.packDeathTrinkets[pack] = {}
        end
      end
      if profile.packTargetTrinkets then
        for pack, info in pairs(profile.packTargetTrinkets) do
          TrinketMenu.ProfileBuilder.packTargetTrinkets[pack] = { trinket1 = info.trinket1, trinket2 = info.trinket2 }
				end
			end
			if profile.timings then
				TrinketMenu.ProfileBuilder.timings = profile.timings
			end
		else
			TrinketMenu_ProfileNameEdit:SetText("")
			TrinketMenu.ProfileCreateSelectRaid(TrinketMenu.ProfileRaidList and TrinketMenu.ProfileRaidList[1] or nil)
		end
	else
		TrinketMenu_ProfileNameEdit:SetText("")
		TrinketMenu.ProfileCreateSelectRaid(TrinketMenu.ProfileRaidList and TrinketMenu.ProfileRaidList[1] or nil)
	end
	if not TrinketMenu.TrinketList or TrinketMenu.TrinketListSize == 0 then
		TrinketMenu.UpdateTrinketList()
	end
	TrinketMenu.BuildProfileTrinketList()
	TrinketMenu.ProfileTrinketScrollFrameUpdate()
	TrinketMenu.ProfilePackScrollFrameUpdate()
	TrinketMenu.ProfileUpdatePackTrinketDisplay()
	TrinketMenu.ProfileCreateValidate()
end

function TrinketMenu.ProfileCreateFrame_OnHide()
	if TrinketMenu.Escable then
		TrinketMenu.Escable("TrinketMenu_ProfileCreateFrame", "remove")
	end
	TrinketMenu.ProfileEditIndex = nil
end

function TrinketMenu.ProfileCreateClose_OnClick()
	if TrinketMenu_ProfileCreateFrame then
		TrinketMenu_ProfileCreateFrame:Hide()
	end
end

function TrinketMenu.ProfileCreateCancel_OnClick()
	if TrinketMenu_ProfileCreateFrame then
		TrinketMenu_ProfileCreateFrame:Hide()
	end
end

function TrinketMenu.ProfileNameEdit_OnTextChanged()
	TrinketMenu.ProfileCreateValidate()
end

function TrinketMenu.ProfileCreateValidate()
	local name = TrinketMenu_ProfileNameEdit and TrinketMenu_ProfileNameEdit:GetText() or ""
	name = string.gsub(name, "^%s*(.-)%s*$", "%1")
	local raid = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.raid
	if TrinketMenu_ProfileCreateSave then
		if name ~= "" and raid then
			TrinketMenu_ProfileCreateSave:Enable()
		else
			TrinketMenu_ProfileCreateSave:Disable()
		end
	end
end

function TrinketMenu.ProfileCreateBuildRaidList()
	local list = {}
	if TrinketMenu.packDescriptions then
		for raid in pairs(TrinketMenu.packDescriptions) do
			table.insert(list, raid)
		end
	end
	table.sort(list)
	TrinketMenu.ProfileRaidList = list
	if TrinketMenu_ProfileRaidDropDown then
		UIDropDownMenu_Initialize(TrinketMenu_ProfileRaidDropDown, TrinketMenu.ProfileRaidDropDown_Initialize)
	end
end

function TrinketMenu.ProfileRaidDropDown_OnLoad()
	UIDropDownMenu_SetWidth(150, TrinketMenu_ProfileRaidDropDown)
	UIDropDownMenu_Initialize(TrinketMenu_ProfileRaidDropDown, TrinketMenu.ProfileRaidDropDown_Initialize)
	UIDropDownMenu_SetText("Select Raid", TrinketMenu_ProfileRaidDropDown)
end

UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo or loadstring("local t = {} return function() for k in pairs(t) do t[k] = nil end return t end")()

-- Menu Sorting Dropdown
function TrinketMenu.MenuSortingDropDown_OnLoad()
	UIDropDownMenu_SetWidth(100, TrinketMenu_MenuSortingDropDown)
	UIDropDownMenu_Initialize(TrinketMenu_MenuSortingDropDown, TrinketMenu.MenuSortingDropDown_Initialize)
	local currentSorting = (TrinketMenuOptions and TrinketMenuOptions.MenuSorting) or "Bag Position"
	UIDropDownMenu_SetSelectedValue(TrinketMenu_MenuSortingDropDown, currentSorting)
	UIDropDownMenu_SetText(currentSorting, TrinketMenu_MenuSortingDropDown)
end

function TrinketMenu.MenuSortingDropDown_Initialize()
	local sortOptions = {"Bag Position", "Alphabetical", "Item Level"}
	for _, option in ipairs(sortOptions) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = option
		info.value = option
		info.func = TrinketMenu.MenuSortingDropDown_OnClick
		UIDropDownMenu_AddButton(info)
	end
end

function TrinketMenu.MenuSortingDropDown_OnClick()
	TrinketMenuOptions.MenuSorting = this.value
	UIDropDownMenu_SetSelectedValue(TrinketMenu_MenuSortingDropDown, this.value)
	UIDropDownMenu_SetText(this.value, TrinketMenu_MenuSortingDropDown)
	if TrinketMenu_MenuFrame:IsVisible() then
		TrinketMenu.BuildMenu()
	end
end

function TrinketMenu.ProfileRaidDropDown_Initialize()
	local list = TrinketMenu.ProfileRaidList or {}
	for _, raid in ipairs(list) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = raid
		info.value = raid
		info.func = TrinketMenu.ProfileRaidDropDown_OnClick
		UIDropDownMenu_AddButton(info)
	end
end

function TrinketMenu.ProfileRaidDropDown_OnClick()
	TrinketMenu.ProfileCreateSelectRaid(this.value)
end

function TrinketMenu.ProfileCreateSelectRaid(raid)
	if TrinketMenu_ProfileRaidDropDown then
		if raid then
			UIDropDownMenu_SetSelectedValue(TrinketMenu_ProfileRaidDropDown, raid)
		else
			UIDropDownMenu_SetText("Select Raid", TrinketMenu_ProfileRaidDropDown)
		end
	end
	if TrinketMenu.ProfileBuilder then
		TrinketMenu.ProfileBuilder.raid = raid
		TrinketMenu.ProfileBuilder.selectedPack = nil
		TrinketMenu.ProfileBuilder.selectedTrinket = nil
    TrinketMenu.ProfileBuilder.packDeathTrinkets = {}
    TrinketMenu.ProfileBuilder.packTargetTrinkets = {}
	end
	TrinketMenu.BuildProfilePackList(raid)
	TrinketMenu.ProfilePackScrollFrameUpdate()
	TrinketMenu.ProfileUpdatePackTrinketDisplay()
	TrinketMenu.ProfileCreateValidate()
end

function TrinketMenu.BuildProfilePackList(raid)
	local packs = TrinketMenu.packDescriptions and raid and TrinketMenu.packDescriptions[raid]
	TrinketMenu.ProfilePackList = packs or {}
end

function TrinketMenu.BuildProfileTrinketList()
	local list = {}
	local seen = {}
	local trinkets = TrinketMenu.GetTrinketList()
	for _, trinket in ipairs(trinkets) do
		local id = trinket.itemId
		local name = trinket.trinketName
		local texture = trinket.icon
		if id and not seen[id] then
			seen[id] = true
			texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
			table.insert(list, { itemId = id, name = name or ("Trinket " .. id), icon = texture })
		end
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	table.insert(list, 1, {
		itemId = "clear",
		name = "Clear Slot",
		icon = "Interface\\Icons\\INV_Misc_QuestionMark",
	})
	table.insert(list, 2, {
		itemId = "autoswap",
		name = "Trigger Autoswap",
		icon = "Interface\\AddOns\\TrinketMenu\\TrinketMenu-Gear",
	})
	TrinketMenu.ProfileTrinketList = list
end

function TrinketMenu.ProfilePackScrollFrameUpdate()
	local offset = FauxScrollFrame_GetOffset(TrinketMenu_ProfilePackScroll)
	local list = TrinketMenu.ProfilePackList or {}
	FauxScrollFrame_Update(TrinketMenu_ProfilePackScroll, table.getn(list), 12, 18)

	-- Build trinket lookup table
	local trinketIndex = {}
	for _, trinket in ipairs(TrinketMenu.GetTrinketList()) do
		if trinket.itemId then
			trinketIndex[trinket.itemId] = trinket
		end
	end

	-- Calculate timings from imported data
	local timings = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.timings or {}
	local timingGaps = {}
	local absoluteTimes = {}

	-- Find first engage time
	local firstEngageTime = nil
	for i = 1, table.getn(list) do
		local pack = list[i]
		if pack and timings[pack.packName] and timings[pack.packName].engageTime then
			firstEngageTime = timings[pack.packName].engageTime
			break
		end
	end

	-- Calculate times for each pack
	for i = 1, table.getn(list) do
		local pack = list[i]
		local timing = pack and timings[pack.packName]
		if pack and timing then
			-- Time out of combat
			if timing.timeSinceLastCombat ~= nil then
				timingGaps[pack.packName] = math.floor(timing.timeSinceLastCombat + 0.5)
			end

			-- Absolute time (minutes since first combat)
			if firstEngageTime and timing.engageTime then
				local firstSec = TrinketMenu.ParseTimeToSeconds(firstEngageTime)
				local currSec = TrinketMenu.ParseTimeToSeconds(timing.engageTime)
				if firstSec and currSec then
					local minutes = (currSec - firstSec) / 60
					absoluteTimes[pack.packName] = math.floor(minutes * 10 + 0.5) / 10  -- Round to nearest tenth
				end
			end
		end
	end

	for i = 1, 12 do
		local button = getglobal("TrinketMenu_ProfilePack" .. i)
		local text = getglobal("TrinketMenu_ProfilePack" .. i .. "Text")
		local absoluteTimeText = getglobal("TrinketMenu_ProfilePack" .. i .. "AbsoluteTime")
		local timingText = getglobal("TrinketMenu_ProfilePack" .. i .. "Timing")
		local highlight = getglobal("TrinketMenu_ProfilePack" .. i .. "Highlight")
    local targetTrinket1Icon = getglobal("TrinketMenu_ProfilePack" .. i .. "TargetTrinket1Icon")
    local targetTrinket2Icon = getglobal("TrinketMenu_ProfilePack" .. i .. "TargetTrinket2Icon")
		local trinket1Icon = getglobal("TrinketMenu_ProfilePack" .. i .. "Trinket1Icon")
		local trinket2Icon = getglobal("TrinketMenu_ProfilePack" .. i .. "Trinket2Icon")
		local idx = offset + i
		local row = list[idx]
		if row then
			button:Show()
			text:SetText(row.desc)

			-- Display absolute time
			if absoluteTimeText then
				local absTime = absoluteTimes[row.packName]
				if absTime then
					absoluteTimeText:SetText(string.format("%.1f", absTime))
					absoluteTimeText:SetTextColor(0.7, 0.7, 0.7)
				else
					absoluteTimeText:SetText("")
				end
			end

			-- Display timing gap
			if timingText then
				local gap = timingGaps[row.packName]
				if gap then
					timingText:SetText(string.format("%d", gap))
					timingText:SetTextColor(0.7, 0.7, 0.7)
				else
					timingText:SetText("")
				end
			end
			local selected = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.selectedPack == row.packName
			if selected then
				highlight:Show()
			else
				highlight:Hide()
			end

      -- Display target trinket icons if assigned
      local packTargetTrinkets = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.packTargetTrinkets and TrinketMenu.ProfileBuilder.packTargetTrinkets[row.packName]
      if packTargetTrinkets and packTargetTrinkets.trinket1 then
        if packTargetTrinkets.trinket1 == "autoswap" then
          targetTrinket1Icon:SetTexture("Interface\\AddOns\\TrinketMenu\\TrinketMenu-Gear")
          targetTrinket1Icon:Show()
        else
          local trinket = trinketIndex[packTargetTrinkets.trinket1]
          if trinket and trinket.icon then
            targetTrinket1Icon:SetTexture(trinket.icon)
            targetTrinket1Icon:Show()
          else
            targetTrinket1Icon:Hide()
          end
        end
      else
        targetTrinket1Icon:Hide()
      end

      if packTargetTrinkets and packTargetTrinkets.trinket2 then
        if packTargetTrinkets.trinket2 == "autoswap" then
          targetTrinket2Icon:SetTexture("Interface\\AddOns\\TrinketMenu\\TrinketMenu-Gear")
          targetTrinket2Icon:Show()
        else
          local trinket = trinketIndex[packTargetTrinkets.trinket2]
          if trinket and trinket.icon then
            targetTrinket2Icon:SetTexture(trinket.icon)
            targetTrinket2Icon:Show()
          else
            targetTrinket2Icon:Hide()
          end
        end
      else
        targetTrinket2Icon:Hide()
      end

      -- Display on-death trinket icons if assigned
      local packDeathTrinkets = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.packDeathTrinkets and TrinketMenu.ProfileBuilder.packDeathTrinkets[row.packName]
      if packDeathTrinkets and packDeathTrinkets.trinket1 then
        if packDeathTrinkets.trinket1 == "autoswap" then
					trinket1Icon:SetTexture("Interface\\AddOns\\TrinketMenu\\TrinketMenu-Gear")
					trinket1Icon:Show()
				else
          local trinket = trinketIndex[packDeathTrinkets.trinket1]
					if trinket and trinket.icon then
						trinket1Icon:SetTexture(trinket.icon)
						trinket1Icon:Show()
					else
						trinket1Icon:Hide()
					end
				end
			else
				trinket1Icon:Hide()
			end

      if packDeathTrinkets and packDeathTrinkets.trinket2 then
        if packDeathTrinkets.trinket2 == "autoswap" then
					trinket2Icon:SetTexture("Interface\\AddOns\\TrinketMenu\\TrinketMenu-Gear")
					trinket2Icon:Show()
				else
          local trinket = trinketIndex[packDeathTrinkets.trinket2]
					if trinket and trinket.icon then
						trinket2Icon:SetTexture(trinket.icon)
						trinket2Icon:Show()
					else
						trinket2Icon:Hide()
					end
				end
			else
				trinket2Icon:Hide()
			end
		else
      if targetTrinket1Icon then
        targetTrinket1Icon:Hide()
      end
      if targetTrinket2Icon then
        targetTrinket2Icon:Hide()
      end
			button:Hide()
		end
	end
end

function TrinketMenu.ProfileTrinketScrollFrameUpdate()
	local offset = FauxScrollFrame_GetOffset(TrinketMenu_ProfileTrinketScroll)
	local list = TrinketMenu.ProfileTrinketList or {}
	FauxScrollFrame_Update(TrinketMenu_ProfileTrinketScroll, table.getn(list), 12, 18)
	for i = 1, 12 do
		local button = getglobal("TrinketMenu_ProfileTrinket" .. i)
		local text = getglobal("TrinketMenu_ProfileTrinket" .. i .. "Text")
		local icon = getglobal("TrinketMenu_ProfileTrinket" .. i .. "Icon")
		local highlight = getglobal("TrinketMenu_ProfileTrinket" .. i .. "Highlight")
		local idx = offset + i
		local row = list[idx]
		if row then
			button:Show()
			text:SetText(row.name)
			icon:SetTexture(row.icon)
			local selected = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.selectedTrinket == row.itemId
			if selected then
				highlight:Show()
			else
				highlight:Hide()
			end
		else
			button:Hide()
		end
	end
end

function TrinketMenu.ProfilePack_OnClick()
	local idx = FauxScrollFrame_GetOffset(TrinketMenu_ProfilePackScroll) + this:GetID()
	local row = TrinketMenu.ProfilePackList and TrinketMenu.ProfilePackList[idx]
	if not row or not TrinketMenu.ProfileBuilder then
		return
	end
	TrinketMenu.ProfileBuilder.selectedPack = row.packName
	TrinketMenu.ProfileBuilder.selectedTrinket = nil
  TrinketMenu.ProfileBuilder.packDeathTrinkets[row.packName] = TrinketMenu.ProfileBuilder.packDeathTrinkets[row.packName] or {}
  TrinketMenu.ProfileBuilder.packTargetTrinkets[row.packName] = TrinketMenu.ProfileBuilder.packTargetTrinkets[row.packName] or {}
	TrinketMenu.ProfilePackScrollFrameUpdate()
	TrinketMenu.ProfileTrinketScrollFrameUpdate()
	TrinketMenu.ProfileUpdatePackTrinketDisplay()
end

function TrinketMenu.ProfileTrinket_OnClick()
	local idx = FauxScrollFrame_GetOffset(TrinketMenu_ProfileTrinketScroll) + this:GetID()
	local row = TrinketMenu.ProfileTrinketList and TrinketMenu.ProfileTrinketList[idx]
	if not row or not TrinketMenu.ProfileBuilder then
		return
	end
	if not TrinketMenu.ProfileBuilder.selectedPack then
		return
	end
	TrinketMenu.ProfileBuilder.selectedTrinket = row.itemId
  local targetOnSelect = IsShiftKeyDown and IsShiftKeyDown()
  local packName = TrinketMenu.ProfileBuilder.selectedPack
  local trinketMap = targetOnSelect and TrinketMenu.ProfileBuilder.packTargetTrinkets or TrinketMenu.ProfileBuilder.packDeathTrinkets
  trinketMap[packName] = trinketMap[packName] or {}
	if arg1 == "RightButton" then
    trinketMap[packName].trinket2 = row.itemId ~= "clear" and row.itemId or nil
	else
    trinketMap[packName].trinket1 = row.itemId ~= "clear" and row.itemId or nil
	end
  TrinketMenu.ProfilePackScrollFrameUpdate()
	TrinketMenu.ProfileTrinketScrollFrameUpdate()
	TrinketMenu.ProfileUpdatePackTrinketDisplay()
end

function TrinketMenu.ProfileUpdatePackTrinketDisplay()
	local pack = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.selectedPack
  local info = pack and TrinketMenu.ProfileBuilder.packDeathTrinkets and TrinketMenu.ProfileBuilder.packDeathTrinkets[pack] or nil
  local targetInfo = pack and TrinketMenu.ProfileBuilder.packTargetTrinkets and TrinketMenu.ProfileBuilder.packTargetTrinkets[pack] or nil

	-- Update pack description text
	local packDesc = ""
	if pack and TrinketMenu.ProfilePackList then
		for _, packInfo in ipairs(TrinketMenu.ProfilePackList) do
			if packInfo.packName == pack then
				packDesc = packInfo.desc or ""
				break
			end
		end
	end
	if TrinketMenu_PackDescriptionText then
		TrinketMenu_PackDescriptionText:SetText(packDesc)
	end
  local isOnEnterPack = pack == "on_enter"
  if TrinketMenu_PackTargetInstructionText then
    if isOnEnterPack then
      TrinketMenu_PackTargetInstructionText:Hide()
    else
      TrinketMenu_PackTargetInstructionText:Show()
    end
  end
  if TrinketMenu_PackInstructionText then
    TrinketMenu_PackInstructionText:ClearAllPoints()
    if isOnEnterPack then
      TrinketMenu_PackInstructionText:SetText("The first time you enter the instance, equip:")
      if TrinketMenu_PackDescriptionText then
        TrinketMenu_PackInstructionText:SetPoint("TOPLEFT", TrinketMenu_PackDescriptionText, "BOTTOMLEFT", 0, -2)
      end
    else
      TrinketMenu_PackInstructionText:SetText("(Left/right click in list) When a mob in this pack dies, equip:")
      if TrinketMenu_PackTargetTrinket1Icon then
        TrinketMenu_PackInstructionText:SetPoint("TOPLEFT", TrinketMenu_PackTargetTrinket1Icon, "BOTTOMLEFT", -6, -6)
      end
    end
  end
  local targetFrames = {
    "TrinketMenu_PackTargetTrinket1Icon",
    "TrinketMenu_PackTargetTrinket1Text",
    "TrinketMenu_PackTargetTrinket2Icon",
    "TrinketMenu_PackTargetTrinket2Text",
    "TrinketMenu_PackTargetTrinket1ClearButton",
    "TrinketMenu_PackTargetTrinket2ClearButton",
    "TrinketMenu_PackTargetTrinket1SinceTooltip",
    "TrinketMenu_PackTargetTrinket2SinceTooltip",
  }
  for _, frameName in ipairs(targetFrames) do
    local frame = getglobal(frameName)
    if frame then
      if isOnEnterPack then
        frame:Hide()
      else
        frame:Show()
      end
    end
  end

	local trinketIndex = {}
	for _, trinket in ipairs(TrinketMenu.GetTrinketList()) do
		if trinket.itemId then
			trinketIndex[trinket.itemId] = trinket
		end
	end
	local timingList = TrinketMenu.ProfilePackList or {}
  local packDeathTrinkets = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.packDeathTrinkets or {}
  local packTargetTrinkets = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.packTargetTrinkets or {}
	local packTimings = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.timings or {}
	local currentIndex = nil
	if pack then
		for i, packInfo in ipairs(timingList) do
			if packInfo.packName == pack then
				currentIndex = i
				break
      end
    end
  end
  local firstEngageSec = nil
  for i, packInfo in ipairs(timingList) do
    local timing = packInfo and packTimings[packInfo.packName]
    if timing and timing.engageTime then
      firstEngageSec = TrinketMenu.ParseTimeToSeconds(timing.engageTime)
      if firstEngageSec then
        break
			end
		end
	end

	local function formatCooldown(durationMs)
		if not durationMs or durationMs <= 0 then
			return nil
		end
		local cooldown = durationMs / 1000
		if cooldown > 7200 then
			return nil
		end
		if cooldown < 60 then
			return string.format("%.1f sec cd", cooldown)
		elseif cooldown < 3600 then
			return string.format("%.1f min cd", cooldown / 60)
		end
		return string.format("%.1f hr cd", cooldown / 3600)
	end

	local function formatElapsed(seconds)
		if not seconds or seconds < 0 then
			return nil
		end
		if seconds < 60 then
			return string.format("~%.1fs", seconds)
		elseif seconds < 3600 then
			return string.format("~%.1fm", seconds / 60)
		end
		return string.format("~%.1fh", seconds / 3600)
	end

  local function getUseTimeForTarget(packName)
    if packName == "on_enter" then
      return firstEngageSec
    end
    local timing = packName and packTimings[packName]
    return timing and timing.engageTime and TrinketMenu.ParseTimeToSeconds(timing.engageTime) or nil
  end

  local function getUseTimeForDeath(packIndex)
    local packInfo = packIndex and timingList[packIndex]
    if packInfo and packInfo.packName == "on_enter" then
      return firstEngageSec
    end
    local nextPack = packIndex and timingList[packIndex + 1]
    local timing = nextPack and packTimings[nextPack.packName]
    return timing and timing.engageTime and TrinketMenu.ParseTimeToSeconds(timing.engageTime) or nil
  end

  local function getSinceLastUseLine(itemId, useMode)
		if not itemId or itemId == "autoswap" then
			return nil
		end
    if not currentIndex then
			return "Since last use: --"
		end
    local currentSec
    if useMode == "target" then
      currentSec = getUseTimeForTarget(pack)
    else
      currentSec = getUseTimeForDeath(currentIndex)
    end
		if not currentSec then
			return "Since last use: --"
		end
		for i = currentIndex - 1, 1, -1 do
			local packInfo = timingList[i]
      local packName = packInfo and packInfo.packName
      local targetInfo = packName and packTargetTrinkets[packName]
      local deathInfo = packName and packDeathTrinkets[packName]
      local candidateSec = nil
      if targetInfo and (targetInfo.trinket1 == itemId or targetInfo.trinket2 == itemId) then
        candidateSec = getUseTimeForTarget(packName)
      end
      if deathInfo and (deathInfo.trinket1 == itemId or deathInfo.trinket2 == itemId) then
        local deathSec = getUseTimeForDeath(i)
        if deathSec and (not candidateSec or deathSec > candidateSec) then
          candidateSec = deathSec
        end
      end
      if candidateSec and candidateSec <= currentSec then
        local elapsed = formatElapsed(math.max(0, currentSec - candidateSec))
        if elapsed then
          return "Since last use: " .. elapsed
				end
			end
		end
		return "Since last use: --"
	end

  local function setDisplay(slot, itemId, iconFrameName, textFrameName, showSince, clearButtonName, sinceTooltipFrameName)
    local iconFrame = getglobal(iconFrameName)
    local textFrame = getglobal(textFrameName)
		if not iconFrame or not textFrame then
			return
		end
    local clearButton = clearButtonName and getglobal(clearButtonName)
    if clearButton then
      if itemId then
        clearButton:Enable()
      else
        clearButton:Disable()
      end
    end
    local sinceTooltip = sinceTooltipFrameName and getglobal(sinceTooltipFrameName)
    if sinceTooltip then
      sinceTooltip:Hide()
    end
		if itemId == "autoswap" then
			textFrame:SetText("Trinket" .. slot .. ": Trigger Autoswap")
			iconFrame:SetTexture("Interface\\AddOns\\TrinketMenu\\TrinketMenu-Gear")
			return
		end
		if itemId then
			local trinket = trinketIndex[itemId]
			local name = (trinket and trinket.trinketName) or itemId
			local texture = trinket and trinket.icon
			local cooldownSuffix = ""
			local sinceLine = nil
			if trinket and trinket.trinketName and GetTrinketCooldown then
				local cooldownData = GetTrinketCooldown(trinket.trinketName)
				if cooldownData then
					local individual = cooldownData.individualDurationMs or 0
					local category = cooldownData.categoryDurationMs or 0
					if individual > 7200000 then
						individual = 0
					end
					if category > 7200000 then
						category = 0
					end
					local maxDuration = math.max(individual, category)
					local cooldownText = formatCooldown(maxDuration)
					if cooldownText then
						cooldownSuffix = " (" .. cooldownText .. ")"
            if showSince then
              sinceLine = getSinceLastUseLine(itemId, showSince)
            end
					end
				end
			end
			texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
      local displayText
			if sinceLine then
        displayText = "Trinket" .. slot .. ": " .. name .. cooldownSuffix .. "\n" .. sinceLine
			else
        displayText = "Trinket" .. slot .. ": " .. name .. cooldownSuffix
      end
      textFrame:SetText(displayText)
      if sinceLine and sinceTooltip then
        local width = textFrame.GetStringWidth and textFrame:GetStringWidth() or (textFrame:GetWidth() or 0)
        local height = textFrame:GetHeight() or 0
        if height <= 0 then
          height = 24
        end
        sinceTooltip:ClearAllPoints()
        sinceTooltip:SetPoint("TOPLEFT", textFrame, "TOPLEFT", 0, 0)
        sinceTooltip:SetWidth(math.max(1, width))
        sinceTooltip:SetHeight(math.max(1, height))
        sinceTooltip:Show()
			end
			iconFrame:SetTexture(texture)
		else
			textFrame:SetText("Trinket" .. slot .. ": None")
			iconFrame:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end
  setDisplay(1, targetInfo and targetInfo.trinket1, "TrinketMenu_PackTargetTrinket1Icon", "TrinketMenu_PackTargetTrinket1Text", "target", "TrinketMenu_PackTargetTrinket1ClearButton", "TrinketMenu_PackTargetTrinket1SinceTooltip")
  setDisplay(2, targetInfo and targetInfo.trinket2, "TrinketMenu_PackTargetTrinket2Icon", "TrinketMenu_PackTargetTrinket2Text", "target", "TrinketMenu_PackTargetTrinket2ClearButton", "TrinketMenu_PackTargetTrinket2SinceTooltip")
  setDisplay(1, info and info.trinket1, "TrinketMenu_PackTrinket1Icon", "TrinketMenu_PackTrinket1Text", "death", "TrinketMenu_PackTrinket1ClearButton", "TrinketMenu_PackTrinket1SinceTooltip")
  setDisplay(2, info and info.trinket2, "TrinketMenu_PackTrinket2Icon", "TrinketMenu_PackTrinket2Text", "death", "TrinketMenu_PackTrinket2ClearButton", "TrinketMenu_PackTrinket2SinceTooltip")
end

function TrinketMenu.ProfileCreateSave_OnClick()
	local name = TrinketMenu_ProfileNameEdit and TrinketMenu_ProfileNameEdit:GetText() or ""
	name = string.gsub(name, "^%s*(.-)%s*$", "%1")
	local raid = TrinketMenu.ProfileBuilder and TrinketMenu.ProfileBuilder.raid
	if name == "" or not raid then
		return
	end
	TrinketMenuQueue = TrinketMenuQueue or {}
	TrinketMenuQueue.PackProfiles = TrinketMenuQueue.PackProfiles or {}
	local profile = {
		name = name,
		raid = raid,
		packs = {},
		trinkets = {},
    packDeathTrinkets = {},
    packTargetTrinkets = {},
		timings = TrinketMenu.ProfileBuilder.timings or {},
	}
  for pack, info in pairs(TrinketMenu.ProfileBuilder.packDeathTrinkets or {}) do
		table.insert(profile.packs, pack)
    profile.packDeathTrinkets[pack] = { trinket1 = info.trinket1, trinket2 = info.trinket2 }
	end
  for pack, info in pairs(TrinketMenu.ProfileBuilder.packTargetTrinkets or {}) do
    if not profile.packDeathTrinkets[pack] then
      table.insert(profile.packs, pack)
    end
    profile.packTargetTrinkets[pack] = { trinket1 = info.trinket1, trinket2 = info.trinket2 }
  end
	if table.getn(profile.packs) == 0 and TrinketMenu.ProfileBuilder.selectedPack then
		table.insert(profile.packs, TrinketMenu.ProfileBuilder.selectedPack)
	end
	table.sort(profile.packs)
	if TrinketMenu.ProfileEditIndex and TrinketMenuQueue.PackProfiles[TrinketMenu.ProfileEditIndex] then
		TrinketMenuQueue.PackProfiles[TrinketMenu.ProfileEditIndex] = profile
		if TrinketMenuQueue.PackProfileActive == TrinketMenu.ProfileEditIndex then
			TrinketMenu.ApplyPackProfileActivation(profile)
		end
	else
		table.insert(TrinketMenuQueue.PackProfiles, 1, profile)
	end
	TrinketMenu_ProfileCreateFrame:Hide()
	TrinketMenu.PackProfileScrollFrameUpdate()
end

function TrinketMenu.PackProfileScrollFrameUpdate()
	local list = TrinketMenuQueue and TrinketMenuQueue.PackProfiles or {}
	local offset = FauxScrollFrame_GetOffset(TrinketMenu_PackProfileScroll)
	FauxScrollFrame_Update(TrinketMenu_PackProfileScroll, table.getn(list), 8, 20)
	if TrinketMenu_PackProfileEmptyText then
		if table.getn(list) == 0 then
			TrinketMenu_PackProfileEmptyText:Show()
		else
			TrinketMenu_PackProfileEmptyText:Hide()
		end
	end
	for i = 1, 8 do
		local button = getglobal("TrinketMenu_PackProfile" .. i)
		local text = getglobal("TrinketMenu_PackProfile" .. i .. "Text")
		local highlight = getglobal("TrinketMenu_PackProfile" .. i .. "Highlight")
		local active = getglobal("TrinketMenu_PackProfile" .. i .. "Active")
		local idx = offset + i
		local profile = list[idx]
		if profile then
			button:Show()
			text:SetText((profile.name or "Profile") .. " - " .. (profile.raid or ""))
			if active then
				if TrinketMenuQueue and TrinketMenuQueue.PackProfileActive == idx then
					active:Show()
				else
					active:Hide()
				end
			end
			if TrinketMenu.PackProfileSelected == idx then
				highlight:Show()
			else
				highlight:Hide()
			end
		else
			button:Hide()
		end
	end
	TrinketMenu.PackProfileValidateButtons()
end

function TrinketMenu.PackProfileValidateButtons()
	local enabled = TrinketMenu.PackProfileSelected ~= nil
	local isActive = TrinketMenuQueue and TrinketMenuQueue.PackProfileActive == TrinketMenu.PackProfileSelected
	if TrinketMenu_PackProfileEdit then
		if enabled then
			TrinketMenu_PackProfileEdit:Enable()
		else
			TrinketMenu_PackProfileEdit:Disable()
		end
	end
	if TrinketMenu_PackProfileDelete then
		if enabled then
			TrinketMenu_PackProfileDelete:Enable()
		else
			TrinketMenu_PackProfileDelete:Disable()
		end
	end
	if TrinketMenu_PackProfileActivate then
		TrinketMenu_PackProfileActivate:SetText(isActive and "Deactivate" or "Activate")
		if enabled then
			TrinketMenu_PackProfileActivate:Enable()
		else
			TrinketMenu_PackProfileActivate:Disable()
		end
	end
end

function TrinketMenu.PackProfileList_OnClick()
	local idx = FauxScrollFrame_GetOffset(TrinketMenu_PackProfileScroll) + this:GetID()
	local list = TrinketMenuQueue and TrinketMenuQueue.PackProfiles or {}
	if list[idx] then
		TrinketMenu.PackProfileSelected = idx
	else
		TrinketMenu.PackProfileSelected = nil
	end
	TrinketMenu.PackProfileScrollFrameUpdate()
end

function TrinketMenu.PackProfileEdit_OnClick()
	if not TrinketMenu.PackProfileSelected then
		return
	end
	TrinketMenu.ProfileEditIndex = TrinketMenu.PackProfileSelected
	TrinketMenu_ProfileCreateFrame:Show()
end

function TrinketMenu.PackProfileDelete_OnClick()
	local idx = TrinketMenu.PackProfileSelected
	if not idx or not TrinketMenuQueue or not TrinketMenuQueue.PackProfiles then
		return
	end
	local profile = TrinketMenuQueue.PackProfiles[idx]
	if profile then
		StaticPopupDialogs.TrinketMenu_PackProfileDelete = {
			text = "Delete profile \"" .. (profile.name or "Profile") .. "\"?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				table.remove(TrinketMenuQueue.PackProfiles, idx)
				TrinketMenu.AdjustPackProfileIndexesAfterDelete(idx)
				if TrinketMenu.UpdateActiveProfileText then
					TrinketMenu.UpdateActiveProfileText()
				end
				TrinketMenu.PackProfileSelected = nil
				TrinketMenu.PackProfileScrollFrameUpdate()
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
		}
		StaticPopup_Show("TrinketMenu_PackProfileDelete")
		return
	end
	table.remove(TrinketMenuQueue.PackProfiles, idx)
	TrinketMenu.AdjustPackProfileIndexesAfterDelete(idx)
	TrinketMenu.UpdateActiveProfileText()
	TrinketMenu.PackProfileSelected = nil
	TrinketMenu.PackProfileScrollFrameUpdate()
end

function TrinketMenu.BuildPackProfileGuidTrinkets(profile)
	local map = {}
  if not profile or not profile.packDeathTrinkets then
		TrinketMenu.PackProfileGuidTrinkets = map
    TrinketMenu.PackProfileTargetGuidTrinkets = {}
		if profile then
			print("|cff00ff00TrinketMenu:|r Error activating profile " .. (profile.name or "Unknown"))
		end
		return
	end

	local numPacksFound = 0
	local raidPacks = profile.raid and TrinketMenu.packDescriptions and TrinketMenu.packDescriptions[profile.raid] or nil

	-- Build a lookup table for pack name -> pack data
	local packLookup = {}
	if raidPacks then
		for _, pack in ipairs(raidPacks) do
			if pack.packName then
				packLookup[pack.packName] = pack
			end
		end
	end

  for packName, trinkets in pairs(profile.packDeathTrinkets) do
		local pack = packLookup[packName]
		if pack and pack.mob_guids then
			numPacksFound = numPacksFound + 1
			for _, guid in ipairs(pack.mob_guids) do
				map[guid] = { trinket1 = trinkets.trinket1, trinket2 = trinkets.trinket2, packName = packName }
			end
		end
	end

	print("|cff00ff00TrinketMenu:|r Activated profile " .. profile.name .. " with swaps on " .. tostring(numPacksFound) .. " packs.")
	TrinketMenu.PackProfileGuidTrinkets = map
  local targetGuidMap = {}
  for packName, trinkets in pairs(profile.packTargetTrinkets or {}) do
    local pack = packLookup[packName]
    if pack then
      if pack.mob_guids then
        for _, guid in ipairs(pack.mob_guids) do
          targetGuidMap[guid] = { trinket1 = trinkets.trinket1, trinket2 = trinkets.trinket2, packName = packName }
        end
      end
    end
  end
  TrinketMenu.PackProfileTargetGuidTrinkets = targetGuidMap
end

function TrinketMenu.PackProfileActivate_OnClick()
	local idx = TrinketMenu.PackProfileSelected
	if not idx or not TrinketMenuQueue or not TrinketMenuQueue.PackProfiles then
		return
	end
	if TrinketMenuQueue.PackProfileActive == idx then
		TrinketMenu.ClearActivePackProfile()
	else
		TrinketMenu.SetActivePackProfile(idx)
	end
	TrinketMenu.UpdateActiveProfileText()
	TrinketMenu.PackProfileScrollFrameUpdate()
end

function TrinketMenu.ApplyPackProfileActivation(profile)
	if not profile or not TrinketMenu.hasNampower then
		return
	end
	TrinketMenu.BuildPackProfileGuidTrinkets(profile)
	TrinketMenu.UpdateActiveProfileText()
end

-- Parse time string "M/D HH:MM:SS.mmm" to seconds
function TrinketMenu.ParseTimeToSeconds(timeStr)
	if not timeStr then return nil end
	local monthDay, timepart = string.match(timeStr, "(%d+/%d+)%s+(.+)")
	if not timepart then return nil end
	local hour, min, sec = string.match(timepart, "(%d+):(%d+):([%d%.]+)")
	if not hour then return nil end
	return tonumber(hour) * 3600 + tonumber(min) * 60 + tonumber(sec)
end

function TrinketMenu.ProfileImportTimings_OnClick()
	if not TrinketMenu.ProfileBuilder then
		return
	end

	StaticPopupDialogs["TRINKETMENU_IMPORT_TIMINGS"] = {
		text = "Use generate_pack_timings.py and paste the contents of PackTimings.lua here:",
		button1 = "Import",
		button2 = "Cancel",
		hasEditBox = 1,
		hasWideEditBox = 1,
		editBoxWidth = 350,
		maxLetters = 0,
		OnShow = function()
			getglobal(this:GetName().."WideEditBox"):SetText("")
			getglobal(this:GetName().."WideEditBox"):SetFocus()
		end,
		OnAccept = function()
			local text = getglobal(this:GetParent():GetName().."WideEditBox"):GetText()
			TrinketMenu.ImportPackTimings(text)
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
	StaticPopup_Show("TRINKETMENU_IMPORT_TIMINGS")
end

function TrinketMenu.ImportPackTimings(luaCode)
	if not luaCode or luaCode == "" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TrinketMenu:|r No timing data provided.")
		return
	end

	-- Parse the Lua table
	local timings = {}
	local success, err = pcall(function()
		-- Extract the table content
		local tableContent = string.match(luaCode, "local%s+packTimings%s*=%s*(%b{})")
		if not tableContent then
			tableContent = string.match(luaCode, "^%s*(%b{})%s*$")
		end
		if not tableContent then
			error("Could not find valid Lua table in input")
		end

		-- Parse each pack entry
		for packBlock in string.gmatch(tableContent, '%[%"([^%"]+)%"%]%s*=%s*(%b{})') do end

		for packName, packData in string.gmatch(tableContent, '%[%"([^%"]+)%"%]%s*=%s*(%b{})') do
			local engageTime = string.match(packData, 'engageTime%s*=%s*%"([^%"]+)%"')
			local deathTimesStr = string.match(packData, 'deathTimes%s*=%s*(%b{})')
			local timeSinceLastCombat = string.match(packData, 'timeSinceLastCombat%s*=%s*([%d%.]+)')

			if engageTime then
				local deathTimes = {}
				if deathTimesStr then
					for deathTime in string.gmatch(deathTimesStr, '%"([^%"]+)%"') do
						table.insert(deathTimes, deathTime)
					end
				end

				timings[packName] = {
					engageTime = engageTime,
					deathTimes = deathTimes,
					timeSinceLastCombat = timeSinceLastCombat and tonumber(timeSinceLastCombat) or nil
				}
			end
		end
	end)

	if not success then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TrinketMenu:|r Failed to parse timing data: " .. tostring(err))
		return
	end

	if not next(timings) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TrinketMenu:|r No valid pack timings found in input.")
		return
	end

	-- Store timings in ProfileBuilder
	TrinketMenu.ProfileBuilder.timings = timings
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TrinketMenu:|r Imported timing data for " .. tostring(TrinketMenu.TableCount(timings)) .. " packs.")

	-- Refresh the pack list display
	TrinketMenu.ProfilePackScrollFrameUpdate()
end

function TrinketMenu.TableCount(t)
	local count = 0
	for _ in pairs(t) do count = count + 1 end
	return count
end
