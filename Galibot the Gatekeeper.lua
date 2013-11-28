--[[Galibot the Gatekeeper by BotHappy


v1.0 First Release
v1.1 Orbwalking added
v1.2 Prodiction fixed, improved code and script

TODO

*Cast W at Allies (AutoShield)
*Farming
]]

require "Prodiction"

if myHero.charName ~= "Galio" or not VIP_USER then return end

function Variables()
	RangeQ = 940
	WidthQ = 120
	
	RangeW = 800

	RangeE = 1180
	WidthE = 120

	RangeR = 600

	Prodict = ProdictManager.GetInstance()
	ProdictQ = Prodict:AddProdictionObject(_Q, RangeQ, 1300, 0.250, WidthQ)
	ProdictE = Prodict:AddProdictionObject(_E, RangeE, 1200, 0.1, WidthE)

	QReady, WReady, EReady, RReady = false, false, false, false
	QMana, WMana, EMana, RMana = 0,0,0,0

	lastAnimation = nil
	lastAttack = 0
	lastAttackCD = 0
	lastWindUpTime = 0

	IgniteSlot = nil
	
	enemyHeroes = GetEnemyHeroes()
	enemyMinions = minionManager(MINION_ENEMY, RangeQ, player, MINION_SORT_HEALTH_ASC)
	
	ts = TargetSelector(TARGET_NEAR_MOUSE, 1300, DAMAGE_MAGIC)
	ts.name = "Galio"
	
	LastTickChecked = 0
	LastHealthChecked = 0
	
	HKQ = string.byte("X")
	HKE = string.byte("C")
	HKCombo = string.byte("T")
	
	items =
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
	
	qDmg,eDmg,dfgDmg,rDmg,IgniteDmg = 0,0,0,0,0
	ComboQE, FullCombo = 0, 0
	
	DFGSlot = nil
	
	Ult = false
	idolbuff = false
	
end
	

--Main Code
function OnLoad()
	Variables()
	CheckIgnite()
	Menu()
	
	PrintChat(">> Galibot the Gatekeeper 1.2 loaded")
end

function Menu()
	GalioConfig = scriptConfig("Galio Options", "GalioCONFIG1.2")
	
	GalioConfig:addParam("sep", "----- [ General Settings ] -----", SCRIPT_PARAM_INFO, "")
	GalioConfig:addParam("Q", "Cast Q", SCRIPT_PARAM_ONKEYDOWN, false, HKQ)
	GalioConfig:addParam("E", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	GalioConfig:addParam("anticassio", "Anti Cassio Shield", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("KSq", "AutoKS with Q", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("KSe", "AutoKS with E", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("Ignite", "AutoIgnite KS", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("UseOrbwalk", "Use Orbwalk", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("sep", "----- [ Combo Settings ] -----", SCRIPT_PARAM_INFO, "")
	GalioConfig:addParam("Combo", "Cast Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKCombo)
	GalioConfig:addParam("UseQ", "Use Q at Combo", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("UseW", "Use W at Combo", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("UseE", "Use E at Combo", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("UseR", "Use R at Combo", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("CharNum", "AutoR when X enemies in range", SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
	GalioConfig:addParam("AllyNum", "AutoR when X allies near", SCRIPT_PARAM_SLICE, 1, 0, 4, 0)
	GalioConfig:addParam("sep", "----- [ Draws Settings ] -----", SCRIPT_PARAM_INFO, "")
	GalioConfig:addParam("draws", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("texts", "Draw Kill Text", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("farming", "Draw Killable minions", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("ultonenemies", "Draw Ult on Enemies", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:permaShow("Q")
	GalioConfig:permaShow("E")
	GalioConfig:permaShow("Combo")
	GalioConfig:permaShow("UseR")
	GalioConfig:addTS(ts)
end


function OnTick()
	Checks()
	AutoIgniteKS()
	if GalioConfig.KSe then	KSe() end
	if GalioConfig.KSq then	KSq() end
	if IsKeyDown((HKQ or HKE)) then moveToCursor() end
	if ValidTarget(ts.target) then
		if GalioConfig.Q then
			CastQ(ts.target)
		end
		if GalioConfig.E then
			CastE(ts.target)
		end
		if GalioConfig.Combo then
			ComboCast(ts.target)
		end
	end
	if GalioConfig.UseOrbwalk and IsKeyDown(HKCombo) then
		if ValidTarget(ts.target) then
			OrbWalking(ts.target)
		else
			moveToCursor()
		end
	end
	
	if LastTickChecked <= GetTickCount() - 500 then
		LastHealthChecked = myHero.health
		LastTickChecked = GetTickCount()
	end
	if GalioConfig.anticassio then VSCassio() end
	if Ult then
		if not idolbuff then Ult = false end
	end
end

function OnDraw()
	if GalioConfig.draws then
		if ValidTarget(ts.target, RangeE+150) then
			local dist = getHitBoxRadius(ts.target)/2
			
			if GetDistance(ts.target) - dist < RangeQ then
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
			end
			
			if GetDistance(ts.target) - dist < RangeE then
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x5F9F9F)
			end
		end
		if QReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeQ, 0xFFFFFF)
		end
		if WReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeW, 0x7F006E)
		end
		if EReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeE, 0x99FF00)
		end
		if RReady then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeR, 0xCCFF00)
			if GalioConfig.ultonenemies then
				for i = 1, heroManager.iCount do
					local Enemy = heroManager:getHero(i)
					if Enemy.team ~= myHero.team and DistanceToHit(Enemy) < RangeR then
						PrintFloatText(Enemy, 0, "ULT")
						DrawCircle(Enemy.x, Enemy.y, Enemy.z, 120, 0x00FF00)
						DrawCircle(Enemy.x, Enemy.y, Enemy.z, 130, 0x00FF00)
						DrawCircle(Enemy.x, Enemy.y, Enemy.z, 140, 0x00FF00)
					end
				end
			end
		end
	end
	if GalioConfig.texts then KillDraws() end
	if GalioConfig.farming then 
		for _, Enemy in pairs(enemyMinions.objects) do
			if ValidTarget(Enemy, RangeE) then
				QKILL = math.ceil(Enemy.health/getDmg("Q",Enemy,myHero))
				if QKILL < 2 and QReady then
					DrawText3D("Q", Enemy.x, Enemy.y, Enemy.z, 23, RGB(255,0,0), true)
				end
			end
		end
	end
end

function GetDamages()
	for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		qDmg = getDmg("Q", Enemy, myHero)
		eDmg = getDmg("E", Enemy, myHero)
		dfgDmg = getDmg("DFG", Enemy, myHero)
		rDmg = getDmg("R", Enemy, myHero)
		IgniteDmg = getDmg("IGNITE", Enemy, myHero)
	end
	ComboQE = qDmg + eDmg
	FullCombo = qDmg + eDmg + dfgDmg + rDmg
end

function KillDraws()
	for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if ValidTarget(Enemy) then
			if Enemy.health < qDmg then
				PrintFloatText(Enemy, 0, "Q to Kill")
			elseif Enemy.health < ComboQE then
				PrintFloatText(Enemy, 0, "Q+E to Kill")
			elseif Enemy.health < FullCombo then
				PrintFloatText(Enemy, 0, "Full Combo to kill")
			elseif Enemy.health > FullCombo then
				PrintFloatText(Enemy, 0, "Harrass!")
			end
		end
	end
end
--Added functions, code...

function CountAllyHeroInRange(range)
    local allyInRange = 0
    for i = 1, heroManager.iCount, 1 do
        local hero = heroManager:getHero(i)
        if ValidTarget(hero, range, true) and hero.team == myHero.team then
            allyInRange = allyInRange + 1
        end
    end
    return allyInRange
end

function ComboCast(Target)
	UseItems(Target)
	if QReady and GalioConfig.UseQ and DistanceToHit(Target) <RangeQ and myHero.mana >= QMana then
		CastQ(Target)
	end
	
	if EReady and GalioConfig.UseE and DistanceToHit(Target) <RangeE and myHero.mana >= EMana then
		CastE(Target)
	end
	
	if WReady and GalioConfig.UseW and myHero.mana >= WMana then
		if LastHealthChecked > myHero.health then
			CastSpell(_W)
		end
	end
	if RReady and GalioConfig.UseR then
		if CountEnemyHeroInRange(RangeR) >= GalioConfig.CharNum and CountAllyHeroInRange(RangeR+300) >= GalioConfig.AllyNum then
			CastSpell(_R)
			Ult = true
		end
	end
end

function VSCassio()
	for _,enemy in pairs(enemyHeroes) do
		if enemy.charName == "Cassiopeia" and isPoisoned(myHero) then
			CastSpell(_W, myHero)
		end
	end
end

function isPoisoned(target)
	for i = 1, target.buffCount, 1 do
		local tBuff = target:getBuff(i)
		if BuffIsValid(tBuff) then
			if tBuff.name:lower():find("poison") then
				return true
			end
		end
	end
	return false
end

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

function CastE(unit)
	if DistanceToHit(unit) < RangeE and ValidTarget(unit, RangeE) then
		EPos = ProdictE:GetPrediction(unit)
		CastSpell(_E, EPos.x, EPos.z)
	end
end

function CastQ(unit)
	if DistanceToHit(unit) < RangeQ and ValidTarget(unit, RangeQ) then
		QPos = ProdictQ:GetPrediction(unit)
		CastSpell(_Q, QPos.x, QPos.z)
	end
end

function KSq()
    for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if QReady and ValidTarget(Enemy, RangeQ, true) and Enemy.health < getDmg("Q",Enemy,myHero) - 50 then
			CastQ(Enemy)
		end
    end
end

function KSe()
    for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if EReady and ValidTarget(Enemy, RangeE, true) and Enemy.health < getDmg("E",Enemy,myHero) - 50 then
			CastE(Enemy)
		end
    end
end

function Checks()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	if IgniteSlot ~= nil then IgniteReady = (myHero:CanUseSpell(IgniteSlot) == READY) end
	
	QMana = myHero:GetSpellData(_Q).mana
	WMana = myHero:GetSpellData(_W).mana
	EMana = myHero:GetSpellData(_E).mana
	RMana = myHero:GetSpellData(_R).mana
	
	DFGSlot = GetInventorySlotItem(3128)
	
	ReadyDFG = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
	GetDamages()
	enemyMinions:update()
	ts:update()
end

function UseItems(target)
    if not ValidTarget(target) then return end
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
	if GalioConfig.Ignite and IgniteReady then
		IgniteDMG = 50 + (20 * myHero.level)
		for _, Enemy in pairs(GetEnemyHeroes()) do
			if ValidTarget(Enemy, 600) and Enemy.health <= IgniteDMG then
				CastSpell(IgniteSlot, Enemy)
			end
		end
	end
end

--Based on Manciuzz Orbwalker http://pastebin.com/jufCeE0e

function OrbWalking(Target)
	if TimeToAttack() and GetDistance(Target) <= myHero.range + GetDistance(myHero.minBBox) then
		myHero:Attack(Target)
	elseif heroCanMove() then
		moveToCursor()
	end
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

function OnSendPacket(p)
	if Ult then
		packet = Packet(p)
		packetName = Packet(p):get('name')
		if packetName == 'S_MOVE' or packetName == 'S_CAST' then
			packet:block()
		end
	end
end

function OnGainBuff(hero, buff)
	if hero == myHero and buff.name == "GalioIdolOfDurand" then
		idolbuff = true
	end
end

function OnLoseBuff(hero, buff)
	if hero == myHero and buff.name == "GalioIdolOfDurand" then
		idolbuff = false
	end
end