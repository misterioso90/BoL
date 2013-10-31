--[[ Shyvana Prodiction by BotHappy

0.1 - Prodiction Adapted to Shyvana
0.2 - AutoCarry Script w/o Prodiction
0.3 - Prodiction Update]]

require "Collision"
require "Prodiction"

if myHero.charName ~= "Shyvana" then return end

if not VIP_USER then
	print("Shyvana Tiem is VIP Only ATM.")
	return
end

local QRange = 125
local WRange = 325
local ERange = 925
local RRange = 1000
local QAble, WAble, EAble, RAble = false, false, false, false

local Prodict = ProdictManager.GetInstance()
local ProdictE, ProdictR
local ts = {}
--local SkillE = {spellKey = _E, range = ERange, speed = 1.5, delay = 125, width = 80}
--local SkillR = {spellKey = _R, range = RRange, speed = 1.0, delay = 250, width = 80}

function Menu()
	AutoCarry.PluginMenu:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useR", "Use R in combo", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
end

local function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function CastE(unit, pos, spell)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < ERange then
		CastSpell(_E, pos.x, pos.z) 
	end
end

function CastR(unit, pos, spell)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < RRange then
		CastSpell(_R, pos.x, pos.z) 
	end
end

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 1100
	Menu()
	
	ProdictE = Prodict:AddProdictionObject(_E, 925, 1500, 0.125, 80, myHero, CastE) --925+125? myHero:GetSpellData(_E).lineWidth
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictE:CanNotMissMode(true, hero)
		end
	end
	
	ProdictR = Prodict:AddProdictionObject(_R, 1000, 1000, 0.125, 80, myHero, CastR) -- myHero:GetSpellData(_R).lineWidth
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictR:CanNotMissMode(true, hero)
		end
	end
	
	PrintChat(">> Shyvana Tiem 0.3 Loaded")
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
	if EAble and AutoCarry.PluginMenu.useE then ProdictE:EnableTarget(Target, true) end
	if RAble and AutoCarry.PluginMenu.useR then ProdictR:EnableTarget(Target, true) end
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