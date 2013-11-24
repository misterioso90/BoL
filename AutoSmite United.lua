--[[
	AutoSmite United 1.0
		by BotHappy
		Credits: eXtragoZ (Original AutoSmite)
		
		Features:
		- Hotkey for switching AutoSmite On/Off (default: N)
		- Hold-HotKey for using AutoSmite (default: CTRL)
		- Range indicator of Smite
		- Says the percentage of current life you will do to the monster using smite
		- Circles in the camp in the range of smite
		- Supports Nunu Q and Chogath R
		- AutoSmite Enable Option at Dragon, Nashor and Vilemaw
		- Fast jungleclearing Wolf/Wraith/SmallGolem camps
		- Added new camp (Preseason 4)
		
		Extra features:
		- Works also on Twisted Treeline
		- Trundle Autosaver: Try to save himself smiting a minion to recover some life (Passive)
		
1.0 : First release

]]

function Lifesaver()
	if myHero.charName ~= "Trundle" then return end
	enemyMinions:update()
	for i, minion in pairs(enemyMinions.objects) do
		if minion.health < SmiteDmg and myHero.health < (1/100)*SmiteUnited.lifesaver*myHero.maxHealth then
			CastSpell(SmiteSlot, minion)
		end
	end
end

function Variables()
	gameState = GetGame()
	if gameState.map.shortName == "twistedTreeline" then
		TTMAP = true
	else
		TTMAP = false
	end
	range = 800
	
	SmiteSlot = nil
	SmiteDmg, qDmg, MixDmg, rDmg, MixRDmg = 0, 0, 0, 0, 0
	SmiteIsOn = false
	
	if TTMAP then
		Vilemaw = nil
		WolfL, GolemL, WraithL = nil, nil, nil
		WolfR, GolemR, WraithR = nil, nil, nil
	else 
		Nashor, Dragon, Golem1, Golem2, Lizard1, Lizard2 = nil, nil, nil, nil, nil, nil
		Wolf1, Wolf2, Wraith1, Wraith2, BigWraith1, BigWraith2, SmallGolem1, SmallGolem2 = nil, nil, nil, nil, nil, nil, nil, nil
	end
	DragonRDY, VilemawRDY, NashorRDY = false, false, false
	enemyMinions = minionManager(MINION_ENEMY, range, player, MINION_SORT_HEALTH_ASC)
end

function CheckSmite()
	if myHero:GetSpellData(SUMMONER_1).name:find("Smite") then SmiteSlot = SUMMONER_1
		elseif myHero:GetSpellData(SUMMONER_2).name:find("Smite") then SmiteSlot = SUMMONER_2 end
end

function Menu()
	SmiteUnited = scriptConfig("AutoSmite United 1.0", "smiteunited")
	SmiteUnited:addParam("active", "AutoSmite", SCRIPT_PARAM_INFO, false)
	SmiteUnited:addParam("switcher", "Switcher Hotkey", SCRIPT_PARAM_ONKEYTOGGLE, (SmiteSlot ~= nil), 78)
    SmiteUnited:addParam("hold", "Hold Hotkey (CTRL)", SCRIPT_PARAM_ONKEYDOWN, false, 17)
	SmiteUnited:addParam("nosmite", "Desactivate Smite", SCRIPT_PARAM_ONOFF, false)
	if myHero.charName == "Nunu" then SmiteUnited:addParam("nomix", "NUNU: Desactivate Mix Dmg", SCRIPT_PARAM_ONOFF, false) end
	if myHero.charName == "Chogath" then SmiteUnited:addParam("nomixr", "CHOGATH: Desactivate Mix Dmg", SCRIPT_PARAM_ONOFF, false) end
	SmiteUnited:permaShow("nosmite")
	if myHero.charName == ("Nunu" or "Chogath") then SmiteUnited:addParam("jungleclear", "Activate Jungleclearing", SCRIPT_PARAM_ONOFF, true) end
	if myHero.charName == "Nunu" then SmiteUnited:permaShow("nomix") end
	if myHero.charName == "Chogath" then SmiteUnited:permaShow("nomixr") end
	if myHero.charName == "Trundle" then SmiteUnited:addParam("lifesaver", "TRUNDLE: Smite Minion when <X% life", SCRIPT_PARAM_SLICE, 15, 0, 100, 0) end
	if TTMAP then
		SmiteUnited:addParam("vilemaw", "AutoSmite Vilemaw", SCRIPT_PARAM_ONOFF, true)
	else
		SmiteUnited:addParam("nashor", "AutoSmite Nashor", SCRIPT_PARAM_ONOFF, true)
		SmiteUnited:addParam("dragon", "AutoSmite Dragon", SCRIPT_PARAM_ONOFF, true)
    end
	SmiteUnited:addParam("drawrange", "Draw Smite Range", SCRIPT_PARAM_ONOFF, true)
    SmiteUnited:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
    SmiteUnited:addParam("drawtext", "Draw Text", SCRIPT_PARAM_ONOFF, true)
	SmiteUnited:permaShow("active")
end

function OnLoad()
	Variables()
	CheckSmite()
	if myHero.charName == ("Nunu" or "Chogath" or "Trundle") or SmiteSlot then
		Menu()
		ASLoadMinions()
		SmiteIsOn = true
		PrintChat(" >> AutoSmite United v1.0 loaded!")
	end
end

function Checks()
	CanUseQ = (myHero.charName == "Nunu" and myHero:CanUseSpell(_Q) == READY)
	CanUseR = (myHero.charName == "Chogath" and myHero:CanUseSpell(_R) == READY)
	if SmiteSlot ~= nil then CanUseSmite = (myHero:CanUseSpell(SmiteSlot) == READY) end
end

function Damages()
	SmiteDmg = math.max(20*myHero.level+370,30*myHero.level+330,40*myHero.level+240,50*myHero.level+100)
	qDmg = 250+150*myHero:GetSpellData(_Q).level
	MixDmg = qDmg+SmiteDmg
	rDmg = 1000+.7*myHero.ap
	MixRDmg = rDmg+SmiteDmg
end

function OnTick()
	if not SmiteIsOn then return end
	Checks()
	Damages()
	CheckDeadMonsters()
	Lifesaver()
	
	SmiteUnited.active = SmiteUnited.hold or SmiteUnited.switcher
	
	if not SmiteUnited.active then
		if TTMAP and SmiteUnited.vilemaw and VilemawRDY then
			SmiteUnited.active = true
		elseif not TTMAP then
			if (SmiteUnited.nashor and NashorRDY) or (SmiteUnited.dragon and DragonRDY) then
				SmiteUnited.active = true
			end
		end
	end
	if SmiteUnited.active and not myHero.dead and (CanUseSmite or CanUseQ or CanUseR) then
		KillMonsters()
	end
end

function KillMonsters()
	if TTMAP then
		if Vilemaw ~= nil then TryToKillObjetive(Vilemaw) end
		if GolemL ~= nil then TryToKillObjetive(GolemL) end
		if WolfL ~= nil then TryToKillObjetive(WolfL) end
		if WraithL ~= nil then TryToKillObjetive(WraithL) end
		if GolemR ~= nil then TryToKillObjetive(GolemR) end
		if WolfR ~= nil then TryToKillObjetive(WolfR) end
		if WraithR ~= nil then TryToKillObjetive(WraithR) end
	else
		if Nashor ~= nil then TryToKillObjetive(Nashor) end
		if Dragon ~= nil then TryToKillObjetive(Dragon) end
		if Golem1 ~= nil then TryToKillObjetive(Golem1) end
		if Golem2 ~= nil then TryToKillObjetive(Golem2) end
		if Lizard1 ~= nil then TryToKillObjetive(Lizard1) end
		if Lizard2 ~= nil then TryToKillObjetive(Lizard2) end
		if SmiteUnited.jungleclear then
			if SmallGolem1 ~= nil then JungleClearing(SmallGolem1) end
			if SmallGolem2 ~= nil then JungleClearing(SmallGolem2) end
			if Wolf1 ~= nil then JungleClearing(Wolf1) end
			if Wolf2 ~= nil then JungleClearing(Wolf2) end
			if Wraith1 ~= nil then JungleClearing(Wraith1) end
			if Wraith2 ~= nil then JungleClearing(Wraith2) end
			if BigWraith1 ~= nil then JungleClearing(BigWraith1) end
			if BigWraith2 ~= nil then JungleClearing(BigWraith2) end
		end
	end
end

function JungleClearing(object)
	if ValidTarget(object) then
		local DistanceMonster = GetDistance(object)
		if myHero.charName == "Nunu" then
			if DistanceMonster <= 400 then
				if CanUseQ and object.health <= qDmg then
					CastSpell(_Q, object)
				end
			end
		elseif myHero.charName == "Chogath" then
			if DistanceMonster <= 400 then
				if CanUseR and object.health <= rDmg then
					CastSpell(_R, object)
				end
			end
		end
	end
end

function TryToKillObjetive(object)
    if ValidTarget(object) then
        local DistanceMonster = GetDistance(object)
		if myHero.charName == "Nunu" then
		    if DistanceMonster <=125+200 then
				if CanUseQ and object.health <= qDmg then
					CastSpell(_Q, object)
				elseif CanUseSmite and not SmiteUnited.nosmite and DistanceMonster <= range and object.health <= SmiteDmg then
						CastSpell(SmiteSlot, object)
				elseif not SmiteUnited.nomix and CanUseQ and not SmiteUnited.nosmite and CanUseSmite and object.health <= MixDmg then
					if DistanceMonster <=125+200 then
						CastSpell(_Q, object)
						CastSpell(SmiteSlot, object)
					end
				end
			end
		elseif myHero.charName == "Chogath" then
			if DistanceMonster <=500 then
				if CanUseR and object.health <=rDmg then
					CastSpell(_R, object)
				elseif CanUseSmite and not SmiteUnited.nosmite and DistanceMonster <= range and object.health <= SmiteDmg then
					CastSpell(SmiteSlot, object)
				elseif not SmiteUnited.nomixr and CanUseR and not SmiteUnited.nosmite and CanUseSmite and object.health <= MixRDmg then
					if DistanceMonster <=500 then
						CastSpell(_R, object)
						CastSpell(SmiteSlot, object)
					end
				end
			end
		elseif CanUseSmite and not SmiteUnited.nosmite and DistanceMonster <=range and object.health <= SmiteDmg then
			CastSpell(SmiteSlot, object)
        end
    end
end

function OnDraw()
	if not SmiteIsOn then return end
	CheckDeadMonsters()
	if SmiteSlot ~= nil and SmiteUnited.active and SmiteUnited.drawrange and not myHero.dead then
		DrawCircle(myHero.x, myHero.y, myHero.z, range, 0x992D3D)
	end

	if not myHero.dead and (SmiteUnited.drawtext or SmiteUnited.drawcircles) then
		if TTMAP then
			if Vilemaw ~= nil then MonsterDraw(Vilemaw) end
			if GolemL ~= nil then MonsterDraw(GolemL) end
			if WolfL ~= nil then MonsterDraw(WolfL) end
			if WraithL ~= nil then MonsterDraw(WraithL) end
			if GolemR ~= nil then MonsterDraw(GolemR) end
			if WolfR ~= nil then MonsterDraw(WolfR) end
			if WraithR ~= nil then MonsterDraw(WraithR) end
		else
			if Nashor ~= nil then MonsterDraw(Nashor) end
			if Dragon ~= nil then MonsterDraw(Dragon) end
			if Golem1 ~= nil then MonsterDraw(Golem1) end
			if Golem2 ~= nil then MonsterDraw(Golem2) end
			if Lizard1 ~= nil then MonsterDraw(Lizard1) end
			if Lizard2 ~= nil then MonsterDraw(Lizard2) end
			if Wolf1 ~= nil then MonsterDraw(Wolf1) end
			if Wolf2 ~= nil then MonsterDraw(Wolf2) end
			if Wraith1 ~= nil then MonsterDraw(Wraith1) end
			if Wraith2 ~= nil then MonsterDraw(Wraith2) end
			if SmallGolem1 ~= nil then MonsterDraw(SmallGolem1) end
			if SmallGolem2 ~= nil then MonsterDraw(SmallGolem2) end
			if BigWraith1 ~= nil then MonsterDraw(BigWraith1) end
			if BigWraith2 ~= nil then MonsterDraw(BigWraith2) end
		end
	end
end

function MonsterDraw(object)
	if object ~= nil and not object.dead and object.visible and object.x ~= nil then
		local DistanceMonster = GetDistance(object)
		if SmiteUnited.active and SmiteUnited.drawcircles and (CanUseSmite or CanUseQ or CanUseR) and DistanceMonster <= range then
			local healthradius = object.health*100/object.maxHealth
			DrawCircle(object.x, object.y, object.z, healthradius+100, 0x00FF00)
			if CanUseSmite then
				local smitehealthradius = SmiteDmg*100/object.maxHealth
				DrawCircle(object.x, object.y, object.z, smitehealthradius+100, 0x00FFFF)
			end
			if CanUseQ and CanUseSmite then
				local Qsmitehealthradius = MixDmg*100/object.maxHealth
				DrawCircle(object.x, object.y, object.z, Qsmitehealthradius+100, 0x00FFFF)
			elseif CanUseQ then
				local Qhealthradius = qDmg*100/object.maxHealth
				DrawCircle(object.x, object.y, object.z, Qhealthradius+100, 0x00FFFF)
			end
			if CanUseR and CanUseSmite then
				local Rsmitehealthradius = MixRDmg*100/object.maxHealth
				DrawCircle(object.x, object.y, object.z, Rsmitehealthradius+100, 0x00FFFF)
			elseif CanUseR then
				local Rhealthradius = rDmg*100/object.maxHealth
				DrawCircle(object.x, object.y, object.z, Rhealthradius+100, 0x00FFFF)
			end
		end
		if SmiteUnited.drawtext and DistanceMonster <= range*2 then
			local wtsobject = WorldToScreen(D3DXVECTOR3(object.x,object.y,object.z))
			local objectX, objectY = wtsobject.x, wtsobject.y
			local onScreen = OnScreen(wtsobject.x, wtsobject.y)
			if onScreen then
				local statusdmgS = SmiteDmg*100/object.health
				local statuscolorS = (CanUseSmite and 0xFF00FF00 or 0xFFFF0000)
				local textsizeS = statusdmgS < 100 and math.floor((statusdmgS/100)^2*20+8) or 28
				textsizeS = textsizeS > 16 and textsizeS or 16
				DrawText(string.format("%.1f", statusdmgS).."% - Smite", textsizeS, objectX-40, objectY+38, statuscolorS)
				if myHero.charName == "Nunu" and myHero:GetSpellData(_Q).level>0 then
					local statusdmgQ = qDmg*100/object.health
					local statuscolorQ = (CanUseQ and 0xFF00FF00 or 0xFFFF0000)
					local textsizeQ = statusdmgQ < 100 and math.floor((statusdmgQ/100)^2*20+8) or 28
					textsizeQ = textsizeQ > 16 and textsizeQ or 16
					DrawText(string.format("%.1f", statusdmgQ).."% - Q", textsizeQ, objectX-40, objectY+56, statuscolorQ)
					if SmiteSlot ~= nil then
						local statusdmgSQ = MixDmg*100/object.health
						local statuscolorSQ = ((CanUseSmite and CanUseQ) and 0xFF00FF00 or 0xFFFF0000)
						local textsizeSQ = statusdmgSQ < 100 and math.floor((statusdmgSQ/100)^2*20+8) or 28
						textsizeSQ = textsizeSQ > 16 and textsizeSQ or 16
						DrawText(string.format("%.1f", statusdmgSQ).."% - Smite+Q", textsizeSQ, objectX-40, objectY+74, statuscolorSQ)
					end
				end
				if myHero.charName == "Chogath" and myHero:GetSpellData(_R).level>0 then
					local statusdmgR = rDmg*100/object.health
					local statuscolorR = (CanUseR and 0xFF00FF00 or 0xFFFF0000)
					local textsizeR = statusdmgR < 100 and math.floor((statusdmgR/100)^2*20+8) or 28
					textsizeR = textsizeR > 16 and textsizeR or 16
					DrawText(string.format("%.1f", statusdmgR).."% - R", textsizeR, objectX-40, objectY+56, statuscolorR)
					if SmiteSlot ~= nil then
						local statusdmgSR = MixRDmg*100/object.health
						local statuscolorSR = ((CanUseSmite and CanUseR) and 0xFF00FF00 or 0xFFFF0000)
						local textsizeSR = statusdmgSR < 100 and math.floor((statusdmgSR/100)^2*20+8) or 28
						textsizeSR = textsizeSR > 16 and textsizeSR or 16
						DrawText(string.format("%.1f", statusdmgSR).."% - Smite+R", textsizeSR, objectX-40, objectY+74, statuscolorSR)
					end
				end	
			end
		end
	end
end

function OnCreateObj(obj)
    if not SmiteIsOn then return end
    if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
        if TTMAP then
			if obj.name == "TT_Spiderboss8.1.1" then Vilemaw = obj
			elseif obj.name == "TT_NWolf3.1.1" then WolfL = obj
			elseif obj.name == "TT_NWraith1.1.1" then WraithL = obj
			elseif obj.name == "TT_NGolem2.1.1" then GolemL = obj  
			elseif obj.name == "TT_NWolf6.1.1" then WolfR = obj
			elseif obj.name == "TT_NWraith4.1.1" then WraithR = obj
			elseif obj.name == "TT_NGolem5.1.1" then GolemR = obj
			end
		elseif not TTMAP then
			if obj.name == "Worm12.1.1" then Nashor = obj
			elseif obj.name == "Dragon6.1.1" then Dragon = obj
			elseif obj.name == "AncientGolem1.1.1" then Golem1 = obj
			elseif obj.name == "GiantWolf2.1.1" then Wolf1 = obj
			elseif obj.name == "Wraith3.1.1" then Wraith1 = obj
			elseif obj.name == "LizardElder4.1.1" then Lizard1 = obj
			elseif obj.name == "Golem5.1.2" then SmallGolem1 = obj
			elseif obj.name == "AncientGolem7.1.1" then Golem2 = obj
			elseif obj.name == "GiantWolf8.1.1" then Wolf2 = obj
			elseif obj.name == "Wraith9.1.1" then Wraith2 = obj
			elseif obj.name == "LizardElder10.1.1" then Lizard2 = obj
			elseif obj.name == "Golem11.1.2" then SmallGolem2 = obj
			elseif obj.name == "GreatWraith13.1.1" then BigWraith1 = obj
			elseif obj.name == "GreatWraith14.1.1" then BigWraith2 = obj
			end
		end
    end
end

function OnDeleteObj(obj)
    if not SmiteIsOn then return end
    if obj ~= nil and obj.name ~= nil then
        if TTMAP then
			if obj.name == "TT_Spiderboss8.1.1" then Vilemaw = nil
			elseif obj.name == "TT_NWolf3.1.1" then WolfL = nil
			elseif obj.name == "TT_NWraith1.1.1" then WraithL = nil
			elseif obj.name == "TT_NGolem2.1.1" then GolemL = nil
			elseif obj.name == "TT_NWolf6.1.1" then WolfR = nil
			elseif obj.name == "TT_NWraith4.1.1" then WraithR = nil
			elseif obj.name == "TT_NGolem5.1.1" then GolemR = nil
			end
		elseif not TTMAP then
			if obj.name == "Worm12.1.1" then Nashor = nil
			elseif obj.name == "Dragon6.1.1" then Dragon = nil
			elseif obj.name == "AncientGolem1.1.1" then Golem1 = nil
			elseif obj.name == "GiantWolf2.1.1" then Wolf1 = nil
			elseif obj.name == "Wraith3.1.1" then Wraith1 = nil
			elseif obj.name == "LizardElder4.1.1" then Lizard1 = nil
			elseif obj.name == "Golem5.1.2" then SmallGolem1 = nil
			elseif obj.name == "AncientGolem7.1.1" then Golem2 = nil
			elseif obj.name == "GiantWolf8.1.1" then Wolf2 = nil
			elseif obj.name == "Wraith9.1.1" then Wraith2 = nil
			elseif obj.name == "LizardElder10.1.1" then Lizard2 = nil
			elseif obj.name == "Golem11.1.2" then SmallGolem2 = nil
			elseif obj.name == "GreatWraith13.1.1" then BigWraith1 = nil
			elseif obj.name == "GreatWraith14.1.1" then BigWraith2 = nil
			end
		end
    end
end

function CheckDeadMonsters()
	if TTMAP then
		if Vilemaw ~= nil then
			if ValidTarget(Vilemaw, range) then VilemawRDY = true
			elseif not ValidTarget(Vilemaw, range) then VilemawRDY = false
			elseif not Vilemaw.valid or Vilemaw.dead or Vilemaw.health <= 0 then 
				Vilemaw = nil
			end 
		end
		if WolfL ~= nil then if not WolfL.valid or WolfL.dead or WolfL.health <= 0 then WolfL = nil end end
		if WraithL ~= nil then if not WraithL.valid or WraithL.dead or WraithL.health <= 0 then WraithL = nil end end
		if GolemL ~= nil then if not GolemL.valid or GolemL.dead or GolemL.health <= 0 then GolemL = nil end end
		if WolfR ~= nil then if not WolfR.valid or WolfR.dead or WolfR.health <= 0 then WolfR = nil end end
		if WraithR ~= nil then if not WraithR.valid or WraithR.dead or WraithR.health <= 0 then WraithR = nil end end
		if GolemR ~= nil then if not GolemR.valid or GolemR.dead or GolemR.health <= 0 then GolemR = nil end end
	else
		if Nashor ~= nil then 
			if ValidTarget(Nashor, range) then NashorRDY = true
			elseif not ValidTarget(Nashor, range) then NashorRDY = false
			elseif not Nashor.valid or Nashor.dead or Nashor.health <= 0 then 
				Nashor = nil 
			end 
		end
		if Dragon ~= nil then 
			if ValidTarget(Dragon, range) then DragonRDY = true
			elseif not ValidTarget(Dragon, range) then DragonRDY = false
			elseif not Dragon.valid or Dragon.dead or Dragon.health <= 0 then 
				Dragon = nil
			end
		end
		if Golem1 ~= nil then if not Golem1.valid or Golem1.dead or Golem1.health <= 0 then Golem1 = nil end end
		if Golem2 ~= nil then if not Golem2.valid or Golem2.dead or Golem2.health <= 0 then Golem2 = nil end end
		if Lizard1 ~= nil then if not Lizard1.valid or Lizard1.dead or Lizard1.health <= 0 then Lizard1 = nil end end
		if Lizard2 ~= nil then if not Lizard2.valid or Lizard2.dead or Lizard2.health <= 0 then Lizard2 = nil end end
		if Wolf1 ~= nil then if not Wolf1.valid or Wolf1.dead or Wolf1.health <= 0 then Wolf1 = nil end end
		if Wolf2 ~= nil then if not Wolf2.valid or Wolf2.dead or Wolf2.health <= 0 then Wolf2 = nil end end
		if SmallGolem1 ~= nil then if not SmallGolem1.valid or SmallGolem1.dead or SmallGolem1.health <= 0 then SmallGolem1 = nil end end
		if SmallGolem2 ~= nil then if not SmallGolem2.valid or SmallGolem2.dead or SmallGolem2.health <= 0 then SmallGolem2 = nil end end
		if Wraith1 ~= nil then if not Wraith1.valid or Wraith1.dead or Wraith1.health <= 0 then Wraith1 = nil end end
		if Wraith2 ~= nil then if not Wraith2.valid or Wraith2.dead or Wraith2.health <= 0 then Wraith2 = nil end end
		if BigWraith1 ~= nil then if not BigWraith1.valid or BigWraith1.dead or BigWraith1.health <= 0 then BigWraith1 = nil end end
		if BigWraith2 ~= nil then if not BigWraith2.valid or BigWraith2.dead or BigWraith2.health <= 0 then BigWraith2 = nil end end
	end
end

function ASLoadMinions()
    for i = 1, objManager.maxObjects do
        local obj = objManager:getObject(i)
        if obj ~= nil and obj.type == "obj_AI_Minion" and obj.name ~= nil then
			if TTMAP then
				if obj.name == "TT_Spiderboss8.1.1" then Vilemaw = obj
				elseif obj.name == "TT_NWolf3.1.1" then WolfL = obj
				elseif obj.name == "TT_NWraith1.1.1" then WraithL = obj
				elseif obj.name == "TT_NGolem2.1.1" then GolemL = obj
				elseif obj.name == "TT_NWolf6.1.1" then WolfR = obj
				elseif obj.name == "TT_NWraith4.1.1" then WraithR = obj
				elseif obj.name == "TT_NGolem5.1.1" then GolemR = obj
				end
			elseif not TTMAP then
				if obj.name == "Worm12.1.1" then Nashor = obj
				elseif obj.name == "Dragon6.1.1" then Dragon = obj
				elseif obj.name == "AncientGolem1.1.1" then Golem1 = obj
				elseif obj.name == "GiantWolf2.1.1" then Wolf1 = obj
				elseif obj.name == "Wraith3.1.1" then Wraith1 = obj
				elseif obj.name == "LizardElder4.1.1" then Lizard1 = obj
				elseif obj.name == "Golem5.1.2" then SmallGolem1 = obj
				elseif obj.name == "AncientGolem7.1.1" then Golem2 = obj
				elseif obj.name == "GiantWolf8.1.1" then Wolf2 = obj
				elseif obj.name == "Wraith9.1.1" then Wraith2 = obj
				elseif obj.name == "LizardElder10.1.1" then Lizard2 = obj
				elseif obj.name == "Golem11.1.2" then SmallGolem2 = obj
				elseif obj.name == "GreatWraith13.1.1" then BigWraith1 = obj
				elseif obj.name == "GreatWraith14.1.1" then BigWraith2 = obj
				end
			end
		end
    end
end