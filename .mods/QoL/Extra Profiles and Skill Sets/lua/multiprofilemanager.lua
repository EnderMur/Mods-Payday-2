--Add extra profiles
--skilltreetweakdata already updated EPSS._session_profiles if needed
function MultiProfileManager:_check_amount()
	--Only wanted_amount changed
	local wanted_amount = EPSS._session_profiles
	if not self:current_profile() then
		self:save_current()
	end
	if wanted_amount < self:profile_count() then
		table.crop(self._global._profiles, wanted_amount)
		self._global._current_profile = math.min(self._global._current_profile, wanted_amount)
	elseif wanted_amount > self:profile_count() then
		local prev_current = self._global._current_profile
		self._global._current_profile = self:profile_count()
		while wanted_amount > self._global._current_profile do
			self._global._current_profile = self._global._current_profile + 1
			self:save_current()
		end
		self._global._current_profile = prev_current
	end
end

--Automatically equip corresponding skill set
Hooks:PreHook(MultiProfileManager, "load_current", "EPSS-PreHook-MultiProfileManager:load_current", function(self)
	if EPSS.settings.autobind_skills_2 then
		local index = self._global._current_profile
		if self._global._profiles[index].skillset ~= index then
			local switch_data = managers.skilltree and managers.skilltree._global.skill_switches[index]
			if switch_data and switch_data.unlocked and not managers.skilltree:is_skill_switch_suspended(switch_data) then
				self._global._profiles[index].skillset = index
				self._global._profiles[index].perk_deck = Application:digest_value(switch_data.specialization, false)
			end
		end
	end
end)

Hooks:PostHook(MultiProfileManager, "load", "EPSS-PostHook-MultiProfileManager:load", function(self)
	if EPSS.settings.autobind_skills_2 then
		self:load_current()
	end
end)

Hooks:PreHook(MultiProfileManager, "move_profile", "EPSS-PreHook-MultiProfileManager:move_profile", function(self, old_index, new_index)
	if not EPSS.settings.autobind_skills_2 then
		return
	end

	local skill_switches = managers.skilltree._global.skill_switches
	local switch = skill_switches and skill_switches[old_index]
	if not switch then
		return
	end

	table.remove(skill_switches, old_index)
	table.insert(skill_switches, new_index, switch)
end)

Hooks:PostHook(MultiProfileManager, "move_profile", "EPSS-PostHook-MultiProfileManager:move_profile", function(self, old_index, new_index)
	if not EPSS.settings.autobind_skills_2 then
		return
	end

	local change_start = math.min(old_index, new_index)
	local change_end = math.max(old_index, new_index)
	for index = change_start, change_end do
		local switch_data = managers.skilltree and managers.skilltree._global.skill_switches[index]
		if switch_data and switch_data.unlocked and not managers.skilltree:is_skill_switch_suspended(switch_data) then
			self._global._profiles[index].skillset = index
			self._global._profiles[index].perk_deck = Application:digest_value(switch_data.specialization, false)
		end
	end

	self:load_current()
end)
