for i = 1, #perk_list do
	local perk = perk_list[i]
	if ModSettingGet("PerkBanishing." .. perk.id) then
		perk_list[i].PerkBanishingApplied = true
		perk_list[i].not_in_default_perk_pool = true
	end
end
