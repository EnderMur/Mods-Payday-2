function MissionBriefingGui:mouse_pressed(button, x, y)
	if not alive(self._panel) or not alive(self._fullscreen_panel) or not self._enabled then
		return
	end
	if game_state_machine:current_state().blackscreen_started and game_state_machine:current_state():blackscreen_started() then
		return
	end
	if self._displaying_asset then
		if button == Idstring("mouse wheel down") then
			self:zoom_asset("out")
			return
		elseif button == Idstring("mouse wheel up") then
			self:zoom_asset("in")
			return
		end
		self:close_asset()
		return
	end
	local mwheel_down = button == Idstring("mouse wheel down")
	local mwheel_up = button == Idstring("mouse wheel up")
	if (mwheel_down or mwheel_up) and managers.menu:is_pc_controller() then
		local mouse_pos_x, mouse_pos_y = managers.mouse_pointer:modified_mouse_pos()
		if mouse_pos_x < self._panel:x() then
			return
		end
	end
	if mwheel_down then
		self:next_tab(true)
		return
	elseif mwheel_up then
		self:prev_tab(true)
		return
	end
	if button ~= Idstring("0") then
		return
	end
	if MenuCallbackHandler:is_overlay_enabled() then
		local fx, fy = managers.mouse_pointer:modified_fullscreen_16_9_mouse_pos()
		for peer_id = 1, CriminalsManager.MAX_NR_CRIMINALS do
			if managers.hud:is_inside_mission_briefing_slot(peer_id, "name", fx, fy) then
				local peer = managers.network:session() and managers.network:session():peer(peer_id)
				if peer then
					Steam:overlay_activate("url", "http://www.steamcommunity.com/profiles/" .. peer:user_id() .. "/")
					return
				end
			end
		end
	end
	for index, tab in ipairs(self._items) do
		local pressed, cost = tab:mouse_pressed(button, x, y)
		if pressed == true then
			self:set_tab(index)
		elseif type(pressed) == "number" then
			if cost then
				if type(cost) == "number" then
					local asset_id, is_gage_asset, locked = tab:get_asset_id(pressed)
					if is_gage_asset and not locked then
						self:open_gage_asset(asset_id)
					else
						self:open_asset_buy(pressed, asset_id, is_gage_asset)
					end
				end
			else
				local asset_id, is_gage_asset, locked = tab:get_asset_id(pressed)
				if is_gage_asset then
					self:open_gage_asset(asset_id)
				else
					self:open_asset(pressed)
				end
			end
		end
	end
	if self._ready_button:inside(x, y) or self._ready_tick_box:inside(x, y) then
		self:on_ready_pressed()
	end
	if not self._ready then
		self._multi_profile_item:mouse_pressed(button, x, y)
	end
	return self._selected_item
end
