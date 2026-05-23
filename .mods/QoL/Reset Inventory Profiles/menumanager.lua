


--[[
in the cases of weapons and masks, will search the items in the relevant category 
 for items matching the relevant name. 
it will search for custom names before ids.
it will then equip it if it exists.
otherwise, it will use your currently equipped item in that slot as default.
--]]

local default_deployable = nil --no default deployable
--name of the deployable to equip
--examples: "doctor_bag" "ecm_jammer" or "ammo_bag"

local default_deployable_secondary = nil
--same as above, for secondary deployable using jack of all trades skill

local default_mask = "character_locked" -- aka character-mask
--value is the custom name OR string name of the mask
--it will check the custom name before the string name

local default_skin = "none" --none
--value is the string name of the armor skin

local default_glove = "default" --default
--value is the glove_id of the glove skin

local default_armor = "level_1" -- aka Two-piece Suit
--value is the string name of the armor
--armor naming convention is "level_#", where # is the tier; eg. "level_7" is ICTV
--tier ranges from 1 to 7

local default_outfit = "none" -- i'll let you guess which one that is
--value is the string name of the outfit
--equipped player style

local default_variations = { -- these are for color/skin variations of the outfits (where applicable)
	tux = "default",
	murky_suit = "default",
	scrub = "default",
	winter_suit = "default",
	none = "default",
	jail_pd2_clan = "default",
	miami = "default",
	jumpsuit = "default",
	raincoat = "default",
	clown = "default",
	sneak_suit = "default",
	peacoat = "default"
}
--if an outfit is missing, you can safely add it here

local default_primary = "amcar"
--value is the string name of the weapon

local default_secondary = "glock_17" -- aka chimano 88
--value is the string name of the weapon

local default_melee = "weapon" -- weapon butt melee
--value is the string name of the melee weapon
--equips the first melee weapon found by this name

local default_throwable = "wpn_prj_ace" --aka "Ace of Spades" throwable
--value is the string name of the throwable
--equips the first grenade/throwable found by this name

local default_perkdeck = 1 --aka "Crew Chief" perk deck
--value is the number of this perk deck
--equips the perk deck by this number

local henchman_loadout_1 = {
	primary_category = "primaries",
	primary = "wpn_fps_ass_amcar_npc",
	mask_slot = 1,
	mask = "character_locked"
--	skill = "crew_eager",
--	primary_slot = 1,
--	ability = "crew_interact"
}

local henchman_loadout_2 = {
	primary_category = "primaries",
	primary = "wpn_fps_ass_amcar_npc",
	mask_slot = 1,
	mask = "character_locked"
--	skill = "crew_eager",
--	primary_slot = 1,
--	ability = "crew_interact"
}

local henchman_loadout_3 = {
	primary_category = "primaries",
	primary = "wpn_fps_ass_amcar_npc",
	mask_slot = 1,
	mask = "character_locked"
--	skill = "crew_eager",
--	primary_slot = 1,
--	ability = "crew_interact"
}

local FORCE_SKILLTREE_VERSION = nil
--If PAYDAY 2 somehow miraculously gets another major skilltree update,
--	the "reset skills" portion of this mod will disable itself for safety reasons.
--If I'm still around and modding PAYDAY 2,
--	then I'll update the mod to work with it, of course.
--	but, you are welcome to force-enable attempting the most recent version of the "reset skills" function again
--	by change the value of FORCE_SKILLTREE_VERSION from nil to the version of the skilltree you want to use, eg. 9
--as of 6 July 2020, we're on skilltree version 9 (v 1.95.896)






--hey so if you're scrolling down this far you're probably poking into the code.
--that's cool!
--just... i'm very sorry.
--in advance.			


--check player styles variations table to add missing entries, for future proofing (in case future outfits with variations are added after mod release)
for outfit_name,data in pairs(tweak_data.blackmarket.player_styles) do 
	if data.material_variations and #data.material_variations > 0 then 
		default_variations[outfit_name] = default_variations[outfit_name] or "default"
	end
end

local mod_path = ModPath 

local MAX_PROFILE_COUNT = #tweak_data.skilltree.skill_switches or (_G.fragProfiles and fragProfiles._settings.total_profiles) or 15
local ALL_PROFILES = MAX_PROFILE_COUNT + 1
local DEFAULT_SKILLSET_NUMBER = 1

Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_rsp", function(menu_manager)
	local selected_profile = 1
	
	local default_options = {
		names = true,
		skillset_names = true,
		masks = true,
		weapons = true,
		melees = true,
		perkdecks = true,
		throwables = true,
		armors = true,
		skins = true,
		outfits = true,
		gloves = true,
		skills = true,
		linked_trees_only = false,
		deployables = true,
		henchmen_loadouts = true,
		untie = 1 --1 is do nothing; 2 is set to respective profile num; 3 is set all to single number
	}

	local function refresh_menunames()
		local menu_reset_skill_profile = MenuHelper:GetMenu("menu_reset_skill_profile") or {_items = {}}
		for _,item in pairs(menu_reset_skill_profile._items) do 
			if item._parameters and item._parameters.name == "id_rsp_select_profile" then 
				if item._options then 
					for i = 1,MAX_PROFILE_COUNT do 
						local profile = managers.multi_profile._global._profiles[i]
						item._options[i]._parameters.text_id = profile and profile.name or string.gsub(managers.localization:text("rsp_profile_name"),"$NUMBER",tostring(i))
					end
				end
				break
			end
		end
	end
	
	local function perform_reset()

		
		local mp = managers.multi_profile
		local st = managers.skilltree
		local bm = managers.blackmarket
	
		if not (mp and st and bm) then
			QuickMenu:new(managers.localization:text("rsp_error_unknown"),managers.localization:text("rsp_action_failure"),{
				{
					text = managers.localization:text("rsp_dialog_ok"),
					is_cancel_button = true,
					is_focused_button = true
				}
			},true)
			return
		end
	
		if mp._global._current_profile ~= selected_profile and selected_profile ~= ALL_PROFILES then 
			mp:save_current()			
		end
		
		local function get_weapon_index(category,name)
			category = tostring(category)
			if not bm._global.crafted_items[category] then 
				return 1
			end
			
			local best
			for i,wpn in pairs(bm._global.crafted_items[category]) do 
				if wpn.custom_name and wpn.custom_name == name then 
					best = i
					break
				elseif wpn.weapon_id == name then 
					best = best or i
				end
			end
			
			return best
		end
		
		local function get_mask_index(name)
			local best
			for i,mask in pairs(bm._global.crafted_items.masks) do
				if mask.custom_name and mask.custom_name == default_mask then 
					return i
				elseif mask.mask_id == name then 
					best = best or i
				end
			end
			return best or 1
		end
		local mask_index = get_mask_index(default_mask)
		local primary_index = get_weapon_index("primaries",default_primary)
		local secondary_index = get_weapon_index("secondaries",default_secondary)
		
		for profile_num,profile in ipairs(mp._global._profiles) do			
			local before_skills 
			if (profile_num == selected_profile) or (selected_profile == ALL_PROFILES) then 	
			
				if default_options.skills then 
					--remember the current skillset in case relinking is enabled
					before_skills = profile.skillset 

					--switch skillsets temporarily so that skilltreemanager can respec it
					if default_options.linked_trees_only then 				
						--if "linked_trees_only" is enabled
						--then only reset the skilltree of the current profile
						st:switch_skills(profile.skillset)
					else
						--otherwise just reset all skilltrees in sequential order
						st:switch_skills(profile_num)
					end
					
					
					--reset skills; don't use reset_skilltrees() because it doesn't refund points properly
					local ST_VERSION = FORCE_SKILLTREE_VERSION or st._global.VERSION
					if (ST_VERSION < 5) then 
						for tree_id,_ in pairs(st._global.trees) do 
							st:_respec_tree_version_4(tree_id,1)
						end
					elseif (ST_VERSION == 5) then 
						for tree_id,_ in pairs(st._global.trees) do 
							st:_respec_tree_version5(tree_id,1)
						end
					elseif (ST_VERSION > 5) and (ST_VERSION <= 9) then 
						for i,_ in pairs(st._global.trees) do 
							st:_respec_tree_version6(i,1)
						end
					end
					
				end
				
				--delink/relink skills (separate from resetting skilltrees) 
				if default_options.untie == 2 then 
					--set to respective
					profile.skillset = profile_num
				elseif default_options.untie == 3 then 
					--set to #1
					profile.skillset = 1
				elseif before_skills then 
					--if not set to untie skills then 
					--set the skilltree to what it was before
					st:switch_skills(before_skills)
				end
				
				if default_options.names then 
					profile.name = string.gsub(managers.localization:text("rsp_profile_name"),"$NUMBER",profile_num)
				end
				
				--reset skillset names (separate from resetting skilltrees)
				if default_options.skillset_names then 
					local reset_name_skillset_num = profile_num
					if default_options.linked_trees_only then 		
						reset_name_skillset_num = profile.skillset
					end
					st:set_skill_switch_name(reset_name_skillset_num,st:get_default_skill_switch_name(reset_name_skillset_num))
				end
				
				if default_options.masks then 
					profile.mask = mask_index
				end
								
				if default_options.weapons then 
					profile.primary = primary_index or profile.primary
					profile.secondary = secondary_index or profile.secondary
				end
				if default_options.melees then 
					profile.melee = default_melee or profile.melee
				end
				
				if default_options.throwables then 
					profile.throwable = default_throwable or profile.throwables
				end
				
				if default_options.perkdecks then 
					profile.perk_deck = default_perkdeck
				end
				if default_options.armors then 
					profile.armor = default_armor
				end
				if default_options.skins then 
					if bm._global.armor_skins[default_skin].unlocked then 
						profile.armor_skin = default_skin
					end
				end
				if default_options.outfits then 
					if bm:player_style_unlocked(default_outfit) then 
						profile.player_style = default_outfit
						profile.current_variations = table.deep_map_copy(default_variations)
					end
				end
				
				if default_options.deployables then
					profile.deployable = default_deployable
					profile.deployable_secondary = default_deployable_secondary
				end	
				
				if default_options.untie == 2 then 
					profile.skillset = profile_num
				elseif default_options.untie == 3 then 
					profile.skillset = DEFAULT_SKILLSET_NUMBER
				end
				
				if default_options.henchmen_loadouts then 
					profile.henchmen_loadout = {
						table.deep_map_copy(henchman_loadout_1),
						table.deep_map_copy(henchman_loadout_2),
						table.deep_map_copy(henchman_loadout_3)
					}
				end
				
				if default_options.glove then 
					profile.glove_id = default_glove
				end
				
			end
		end
		--MenuCallbackHandler:save_progress()
		--MenuCallbackHandler:_update_outfit_information()
		mp:load_current()
		refresh_menunames()
	end





	MenuCallbackHandler.callback_rsp_select_profile = function(self,item)
		selected_profile = tonumber(item:value())
	end
	MenuCallbackHandler.callback_rsp_should_reset_names = function(self,item)
		default_options.names = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_skillset_names = function(self,item)
		default_options.skillset_names = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_masks = function(self,item)
		default_options.masks = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_throwables = function(self,item)
		default_options.throwables = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_weapons = function(self,item)
		default_options.weapons = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_melees = function(self,item)
		default_options.melees = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_perkdecks = function(self,item)
		default_options.perkdecks = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_armors = function(self,item)
		default_options.armors = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_skins = function(self,item)
		default_options.skins = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_outfits = function(self,item)
		default_options.outfits = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_skills = function(self,item)
		default_options.skills = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_deployables = function(self,item)
		default_options.deployables = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_henchmen_loadouts = function(self,item)
		default_options.henchmen_loadouts = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_gloves = function(self,item)
		default_options.gloves = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_reset_linked_trees = function(self,item)
		default_options.linked_trees_only = item:value() == "on"
	end
	MenuCallbackHandler.callback_rsp_should_untie_skills = function(self,item)
		default_options.untie = tonumber(item:value())
	end
			
	local function l(a)
		local result = managers.localization:text(a)
		if string.find(result,"ERROR: ") then 
			return a
		end
		return result
	end
	
	local function n(a,b)
		if b and a and (type(b) == "table") and b[a] then
			if b[a].name_id then 
				return b[a].name_id
			end
		end
		return tostring(a or "")
	end
	
	local function formatted_profile(selected)
		local profile = managers.multi_profile._global._profiles[selected] or {}
		local str = ""
		local td

		if default_options.names then 
			if selected == ALL_PROFILES then
				str = str .. string.gsub(managers.localization:text("rsp_literal_name"),"$NAME",managers.localization:text("rsp_profile_all")) .. managers.localization:text("rsp_literal_default_name") .. "\n"
			else
				str = str .. string.gsub(managers.localization:text("rsp_literal_name"),"$NAME",tostring(profile.name)) .. string.gsub(managers.localization:text("rsp_profile_name"),"$NUMBER",tostring(selected)) .. "\n"
			end
		end
		
		if default_options.skillset_names then 
			if selected == ALL_PROFILES then 
				str = str .. string.gsub(managers.localization:text("rsp_literal_skillset_name"),"$NAME",managers.localization:text("rsp_profile_all")) .. managers.localization:text("rsp_literal_default_name") .. "\n"
			else
				str = str .. string.gsub(managers.localization:text("rsp_literal_skillset_name"),"$NAME",managers.skilltree:get_skill_switch_name(profile.skillset,false)) .. string.gsub(managers.localization:text("rsp_profile_name"),"$NUMBER",managers.skilltree:get_default_skill_switch_name(profile.skillset)) .. "\n"
			end
		end
		
		if default_options.skills then 
			if selected == ALL_PROFILES then 
				if not default_options.linked_trees_only then
					str = str .. managers.localization:text("rsp_notice_reset_skill_all") .. "\n" --resetting all skilltrees 
				else
					str = str .. managers.localization:text("rsp_notice_reset_skill_all_linked") .. "\n" --resetting all linked skilltrees
				end
				if default_options.untie == 2 then 
					str = str .. managers.localization:text("rsp_notice_link_skill_all_respective") .. "\n" 
				elseif default_options.untie == 3 then
					str = str .. string.gsub(managers.localization:text("rsp_notice_link_skill_all_static"),"$NAME",DEFAULT_SKILLSET_NUMBER) .. "\n"
				end
			else
				if default_options.linked_trees_only then 
					local s = string.gsub(managers.localization:text("rsp_notice_reset_skill_linked_number"),"$NUMBER",tostring(profile.skillset))
					s = string.gsub(s,"$NAME",managers.skilltree:get_skill_switch_name(profile.skillset))
					str = str .. s .. "\n"
				else
					local s = string.gsub(managers.localization:text("rsp_notice_reset_skill_number"),"$NUMBER",managers.skilltree:get_selected_skill_switch())
					s = string.gsub(s,"$NAME",managers.skilltree:get_skill_switch_name(profile.skillset))
					str = str .. s .. "\n"
				end
				if default_options.untie == 2 then 
					str = str .. string.gsub(managers.localization:text("rsp_notice_link_skill_number"),"$NUMBER",selected) .. "\n"
				elseif default_options.untie == 3 then
					str = str .. string.gsub(managers.localization:text("rsp_notice_link_skill_number"),"$NUMBER",DEFAULT_SKILLSET_NUMBER) .. "\n"
				end
			end
		end
		if default_options.perkdecks then 
			td = tweak_data.skilltree.specializations
			str = str .. string.gsub(managers.localization:text("rsp_literal_specialization"),"$NAME",l(n(profile.perk_deck,td))) .. l(n(default_perkdeck,td)) .. "\n"
		end
		if default_options.masks then 
			td = tweak_data.blackmarket.masks
			local mask = managers.blackmarket._global.crafted_items.masks[profile.mask]
			mask = mask and mask.mask_id or profile.mask
			str = str .. string.gsub(managers.localization:text("rsp_literal_mask"),"$NAME",l(n(mask,td))) .. l(n(default_mask,td)) .. "\n"
		end
		if default_options.weapons then 
			td = tweak_data.weapon
			local primary = managers.blackmarket._global.crafted_items.primaries[profile.primary]
			local secondary = managers.blackmarket._global.crafted_items.secondaries[profile.secondary]

			str = str .. string.gsub(managers.localization:text("rsp_literal_weapon_primary"),"$NAME",l(n(primary and primary.weapon_id or profile.primary,td))) .. l(n(default_primary,td)) .. "\n"
			str = str .. string.gsub(managers.localization:text("rsp_literal_weapon_secondary"),"$NAME",l(n(secondary and secondary.weapon_id or profile.secondary,td))) .. l(n(default_secondary,td)) .. "\n"
		end
		if default_options.melees then 
			td = tweak_data.blackmarket.melee_weapons
			str = str .. string.gsub(managers.localization:text("rsp_literal_weapon_primary"),"$NAME",l(n(profile.melee,td))) .. l(n(default_melee,td)) .. "\n"
		end
		if default_options.throwables then 
			td = tweak_data.blackmarket.projectiles
			str = str .. string.gsub(managers.localization:text("rsp_literal_throwable"),"$NAME",l(n(profile.throwable,td))) .. l(n(default_throwable,td)) .. "\n"
		end
		if default_options.deployables then 
			td = tweak_data.equipments
			local deployable1 = td[profile.deployable or ""] or {text_id = profile.deployable}
			local deployable2 = td[profile.deployable_secondary or ""] or {text_id = profile.deployable_secondary}
			str = str .. string.gsub(managers.localization:text("rsp_literal_deployable_primary"),"$NAME",l(deployable1.text_id or (selected_profile == ALL_PROFILES and "" or "none"))) .. l(td[default_deployable] and td[default_deployable].text_id or "none") .. "\n"
			str = str .. string.gsub(managers.localization:text("rsp_literal_deployable_secondary"),"$NAME",l(deployable2.text_id or (selected_profile == ALL_PROFILES and "" or "none"))) .. l(td[default_deployable_secondary] and td[default_deployable_secondary].text_id or "none") .. "\n"
		end
		if default_options.armors then 
			td = tweak_data.blackmarket.armors
			str = str .. string.gsub(managers.localization:text("rsp_literal_armor"),"$NAME",l(n(profile.armor,td))) .. l(n(default_armor,td)) .. "\n"
		end
		if default_options.skins then 
			td = tweak_data.economy.armor_skins
			str = str .. string.gsub(managers.localization:text("rsp_literal_armor_skin"),"$NAME",l(n(profile.armor_skin,td))) .. l(n(default_skin,td)) .. "\n"
		end
		if default_options.outfits then 
			td = tweak_data.blackmarket.player_styles
			str = str .. string.gsub(managers.localization:text("rsp_literal_outfit"),"$NAME",l(n(profile.player_style,td))) .. l(n(default_outfit,td)) .. "\n"
		end
		
		if default_options.gloves then 
			td = tweak_data.blackmarket.gloves
			local glove_name = ""
			if selected_profile ~= ALL_PROFILES then 
				glove_name = l(n(profile.gloves or "default",td))
			end
			str = str .. string.gsub(managers.localization:text("rsp_literal_glove"),"$NAME",glove_name) .. l(n(default_glove,td)) .. "\n"
		end
		if default_options.henchmen then 
			str = str .. managers.localization:text("rsp_literal_henchmen_loadout") .. "\n"
			--too much info to show imo. and i'm so tired.
		end
		return str
	end
	
	
	MenuCallbackHandler.callback_rsp_do_reset = function(self)
	
		if not (game_state_machine and game_state_machine:verify_game_state(GameStateFilters.lobby)) then
			QuickMenu:new(managers.localization:text("rsp_error_ingame_title"),managers.localization:text("rsp_error_ingame_desc"),{
				{
					text = managers.localization:text("rsp_ok_sarcastic"),
					is_cancel_button = true,
					is_focused_button = true
				}
			},true)
			return
		end
	
	
		local title
		local desc = formatted_profile(selected_profile)
		if selected_profile == ALL_PROFILES then 
			title = managers.localization:text("rsp_confirm_do_reset_all")
		elseif selected_profile then
			title = string.gsub(managers.localization:text("rsp_confirm_do_reset"),"$NUMBER",tostring(selected_profile))
		else
			log("Reset Inventory Profiles: ERROR! No target profiles")
			return
		end
		
		QuickMenu:new(title,desc,{
			{
				text = managers.localization:text("dialog_yes"),
				callback = perform_reset
			},
			{
				text = managers.localization:text("dialog_no"),
				is_cancel_button = true,
				is_focused_button = true
			}
		},true)
	end
	
	MenuCallbackHandler.callback_rsp_wipe_perkdecks = function(this)
		QuickMenu:new(managers.localization:text("rsp_confirm_do_reset_perkdecks_title"),managers.localization:text("rsp_confirm_do_reset_perkdecks_desc"),{
			{
				text = managers.localization:text("dialog_yes"),
				callback = function() managers.skilltree:reset_specializations() end
			},
			{
				text = managers.localization:text("dialog_no"),
				is_cancel_button = true,
				is_focused_button = true
			}
		},true)

	end
	
	MenuCallbackHandler.callback_rsp_clear_perkdeck_progression = function(this)
		QuickMenu:new(managers.localization:text("rsp_clear_perkdeck_progression_dialogue_confirm_title"),managers.localization:text("rsp_clear_perkdeck_progression_dialogue_confirm_desc"),{
			{
				text = managers.localization:text("dialog_yes"),
				callback = function() managers.skilltree:_setup_specialization() end
			},
			{
				text = managers.localization:text("dialog_no"),
				is_cancel_button = true,
				is_focused_button = true
			}
		},true)
	end
	
	local populated_menu --bool; indicates whether multiplechoice menu option item has been populated with skillset names/count
	MenuCallbackHandler.rsp_focus_changed_callback = function(self) --populate multiplechoice with profile options
		MAX_PROFILE_COUNT = managers.multi_profile and managers.multi_profile:profile_count() or 3
		ALL_PROFILES = MAX_PROFILE_COUNT + 1
		
		
		if populated_menu then 
			refresh_menunames()		
			return
		end
		
		local menu_reset_skill_profile = MenuHelper:GetMenu("menu_reset_skill_profile") or {_items = {}}
		for _,item in pairs(menu_reset_skill_profile._items) do 
			if item._parameters and item._parameters.name == "id_rsp_select_profile" then 
				for i = 1, MAX_PROFILE_COUNT do 
					item:add_option(
						CoreMenuItemOption.ItemOption:new(
							{
								_meta = "option",
								text_id = managers.multi_profile and managers.multi_profile._global._profiles[i].name or string.gsub(managers.localization:text("rsp_profile_name"),"$NUMBER",tostring(i)),
								value = i,
								localize = false
							}
						)
					)
				end
				item:add_option(
					CoreMenuItemOption.ItemOption:new(
						{
							_meta = "option",
							text_id = "rsp_profile_all",
							value = MAX_PROFILE_COUNT + 1,
							localize = true
						}
					)
				)
				break
			end
		end
		populated_menu = true
	end
	
	
	
	MenuHelper:LoadFromJsonFile(mod_path .. "options.txt",nil,default_options)

end)

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_resetskillsets", function( loc )
	if not BeardLib then
		loc:load_localization_file(mod_path .. "localization/english.json")
	end
end)

--[[

example data:
{
	mask = "character_locked", --character specific mask
	armor = "level_1", --two-piece suit
	armor_skin = "none", --none, as you probably guessed
	player_style = "none", --aka outfit
	preferred_character = "russian", --dallas
	grenade = "frag", --frag grenade, paid dlc version, NOT community
	melee_weapon = "weapon" --weapon butt melee
}

--]]