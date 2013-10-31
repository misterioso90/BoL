--[[AutoSmite TT Beta by BotHappy
Based on eXtragoZ "AutoSmite"
Object TT Info: http://pastebin.com/zhDfUzPg

0.1 - First Release (Smite test)
0.2 - Nunu Q added
0.2a - Fixed some damages
0.2b - Fixed Draws
0.3 - Added NoSmite Nunu
0.3a - Improved Nunu]]

--[[TO-DO

- Add Trundle Smite with low health (Passive) (ON WORK)
- Add Chogath R

]]

gameState = GetGame()
if gameState.map.shortName ~= "twistedTreeline" then return end

-- Variables

local range = 750       -- Range of smite 625+model. Usually 750.
local turnoff = false   --true/false

local SmiteSlot = nil
local SmiteDamage, qDamage, MixDamage = 0, 0, 0
local CanUseSmite, CanUseQ = false, false
local SmiteIsOn = false

local Vilemaw
local WolfL, GolemL, WraighL -- Western Camps
local WolfR, GolemR, WraighR -- Eastern Camps


--local BMinion, CMinion, WMinion, MMinion

-- Code
function CheckSmite()
	if myHero:GetSpellData(SUMMONER_1).name:find("Smite") then SmiteSlot = SUMMONER_1
		elseif myHero:GetSpellData(SUMMONER_2).name:find("Smite") then SmiteSlot = SUMMONER_2 end
end

function Menu()
    SmiteTT = scriptConfig("AutoSmite TT 0.3a", "autosmiteTT")
    SmiteTT:addParam("switcher", "Switcher Hotkey", SCRIPT_PARAM_ONKEYTOGGLE, (SmiteSlot ~= nil), 78)
    SmiteTT:addParam("hold", "Hold Hotkey (CTRL)", SCRIPT_PARAM_ONKEYDOWN, false, 17)
    SmiteTT:addParam("active", "AutoSmite", SCRIPT_PARAM_INFO, false)
	SmiteTT:permaShow("active")
	
	if myHero.charName == "Nunu" then
		SmiteTT:addParam("nosmite", "NUNU: Desactivate Smite", SCRIPT_PARAM_ONOFF, false)
		SmiteTT:addParam("nomix", "NUNU: Desactivate Mixed Damage", SCRIPT_PARAM_ONOFF, false)
		SmiteTT:permaShow("nosmite")
		SmiteTT:permaShow("nomix")
	end
	
--[[	if myHero.charName == "Trundle" then
		SmiteTT:addParam("lasthope", "TRUNDLE: Last Hope Smite", SCRIPT_PARAM_ONOFF, false)
		SmiteTT:permaShow("lasthope")
	end]]
	
	SmiteTT:addParam("vilemaw", "AutoSmite Vilemaw", SCRIPT_PARAM_ONOFF, true)
    SmiteTT:addParam("drawrange", "Draw Smite Range", SCRIPT_PARAM_ONOFF, true)
    SmiteTT:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
    SmiteTT:addParam("drawtext", "Draw Text", SCRIPT_PARAM_ONOFF, true)
end

function OnLoad()
    CheckSmite()
	if myHero.charName == "Nunu" or SmiteSlot or not turnoff then
		Menu()
        ASLoadMinions()
        SmiteIsOn = true --Everything going well
        PrintChat(" >> AutoSmite TT 0.3a by BotHappy")
    end
end

function Damages()
	SmiteDamage = 460+30*myHero.level
	qDamage = 500+125*(myHero:GetSpellData(_Q).level-1)
	MixDamage = qDamage+SmiteDamage
end

function OnTick()
	if not SmiteIsOn then return end
	
	CheckDeadMonsters()

	SmiteTT.active = SmiteTT.hold or SmiteTT.switcher 

    if not SmiteTT.active and SmiteTT.vilemaw and Vilemaw ~= nil then 
		SmiteTT.active = true
	end
		
	CanUseQ = (myHero.charName == "Nunu" and myHero:CanUseSpell(_Q) == READY)
	Damages()

	if SmiteSlot ~= nil then CanUseSmite = (myHero:CanUseSpell(SmiteSlot) == READY) end
  
	if SmiteTT.active and not myHero.dead and (CanUseSmite or CanUseQ) then
		if Vilemaw ~= nil then TryToKillObjetive(Vilemaw) end
		if GolemL ~= nil then TryToKillObjetive(GolemL) end
		if WolfL ~= nil then TryToKillObjetive(WolfL) end
		if WraighL ~= nil then TryToKillObjetive(WraighL) end
		if GolemR ~= nil then TryToKillObjetive(GolemR) end
		if WolfR ~= nil then TryToKillObjetive(WolfR) end
		if WraighR ~= nil then TryToKillObjetive(WraighR) end
	end
	
--[[	if myHero.charName == "Trundle" then
		LifeSaver()
	
		if SmiteTT.active and not myHero.dead and SmiteTT.lasthope then
			if BMinion ~= nil then if CanUseSmite and BMinion.health <= SmiteDamage then CastSpell(SmiteSlot, object) end end
			if CMinion ~= nil then if CanUseSmite and CMinion.health <= SmiteDamage then CastSpell(SmiteSlot, object) end end
			if WMinion ~= nil then if CanUseSmite and WMinion.health <= SmiteDamage then CastSpell(SmiteSlot, object) end end
			if MMinion ~= nil then if CanUseSmite and MMinion.health <= SmiteDamage then CastSpell(SmiteSlot, object) end end
		end
	end]]
end

function TryToKillObjetive(object)
    if object ~= nil and not object.dead and object.visible and object.x ~= nil then
        local DistanceMonster = GetDistance(object)
        if CanUseQ and DistanceMonster <=125+200 then
			if object.health <= qDamage then
			CastSpell(_Q, object)
			elseif CanUseSmite and not SmiteTT.nosmite and DistanceMonster <= range and object.health <= SmiteDamage then
				CastSpell(SmiteSlot, object)
				elseif not SmiteTT.nomix and CanUseSmite and object.health <= MixDamage then
				if DistanceMonster <=125+200 then
					CastSpell(_Q, object)
					CastSpell(SmiteSlot, object)
				end
			end
        end
    end
end

function OnDraw()
    if not SmiteIsOn then return end
    CheckDeadMonsters()
    if SmiteSlot ~= nil and SmiteTT.active and SmiteTT.drawrange and not myHero.dead then
        DrawCircle(myHero.x, myHero.y, myHero.z, range, 0x992D3D)
    end

	if not myHero.dead and (SmiteTT.drawtext or SmiteTT.drawcircles) then
        if Vilemaw ~= nil then MonsterDraw(Vilemaw) end
        if GolemL ~= nil then MonsterDraw(GolemL) end
        if WolfL ~= nil then MonsterDraw(WolfL) end
        if WraighL ~= nil then MonsterDraw(WraighL) end
		if GolemR ~= nil then MonsterDraw(GolemR) end
        if WolfR ~= nil then MonsterDraw(WolfR) end
        if WraighR ~= nil then MonsterDraw(WraighR) end
    end
end

function MonsterDraw(object)
    if object ~= nil and not object.dead and object.visible and object.x ~= nil then
        local DistanceMonster = GetDistance(object)
        if SmiteTT.active and SmiteTT.drawcircles and CanUseSmite and DistanceMonster <= range then
            local healthradius = object.health*100/object.maxHealth
            DrawCircle(object.x, object.y, object.z, healthradius+100, 0x00FF00)
            if CanUseSmite and not SmiteTT.nosmite then
                local smitehealthradius = SmiteDamage*100/object.maxHealth
                DrawCircle(object.x, object.y, object.z, smitehealthradius+100, 0x00FFFF)
            end
			if CanUseQ and CanUseSmite and not Smite.nomix then
                local Qsmitehealthradius = MixDamage*100/object.maxHealth
                DrawCircle(object.x, object.y, object.z, Qsmitehealthradius+100, 0x00FFFF)
			end
            if CanUseQ then
                local Qhealthradius = qDamage*100/object.maxHealth
                DrawCircle(object.x, object.y, object.z, Qhealthradius+100, 0x00FFFF)
            end
        end
        if SmiteTT.drawtext and DistanceMonster <= range*2 then
            local wtsobject = WorldToScreen(D3DXVECTOR3(object.x,object.y,object.z))
            local objectX, objectY = wtsobject.x, wtsobject.y
            local onScreen = OnScreen(wtsobject.x, wtsobject.y)
			
            if onScreen then
                local statusdmgS = SmiteDamage*100/object.health
                local statuscolorS = (CanUseSmite and 0xFF00FF00 or 0xFFFF0000)
                local textsizeS = statusdmgS < 100 and math.floor((statusdmgS/100)^2*20+8) or 28
                textsizeS = textsizeS > 16 and textsizeS or 16
                DrawText(string.format("%.1f", statusdmgS).."% - Smite", textsizeS, objectX-40, objectY+38, statuscolorS)
				if myHero.charName == "Nunu" and myHero:GetSpellData(_Q).level>0 then
                    local statusdmgQ = qDamage*100/object.health
                    local statuscolorQ = (CanUseQ and 0xFF00FF00 or 0xFFFF0000)
                    local textsizeQ = statusdmgQ < 100 and math.floor((statusdmgQ/100)^2*20+8) or 28
                    textsizeQ = textsizeQ > 16 and textsizeQ or 16
                    DrawText(string.format("%.1f", statusdmgQ).."% - Q", textsizeQ, objectX-40, objectY+56, statuscolorQ)
                    if SmiteSlot ~= nil then
                        local statusdmgSQ = MixDamage*100/object.health
                        local statuscolorSQ = ((CanUseSmite and CanUseQ) and 0xFF00FF00 or 0xFFFF0000)
                        local textsizeSQ = statusdmgSQ < 100 and math.floor((statusdmgSQ/100)^2*20+8) or 28
                        textsizeSQ = textsizeSQ > 16 and textsizeSQ or 16
                        DrawText(string.format("%.1f", statusdmgSQ).."% - Smite+Q", textsizeSQ, objectX-40, objectY+74, statuscolorSQ)
					end
                end
            end
        end
    end
end

function OnCreateObj(obj)
    if not SmiteIsOn then return end
    if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
        if obj.name == "TT_Spiderboss8.1.1" then Vilemaw = obj
			elseif obj.name == "TT_NWolf3.1.1" then WolfL = obj
			elseif obj.name == "TT_NWraith1.1.1" then WraighL = obj
			elseif obj.name == "TT_NGolem2.1.1" then GolemL = obj  
			elseif obj.name == "TT_NWolf6.1.1" then WolfR = obj
			elseif obj.name == "TT_NWraith4.1.1" then WraighR = obj
			elseif obj.name == "TT_NGolem5.1.1" then GolemR = obj
		end
    end
end

function OnDeleteObj(obj)
    if not SmiteIsOn then return end
    if obj ~= nil and obj.name ~= nil then
        if obj.name == "TT_Spiderboss8.1.1" then Vilemaw = nil
			elseif obj.name == "TT_NWolf3.1.1" then WolfL = nil
			elseif obj.name == "TT_NWraith1.1.1" then WraighL = nil
			elseif obj.name == "TT_NGolem2.1.1" then GolemL = nil
			elseif obj.name == "TT_NWolf6.1.1" then WolfR = nil
			elseif obj.name == "TT_NWraith4.1.1" then WraighR = nil
			elseif obj.name == "TT_NGolem5.1.1" then GolemR = nil
		end
    end
end

function CheckDeadMonsters()
    if Vilemaw ~= nil then if not Vilemaw.valid or Vilemaw.dead or Vilemaw.health <= 0 then Vilemaw = nil end end
    if WolfL ~= nil then if not WolfL.valid or WolfL.dead or WolfL.health <= 0 then WolfL = nil end end
    if WraighL ~= nil then if not WraighL.valid or WraighL.dead or WraighL.health <= 0 then WraighL = nil end end
    if GolemL ~= nil then if not GolemL.valid or GolemL.dead or GolemL.health <= 0 then GolemL = nil end end
    if WolfR ~= nil then if not WolfR.valid or WolfR.dead or WolfR.health <= 0 then WolfR = nil end end
    if WraighR ~= nil then if not WraighR.valid or WraighR.dead or WraighR.health <= 0 then WraighR = nil end end
    if GolemR ~= nil then if not GolemR.valid or GolemR.dead or GolemR.health <= 0 then GolemR = nil end end
end

function ASLoadMinions()
    for i = 1, objManager.maxObjects do
        local obj = objManager:getObject(i)
        if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
            if obj.name == "TT_Spiderboss8.1.1" then Vilemaw = obj
				elseif obj.name == "TT_NWolf3.1.1" then WolfL = obj
				elseif obj.name == "TT_NWraith1.1.1" then WraighL = obj
				elseif obj.name == "TT_NGolem2.1.1" then GolemL = obj
				elseif obj.name == "TT_NWolf6.1.1" then WolfR = obj
				elseif obj.name == "TT_NWraith4.1.1" then WraighR = obj
				elseif obj.name == "TT_NGolem5.1.1" then GolemR = obj
--				elseif obj.name == "_Minion_Basic" then BMinion = obj
--				elseif obj.name == "_Minion_Caster" then CMinion = obj
--				elseif obj.name == "_Minion_Wizard" then WMinion = obj
--				elseif obj.name == "_Minion_MechCannon" then MMinion = obj
			end
		end
    end
end

--[[function LifeSaver()
	for i = 1, objManager.maxObjects do
		local obj = objManager:getObject(i)
		if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
			if obj.name == "_Minion_Basic" then BMinion = obj
				elseif obj.name == "_Minion_Caster" then CMinion = obj
				elseif obj.name == "_Minion_Wizard" then WMinion = obj
				elseif obj.name == "_Minion_MechCannon" then MMinion = obj
			end
		end
	end
	
end]]