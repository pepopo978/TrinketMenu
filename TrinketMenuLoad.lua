local function HasMinimumNampowerVersion(major, minor, patch)
	if GetNampowerVersion then
		local installedMajor, installedMinor, installedPatch = GetNampowerVersion()

		if installedMajor > major then
			return true
		elseif installedMajor == major and installedMinor > minor then
			return true
		elseif installedMajor == major and installedMinor == minor and installedPatch >= patch then
			return true
		end
	end

	return false
end

if not HasMinimumNampowerVersion(2, 20, 0) then
	DEFAULT_CHAT_FRAME:AddMessage("Nampower v2.20.0 or greater is required for TrinketMenu V4")
	return
end

TrinketMenu = {
  packDescriptions = {},
  OnEnterUsed = {}
}

TrinketMenu.AddRaid = function(raidName, raidPackData)
  if raidPackData and (not raidPackData[1] or raidPackData[1].packName ~= "on_enter") then
    table.insert(raidPackData, 1, {
      packName = "on_enter",
      desc = "On Enter",
      mob_names = {},
      mob_guids = {}
    })
  end
  TrinketMenu.packDescriptions[raidName] = raidPackData
  TrinketMenu.addPackGuids(raidPackData)
end
