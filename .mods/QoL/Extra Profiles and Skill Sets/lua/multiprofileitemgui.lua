--More characters for profile names
Hooks:PostHook(MultiProfileItemGui, "init", "EPSS-PostHook-MultiProfileItemGui:init", function(self, ...)
	self._max_length = 30
	self:update()
end)
