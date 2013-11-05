--[[Heimerdinger Prodiction test by BotHappy

0.1 - First test
0.2 - Added E
0.3 - Added Simple Combo
0.5 - Added Items + Dragon Lvl1 Spot
0.6 - Autoignite + Fixes

http://pastebin.com/SJ2zXeNk
Revisar para ideas de combos del chaval este]]

if myHero.charName ~= "Heimerdinger" then return end

if not VIP_USER then
	return
end

require "Collision"
require "Prodiction"

gameState = GetGame()

local RangeW = 1350
local RangeE = 925

local Prodict = ProdictManager.GetInstance()
local ProdictW, ProdictWCol, ProdictE

local WAble, EAble, RAble

local IgniteSlot = nil

local ts = {}
local HeimerConfig = {}

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

function CheckIgnite()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then IgniteSlot = SUMMONER_1
        elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then IgniteSlot = SUMMONER_2
    end
end

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

function CastCombo(Target)
	if WAble and EAble and RAble and HeimerConfig.UseR then
		if GetDistance(Target) - getHitBoxRadius(Target)/2 < RangeE then
			local willCollide = ProdictWCol:GetMinionCollision(Target, myHero)
			if not willCollide then
				UseItems(Target)
				ProdictE:EnableTarget(Target, true)
				CastSpell(_R)
				ProdictW:EnableTarget(Target, true)
			end
		end
	elseif (WAble and not EAble and RAble and HeimerConfig.UseR) or (WAble and RAble and HeimerConfig.UseR) then
		if GetDistance(Target) - getHitBoxRadius(Target)/2 < RangeW and GetDistance(Target) - getHitBoxRadius(Target)/2 > RangeE then
			local willCollide = ProdictWCol:GetMinionCollision(Target, myHero)
			if not willCollide then
				UseItems(Target)
				CastSpell(_R)
				ProdictW:EnableTarget(Target, true)
			end
		end
	elseif not RAble and WAble and EAble then
		if GetDistance(Target) - getHitBoxRadius(Target)/2 < RangeE then
			local willCollide = ProdictWCol:GetMinionCollision(Target, myHero)
			if not willCollide then
				UseItems(Target)
				ProdictE:EnableTarget(Target, true)
				ProdictW:EnableTarget(Target, true)
			end
		end
	end
	--Turret Combo E + R+Q
	--Stun Combo -> W + R+E
end

function OnLoad()

	CheckIgnite()

	ts = TargetSelector(TARGET_LESS_CAST, 1550, DAMAGE_MAGIC)
	HeimerConfig = scriptConfig("Heimer Options", "HeimerCONF")
	local HKW = string.byte("X")
	local HKE = string.byte("C")
	local HKCombo = string.byte("T")
	
	HeimerConfig:addParam("W", "Cast W", SCRIPT_PARAM_ONKEYDOWN, false, HKW)
	HeimerConfig:addParam("E", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	HeimerConfig:addParam("Combo", "Cast Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKCombo)
	HeimerConfig:addParam("UseR", "Use R at Combo", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:addParam("Dragon", "Draw Turrets Placement to Dragon", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:addParam("Ignite", "Auto Ignite KS", SCRIPT_PARAM_ONOFF, true)
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
	
	PrintChat(">> Heimer Prodiction 0.6 loaded")
end

function OnTick()
	Checks()
	ts:update()
	AutoIgniteKS()
	if ts.target ~= nil and HeimerConfig.W then
		ProdictW:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and HeimerConfig.E then
		ProdictE:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and HeimerConfig.Combo then
		CastCombo(ts.target)
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
	if HeimerConfig.Dragon and gameState.map.shortName == "summonerRift" then
		DrawCircle(10117.653320 , -61.549327, 4804.696289, 40, 0xFFFFFF) --Top One
		DrawCircle(10330.710937 , -62.091323, 4567.517089, 40, 0xFFFFFF) --Mid One
		DrawCircle(10295 , -61.179419, 4330.397460, 40, 0xFFFFFF) --Bottom One??
		--DrawCircle(10254.695312, -60.704513, 4303.810546, 40, 0xFFFFFF) --Could work as bottom one
	end
end 

function Checks()
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_R) == READY)
	if IgniteSlot ~= nil then IgniteAble = (myHero:CanUseSpell(IgniteSlot) == READY) end
end

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

function AutoIgniteKS()
	if HeimerConfig.Ignite and IgniteAble then
		IgniteDMG = 50 + (20 * myHero.level)
		for _, enemy in pairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 600) and enemy.health <= IgniteDMG then
				CastSpell(IgniteSlot, enemy)
			end
		end
	end
end