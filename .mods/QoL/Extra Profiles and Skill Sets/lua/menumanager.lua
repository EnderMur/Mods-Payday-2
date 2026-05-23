Hooks:PostHook(MenuManager, "init", "EPSS-PostHook-MenuManager:init", function(...)
	local item = EPSS:get_menu_item("total_profiles_deferred")
	if item then
		if not EPSS.settings.allow_fewer then
			item._min = EPSS._base_num_profiles
		else
			item._min = 1
		end
		--Adjust slider max if someone manually edited their save
		if EPSS.settings.total_profiles_deferred > item._max then
			item._max = EPSS.settings.total_profiles_deferred
			item._value = EPSS.settings.total_profiles_deferred
		end
	end
end)

--Not allowed to switch skill sets if not suspended
local orig_MenuCallbackHandler_set_active_skill_switch = MenuCallbackHandler.set_active_skill_switch
function MenuCallbackHandler:set_active_skill_switch(item)
	if EPSS.settings.autobind_skills_2 then
		local skill_idx = item:parameters().name
		local profile_idx = managers.multi_profile and managers.multi_profile._global._current_profile
		if profile_idx and profile_idx ~= skill_idx then
			local switch_data = managers.skilltree and managers.skilltree._global.skill_switches[profile_idx]
			if switch_data and switch_data.unlocked and not managers.skilltree:is_skill_switch_suspended(switch_data) then
				managers.skilltree:switch_skills(profile_idx)
				self:refresh_node()
				local menu_title = managers.localization:text("epss_dialog_title")
				local menu_message = managers.localization:text("epss_dialog_autobind")
				local menu_options = {{text = managers.localization:text("dialog_continue"), is_cancel_button = true}}
				QuickMenu:new(menu_title, menu_message, menu_options, true)
				return
			end
		end
	end
	orig_MenuCallbackHandler_set_active_skill_switch(self, item)
end

--Auto-equip on unsuspend
local orig_MenuCallbackHandler_unsuspend_skill_switch_dialog_yes = MenuCallbackHandler.unsuspend_skill_switch_dialog_yes
function MenuCallbackHandler:unsuspend_skill_switch_dialog_yes(skill_switch)
	orig_MenuCallbackHandler_unsuspend_skill_switch_dialog_yes(self, skill_switch)
	if EPSS.settings.autobind_skills_2 then
		local profile_idx = managers.multi_profile and managers.multi_profile._global._current_profile
		if profile_idx and profile_idx == skill_switch then
			managers.skilltree:switch_skills(skill_switch)
			self:refresh_node()
		end
	end
end
