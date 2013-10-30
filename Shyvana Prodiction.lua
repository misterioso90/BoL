--[[ Shyvana Prodiction by BotHappy

0.1 - Prodiction Adapted to Shyvana ]]

require "Collision"
require "Prodiction"

if myHero.charName ~= "Shyvana" then return end


local ERange = 925
local RRange = 1000

local Prodict = ProdictManager.GetInstance()

local ProdictE, ProdictR

local ts = {}
local ShyvanaConfig = {}

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

function OnLoad()

	ts = TargetSelector(TARGET_LESS_CAST, 1100, DAMAGE_MAGIC)
	ShyvanaConfig = scriptConfig("Shyvana Prodiction", "ShyvanaE")
	
	local HKE = string.byte("X")
	local HKR = string.byte("C")
	
	ShyvanaConfig:addParam("E", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	ShyvanaConfig:addParam("R", "Cast R", SCRIPT_PARAM_ONKEYDOWN, false, HKR)
	ShyvanaConfig:addTS(ts)
	
	
	ts.name = "ShyvanaE"
	
	ProdictE = Prodict:AddProdictionObject(_E, 925, 1500, 0.125, 80, myHero, CastE) --925+125?
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictE:CanNotMissMode(true, hero)
		end
	end
	
	ProdictR = Prodict:AddProdictionObject(_R, 1000, 1000, 0.125, 80, myHero, CastR)
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictR:CanNotMissMode(true, hero)
		end
	end
	
	PrintChat(">>Shyvana Prodiction 0.1 loaded")
end

function OnTick()
	ts:update()
	if ts.target ~= nil and ShyvanaConfig.E then
		ProdictE:EnableTarget(ts.target, true)
	end
	
	if ts.target ~= nil and ShyvanaConfig.R then
		ProdictR:EnableTarget(ts.target, true)
	end
end

function OnDraw()
	if ts.target ~= nil then
		local dist = getHitBoxRadius(ts.target)/2
		DrawCircle(myHero.x, myHero.y, myHero.z, 1050, 0x7F006E)
		if GetDistance(ts.target) - dist < 1050 then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
		end
		
		DrawCircle(myHero.x, myHero.y, myHero.z, 1125, 0xFF3300)
		if GetDistance(ts.target) - dist < 1125 then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0xFF3300)
		end
	end
end
