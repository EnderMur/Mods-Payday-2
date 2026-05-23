--Automatically unlock all skill sets if using autobind
Hooks:PostHook(SkillTreeManager, "load", "EPSS-PostHook-SkillTreeManager:load", function(self)
	if EPSS.settings.autobind_skills_2 then
		for i, switch_data in ipairs(self._global.skill_switches) do
			switch_data.unlocked = true
		end
	end
end)
