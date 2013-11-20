--[[ Bot-Laf the Viking by BotHappy
Some ideas: http://pastebin.com/yZAHuKWr

v0.1 - Initial release (WIP)
v0.2 - Added items + Combo
v0.5 - Tons of Fixes, Combo, KS with E, AutoIgnite, Farm with E + AA
v0.6 - Added Q Farming, Q and Q+E KS, improved Combo
v0.7 - Autotake Axe
v0.7a - Improved KS
v0.8 - Added Orbwalking at combo
v0.8a - Move to Mouse option added
v0.8b - Fixed KSq, AutoR
v0.8c - Fixed UseR at Dominion (WIP)
v1.0 - Added Kill draws + updated prediction + fixes]]

--[[TODO
* Improve Combo draws
* Add time to kill
* Improve R logic
* Add Entropy to Combo
]]

require "Prodiction"

if myHero.charName ~= "Olaf" then return end

if not VIP_USER then
	return
end

------------------------------------------------------
--					Basic Functions					--
------------------------------------------------------

function OnLoad()
	Variables()
	CheckIgnite()
	Menu()
	
	PrintChat(">> Bot-Laf the Viking 1.0 loaded!")
end

function OnTick()
	Checks()
	ts:update()
	AutoIgniteKS()
	
	if OlafConfig.UseR then UseSkillR() end
	if IsKeyDown(HKQ) then	MoveToCursor() end
	
	if OlafConfig.KSe then	KSwithE()	end
	if OlafConfig.KSq then	KSwithQ()	end
	
	if ValidTarget(ts.target) and OlafConfig.Q then
		CastQ(ts.target)
	end
	
	if ValidTarget(ts.target) and OlafConfig.Combo then
		ComboCast(ts.target)
	end
	
	if OlafConfig.UseOrbwalk and IsKeyDown(HKCombo) then
		if ValidTarget(ts.target) then
			OrbWalking(ts.target)
		else
			MoveToCursor()
		end
	end
	
	if Axe ~= nil and OlafConfig.AutoAxe and not QAble and GetDistance(myHero, Axe) <= 500 then
		myHero:MoveTo(Axe.x, Axe.z)
	end
	
	if OlafConfig.Farm then
		if IsKeyDown(HKFarm) and GetTickCount() > NextTick then
			MoveToCursor()
		end
		AutoFarm()
	end
end

function OnDraw()
	if OlafConfig.Draws then
		if ValidTarget(ts.target) then
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
	if OlafConfig.DrawKill then KillDraws() end
end

------------------------------------------------------
--					Aux Functions					--
------------------------------------------------------

function CheckIgnite()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then IgniteSlot = SUMMONER_1
        elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then IgniteSlot = SUMMONER_2
    end
end

function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function Variables()
	if GetGame().map.index == 8 then
		Dominion = true
	else
		Dominion = false
	end
	
	qRange = 1000 -- Q range
	eRange = 325 -- E range

	Prodict = ProdictManager.GetInstance()

	NextTick = 0
	IgniteSlot = nil

	lastAnimation = nil
	lastAttack = 0
	lastAttackCD = 0
	lastWindUpTime = 0

	Axe = nil

	units = {}

	items = -- With entropy
	{
		BRK = {id=3153, range = 500, reqTarget = true, slot = nil },
		ETP = {id=3184, range = 350, reqTarget = true, slot = nil },
		BWC = {id=3144, range = 400, reqTarget = true, slot = nil },
		DFG = {id=3128, range = 750, reqTarget = true, slot = nil },
		HGB = {id=3146, range = 400, reqTarget = true, slot = nil },
		RSH = {id=3074, range = 350, reqTarget = false, slot = nil},
		STD = {id=3131, range = 350, reqTarget = false, slot = nil},
		TMT = {id=3077, range = 350, reqTarget = false, slot = nil},
		YGB = {id=3142, range = 350, reqTarget = false, slot = nil}
	}
	
	TrinitySlot, SheenSlot, BidgCutSlot, BotrkSlot, YoumuSlot, HydraSlot, EntropySlot = nil, nil, nil, nil, nil, nil, nil
	qDmg, eDmg, AADmg, IgniteDmg = 0,0,0,0
	Combo1, Combo2, Combo3, Combo4 = 0,0,0,0
	
	ts = TargetSelector(TARGET_LESS_CAST, 1200, DAMAGE_PHYSICAL)
	ts.name = "Olaf"
	
	--old one: ProdictQ = Prodict:AddProdictionObject(_Q, qRange, 1600, 0.3, 75, myHero, CastQ)
	ProdictQ = Prodict:AddProdictionObject(_Q, qRange, 1600, 0.250, 75)
	
	HKQ = string.byte("X")
	HKCombo = string.byte("T")
	HKFarm = string.byte("C")
	
	CapturingDom = false
end

function Menu()
	OlafConfig = scriptConfig("Olaf Options", "OLAF CONFIG1.0")

	OlafConfig:addParam("sep", "----- [ General Settings ] -----", SCRIPT_PARAM_INFO, "")
	OlafConfig:addParam("Q", "Cast Q", SCRIPT_PARAM_ONKEYDOWN, false, HKQ)
	OlafConfig:addParam("KSq", "KS with Q", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("KSe", "KS with E", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("AutoAxe", "AutoCatch Axe", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("UseR", "Auto use R when CC'd", SCRIPT_PARAM_ONOFF, false) 	
	
	OlafConfig:addParam("sep", "----- [ Combo Settings ] -----", SCRIPT_PARAM_INFO, "")	
	
	OlafConfig:addParam("Combo", "Cast Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKCombo)
	OlafConfig:addParam("NoQ", "No Q at Combo", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("NoW", "No W at Combo", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("NoE", "No E at Combo", SCRIPT_PARAM_ONOFF, false)
	OlafConfig:addParam("UseOrbwalk", "Use Orbwalk", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("AxeCombo", "AutoCatch Axe at combo", SCRIPT_PARAM_ONOFF, true)

	OlafConfig:addParam("sep", "----- [ Other Settings ] -----", SCRIPT_PARAM_INFO, "")
	OlafConfig:addParam("Farm", "AutoFarm with E + AA", SCRIPT_PARAM_ONKEYDOWN, false, HKFarm)
	OlafConfig:addParam("FarmQ", "Add Q to AutoFarm", SCRIPT_PARAM_ONOFF, false)	
	OlafConfig:addParam("IgniteKS", "Auto Ignite KS", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("Draws", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	OlafConfig:addParam("DrawKill", "Draw Kill Text", SCRIPT_PARAM_ONOFF, true)

	OlafConfig:permaShow("Q")
	OlafConfig:permaShow("Combo")
	OlafConfig:permaShow("UseR")
	OlafConfig:permaShow("Farm")
	OlafConfig:addTS(ts)
	
end

function Checks()
	QAble = (myHero:CanUseSpell(_Q) == READY)
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_R) == READY)
	
	IgniteAble = (IgniteSlot ~= nil and myHero:CanUseSpell(IgniteSlot) == READY)
	
	TrinitySlot = GetInventorySlotItem(3078)
	SheenSlot = GetInventorySlotItem(3057)
	BidgCutSlot = GetInventorySlotItem(3144)
	BotrkSlot = GetInventorySlotItem(3153)
	YoumuSlot = GetInventorySlotItem(3142)
	TiamatSlot = GetInventorySlotItem(3077)
	HydraSlot = GetInventorySlotItem(3074)
	EntropySlot = GetInventorySlotItem(3184)
	
	TrinityAble = (TrinitySlot ~= nil and myHero:CanUseSpell(TrinitySlot) == READY)
	SheenAble = (SheenSlot ~= nil and myHero:CanUseSpell(SheenSlot) == READY)
	BidgCutAble = (BidgCutSlot ~= nil and myHero:CanUseSpell(BidgCutSlot) == READY)
	BotrkAble = (BotrkSlot ~= nil and myHero:CanUseSpell(BotrkSlot) == READY)
	YoumuAble = (YoumuSlot ~= nil and myHero:CanUseSpell(YoumuSlot) == READY)
	TiamatAble = (TiamatSlot ~= nil and myHero:CanUseSpell(TiamatSlot) == READY)
	HydraAble = (HydraSlot ~= nil and myHero:CanUseSpell(HydraSlot) == READY)
	EntropyAble = (EntropySlot ~= nil and myHero:CanUseSpell(EntropySlot) == READY)
	GetDamages()
end

------------------------------------------------------
--					Damages & Calcs					--
------------------------------------------------------

-- function TimeToKill()

function GetDamages()
	for i = 1, heroManager.iCount do
		EnemyDraws = heroManager:getHero(i)
		qDmg = getDmg("Q", EnemyDraws, myHero)
		eDmg = getDmg("E", EnemyDraws, myHero)
		AADmg = getDmg("AD", EnemyDraws, myHero)
		IgniteDmg = getDmg("IGNITE", EnemyDraws, myHero)
		SheenDmg = getDmg("SHEEN", EnemyDraws, myHero)
		BidgCutDmg = getDmg("BWC", EnemyDraws, myHero)
		TrinityDmg = getDmg("TRINITY", EnemyDraws, myHero)
		BotrkDmg = getDmg("RUINEDKING", EnemyDraws, myHero)
		HydraDmg = AADmg*0.6
		TiamatDmg = AADmg*0.6
		-- Entropy?
	end
	--Combos
	
	Combo1 = qDmg + eDmg + AADmg + IgniteDmg
	Combo2 = qDmg*2 + eDmg + AADmg*2 + SheenDmg + TrinityDmg + BidgCutDmg + BotrkDmg + HydraDmg + TiamatDmg + IgniteDmg
	Combo3 = qDmg*2 + eDmg*2 + AADmg*4 + IgniteDmg + 2*SheenDmg + 2*TrinityDmg + BidgCutDmg + BotrkDmg + HydraDmg + TiamatDmg + IgniteDmg
	Combo4 = qDmg*3 + eDmg*3 + AADmg*6 + IgniteDmg + 3*SheenDmg + 3*TrinityDmg + BidgCutDmg + BotrkDmg + HydraDmg + TiamatDmg + IgniteDmg
end

function KillDraws()
	for i = 1, heroManager.iCount do
		local EnemyDraws = heroManager:getHero(i)
		if ValidTarget(EnemyDraws) then
			if EnemyDraws.health < (qDmg or eDmg) then
				PrintFloatText(EnemyDraws, 0, "Almost dead!")
			elseif EnemyDraws.health < IgniteDmg then
				PrintFloatText(EnemyDraws, 0, "Ignite!")
			elseif EnemyDraws.health < Combo1 then
				PrintFloatText(EnemyDraws, 0, "Easy Kill!")
			elseif EnemyDraws.health < Combo2 then
				PrintFloatText(EnemyDraws, 0, "Medium Difficulty")
			elseif EnemyDraws.health < Combo3 then
				PrintFloatText(EnemyDraws, 0, "Decent Difficulty")
			elseif EnemyDraws.health < Combo4 then
				PrintFloatText(EnemyDraws, 0, "Hard to kill")
			elseif EnemyDraws.health > Combo4 then
				PrintFloatText(EnemyDraws, 0, "Almost Impossible")
			end
		end
	end
end

------------------------------------------------------
--					Combo Functions					--
------------------------------------------------------

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
		if QAble and ValidTarget(Enemy, 1100, true) and Enemy.health < (getDmg("Q",Enemy,myHero) - 35) then
			CastQ(Enemy)
			--Old One: Prodict:EnableTarget(Enemy, true)
		end
    end
end

function CastQ(unit)
	if GetDistance(unit) - getHitBoxRadius(unit)/2 < qRange and ValidTarget(unit) then
		QPos = ProdictQ:GetPrediction(unit)
		CastSpell(_Q, QPos.x, QPos.z)
	end
end

function UseSkillR()
	if not myHero.canMove or myHero.isTaunted or myHero.isCharmed or myHero.isFeared then
		if not Dominion then
			CastSpell(_R)
		elseif Dominion and not CapturingDom then
			if not GetTowerNear() then
				CastSpell(_R)
			end
		end
	end
end

function ComboCast(Target) 
	UseItems(Target)
	if QAble and not OlafConfig.NoQ then
		CastQ(Target)
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
	if Axe ~= nil and not QAble and OlafConfig.AxeCombo and GetDistance(myHero, Axe) <= 400 then
		myHero:MoveTo(Axe.x, Axe.z)
	end
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
	if OlafConfig.IgniteKS and IgniteAble then
		IgniteDMG = 50 + (20 * myHero.level)
		for _, enemy in pairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 600) and enemy.health <= IgniteDMG then
				CastSpell(IgniteSlot, enemy)
			end
		end
	end
end

------------------------------------------------------
--					Other Functions					--
------------------------------------------------------

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

function GetTowerNear()
	for i = 0, objManager.maxObjects do
		local obj = objManager:getObject(i)
		if obj ~= nil and obj.name == "OdinNeutralGuardian" and obj.team ~= myHero.team and GetDistance(obj, myHero) <600 then
			return true
		end
	end
end

------------------------------------------------------
--					Orbwalk Functions				--
------------------------------------------------------
--Based on Manciuzz Orbwalker http://pastebin.com/jufCeE0e

function OrbWalking(Target)
	if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
		myHero:Attack(Target)
	elseif HeroCanMove() then
		MoveToCursor()
	end
end

function TimeToAttack()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastAttackCD)
end

function HeroCanMove()
	return (GetTickCount() + GetLatency()/2 > lastAttack + lastWindUpTime + 20)
end

function MoveToCursor()
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

------------------------------------------------------
--					Extra Callbacks					--
------------------------------------------------------

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

function OnSendPacket(packet)
	if tostring(packet.header) == "57" then 
		CapturingDom = true
		NextTick = GetTickCount() + 2000
	elseif NextTick < GetTickCount() then
		CapturingDom = false
	end
end