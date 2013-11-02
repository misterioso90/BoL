--[[Heimerdinger Prodiction test by BotHappy

0.1 - First test
0.2 - Added E
0.3 - Added Simple Combo]]

if myHero.charName ~= "Heimerdinger" then return end

if not VIP_USER then
	return
end

require "Collision"
require "Prodiction"

local RangeW = 1350
local RangeE = 925

local Prodict = ProdictManager.GetInstance()
local ProdictW, ProdictWCol, ProdictE

local WAble, EAble, RAble

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

function CastE(unit, pos, spell)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < RangeE then
		CastSpell(_E, pos.x, pos.z)
	end
end

function CastCombo()
	if WAble and EAble and RAble and HeimerConfig.UseR then
		if GetDistance(ts.target) - getHitBoxRadius(ts.target)/2 < RangeE then
			local willCollide = ProdictWCol:GetMinionCollision(ts.target, myHero)
			if not willCollide then
				ProdictE:EnableTarget(ts.target, true)
				CastSpell(_R)
				ProdictW:EnableTarget(ts.target, true)
			end
		end
	elseif WAble and RAble and HeimerConfig.UseR then
		if GetDistance(ts.target) - getHitBoxRadius(ts.target)/2 < RangeW then
			local willCollide = ProdictWCol:GetMinionCollision(ts.target, myHero)
			if not willCollide then
				CastSpell(_R)
				ProdictW:EnableTarget(ts.target, true)
			end
		end
	elseif WAble and EAble then
		if GetDistance(ts.target) - getHitBoxRadius(ts.target)/2 < RangeE then
			local willCollide = ProdictWCol:GetMinionCollision(ts.target, myHero)
			if not willCollide then
				ProdictE:EnableTarget(ts.target, true)
				ProdictW:EnableTarget(ts.target, true)
			end
		end
	end
end

function OnLoad()

	ts = TargetSelector(TARGET_LESS_CAST, 1550, DAMAGE_MAGIC)
	HeimerConfig = scriptConfig("Heimer Options", "HeimerCONF")
	local HKW = string.byte("X")
	local HKE = string.byte("C")
	local HKCombo = string.byte("T")
	
	HeimerConfig:addParam("W", "Cast W", SCRIPT_PARAM_ONKEYDOWN, false, HKW)
	HeimerConfig:addParam("E", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	HeimerConfig:addParam("Combo", "Cast Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKCombo)
	HeimerConfig:addParam("UseR", "Use R at Combo", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:permaShow("W")
	HeimerConfig:permaShow("E")
	HeimerConfig:permaShow("Combo")
	HeimerConfig:addTS(ts)
	
	ts.name = "Heimerdinger"
	
	ProdictW = Prodict:AddProdictionObject(_W, RangeW, 1200, 0.2, 70, myHero, CastW)
	ProdictWCol = Collision(RangeW, 1200, 0.2, 70)
	ProdictE = Prodict:AddProdictionObject(_E, RangeE, 1000, 0.2, 70, myHero, CastE)
	
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictW:CanNotMissMode(true, hero)
			ProdictE:CanNotMissMode(true, hero)
		end
	end
	
	PrintChat(">> Heimer Prodiction 0.3 loaded")
end

function OnTick()
	Checks()
	ts:update()
	if ts.target ~= nil and HeimerConfig.W then
		ProdictW:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and HeimerConfig.E then
		ProdictE:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and HeimerConfig.Combo then
		CastCombo()
	end
end

function OnDraw()
	if ts.target ~= nil then
		local dist = getHitBoxRadius(ts.target)/2
		
		if GetDistance(ts.target) - dist < RangeW then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
		end
		if GetDistance(ts.target) - dist < RangeE then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x5F9F9F)
		end
	end
	
	if WAble then
		DrawCircle(myHero.x, myHero.y, myHero.z, RangeW, 0x7F006E)
	end
	if EAble then
		DrawCircle(myHero.x, myHero.y, myHero.z, RangeE, 0x5F9F9F)
	end
end

function Checks()
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_E) == READY)
end