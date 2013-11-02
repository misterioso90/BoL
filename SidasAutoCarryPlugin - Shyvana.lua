--[[ Shyvana Prodiction Autocarry Plugin by BotHappy

0.1 - Prodiction Adapted to Shyvana
0.2 - AutoCarry Script w/o Prodiction
0.3 - Prodiction Update
0.4 - Added Item Usage
0.5 - Dragon + Fixes + Harrass]]

--require "Collision"
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
local QAble, WAble, EAble, RAble, WActive, DragonActive = false, false, false, false, false, false

local Prodict = ProdictManager.GetInstance()
local ProdictE, ProdictR

local items =
		{
				BRK = {id=3153, range = 500, reqTarget = true, slot = nil },
                BWC = {id=3144, range = 400, reqTarget = true, slot = nil },
				DFG = {id=3128, range = 750, reqTarget = true, slot = nil },
                HGB = {id=3146, range = 400, reqTarget = true, slot = nil },
                RSH = {id=3074, range = 350, reqTarget = false, slot = nil},
                STD = {id=3131, range = 350, reqTarget = false, slot = nil},
                TMT = {id=3077, range = 350, reqTarget = false, slot = nil},
                YGB = {id=3142, range = 350, reqTarget = false, slot = nil}
		}

		
function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 1100
	Menu()
	
	ProdictE = Prodict:AddProdictionObject(_E, 925, 1500, 0.125, 80, myHero, CastE) --925+125? myHero:GetSpellData(_E).lineWidth
	ProdictR = Prodict:AddProdictionObject(_R, 1000, 1000, 0.125, 80, myHero, CastR) -- myHero:GetSpellData(_R).lineWidth
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictE:CanNotMissMode(true, hero)
			ProdictR:CanNotMissMode(true, hero)
		end
	end
	
	PrintChat(">> Shyvana Tiem 0.5 Loaded")
end

function PluginOnTick()
	Checks()
	if Target then
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			ComboCast()
		end
		if AutoCarry.PluginMenu.Harrass and EAble then
			ProdictE:EnableTarget(Target, true)
		end
	end
end

function PluginOnDraw()
	if not myHero.dead then
		if (WAble or WActive) and AutoCarry.PluginMenu.drawW then
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

function ComboCast() 
	UseItems(Target)
	if QAble and AutoCarry.PluginMenu.useQ then
		if GetDistance(Target) <= QRange  and AutoCarry.shotFired then
			CastSpell(_Q)
		end
	end
	if WAble and AutoCarry.PluginMenu.useW then CastSpell(_W) end
	if EAble and AutoCarry.PluginMenu.useE then ProdictE:EnableTarget(Target, true) end
	if RAble and AutoCarry.PluginMenu.useR then ProdictR:EnableTarget(Target, true) end
end

function Checks()
	QAble = (myHero:CanUseSpell(_Q) == READY)
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
	if DragonActive then
		ERange = 700
	elseif not DragonActive then
		ERange = 925
	end
end

function Menu()
	local HKE = string.byte("T")
	AutoCarry.PluginMenu:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useR", "Use R in combo", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("Harrass", "Harrass with E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	AutoCarry.PluginMenu:permaShow("Harrass")
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

-- By Sida
function UseItems(target)
    if target == nil then return end
    for _,item in pairs(items) do
        item.slot = GetInventorySlotItem(item.id)
        if item.slot ~= nil then
            if item.reqTarget and GetDistance(target) < item.range then
                CastSpell(item.slot, target)
                elseif not item.reqTarget then
                if (GetDistance(target) - getHitBoxRadius(myHero) - getHitBoxRadius(target)) < 50 then
                    CastSpell(item.slot)
                end
            end
        end
    end
end

function OnGainBuff(myHero, buff)
	if buff.name == "ShyvanaImmolationAura" then
		WActive = true
	end
	if buff.name == "shyvanatransform" then
		DragonActive = true
	end
end

function OnLoseBuff(myHero, buff)
	if buff.name == "ShyvanaImmolationAura" then
		WActive = false
	end
	if buff.name == "shyvanatransform" then
		DragonActive = false
	end
end