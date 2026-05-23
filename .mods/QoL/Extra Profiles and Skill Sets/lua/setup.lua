if _G.EPSS then return end

_G.EPSS = {}
EPSS.meta = {
	mod_path = ModPath,
	save_path = SavePath,
	menu_id = "epss_options_menu",
	menu_file = ModPath.."menu/options.json",
	save_file = SavePath.."extraprofiles_settings.txt",
}

function EPSS:save_json(path, data)
	local file = io.open(path, "w+")
	file:write(json.encode(data))
	file:close()
end

function EPSS:load_json(path)
	local data
	local file = io.open(path, "r")
	if file then
		data = json.decode(file:read("*all"))
		file:close()
	end
	return data
end

function EPSS:save_settings()
	self:save_json(self.meta.save_file, self.settings)
end

function EPSS:load_settings()
	local data = self:load_json(self.meta.save_file) or {}
	for k, _ in pairs(self.settings) do
		if data[k] ~= nil then
			self.settings[k] = data[k]
		end
	end
end

EPSS.settings = {
	total_profiles = 45,
	total_profiles_deferred = 45,
	autobind_skills_2 = false,
	allow_fewer = false,
}
EPSS:load_settings()
--Legacy users don't have total_profiles_deferred, make sure it's set.
EPSS.settings.total_profiles_deferred = EPSS.settings.total_profiles
--Cache session profiles. Make sure it's higher than base later.
EPSS._session_profiles = EPSS.settings.total_profiles
--Base game number of skill sets, get from skilltreetweakdata
--EPSS._base_num_profiles = ...
function EPSS:update_session_settings(base_num_profiles)
	self._base_num_profiles = base_num_profiles
	if self._session_profiles < base_num_profiles and not self.settings.allow_fewer then
		self._session_profiles = base_num_profiles
		self.settings.total_profiles = base_num_profiles
		self.settings.total_profiles_deferred = base_num_profiles
		self:save_settings()
	end
end

Hooks:Add("LocalizationManagerPostInit", "EPSS-Hooks-LocalizationManagerPostInit", function(loc)
	loc:load_localization_file(EPSS.meta.mod_path.."localizations/english.json")
end)

Hooks:Add("MenuManagerInitialize", "EPSS-Hooks-MenuManagerInitialize", function(menu_manager)
	local Mod = EPSS

	MenuCallbackHandler.epss_callback_slider_discrete = function(self, item)
		Mod.settings[item:name()] = math.floor(item:value()+0.5)
	end

	MenuCallbackHandler.epss_callback_toggle = function(self, item)
		Mod.settings[item:name()] = item:value() == "on"
		Mod:update_menu_options()
	end

	MenuCallbackHandler.epss_callback_button = function(self, item)
		Mod[item:name()](Mod)
	end

	MenuCallbackHandler.epss_callback_save = function(self, item)
		Mod:back_callback()
	end

	MenuHelper:LoadFromJsonFile(Mod.meta.menu_file, Mod, Mod.settings)
end)

function EPSS:back_callback()
	self:discard_deferred_profiles()
	self:save_settings()
	if self.settings.autobind_skills_2 and managers.multi_profile then
		managers.multi_profile:load_current()
	end
end

function EPSS:get_menu_item(setting_id)
	local menu = MenuHelper:GetMenu(self.meta.menu_id)
	for _, item in pairs(menu._items) do
		local name = item._parameters and item._parameters.name
		if name == setting_id then
			return item
		end
	end
end

function EPSS:update_menu_options()
	local item = self:get_menu_item("total_profiles_deferred")
	if not self.settings.allow_fewer then
		item._min = self._base_num_profiles
		if item._value < item._min then
			item._value = item._min
			self.settings.total_profiles_deferred = item._min
			self:save_deferred_profiles()
		end
	else
		item._min = 1
	end
	item:dirty_callback()
end

--Commit settings button
function EPSS:commit_settings()
	local new_num = self.settings.total_profiles_deferred
	local old_num = self.settings.total_profiles
	local delta = new_num - old_num

	if delta == 0 then
		local menu_title = managers.localization:text("epss_dialog_title")
		local menu_message = managers.localization:text("epss_dialog_unchanged")
		local menu_options = {{text = managers.localization:text("dialog_continue"), is_cancel_button = true}}
		QuickMenu:new(menu_title, menu_message, menu_options, true)
		return
	end

	local menu_title = managers.localization:text("epss_dialog_title")
	local menu_message = managers.localization:text("epss_dialog_number_profiles", {new_num=new_num, old_num=old_num})

	local adding = delta > 0
	if math.abs(delta) == 1 then
		local macros = {
			profile_num = math.max(old_num, new_num),
			operation = delta > 0 and "added" or "removed",
		}
		menu_message = menu_message.."\n\n"..managers.localization:text("epss_dialog_add_remove_single", macros)
	else
		local macros = {
			profile_min = math.min(old_num, new_num) + 1,
			profile_max = math.max(old_num, new_num),
			operation = delta > 0 and "added" or "removed",
		}
		menu_message = menu_message.."\n\n"..managers.localization:text("epss_dialog_add_remove_multiple", macros)
	end

	menu_message = menu_message.."\n\n"..managers.localization:text("epss_dialog_ask_continue")

	local menu_options = {
		{
			text = managers.localization:text("dialog_continue"),
			callback = function()
				self:save_deferred_profiles()
			end,
		},
		{
			text = managers.localization:text("dialog_cancel"),
			callback = function()
				self:discard_deferred_profiles()
			end,
			is_focused_button = true,
		}
	}

	QuickMenu:new(menu_title, menu_message, menu_options, true)
end

--Save and show message
function EPSS:save_deferred_profiles()
	self.settings.total_profiles = self.settings.total_profiles_deferred
	self:save_settings()
	local menu_title = managers.localization:text("epss_dialog_title")
	local menu_message = managers.localization:text("epss_dialog_saved")
	local menu_options = {{text = managers.localization:text("dialog_continue"), is_cancel_button = true}}
	QuickMenu:new(menu_title, menu_message, menu_options, true)
end

--Discard and update UI
function EPSS:discard_deferred_profiles()
	self.settings.total_profiles_deferred = self.settings.total_profiles
	local item = self:get_menu_item("total_profiles_deferred")
	item._value = self.settings.total_profiles_deferred
	item:dirty_callback()
end
