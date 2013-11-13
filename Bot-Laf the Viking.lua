--[[ Bot-Laf the Viking by BotHappy
Some ideas: http://pastebin.com/yZAHuKWr

v0.1 - Initial release (WIP)
v0.2 - Added items + Combo
v0.5 - Tons of Fixes, Combo, KS with E, AutoIgnite, Farm with E + AA
v0.6 - Added Q Farming, Q and Q+E KS, improved Combo
v0.7 - Autotake Axe
v0.7a - Improved KS
v0.8 - Added Orbwalking at combo]]

--[[TODO
 * Better Draws
 * Fix UseR at Dominion (Packets)
]]

require "Prodiction"

if myHero.charName ~= "Olaf" then return end

if not VIP_USER then
	return
end

local qRange = 1000 -- Q range
local eRange = 325 -- E range

local Prodict = ProdictManager.GetInstance()
local ProdictQ

local AlreadyAttacked = false

local NextTick = 0
local IgniteSlot = nil

local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local lastWindUpTime = 0

local Axe = nil

local units = {}

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

function CastQ(unit, pos, spell)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < qRange then
		CastSpell(_Q, pos.x, pos.z)
	end
end

function UseR()
	if not myHero.canMove or myHero.isTaunted or myHero.isCharmed or myHero.isFeared then
		CastSpell(_R)
	end
end

function OnLoad()

	CheckIgnite()

	ts = TargetSelector(TARGET_LESS_CAST, 1200, DAMAGE_PHYSICAL)
	OlafConfig = scriptConfig("Olaf Options", "OLAF CONFIG0.8")
	local HKQ = string.byte("X")
	local HKCombo = string.byte("T")
	local HKFarm = string.byte("C")
	
	OlafConfig:addParam("Q", "Cast Q", SCRIPT_PARAM_ONKEYDOWN, false, HKQ)
	OlafConfig:addParam("Combo", "Cast Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKCombo)
	OlafConfig:addParam("NoQ", "No Q at Combo", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("NoW", "No W at Combo", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("NoE", "No E at Combo", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("KSq", "KS with Q", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("KSe", "KS with E", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("AxeCombo", "AutoCatch Axe at combo", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("AutoAxe", "AutoCatch Axe", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("UseR", "Auto use R when CC'd", SCRIPT_PARAM_ONOFF, true) --fix dominion.
	OlafConfig:addParam("Ignite", "Auto Ignite KS", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("Farm", "AutoFarm with E + AA", SCRIPT_PARAM_ONKEYDOWN, false, HKFarm)
	OlafConfig:addParam("FarmQ", "Add Q to AutoFarm", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("draws", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("UseOrbwalk", "Use Orbwalk", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:permaShow("Q")
	OlafConfig:permaShow("Combo")
	OlafConfig:permaShow("UseR")
	OlafConfig:permaShow("Farm")
	OlafConfig:addTS(ts)
	
	ts.name = "Olaf"
	
	ProdictQ = Prodict:AddProdictionObject(_Q, qRange, 1600, 0.3, 75, myHero, CastQ)
	
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictQ:CanNotMissMode(true, hero)
		end
	end
	
	PrintChat(">> Bot-Laf the Viking 0.8 loaded")
end

function KSwithE()
    for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if EAble and ValidTarget(Enemy, 400, true) and Enemy.health < getDmg("E",Enemy,myHero) then
			CastSpell(_E, Enemy)
		end
    end
end

function KSwithQ()
    for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if QAble and ValidTarget(Enemy, 1100, true) and Enemy.health < getDmg("Q",Enemy,myHero) - 40 then
			ProdictQ:EnableTarget(Target, true)
		end
    end
end

function OnTick()
	Checks()
	ts:update()
	AutoIgniteKS()
	UseR()	
	if IsKeyDown(GetKey("X")) then
		moveToCursor()
	end
	if OlafConfig.KSe then
		KSwithE()
	end
	if OlafConfig.KSq then
		KSwithQ()
	end
	
	if ts.target ~= nil and OlafConfig.Q then
		ProdictQ:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and OlafConfig.Combo then
		ComboCast(ts.target)
	end
	if OlafConfig.UseOrbwalk and IsKeyDown(GetKey("T")) then
		if ts.target ~= nil then
			OrbWalking(ts.target)
		else
			moveToCursor()
		end
	end
	if Axe ~= nil and OlafConfig.AutoAxe and not QAble and GetDistance(myHero, Axe) <= 500 then
		myHero:MoveTo(Axe.x, Axe.z)
	end
	if OlafConfig.Farm then
		if IsKeyDown(GetKey("C")) and GetTickCount() > NextTick then
			moveToCursor()
		end
	AutoFarm()
	end
end

function OnDraw()
	if OlafConfig.draws then
		if ts.target ~= nil then
			local dist = getHitBoxRadius(ts.target)/2
		
			if GetDistance(ts.target) - dist < qRange then
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
			end
			if GetDistance(ts.target) - dist < eRange then
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x5F9F9F)
			end
		end
	
		if QAble then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x7F006E)
		end
		if EAble then
			DrawCircle(myHero.x, myHero.y, myHero.z, eRange, 0x5F9F9F)
		end
	end
end

function ComboCast(Target) 
	UseItems(Target)
	if QAble and not OlafConfig.NoQ then
		ProdictQ:EnableTarget(Target, true)
	end
	if WAble and not OlafConfig.NoW then
		if GetDistance(Target) <= 250 then
			CastSpell(_W) 
		end
	end
	if EAble and not OlafConfig.NoE then
		if GetDistance(Target) <= eRange then
			CastSpell(_E, Target)
		end
	end
	if Axe ~= nil and not QAble and OlafConfig.AutoAxe and GetDistance(myHero, Axe) <= 400 then
		myHero:MoveTo(Axe.x, Axe.z)
	end
end

function Checks()
	QAble = (myHero:CanUseSpell(_Q) == READY)
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
	if OlafConfig.Ignite and IgniteAble then
		IgniteDMG = 50 + (20 * myHero.level)
		for _, enemy in pairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 600) and enemy.health <= IgniteDMG then
				CastSpell(IgniteSlot, enemy)
			end
		end
	end
end

function AutoFarm()
	for i = 1, objManager.maxObjects, 1 do
		local object = objManager:getObject(i)
		if object ~= nil and object.team ~= myHero.team and object.type == "obj_AI_Minion" and string.find(object.charName,"Minion") then
			if not object.dead and GetDistance(object,myHero) <= (myHero.range + 300) then --Additional Range
				if units[object.name] == nil then
					units[object.name] = { obj = object }
				end
			else
				units[object.name] = nil
			end
		end
	end
	for i, unit in pairs(units) do
		if unit.obj == nil or unit.obj.dead or GetDistance(myHero,unit.obj) > (myHero.range + 300) then --Additional Range
			units[i] = nil
		elseif unit.obj.health <= getDmg("AD",unit.obj,myHero) and GetDistance(unit.obj) <= (myHero.range + 100) then
			myHero:Attack(unit.obj)
			NextTick = GetTickCount() + 300
			return
		elseif unit.obj.health <= getDmg("E",unit.obj,myHero) and EAble then
			CastSpell(_E,unit.obj)
			return
		elseif unit.obj.health <= getDmg("Q",unit.obj,myHero) and QAble and OlafConfig.FarmQ then
			CastSpell(_Q,unit.obj.x,unit.obj.z)
			return
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

function OnCreateObj(obj) 
	if obj and GetDistance(obj) < 1500 and not obj.name:find("Odin") then
		if obj.name:find("olaf_axe_totem") then
			Axe = obj
		end
	end
end 

function OnDeleteObj(obj) 
	if obj and GetDistance(obj) < 1500 and not obj.name:find("Odin") then
		 if obj.name:find("olaf_axe_totem") then 
		 	Axe = nil
		 end
	end
end