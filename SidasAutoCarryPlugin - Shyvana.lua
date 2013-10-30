--[[ Shyvana Prodiction by BotHappy

0.1 - Prodiction Adapted to Shyvana
0.2 - AutoCarry Script w/o Prodiction]]

require "Collision"

if myHero.charName ~= "Shyvana" then return end

local QRange = 125
local WRange = 325
local ERange = 925
local RRange = 1000
local QAble, WAble, EAble, RAble = false, false, false, false
local SkillE = {spellKey = _E, range = ERange, speed = 1.5, delay = 125, width = 80}
local SkillR = {spellKey = _R, range = RRange, speed = 1.0, delay = 250, width = 80}

function Menu()
	AutoCarry.PluginMenu:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useR", "Use R in combo", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
end

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 1100
	Menu()
	PrintChat(">>Shyvana 0.1 Loaded")
end

function PluginOnTick()
	Checks()
	if Target then
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			ComboCast()
		end
	end
end

function ComboCast() 
	if QAble and AutoCarry.PluginMenu.useQ then
		if GetDistance(Target) <= QRange  and AutoCarry.shotFired then
			CastSpell(_Q, Target)
		end
	end
	if WAble and AutoCarry.PluginMenu.useW then CastSpell(_W, Target) end
	if EAble and AutoCarry.PluginMenu.useE then AutoCarry.CastSkillshot(SkillE, Target) end
	if RAble and AutoCarry.PluginMenu.useR then AutoCarry.CastSkillshot(SkillR, Target) end
end

function Checks()
	QAble = (myHero:CanUseSpell(_Q) == READY)
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
end

function PluginOnDraw()
	if not myHero.dead then
		if WAble and AutoCarry.PluginMenu.drawW then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0x7CFC00)
		end
		if EAble and AutoCarry.PluginMenu.drawE then 
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FFFF)
		end
		if RAble and AutoCarry.PluginMenu.drawR then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF0000)
		end
	end
end