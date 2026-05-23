function ContractBoxGui:mouse_pressed(button, x, y)
	if not self:can_take_input() then
		return
	end
	if button == Idstring("0") then
		local used = false
		local pointer = "arrow"
		if self._peers and SystemInfo:platform() == Idstring("WIN32") and MenuCallbackHandler:is_overlay_enabled() then
			for peer_id, object in pairs(self._peers) do
				if alive(object) and object:inside(x, y) then
					local peer = managers.network:session() and managers.network:session():peer(peer_id)
					if peer then
						Steam:overlay_activate("url", "http://www.steamcommunity.com/profiles/" .. peer:user_id() .. "/")
						return
					end
				end
			end
		end
	end
end
