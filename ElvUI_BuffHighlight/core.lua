local E, L, V, P, G = unpack(ElvUI); 
local BH = E:NewModule('BuffHighlight', 'AceHook-3.0'); 
local EP = LibStub("LibElvUIPlugin-1.0") 
local UF = E:GetModule('UnitFrames')
local addon, ns = ...

local CreateFrame = CreateFrame
local UnitIsTapDenied = UnitIsTapDenied
local UnitReaction = UnitReaction
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local ReloadUI = ReloadUI

local ElvUF = E.oUF
assert(ElvUF, 'ElvUI was unable to locate oUF.')

local f = CreateFrame("Frame")
f:RegisterEvent("UNIT_AURA")
E:RegisterModule(BH:GetName())

--GLOBALS: hooksecurefunc
local select, pairs, unpack = select, pairs, unpack

-- Checks wether the specified spell
-- is tracked by the user
local function isTracked(spellID)
	for id, spell in pairs(E.db["BH"].spells) do
		if spellID == tonumber(id) then
			return spell.enabled
		end
	end
	return false
end

-- Check if a tracked buff is currently on the unit
local function CheckBuff(unit)
	if not unit or not UnitCanAssist("player", unit) then return nil end
	local i = 1
	while true do
		local _, texture,_,_,_, expire, source,_,_, spellID = UnitBuff(unit, i, "HELPFUL|PLAYER")
		if not texture then break end

		if(source == "player" and isTracked(spellID)) then
			return expire - GetTime(), spellID
		end
		i = i + 1
	end
end

-- Check wether ElvUI is already highlighting an aura
local function AuraHighlighted(frame)
	if (not frame.AuraHighlight) then return false end
	
	local r, g, b, _ = frame.AuraHighlight:GetVertexColor()
	return r ~= 0 or g ~= 0 or b ~= 0
end

-- Generates color gradient based off of 3 color points
local function ColorGradient(a, b, lowR, lowG, lowB, midR, midG, midB, hiR, hiG, hiB)
	local perc = a/b
	
	--Get corner cases out of the way
	if perc >= 1 then
		return hiR, hiG, hiB
	elseif  perc == 0.5 then
		return midR, midG, midB
	elseif perc == 0 then
		return lowR, lowG, lowB
	end

	--percent health * number of colors (scale up the percent to be distributed among 3 colors)
	local colorInd, colorPerc = math.modf((a/b) * 2)
	if perc < 0.5 then
		return lowR + (midR-lowR)*colorPerc, lowG + (midG-lowG)*colorPerc, lowB + (midB-lowB)*colorPerc
	else
		return midR + (hiR-midR)*colorPerc, midG + (hiG-midG)*colorPerc, midB + (hiB-midB)*colorPerc
	end
end

-- Gets appropriate gradient color for frame
local function GetGradient(frame, unit, lowR, lowG, lowB, midR, midG, midB, hiR, hiG, hiB)
	local colors = E.db.unitframe.colors
	local r, g, b = hiR, hiG, hiB
	if colors.colorhealthbyvalue and not UnitIsTapDenied(unit) then
		if midR and lowR then
			r, g, b =  ColorGradient(frame.cur, frame.max, lowR, lowG, lowB, midR, midG, midB, hiR, hiG, hiB)
		end
	end
	return r, g, b
end

--Resets the health color with default ElvUI colors
--Copied UF:PostUpdateHealthColor from ElvUI but made coloring requirement is more lax
local function resetHealthBarColor(frame, unit)
	local parent = frame:GetParent()
	local colors = E.db.unitframe.colors
	local r, g, b = colors.health.r, colors.health.g, colors.health.b
	local newr, newg, newb = r, g, b
	local classr, classg, classb = nil, nil, nil
	
	-- Get class colors
	if colors.healthclass then
		local reaction, color = (UnitReaction(unit, 'player'))
		if UnitIsPlayer(unit) then
			local _, Class = UnitClass(unit)
			color = parent.colors.class[Class]
		elseif reaction then
			color = parent.colors.reaction[reaction]
		end
		classr, classg, classb = color[1], color[2], color[3]
		if classr then
			r, g, b = classr, classg, classb
		end
	end
	
	newr, newg, newb = GetGradient(frame, unit, 1, 0, 0, 1, 1, 0, r, g, b)
	
	--Set frame color
	frame:SetStatusBarColor(newr, newg, newb, 1.0)
	
	-- Charmed player should have hostile color
	if unit and (strmatch(unit, "raid%d+") or strmatch(unit, "party%d+")) then
		if not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) and UnitIsCharmed(unit) and UnitIsEnemy("player", unit) then
			local color = parent.colors.reaction[HOSTILE_REACTION]
			if color then self:SetStatusBarColor(color[1], color[2], color[3]) end
		end
	end

	-- Set
	if frame.bg then
		frame.bg.multiplier = (colors.healthMultiplier > 0 and colors.healthMultiplier) or 0.35

		if colors.useDeadBackdrop and UnitIsDeadOrGhost(unit) then
			frame.bg:SetVertexColor(colors.health_backdrop_dead.r, colors.health_backdrop_dead.g, colors.health_backdrop_dead.b)
		elseif colors.customhealthbackdrop then
			frame.bg:SetVertexColor(colors.health_backdrop.r, colors.health_backdrop.g, colors.health_backdrop.b)
		elseif colors.classbackdrop then
			if classr then
				frame.bg:SetVertexColor(classr * frame.bg.multiplier, classg * frame.bg.multiplier, classb * frame.bg.multiplier)
			end
		elseif newb then
			frame.bg:SetVertexColor(newr * frame.bg.multiplier, newg * frame.bg.multiplier, newb * frame.bg.multiplier)
		else
			frame.bg:SetVertexColor(r * frame.bg.multiplier, g * frame.bg.multiplier, b * frame.bg.multiplier)
		end
	end
end

-- Update the health color for the frame 
-- and the buff specified.
local function updateHealth(frame, unit, spellID)
	if not E.db["BH"].spells[spellID] then return end

	if frame.BuffHighlightActive then
		-- Get highlight color for the spell
		local t = E.db["BH"].spells[spellID].glowColor
		local t2 = E.db["BH"].spells[spellID].glowColorTwo
		local t3 = E.db["BH"].spells[spellID].glowColorThree
		
		local r, g, b =  GetGradient(frame, unit, t3.r, t3.g, t3.b, t2.r, t2.g, t2.b, t.r, t.g, t.b)
		
		-- Highlight the health backdrop if enabled
		if E.db["BH"].colorBackdrop then
			local m = frame.bg.multiplier
			frame.bg:SetVertexColor(r * m, g * m, b * m)
		end
		-- Update the health color
		frame:SetStatusBarColor(r, g, b, t.a)
	end
end

-- Update the frame. Check if a buff is applied
-- for this frame. Clears any buff highlight 
-- if an aura is already highlighted by ElvUI
-- to avoid conflicts.
local function updateFrame(frame, unit)
	-- Check if an aura is already highlighted
	if AuraHighlighted(frame:GetParent()) then 
		frame.BuffHighlightActive = false
		frame.BuffHighlightFaderActive = false
		
		resetHealthBarColor(frame, unit)
		return 
	end

	-- Check if a buff is on the unit
	local buffDuration, spellID = CheckBuff(unit)
	-- If not, disabled the buff highlight if there was any
	if (frame.BuffHighlightActive or frame.BuffHighlightFaderActive) and (not buffDuration or buffDuration < 0) then 
		frame.BuffHighlightActive = false
		frame.BuffHighlightFaderActive = false

		resetHealthBarColor(frame, unit)
		return
	end

	-- Enable the buff highlight or fade effect for this frame
	if not E.db["BH"].spells[spellID] then return end
	frame.BuffHighlightActive = true
	frame.BuffHighlightFaderActive = false

	-- Update the health color
	updateHealth(frame, unit, spellID)
end

-- Returns a table with the type of unit frames active
-- Toggle whether or not to use raid40 from UI
-- *Need to refactor this to query actual ElvUI variables
local function GetActiveFrames()
	local _headers = {}
	members = GetNumGroupMembers()
	if members <= 5 then
		table.insert(_headers, "party")
	elseif members < 26 then
		table.insert(_headers, "raid")
	elseif E.db["BH"].UseRaid40 then
		table.insert(_headers, "raid40")
	else
		table.insert(_headers, "raid")
	end
	return _headers
end

-- Update function. Cycles through all unitframes
-- in party, raid and raid 40 groups. 
function BH_EventHandler(self, event, ...)
	local unit = ...
	
	if not unit or not UnitCanAssist("player", unit) then
		return
	end
	
	local _headers = GetActiveFrames()
	
	for _, name in pairs(_headers) do
		local header = UF.headers[name]
		for i = 1, header:GetNumChildren() do
			local group = select(i, header:GetChildren())
			for j = 1, group:GetNumChildren() do
				local frame = select(j, group:GetChildren())
				if frame and frame.Health and frame.unit then
					if unit == frame.unit then
						updateFrame(frame.Health, frame.unit)
					end
				end
			end
		end
	end
end

-- Disables the plugin
-- To unhook the UF function PostUpdateColor, the UI needs to reload.
function BH:disablePlugin()
	f:SetScript("OnEvent", nil)
	E:StaticPopup_Show('CONFIG_RL')
end

-- Enables the plugin
-- Hooks the PostUpdateColor of every frame
-- we're tracking. Avoids the flickering effect when 
-- ElvUI updates a frame that we did not update ourselves
function BH:enablePlugin()
	f:SetScript("OnEvent", BH_EventHandler)
	
	if not E.private.unitframe.enable then 
		return 
	end

	local _headers = GetActiveFrames()
	
	for _, name in pairs(_headers) do
		local header = UF.headers[name]
		for i = 1, header:GetNumChildren() do
			local group = select(i, header:GetChildren())
			for j = 1, group:GetNumChildren() do
				local frame = select(j, group:GetChildren())
				if frame and frame.Health and frame.unit then
					hooksecurefunc(
						frame.Health, 
						"PostUpdateColor", 
						function(self, unit, ...) updateFrame(self, unit) end
					)
				end
			end
		end
	end
end

-- Called at the start of the plugin
function BH:Initialize()
	if E.db["BH"].enable then
		BH:enablePlugin()
	end
	EP:RegisterPlugin(addon, BH.GetOptions) 
end