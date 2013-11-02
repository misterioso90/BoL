--[[Heimerdinger Prodiction test by BotHappy

0.1 - First test]]

if myHero.charName ~= "Heimerdinger" then return end

if not VIP_USER then
	return
end

require "Collision"
require "Prodiction"

local RangeW = 1350

local Prodict = ProdictManager.GetInstance()
local ProdictW, ProdictWCol

local WAble

local ts = {}
local HeimerConfig = {}

function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function CastW(unit, pos, spell)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < RangeW then
		local willCollide = ProdictWCol:GetMinionCollision(pos, myHero)
		if not willCollide then CastSpell(_W, pos.x, pos.z) end
	end
end

function OnLoad()

	ts = TargetSelector(TARGET_LESS_CAST, 1550, DAMAGE_MAGIC)
	HeimerConfig = scriptConfig("Heimer Options", "HeimerCONF")
	local HKW = string.byte("X")
	
	HeimerConfig:addParam("W", "Cast W", SCRIPT_PARAM_ONKEYDOWN, false, HKW)
	HeimerConfig:addTS(ts)
	
	ts.name = "Heimerdinger"
	
	ProdictW = Prodict:AddProdictionObject(_W, RangeW, 1200, 0.2, 75, myHero, CastW)
	ProdictWCol = Collision(RangeW, 1200, 0.2, 75)
	
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictW:CanNotMissMode(true, hero)
		end
	end
	
	PrintChat(">> Heimer Prodiction 0.1 loaded")
end

function OnTick()
	Checks()
	ts:update()
	if ts.target ~= nil and HeimerConfig.W then
		ProdictW:EnableTarget(ts.target, true)
	end
end

function OnDraw()
	if ts.target ~= nil then
		local dist = getHitBoxRadius(ts.target)/2
		
		if GetDistance(ts.target) - dist < RangeW then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
		end
	end
	
	if WAble then
		DrawCircle(myHero.x, myHero.y, myHero.z, RangeW, 0x7F006E)
	end
end

function Checks()
	WAble = (myHero:CanUseSpell(_W) == READY)
end