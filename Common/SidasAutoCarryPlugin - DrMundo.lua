--[[Sida's Autocarry Plugin - DrMundo by BotHappy

v0.1 - Initial release (WIP)
v0.2 - Percent Selector + Harrass Mode + Fixes
v1.0 - Rewritten script, tons of updates]]

require "Collision"
require "Prodiction"

if myHero.charName ~= "DrMundo" or not VIP_USER then return end

function Variables()
	qRange = 1050
	wRange = 325
	eRange = 300
	wUsed = false
	
	QReady, WReady, EReady, RReady = false, false, false, false
	
	Prodict = ProdictManager.GetInstance()
    ProdictQ = Prodict:AddProdictionObject(_Q, qRange, 1900, 0.250, 80)
	ProdictQCollision = Collision(qRange, 1900, 0.250, 80)
	
	TrinitySlot, SheenSlot, BWCSlot, BotrkSlot, YoumuSlot, HydraSlot, EntropySlot = nil, nil, nil, nil, nil, nil, nil
	qDmg, wDmg, AADmg, IgniteDmg = 0,0,0,0
	SheenDmg, BWCDmg, TrinityDmg, BotrkDmg, HydraDmg, TiamatDmg, EntropyDmg = 0,0,0,0,0,0,0
	
	AutoCarry.SkillsCrosshair.range = 1400
	
	enemyMinions = minionManager(MINION_ENEMY, 600, player, MINION_SORT_HEALTH_DES)
end

function PluginOnLoad()
	Variables()
	Menu()
	PrintChat("<font color='#FF0000'> >> Time to Mundo! v1.0 Loaded<<</font>")
end

function PluginOnTick()
	Checks()
	if ValidTarget(Target) then
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			ComboCast()
		end
		if QReady and AutoCarry.PluginMenu.Harrass then ProdictQ:EnableTarget(Target, true) end
	end
	if AutoCarry.PluginMenu.useR then CastREmergency() end
	if AutoCarry.PluginMenu.ksQ then KSQ() end
end

function PluginOnDraw()
	if not myHero.dead then
		if QReady and AutoCarry.PluginMenu.drawQ then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x7CFC00)
		end
		if WReady and AutoCarry.PluginMenu.drawW then 
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x00FFFF)
		end
	end
	if AutoCarry.PluginMenu.texts then KillDraws() end
end

function Menu()
	local HKQ = string.byte("T")
	AutoCarry.PluginMenu:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("notQ", "Not Q if below X% health", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
	AutoCarry.PluginMenu:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("notW", "Not W if below X% health", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
	AutoCarry.PluginMenu:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("notE", "Not E if below X% health", SCRIPT_PARAM_SLICE, 10, 0, 100, 0)
	AutoCarry.PluginMenu:addParam("useR", "Auto use R", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("ksQ", "KS with Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("AutoRHP", "R if below X% health", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)
	AutoCarry.PluginMenu:addParam("Harrass", "Harrass with Q", SCRIPT_PARAM_ONKEYDOWN, false, HKQ)
	AutoCarry.PluginMenu:permaShow("Harrass")
	AutoCarry.PluginMenu:addParam("drawQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("texts", "Draw Kill texts", SCRIPT_PARAM_ONOFF, true)
end

function Checks()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
	
	IgniteReady = (IgniteSlot ~= nil and myHero:CanUseSpell(IgniteSlot) == READY)
    
    TrinitySlot = GetInventorySlotItem(3078)
    SheenSlot = GetInventorySlotItem(3057)
    BCWSlot = GetInventorySlotItem(3144)
    BotrkSlot = GetInventorySlotItem(3153)
    YoumuSlot = GetInventorySlotItem(3142)
    TiamatSlot = GetInventorySlotItem(3077)
    HydraSlot = GetInventorySlotItem(3074)
    EntropySlot = GetInventorySlotItem(3184)
	
	TrinityReady = (TrinitySlot ~= nil and myHero:CanUseSpell(TrinitySlot) == READY)
    SheenReady = (SheenSlot ~= nil and myHero:CanUseSpell(SheenSlot) == READY)
    BCW1Ready = (BCWSlot~= nil and myHero:CanUseSpell(BCWSlot) == READY)
    BotrkReady = (BotrkSlot ~= nil and myHero:CanUseSpell(BotrkSlot) == READY)
    YoumuReady = (YoumuSlot ~= nil and myHero:CanUseSpell(YoumuSlot) == READY)
    TiamatReady = (TiamatSlot ~= nil and myHero:CanUseSpell(TiamatSlot) == READY)
    HydraReady = (HydraSlot ~= nil and myHero:CanUseSpell(HydraSlot) == READY)
    EntropyReady = (EntropySlot ~= nil and myHero:CanUseSpell(EntropySlot) == READY)
	
	enemyMinions:update()
	GetDamages()
end

function GetDamages()
    for i = 1, heroManager.iCount do
        local EnemyDraws = heroManager:getHero(i)
		if ValidTarget(EnemyDraws) then
			qDmg = getDmg("Q", EnemyDraws, myHero)
			wDmg = getDmg("W", EnemyDraws, myHero)
			AADmg = getDmg("AD", EnemyDraws, myHero)
			IgniteDmg = getDmg("IGNITE", EnemyDraws, myHero)
			SheenDmg = getDmg("SHEEN", EnemyDraws, myHero)
			BWCDmg = getDmg("BWC", EnemyDraws, myHero)
			TrinityDmg = getDmg("TRINITY", EnemyDraws, myHero)
			BotrkDmg = getDmg("RUINEDKING", EnemyDraws, myHero)
			if HydraSlot ~= nil then HydraDmg = AADmg*0.6 end
			if TiamatSlot ~= nil then TiamatDmg = AADmg*0.6 end
			if EntropySlot ~= nil then EntropyDmg = 80 end
			if BotrkReady then
				AADmg = AADmg + 0.05*EnemyDraws.health
			end
		end
	end
    ItemsDmg = SheenDmg + BWCDmg + TrinityDmg + BotrkDmg + HydraDmg + TiamatDmg + EntropyDmg
	Killable = qDmg + wDmg*3 + AADmg*2 + IgniteDmg + ItemsDmg
end

function KillDraws()
    for i = 1, heroManager.iCount do
        local EnemyDraws = heroManager:getHero(i)
        if ValidTarget(EnemyDraws) then
            if EnemyDraws.health < IgniteDmg then
                PrintFloatText(EnemyDraws, 0, "Ignite!")
            elseif EnemyDraws.health < Killable then
                PrintFloatText(EnemyDraws, 0, "Kill!")
            elseif EnemyDraws.health > Killable then
                PrintFloatText(EnemyDraws, 0, "Harrass!")
            end
        end
    end
end

function KSQ()
    for i = 1, heroManager.iCount do
        local Enemy = heroManager:getHero(i)
        if RReady and ValidTarget(Enemy, rRange, true) and Enemy.health < getDmg("R",Enemy,myHero) + 30 then
            CastQ(Enemy)
        end
    end
end

function ComboCast() 
	if QReady and AutoCarry.PluginMenu.useQ and myHero.health > (myHero.maxHealth*(AutoCarry.PluginMenu.notQ/100)) then 
		CastQ(Target)
	end
	
	if WReady and AutoCarry.PluginMenu.useW and myHero.health > (myHero.maxHealth*(AutoCarry.PluginMenu.notW/100)) then 
		if wUsed == false and HeroesAround() then
			CastSpell(_W)
		elseif not HeroesAround() and wUsed == true then
			CastSpell(_W)
		end
	end
	
	if EReady and AutoCarry.PluginMenu.useE and myHero.health > (myHero.maxHealth*(AutoCarry.PluginMenu.notE/100)) then
		if GetDistance(Target) <= eRange then
			CastSpell(_E)
		end
	end
end

function HeroesAround()
    for i = 1, heroManager.iCount do
        local Enemy = heroManager:getHero(i)
        if ValidTarget(Enemy, 550) then
            return true
		else 
			return false
        end
    end
end


function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function CastQ(Unit)
    if GetDistance(Unit) - getHitBoxRadius(Unit)/2 < q1Range and ValidTarget(Unit) then
        QPos = ProdictQ:GetPrediction(Unit)
        local willCollide = ProdictQCollision:GetMinionCollision(QPos, myHero)
        if not willCollide then CastSpell(_Q, QPos.x, QPos.z) end
    end
end

function CastREmergency()
    if myHero.health < (myHero.maxHealth*(AutoCarry.PluginMenu.AutoRHP/100)) then
		if RReady then
			CastSpell(_R)
        end
    end
end

function FarmWithW() --Thanks to Skeem
	for _, minion in pairs(enemyMinions.objects) do
		if minion ~=nil and minion.health < getDmg("W", minion, myHero) then
			CastSpell(_W)
		end
	end
end

function OnGainBuff(myHero, buff)
	if buff.name == "BurningAgony" then
		wUsed = true
	end
end

function OnLoseBuff(myHero, buff)
	if buff.name == "BurningAgony" then
		wUsed = false
	end
end