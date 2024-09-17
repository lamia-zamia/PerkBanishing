dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id = "PerkBanishing"
local setting_prfx = mod_id .. "."
local show_window = false
local T = {}
local D = {}
local gui_id = 1000
local function id()
	gui_id = gui_id + 1
	return gui_id
end
-- ###########################################
-- ############		Helpers		##############
-- ###########################################

local U = {
	offset = 0,
}
do --helpers
	---@param gui gui
	---@param array mod_settings_global|mod_settings
	---@return number
	function U.calculate_elements_offset(gui, array)
		local max_width = 10
		for _, setting in ipairs(array) do
			if setting.category_id then
				cat_max_width = U.calculate_elements_offset(gui, setting.settings)
				max_width = math.max(max_width, cat_max_width)
			end
			if setting.ui_name then
				local name_length = GuiGetTextDimensions(gui, setting.ui_name)
				max_width = math.max(max_width, name_length)
			end
		end
		return max_width + 3
	end

	---@param setting_name setting_id
	---@param value setting_value
	function U.set_setting(setting_name, value)
		ModSettingSet(setting_prfx .. setting_name, value)
		ModSettingSetNextValue(setting_prfx .. setting_name, value, false)
	end

	---@param setting_name setting_id
	---@return setting_value?
	function U.get_setting(setting_name)
		return ModSettingGet(setting_prfx .. setting_name)
	end

	---@param setting_name setting_id
	function U.remove_setting(setting_name)
		ModSettingRemove(setting_prfx .. setting_name)
	end

	function U.reset_settings()
		for i = 1, #perk_list do
			U.remove_setting(perk_list[i].id)
		end
	end
end
-- ###########################################
-- ##########		GUI Helpers		##########
-- ###########################################

local G = {

}
do --gui helpers
	function G.button_options(gui)
		GuiOptionsAddForNextWidget(gui, 4)
		GuiOptionsAddForNextWidget(gui, 7)
		GuiOptionsAddForNextWidget(gui, 8)
	end

	---@param gui gui
	---@param hovered boolean
	function G.yellow_if_hovered(gui, hovered)
		if hovered then GuiColorSetForNextWidget(gui, 1, 1, 0.7, 1) end
	end

	---@param gui gui
	---@param setting_name setting_id
	function G.toggle_checkbox_boolean(gui, setting_name)
		local text = T[setting_name]
		local _, _, _, prev_x, y, prev_w = GuiGetPreviousWidgetInfo(gui)
		local x = prev_x + prev_w + 1
		local value = U.get_setting(setting_name)
		local offset_w = GuiGetTextDimensions(gui, text) + 8

		GuiZSetForNextWidget(gui, -1)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x + 2, y, offset_w, 10, 0) --hover box
		local _, _, hovered = GuiGetPreviousWidgetInfo(gui)
		GuiZSetForNextWidget(gui, 1)
		GuiImageNinePiece(gui, id(), x + 2, y + 2, 6, 6) --check box

		GuiText(gui, 4, 0, "")
		if value then
			GuiColorSetForNextWidget(gui, 0, 0.8, 0, 1)
			GuiText(gui, 0, 0, "V")
			GuiText(gui, 0, 0, " ")
			G.yellow_if_hovered(gui, hovered)
		else
			GuiColorSetForNextWidget(gui, 0.8, 0, 0, 1)
			GuiText(gui, 0, 0, "X")
			GuiText(gui, 0, 0, " ")
			G.yellow_if_hovered(gui, hovered)
		end
		GuiText(gui, 0, 0, text)
		if hovered then
			G.on_clicks(setting_name, not value, D[setting_name])
		end
	end

	---@param setting_name setting_id
	---@param value setting_value
	---@param default setting_value
	function G.on_clicks(setting_name, value, default)
		if InputIsMouseButtonJustDown(1) then
			U.set_setting(setting_name, value)
		end
		if InputIsMouseButtonJustDown(2) then
			GamePlaySound("ui", "ui/button_click", 0, 0)
			U.set_setting(setting_name, default)
		end
	end

	function G.display_perk_window(_, gui, _, _, setting)
		local start_x = 510
		local start_y = 60
		local box_height = 200
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
		GuiBeginScrollContainer(gui, id(), start_x, start_y, 118, 10)
		local text_width = GuiGetTextDimensions(gui, T.name)
		GuiText(gui, (118 - text_width) / 2, 0, T.name)
		GuiEndScrollContainer(gui)
		local x = 0
		local y = 0
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NoLayouting)
		GuiBeginScrollContainer(gui, id(), start_x, start_y + 20, 110, box_height)
		for i = 1, #perk_list do
			local perk = perk_list[i]
			if perk.not_in_default_perk_pool and not perk.PerkBanishingApplied then goto continue end
			if x >= 110 then
				x = 0
				y = y + 16
			end
			local banished = U.get_setting(perk.id)
			if banished then GuiColorSetForNextWidget(gui, 0.3, 0.3, 0.3, 1) end
			GuiImage(gui, id(), x, y, perk.perk_icon, 1, 1, 1)
			local clicked, _, hovered, _, img_y = GuiGetPreviousWidgetInfo(gui)
			if img_y - 12 > start_y and img_y - 12 < start_y + box_height then
				if hovered then
					local description = banished and T.did or GameTextGetTranslatedOrNot(perk.ui_description)
					GuiTooltip(gui, GameTextGetTranslatedOrNot(perk.ui_name), description)
				end
				if clicked then
					GamePlaySound("ui", "ui/button_click", 0, 0)
					if banished then
						U.remove_setting(perk.id)
					else
						U.set_setting(perk.id, true)
					end
				end
			end
			x = x + 16
			::continue::
		end
		GuiEndScrollContainer(gui)
	end
end
-- ###########################################
-- ########		Settings GUI		##########
-- ###########################################

local S = {

}
do -- Settings GUI
	function S.mod_setting_better_boolean(_, gui, _, _, setting)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
		GuiLayoutBeginHorizontal(gui, U.offset, 0, true, 0, 0)
		GuiText(gui, 7, 0, "")
		for _, setting_id in ipairs(setting.checkboxes) do
			G.toggle_checkbox_boolean(gui, setting_id)
		end
		GuiLayoutEnd(gui)
	end

	function S.toggle_display(_, gui, _, _, setting)
		if not U.get_setting("enable_mod") then return end
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiText(gui, 0, 0, "")
		local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
		local text = "[" .. (show_window and T["hide"] or T["show"]) .. " " .. T["window"] .. "]"
		local width, height = GuiGetTextDimensions(gui, text)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x, y, width, height, 0)
		local clicked, _, hovered = GuiGetPreviousWidgetInfo(gui)
		G.yellow_if_hovered(gui, hovered)
		GuiText(gui, 0, 0, text)
		if clicked then
			show_window = not show_window
		end
		if show_window then G.display_perk_window(_, gui, _, _, setting) end
	end

	function S.show_message(_, gui, _, _, _)
		if not U.get_setting("enable_mod") then
			GuiColorSetForNextWidget(gui, 0.6, 0.6, 0.6, 1)
			GuiText(gui, 0, 0, T.disabled)
			return
		end
		if ModIsEnabled(mod_id) then
			GuiColorSetForNextWidget(gui, 0.6, 0.6, 0.6, 1)
			GuiText(gui, 0, 0, T.next)
		else
			GuiColorSetForNextWidget(gui, 1, 0.4, 0.4, 1)
			GuiText(gui, 0, 0, T.load)
		end
	end

	function S.reset_settings(_, gui, _, _, _)
		if not U.get_setting("enable_mod") then return end
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiText(gui, 0, 0, "")
		local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
		local text = "[" .. T.reset .. "]"
		local width, height = GuiGetTextDimensions(gui, text)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x, y, width, height, 0)
		local clicked, _, hovered = GuiGetPreviousWidgetInfo(gui)
		G.yellow_if_hovered(gui, hovered)
		GuiText(gui, 0, 0, text)
		if clicked then
			U.reset_settings()
		end
	end
end

-- ###########################################
-- ########		Translations		##########
-- ###########################################

local translations =
{
	["English"] = {
		show = "Show",
		hide = "Hide",
		window = "banishing window",
		name = "Banish Perks",
		did = "Banished",
		mod_state = "State",
		enable_mod = "Enabled",
		load = "Load the game to see modded perks",
		next = "Mod is loaded, perks will be banished on next run",
		disabled = "Mod is disabled",
		reset = "Reset Settings",
	}
}

local mt = {
	__index = function(t, k)
		local currentLang = GameTextGetTranslatedOrNot("$current_language")
		if not translations[currentLang] then
			currentLang = "English"
		end
		return translations[currentLang][k]
	end
}
setmetatable(T, mt)

-- ###########################################
-- #########		Settings		##########
-- ###########################################

---@class ml_settings_default
D = {
	enable_mod = true
}

local function build_settings()
	---@type mod_settings_global
	local settings = {
		{
			not_setting = true,
			id = "mod_state",
			ui_fn = S.mod_setting_better_boolean,
			ui_name = T.enable_mod,
			checkboxes = { "enable_mod" },
		},
		{
			ui_fn = S.toggle_display,
			not_setting = true,
		},
		{
			ui_fn = S.show_message,
			not_setting = true
		},
		{
			ui_fn = S.reset_settings,
			not_setting = true
		},
	}
	U.offset = 0
	return settings
end

-- ###########################################
-- #############		Meh		##############
-- ###########################################

---@param init_scope number
function ModSettingsUpdate(init_scope)
	local current_language = GameTextGetTranslatedOrNot("$current_language")
	if current_language ~= current_language_last_frame then
		mod_settings = build_settings()
	end
	current_language_last_frame = current_language
	mod_settings_update(mod_id, mod_settings, init_scope)
end

---@return number
function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

---@param gui gui
---@param in_main_menu boolean
function ModSettingsGui(gui, in_main_menu)
	gui_id = 1000
	GuiIdPushString(gui, setting_prfx)
	if U.offset == 0 then U.offset = U.calculate_elements_offset(gui, mod_settings) end
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
	GuiIdPop(gui)
end

dofile("data/scripts/perks/perk_list.lua")

---@type mod_settings_global
mod_settings = build_settings()
