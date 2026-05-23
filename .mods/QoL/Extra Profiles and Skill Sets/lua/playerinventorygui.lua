local orig_PlayerInventoryGui_previous_skilltree = PlayerInventoryGui.previous_skilltree
function PlayerInventoryGui:previous_skilltree(...)
	if EPSS.settings.autobind_skills_2 then
		return
	end
	orig_PlayerInventoryGui_previous_skilltree(self, ...)
end

local orig_PlayerInventoryGui_next_skilltree = PlayerInventoryGui.next_skilltree
function PlayerInventoryGui:next_skilltree(...)
	if EPSS.settings.autobind_skills_2 then
		return
	end
	orig_PlayerInventoryGui_next_skilltree(self, ...)
end
