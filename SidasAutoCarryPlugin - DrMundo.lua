--[[Sida's Autocarry Plugin - DrMundo by BotHappy

v0.1 - Initial release (WIP)
]]

require "Collision"
require "Prodiction"

if myHero.charName ~= "DrMundo" then return end

local qRange = 1050 -- Q range
local wRange = 325 -- Turn on W when target is in this range
local eRange = 300 -- Turn on E when in this range
local wUsed = false

local QAble, WAble, EAble, RAble = false, false, false, false

local Prodict = ProdictManager.GetInstance()
local ProdictQ, ProdictQCol


function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 1400
	Menu()
	
	ProdictQ = Prodict:AddProdictionObject(_Q, qRange, 1900, 0.3, 80, myHero, CastQ)
	ProdictQCol = Collision(qRange, 1900, 0.3, 80)
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictQ:CanNotMissMode(true, hero)
		end
	end
	PrintChat(">> Time to Mundo! 0.1 Loaded")
end

function PluginOnTick()
	Checks()
	if Target then
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			ComboCast()
		end
	end
	if AutoCarry.PluginMenu.useR then CastREmergency() end
end

function PluginOnDraw()
	if not myHero.dead then
		if QAble and AutoCarry.PluginMenu.drawQ then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x7CFC00)
		end
		if WAble and AutoCarry.PluginMenu.drawW then 
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x00FFFF)
		end
	end
end

function Menu()
	AutoCarry.PluginMenu:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useR", "Auto use R (20% life)", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("drawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
end

function Checks()
	QAble = (myHero:CanUseSpell(_Q) == READY)
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
end

function ComboCast() 

	if QAble and AutoCarry.PluginMenu.useQ then ProdictQ:EnableTarget(Target, true) end
	
	if WAble and AutoCarry.PluginMenu.useW then 
		if wUsed == false and GetDistance(Target) <=wRange then
			CastSpell(_W)
		elseif GetDistance(Target) > 550 and wUsed == true then
			CastSpell(_W)
		end
	end
	
	if EAble and AutoCarry.PluginMenu.useE then
		if GetDistance(Target) <= eRange then
			CastSpell(_E)
		end
	end
end

local function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function CastQ(unit, pos, spell)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < qRange then
		local willCollide = ProdictQCol:GetMinionCollision(pos, myHero)
		if not willCollide then CastSpell(_Q, pos.x, pos.z) end
	end
end

function CastREmergency()
    if myHero.health < (myHero.maxHealth*(20/100)) then
		if RAble then
			CastSpell(_R)
        end
    end
end

function OnGainBuff(myHero, buff)
	if buff.name == "BurningAgony" then
		wUsed = true
	end
end

function OnLoseBuff(myHero, buff)
	if buff.name == "BurningAgony" then
		wUsed = false
	end
end