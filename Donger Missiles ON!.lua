--[[Heimerdinger Prodiction test by BotHappy

0.1 - First test
0.2 - Added E
0.3 - Added Simple Combo
0.5 - Added Items + Dragon Lvl1 Spot
0.6 - Autoignite + Fixes
0.7 - More Combos, improvement and added Blackfire Torch
0.8 - Management of Combos + Mana
0.9 - Added Move while comboing + Rewritten combos (More reliable now)
0.9a - Distance Combo fixed + Improved FPS
0.9b - New Dragon spots at top + Magnet spot
0.9c - Orbwalking improvement

TODO
* Finish Combo Calculation + test WIP
* Draw Killable with Combo Calculation]]

if myHero.charName ~= "Heimerdinger" then return end

if not VIP_USER then
	return
end

require "Collision"
require "Prodiction"

gameState = GetGame()

local RangeW = 1350
local RangeE = 925
local RangeQ = 350
local RangeRE = 1800
local WidthE = 70

local Prodict = ProdictManager.GetInstance()
local ProdictW, ProdictWCol, ProdictE

local QAble, WAble, EAble, RAble = false, false, false, false
local QMana, WMana, EMana, RMana = 0,0,0,0

local UnitSlowed = false

local IgniteSlot = nil

local ts = {}
local HeimerConfig = {}

local items =
	{
		BRK = {id=3153, range = 500, reqTarget = true, slot = nil },
		BFT = {id=3188, range = 750, reqTarget = true, slot = nil },
		BWC = {id=3144, range = 400, reqTarget = true, slot = nil },
		DFG = {id=3128, range = 750, reqTarget = true, slot = nil },
		HGB = {id=3146, range = 400, reqTarget = true, slot = nil },
		RSH = {id=3074, range = 350, reqTarget = false, slot = nil},
		STD = {id=3131, range = 350, reqTarget = false, slot = nil},
		TMT = {id=3077, range = 350, reqTarget = false, slot = nil},
        YGB = {id=3142, range = 350, reqTarget = false, slot = nil}
	}
	
local TurretSpots =
	{
		--Bottom towers
		{x= 10117.65 ,	y= -61.54,	z=4804.69}, --Top One
		{x= 10330.71 ,	y= -62.09,	z=4567.51}, --Mid One
		{x= 10295 ,		y=-61.17, 	z=4330.39}, --Bottom One
		
		--Top Towers
		{x= 9595, 		y=-59.20, 	z=5102.39},
		{x= 9532, 		y=-58.07, 	z=5125.13},
		{x= 9272, 		y=-58.45, 	z=5011.17},
	}

function CheckIgnite()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then IgniteSlot = SUMMONER_1
        elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then IgniteSlot = SUMMONER_2
    end
end

function getHitBoxRadius(Target)
	return GetDistance(Target, Target.minBBox)
end

function DistanceToHit(Target)
	Distance = GetDistance(Target) - getHitBoxRadius(Target)/2
	return Distance
end

function CastW(unit, pos)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < RangeW then
		local willCollide = ProdictWCol:GetMinionCollision(pos, myHero)
		if not willCollide then CastSpell(_W, pos.x, pos.z) end
	end
end

function CastE(unit, pos)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < RangeE then
		CastSpell(_E, pos.x, pos.z)
	end
end

function CastDistanceCombo(Target)
	if RAble and HeimerConfig.UseR then
		if EAble and DistanceToHit(Target) > RangeW and DistanceToHit(Target) <RangeRE and myHero.mana >= RMana then
			CastSpell(_R)
			ProdictE:EnableTarget(Target, true)
			ERCastTime = GetTickCount() + 150
		end
	end
	if WAble and (not Target.canMove or UnitSlowed) and GetTickCount() > ERCastTime and myHero.mana >= WMana and DistanceToHit(Target) < RangeW then
		ProdictW:EnableTarget(Target, true)
	end
	
end

function IntelligentCombo(Target)
	UseItems(Target)
	local ECastTime = 0
	
	if EAble and DistanceToHit(Target) <RangeE and myHero.mana >= EMana then
		ProdictE:EnableTarget(Target, true)
		ECastTime = GetTickCount() + 150
	end
	
	if QAble and HeimerConfig.UseQ and (not Target.canMove or UnitSlowed) and RAble and HeimerConfig.UseR and GetTickCount() > ECastTime and myHero.mana >= RMana and DistanceToHit(Target) < RangeQ then
		CastSpell(_R)
		CastSpell(_Q, Target.x, Target.z)
		myHero:Attack(Target)
	end
	
	if WAble and (not Target.canMove or UnitSlowed) and RAble and HeimerConfig.UseR and GetTickCount() > ECastTime and myHero.mana >= RMana and DistanceToHit(Target) < RangeW and ((QAble and DistanceToHit(Target) > RangeQ) or not HeimerConfig.UseQ) then
		CastSpell(_R)
		ProdictW:EnableTarget(Target, true)
	end
	
	if WAble and (not Target.canMove or UnitSlowed) and GetTickCount() > ECastTime and myHero.mana >= WMana and DistanceToHit(Target) <RangeW then
		ProdictW:EnableTarget(Target, true)
	end
	
	if QAble and (not Target.canMove or UnitSlowed) and HeimerConfig.UseQ and GetTickCount() > ECastTime and myHero.mana >= QMana and DistanceToHit(Target) < RangeQ then
		CastSpell(_Q, Target.x, Target.z)
	end
	
	if QAble and HeimerConfig.UseQ and WAble and not EAble and Target.canMove and myHero.mana >= QMana + WMana and DistanceToHit(Target) <RangeQ then
		CastSpell(_Q, Target.x, Target.z)
		ProdictW:EnableTarget(Target, true)
	end

end

function OnLoad()

	CheckIgnite()

	ts = TargetSelector(TARGET_LESS_CAST, RangeRE+150, DAMAGE_MAGIC)
	HeimerConfig = scriptConfig("Heimer Options", "HeimerCONFIG0.9c")
	local HKW = string.byte("X")
	local HKE = string.byte("C")
	local HKDCombo = string.byte("T")
	local HKSCombo = 32
	
	HeimerConfig:addParam("W", "Cast W", SCRIPT_PARAM_ONKEYDOWN, false, HKW)
	HeimerConfig:addParam("E", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	HeimerConfig:addParam("DisCombo", "Cast Distance Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKDCombo)
	HeimerConfig:addParam("IntCombo", "Intelligent Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKSCombo)
	HeimerConfig:addParam("UseR", "Use R at Combo", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:addParam("UseQ", "Use Q at Combo", SCRIPT_PARAM_ONOFF, false)
	HeimerConfig:addParam("Dragon", "Draw Turrets Placement to Dragon", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:addParam("Ignite", "Auto Ignite KS", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:addParam("magnet", "Magnet Turret Spot (Press Z)", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:addParam("UseOrbwalk", "Orbwalking at combo", SCRIPT_PARAM_ONOFF, true)
	HeimerConfig:permaShow("W")
	HeimerConfig:permaShow("E")
	HeimerConfig:permaShow("IntCombo")
	HeimerConfig:permaShow("DisCombo")
	HeimerConfig:addTS(ts)
	
	ts.name = "Heimerdinger"
	
	ProdictW = Prodict:AddProdictionObject(_W, RangeW, 1200, 0.2, 70, myHero, CastW)
	ProdictWCol = Collision(RangeW, 1200, 0.2, 70)
	ProdictE = Prodict:AddProdictionObject(_E, RangeE, 1000, 0.1, WidthE, myHero, CastE)
	
	-- for I = 1, heroManager.iCount do
		-- local hero = heroManager:GetHero(I)
		-- if hero.team ~= myHero.team then
			-- ProdictW:CanNotMissMode(true, hero)
			-- ProdictE:CanNotMissMode(true, hero)
		-- end
	-- end
	
	PrintChat(">> Donger Missiles ON! 0.9c loaded")
end

function OnTick()
	Checks()
	ts:update()
	AutoIgniteKS()
	if HeimerConfig.magnet and IsKeyDown(GetKey("Z")) then
		MagneticQSpot()
	end
	--CheckDamages(ts.target)
	if IsKeyDown(GetKey("C")) or IsKeyDown(GetKey("X")) then
		moveToCursor()
	end
	if HeimerConfig.UseOrbwalk and (IsKeyDown(GetKey("T")) or IsKeyDown(32)) then
		if ts.target ~= nil then
			OrbWalking(ts.target)
		else
			moveToCursor()
		end
	end
	if ts.target ~= nil and HeimerConfig.W then
		ProdictW:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and HeimerConfig.E then
		ProdictE:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and HeimerConfig.DisCombo then
		CastDistanceCombo(ts.target)
	end
	if ts.target ~= nil and HeimerConfig.IntCombo then
		IntelligentCombo(ts.target)
	end
end

function MagneticQSpot()
	for i, turretspot in pairs(TurretSpots) do
		if GetDistance(mousePos, turretspot) <= 40 and QAble then
			CastSpell(_Q, turretspot.x, turretspot.z)
			return
		end
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
	if QAble then
		DrawCircle(myHero.x, myHero.y, myHero.z, RangeQ, 0xFFFFFF)
	end
	if HeimerConfig.Dragon and gameState.map.shortName == "summonerRift" then
		DrawCircle(10117.65 , -61.54, 4804.69, 40, 0xFFFFFF) --Top One
		DrawCircle(10330.71 , -62.09, 4567.51, 40, 0xFFFFFF) --Mid One
		DrawCircle(10295 , -61.17, 4330.39, 40, 0xFFFFFF) --Bottom One??
		--DrawCircle(10254.695312, -60.704513, 4303.810546, 40, 0xFFFFFF) --Could work as bottom one

		DrawCircle(9595, -59.20, 5102.39, 40, 0x32cd32)
		DrawCircle(9532, -58.07, 5125.13, 40, 0x32cd32)
		DrawCircle(9272, -58.45, 5011.17, 40, 0x32cd32)
	end
	-- for i=1, heroManager.iCount do
        -- local enemydraw = heroManager:GetHero(i)
		-- if ValidTarget(enemydraw) then
			--DRAWKILLABLE AND SO ON
	-- end
end 

-- function CheckDamages(Target)
	-- if ValidTarget(Target) then
		-- local AADMG = getDmg("AD",Target,myHero)
		-- local wDMG = getDmg("W",Target,myHero)
		-- local eDMG = getDmg("E",Target,myHero)
		-- local ignDMG = getDmg("IGNITE",Target,myHero)
		-- local ActualAP = myHero.ap
		-- local qDMG = (7+7*myHero:GetSpellData(_Q).level+0.15*ActualAP)*1.75*2 -- Estimated PS
		-- local rqDMG = (70+20*myHero:GetSpellData(_R).level+0.33*ActualAP)*1.05*3 -- Per Second at least
		-- local rwDMG = 432+216*myHero:GetSpellData(_R).level+2.16*ActualAP
		-- local reDMG = 100+50*myHero:GetSpellData(_R.level+0.6*ActualAP
		-- --local DFGDMG = (DFGSlot and getDmg("DFG",Target,myHero) or 0)
		
		-- ComboNoUlt = wDMG + eDMG + ignDMG + AADMG
		-- ComboWUlt = rwDMG + eDMG + ignDMG + AADMG
		-- ComboQUlt = rqDMG + eDMG + wDMG + ignDMG + AADMG
		-- ComboWUltTurret = rwDMG + qDMG + eDMG + ignDMG + AADMG
	-- end
-- end

function Checks()
	QAble = (myHero:CanUseSpell(_Q) == READY)
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_R) == READY)
	if IgniteSlot ~= nil then IgniteAble = (myHero:CanUseSpell(IgniteSlot) == READY) end
	
	QMana = myHero:GetSpellData(_Q).mana
	WMana = myHero:GetSpellData(_W).mana
	EMana = myHero:GetSpellData(_E).mana
	RMana = myHero:GetSpellData(_R).mana
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

--Based on Manciuzz Orbwalker http://pastebin.com/jufCeE0e

function OrbWalking(Target)
	--if GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
		if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
			myHero:Attack(Target)
		elseif heroCanMove() then
			moveToCursor()
		end
--	elseif GetDistance(Target) >= myHero.range + GetDistance(myHero.minBBox) or Target == nil then moveToCursor()
	--end
end

function TimeToAttack()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function moveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		myHero:MoveTo(moveToPos.x, moveToPos.z)
	end	
end

function OnProcessSpell(object,spell)
	if object == myHero then
		if spell.name:lower():find("attack") then
			lastAttack = GetTickCount() - GetLatency()/2
			lastWindUpTime = spell.windUpTime*1000
			lastAttackCD = spell.animationTime*1000
		end
	end
end

function OnAnimation(unit,animationName)
        if unit.isMe and lastAnimation ~= animationName then lastAnimation = animationName end
end

function OnGainBuff(unit, buff)
	if unit == myHero and buff.name == "HeimerdingerR" then
		RangeE = RangeRE
		WidthE = 140
		ProdictE = Prodict:AddProdictionObject(_E, RangeE, 1000, 0.1, WidthE, myHero, CastE)
	end
	if buff.name == "heimerdingerespell" then
		UnitSlowed = true
	end
end

function OnLoseBuff(unit, buff)
	if unit == myHero and buff.name == "HeimerdingerR" then
		RangeE = 925
		WidthE = 70
		ProdictE = Prodict:AddProdictionObject(_E, RangeE, 1000, 0.1, WidthE, myHero, CastE)
	end
	if buff.name == "heimerdingerespell" then
		UnitSlowed = false
	end
end

--[[Buff INFO:
"Taunt" Turret attack
"HeimerdingerR" Pop-Up Ult
"heimerdingerespell" Heimer E Slow (+Stun?)
]]