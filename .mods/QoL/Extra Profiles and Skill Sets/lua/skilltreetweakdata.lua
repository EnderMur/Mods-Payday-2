--Add more skill sets
--Make sure our setting is not lower than the number in the base game, update if necessary
Hooks:PostHook(SkillTreeTweakData, "init", "EPSS-PostHook-SkillTreeTweakData:init", function(self, ...)
	--Get the base game number of profiles
	--EPSS updates number of profiles if necessary
	local base_num_profiles = #self.skill_switches
	EPSS:update_session_settings(base_num_profiles)

	local start_idx = #self.skill_switches + 1
	for i = start_idx, EPSS._session_profiles do
		table.insert(self.skill_switches, {})
	end

	if EPSS.settings.allow_fewer then
		table.crop(self.skill_switches, EPSS._session_profiles)
	end
end)
