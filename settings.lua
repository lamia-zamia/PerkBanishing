dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id = "PerkBanishing"
local setting_prfx = mod_id .. "."
local T = {}
local gui_id = 1000
local function id()
	gui_id = gui_id + 1
	return gui_id
end
-- ###########################################
-- ############		Helpers		##############
-- ###########################################

local U = {
	offset = 4,
	presets = {},
	preset_names = {},
	show_window = false,
	chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
}
do --helpers
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

	function U.read_presets()
		local struct = tostring(U.get_setting("presets"))
		if not struct then return end
		for preset in struct:gmatch("([^\n]*)\n?") do
			if preset and preset ~= "" then
				local values = {}
				for value in preset:gmatch("([^,]+)") do
					print(value)
					values[#values + 1] = value
				end
				local name = table.remove(values, 1)
				U.preset_names[name] = name
				U.presets[name] = values
			end
		end
	end

	function U.write_presets()
		local presets = ""
		for name, values in pairs(U.presets) do
			presets = presets .. name .. "," .. table.concat(values, ",") .. "\n"
		end
		U.set_setting("presets", presets)
	end

	function U.write_preset(name)
		U.presets[name] = {}
		local preset = U.presets[name]
		for i = 1, #perk_list do
			if U.get_setting(perk_list[i].id) then
				print(perk_list[i].id)
				preset[#preset + 1] = perk_list[i].id
			end
		end
		U.preset_names[name] = name
		U.write_presets()
	end

	function U.apply_preset(name)
		local preset = U.presets[name]
		U.reset_settings()
		for i = 1, #preset do
			U.set_setting(preset[i], true)
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

	function G.display_perk_window(gui)
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

	---@param gui gui
	---@param x_pos number
	---@param text string
	---@param color? table
	---@return boolean
	---@nodiscard
	function G.button(gui, x_pos, text, color)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiText(gui, x_pos, 0, "")
		local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
		text = "[" .. text .. "]"
		local width, height = GuiGetTextDimensions(gui, text)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x, y, width, height, 0)
		local clicked, _, hovered = GuiGetPreviousWidgetInfo(gui)
		if color then
			local r, g, b = unpack(color)
			GuiColorSetForNextWidget(gui, r, g, b, 1)
		end
		G.yellow_if_hovered(gui, hovered)
		GuiText(gui, x_pos, 0, text)
		return clicked
	end
end
-- ###########################################
-- ########		Settings GUI		##########
-- ###########################################

local S = {

}
do -- Settings GUI
	function S.toggle_display(_, gui, _, _, setting)
		if G.button(gui, U.offset, (U.show_window and T["hide"] or T["show"]) .. " " .. T["window"]) then
			U.show_window = not U.show_window
		end
		if U.show_window then G.display_perk_window(gui) end
	end

	function S.show_message(_, gui, _, _, _)
		if ModIsEnabled(mod_id) then
			GuiColorSetForNextWidget(gui, 0.6, 0.6, 0.6, 1)
			GuiText(gui, U.offset, 0, T.next)
		else
			GuiColorSetForNextWidget(gui, 1, 0.4, 0.4, 1)
			GuiText(gui, U.offset, 0, T.load)
		end
	end

	function S.reset_settings(_, gui, _, _, _)
		if G.button(gui, U.offset, T.reset_settings) then
			U.reset_settings()
		end
		if G.button(gui, U.offset, T.erase_presets, { 1, 0.4, 0.4 }) then
			U.presets = {}
			U.write_presets()
			U.read_presets()
		end
	end

	function S.presets(_, gui, _, _, _)
		local i = 1
		for name, display_name in pairs(U.preset_names) do
			GuiLayoutBeginHorizontal(gui, U.offset * 2, 0, true, 0, 0)
			U.preset_names[name] = GuiTextInput(gui, id(), 0, 0, display_name, 90, 17, U.chars)
			if G.button(gui, 0, T.apply_preset) then
				U.apply_preset(name)
			end
			local color = name == display_name and { 1, 1, 1 } or { 0.4, 0.7, 0.4 }
			if G.button(gui, 0, T.update_preset, color) then
				-- U.presets[display_name] = U.presets[name]
				U.presets[name] = nil
				U.preset_names[name] = nil
				U.write_preset(display_name)
			end
			if G.button(gui, 0, T.delete_preset, { 1, 0.4, 0.4 }) then
				U.presets[name] = nil
				U.preset_names[name] = nil
				U.write_presets()
			end
			GuiLayoutEnd(gui)
			i = i + 1
		end
		if G.button(gui, U.offset * 2, T.new_preset) then
			U.write_preset("Preset_" .. i)
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
		load = "Load the game to see modded perks",
		next = "Mod is loaded, perks will be banished on next run",
		disabled = "Mod is disabled",
		reset_cat = "Reset",
		reset_settings = "Allow all perks",
		presets_cat = "Presets",
		new_preset = "New Preset",
		erase_presets = "Erase presets",
		apply_preset = "Apply",
		update_preset = "Update",
		delete_preset = "Delete",
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
			ui_fn = S.toggle_display,
			not_setting = true,
		},
		{
			ui_fn = S.show_message,
			not_setting = true
		},
		{
			category_id = "presets",
			ui_name = T.presets_cat,
			foldable = true,
			_folded = true,
			settings = {
				{
					ui_fn = S.presets,
					not_setting = true
				}
			}
		},
		{
			category_id = "reset",
			ui_name = T.reset_cat,
			foldable = true,
			_folded = true,
			settings = {
				{
					ui_fn = S.reset_settings,
					not_setting = true
				},
			}

		},

	}
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
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
	GuiIdPop(gui)
end

dofile("data/scripts/perks/perk_list.lua")
U.read_presets()

---@type mod_settings_global
mod_settings = build_settings()
