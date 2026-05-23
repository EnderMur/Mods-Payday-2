function ChatGui:enter_key_callback()
	if not self._enabled then
		return
	end
	local text = self._input_panel:child("input_text")
	local message = text:text()
	local command_key, command_args
	if utf8.sub(message, 1, 1) == "/" then
		local command_string = utf8.sub(message, 2, utf8.len(message))
		command_args = string.split(command_string, " ") or {}
		if #command_args > 0 then
			command_key = Idstring(table.remove(command_args, 1))
		end
	end
	if command_key and command_list[command_key:key()] then
		if command_key == Idstring("ready") then
			managers.menu_component:on_ready_pressed_mission_briefing_gui()
		elseif SystemInfo:distribution() == Idstring("STEAM") then
			if command_key == Idstring("fbi_files") then
				Steam:overlay_activate("url", tweak_data.gui.fbi_files_webpage)
			elseif command_key == Idstring("fbi_search") then
				Steam:overlay_activate("url", "http://www.steamcommunity.com" .. (command_args[1] and "/profiles/" .. command_args[1] .. "/" or ""))
			elseif command_key == Idstring("fbi_inspect") then
				Steam:overlay_activate("url", tweak_data.gui.fbi_files_webpage .. (command_args[1] and "/modus/" .. command_args[1] .. "/" or ""))
			end
		end
	elseif string.len(message) > 0 then
		local u_name = managers.network.account:username()
		managers.chat:send_message(self._channel_id, u_name or "Offline", message)
	else
		self._enter_loose_focus_delay = true
		self:_loose_focus()
	end
	text:set_text("")
	text:set_selection(0, 0)
end
