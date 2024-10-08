local E, L, V, P, G = unpack(ElvUI);
local BH = E:GetModule('SHighlight')
local UF = E:GetModule('UnitFrames')
local addon = ...

local selectedSpell, quickSearchText, spellList = nil, '', {}

local colorDescription = "Color(High Health) is used when UnitFrames>General>Colors>Health By Value is unchecked. Otherwise, Color(High Health), Color(Medium Health), and Color(Low Health) are used together to make a gradient."

local function GetSelectedSpell()
	if selectedSpell and selectedSpell ~= '' then
		local spell = strmatch(selectedSpell, " %((%d+)%)$") or selectedSpell
		if spell then
			return tonumber(spell) or spell
		end
	end
end

function BH:GetOptions()
	E.Options.args.BH = {
		order = 100,
		type = "group",
		name = "|cff00b3ffSHighlight|r",
		args = {
			title = {
				order = 1,
				type = "header",
				name = "SHighlight",
			},
			addonOptions = {
				order = 2,
				type = "group",
				name = "Main Options",
				guiInline = true,
				args = {
					enable = {
						order = 1,
						type = "toggle",
						name = "Enable",
						desc = "Enable/Disable the buff highlight",
						get = function(info)
							return E.db.BH.enable
						end,
						set = function(info, value)
							if value then BH:enablePlugin()
							else BH:disablePlugin() end
							E.db.BH.enable = value
						end,
					},
					colorBackdrop = {
						order = 2,
						type = "toggle",
						name = "Colored backdrop",
						desc = "Enable/Disable color change matching highlight color in the backdrop",
						get = function(info)
							return E.db.BH.colorBackdrop
						end,
						set = function(info, value)
							E.db.BH.colorBackdrop = value
						end,
					}
				},
			},
			framesOptions = {
				order = 3,
				type = "group",
				name = "Frames Options",
				guiInline = true,
				args = {
					frameDescription = {
						order = 0,
						type = 'group',
						name = "Note",
						guiInline = true,
						args = {
							str = {
								order = 1,
								type = 'description',
								fontSize = 'medium',
								name = format('|cffffd200%s|r', "Changing a frame option requires UI reload."),
							},
						},
					},
					party = {
						order = 1,
						type = "toggle",
						name = "Party",
						desc = "Enable/Disable the buff highlight for the party frames",
						width = "half",
						get = function(info)
							return E.db.BH.trackedHeaders.party
						end,
						set = function(info, value)
							E.db.BH.trackedHeaders.party = value
							if not value then BH:resetHeader("party") end
							E:StaticPopup_Show('CONFIG_RL')
						end,
					},
					raid1 = {
						order = 2,
						type = "toggle",
						name = "Raid1",
						desc = "Enable/Disable the buff highlight for the raid1 frames",
						width = "half",
						get = function(info)
							return E.db.BH.trackedHeaders.raid1
						end,
						set = function(info, value)
							E.db.BH.trackedHeaders.raid1 = value
							if not value then BH:resetHeader("raid1") end
							E:StaticPopup_Show('CONFIG_RL')
						end,
					},
					raid2 = {
						order = 3,
						type = "toggle",
						name = "Raid2",
						desc = "Enable/Disable the buff highlight for the raid2 frames",
						width = "half",
						get = function(info)
							return E.db.BH.trackedHeaders.raid2
						end,
						set = function(info, value)
							E.db.BH.trackedHeaders.raid2 = value
							if not value then BH:resetHeader("raid2") end
							E:StaticPopup_Show('CONFIG_RL')
						end,
					},
					raid3 = {
						order = 4,
						type = "toggle",
						name = "Raid3",
						desc = "Enable/Disable the buff highlight for the raid3 frames",
						width = "half",
						get = function(info)
							return E.db.BH.trackedHeaders.raid3
						end,
						set = function(info, value)
							E.db.BH.trackedHeaders.raid3 = value
							if not value then BH:resetHeader("raid3") end
							E:StaticPopup_Show('CONFIG_RL')
						end,
					},
					limitOn5 = {
						order = 5,
						type = "toggle",
						name = "Limit on 5",
						desc = "Enabling this will disable raid-frames tracking when <=5 members. This is a performance enhancement.",
						width = "half",
						get = function(info)
							return E.db.BH.trackedHeaders.limitOn5
						end,
						set = function(info, value)
							E.db.BH.trackedHeaders.limitOn5 = value
							E:StaticPopup_Show('CONFIG_RL')
						end,
					},
				},
			},
			selectGroup = {
				type = 'group',
				name = "Spells options",
				guiInline = true,
				order = 10,
				args = {
					addSpell = {
						order = 1,
						name = "Add Spell ID",
						desc = "Add a buff to highlight.",
						type = 'input',
						get = function(info) return "" end,
						set = function(info, value)
							value = tonumber(value)
							if not value then return end

							local spellName = tonumber(value) and C_Spell.GetSpellName(value)
							selectedSpell = (spellName and value) or nil
							if not selectedSpell then return end
							
							E.db.BH.spells[value] = {
								["enabled"] = true,
								["name"] = spellName,
								["class"] = "",
								["glowColor"] = {r = 0.0, g = 0.2, b = 0.77, a = 1.0},
								["glowColorTwo"] = {r = 0.6, g = 0.0, b = 0.57, a = 1.0},
								["glowColorThree"] = {r = 1.0, g = 0.0, b = 0.0, a = 1.0},
							}
						end,
					},
					quickSearch = {
						order = 2,
						name = "Filter Search",
						desc = "Search for a spell name inside of a filter.",
						type = "input",
						get = function() return quickSearchText end,
						set = function(info,value) quickSearchText = value end,
					},
					selectSpell = {
						name = "Select Spell",
						type = 'select',
						order = 10,
						width = "double",
						get = function(info) return selectedSpell or '' end,
						set = function(info, value)
							selectedSpell = (value ~= '' and value) or nil
						end,
						values = function()
							local list = E.db.BH.spells
	
							if not list then return end
							wipe(spellList)
	
							local searchText = quickSearchText:lower()
							for id, spell in pairs(list) do
								local spellName = tonumber(id) and C_Spell.GetSpellName(id)
								local name = (spellName and format("%s |cFF888888(%s)|r", spellName, id)) or tostring(id)
	
								if name:lower():find(searchText) then
									spellList[id] = name
								end
							end
	
							if not next(spellList) then
								spellList[''] = "NONE"
							end
	
							return spellList
						end,
					},
					removeSpell = {
						order = 11,
						name = "Remove Spell",
						desc = "Remove a highlighted buff.",
						type = 'execute',
						func = function()
							local value = GetSelectedSpell()
							if not value then return end
							selectedSpell = nil
	
							E.db.BH.spells[value] = nil
						end,
						disabled = function()
							local spell = GetSelectedSpell()
							if not spell then return true end
						end,
					},
				},
			},
			spellGroup = {
				type = "group",
				name = function()
					local id = GetSelectedSpell()
					local spellName = tonumber(id) and C_Spell.GetSpellName(id)
					return (spellName and format("%s |cFF888888(%s)|r", spellName, id)) or tostring(id)
				end,
				hidden = function() return not selectedSpell end,
				order = -15,
				guiInline = true,
				args = {
					mainSpellOptions = {
						order = 0,
						type = "group",
						name = 'Glow options',
						guiInline = true,
						args = {
							enabled = {
								name = "Enable",
								order = 0,
								type = 'toggle',
								get = function(info)
									local spell = GetSelectedSpell()
									if not spell then return end
			
									return E.db.BH.spells[spell].enabled
								end,
								set = function(info, value)
									local spell = GetSelectedSpell()
									if not spell then return end
			
									E.db.BH.spells[spell].enabled = value
								end,
							},
							glowColor = {
								order = 1,
								type = "color",
								name = "Color (High Health)",
								desc = colorDescription,
								hasAlpha = true,
								get = function(info)
									local spell = GetSelectedSpell()
									local t = E.db.BH.spells[spell].glowColor
									if t then
										return t.r, t.g, t.b, t.a
									end
								end,
								set = function(info, r, g, b, a)
									local spell = GetSelectedSpell()
									local t = E.db.BH.spells[spell].glowColor
									if t then
										t.r, t.g, t.b, t.a = r, g, b, a
									end
								end,
							},
							glowColorTwo = {
								order = 2,
								type = "color",
								name = "Color (Medium Health)",
								desc = colorDescription,
								hasAlpha = true,
								get = function(info)
									local spell = GetSelectedSpell()
									local t = E.db.BH.spells[spell].glowColorTwo
									if t then
										return t.r, t.g, t.b, t.a
									end
								end,
								set = function(info, r, g, b, a)
									local spell = GetSelectedSpell()
									local t = E.db.BH.spells[spell].glowColorTwo
									if t then
										t.r, t.g, t.b, t.a = r, g, b, a
									end
								end,
							},
							glowColorThree = {
								order = 3,
								type = "color",
								name = "Color (Low Health)",
								desc = colorDescription,
								hasAlpha = true,
								get = function(info)
									local spell = GetSelectedSpell()
									local t = E.db.BH.spells[spell].glowColorThree
									if t then
										return t.r, t.g, t.b, t.a
									end
								end,
								set = function(info, r, g, b, a)
									local spell = GetSelectedSpell()
									local t = E.db.BH.spells[spell].glowColorThree
									if t then
										t.r, t.g, t.b, t.a = r, g, b, a
									end
								end,
							},
						},
					},
					class = {
						order = 1,
						type = "group",
						name = 'Class Association',
						guiInline = true,
						args = {
							selectSpell = {
								name = "Select Class",
								desc = "Leave blank if unwanted. Associates a class with the buff. Performance enhancement. Helps limit the number of buffs checked.",
								type = 'select',
								order = 10,
								width = "double",
								get = function(info, value) 
									local spell = GetSelectedSpell()
									local t = E.db.BH.spells[spell].class
									for key, val in  ipairs(E.db.BH.classes) do
										if val == t then
											return key
										end
									end
								end,
								set = function(info, value)
									selectedGroup = (value ~= '' and value) or nil
									local spell = GetSelectedSpell()
									E.db.BH.spells[spell].class = E.db.BH.classes[selectedGroup]
								end,
								values = function()
									E.db.BH.classes= {
										"", "Druid", "Shaman", "Paladin", "Evoker", "Monk", "Priest"
									}
									return E.db.BH.classes
								end,
							},
						},
					},
				
				},
			}
		},
	}
end
