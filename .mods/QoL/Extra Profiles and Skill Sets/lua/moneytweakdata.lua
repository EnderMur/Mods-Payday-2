--Add costs for the skill sets
--skilltreetweakdata already updated EPSS._session_profiles if needed
Hooks:PostHook(MoneyTweakData, "init" , "EPSS-PostHook-MoneyTweakData:init" , function(self, ...)
	while #self.skill_switch_cost < EPSS._session_profiles do
		table.insert(self.skill_switch_cost, {spending = 0, offshore = 0})
	end
	if EPSS.settings.allow_fewer then
		table.crop(self.skill_switch_cost, EPSS._session_profiles)
	end
end)
