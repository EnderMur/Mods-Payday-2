function MenuCallbackHandler:on_visit_fbi_files_suspect(item)
	if item and SystemInfo:distribution() == Idstring("STEAM") then
		if MenuCallbackHandler:is_overlay_enabled() then
			Steam:overlay_activate("url", "http://www.steamcommunity.com" .. (item and "/profiles/" .. item:name() .. "/" or ""))
		else
			managers.menu:show_enable_steam_overlay()
		end
	end
end
