--[[Sida's Autocarry Plugin - DrMundo by BotHappy

v0.1 - Initial release (WIP)
v0.2 - Percent Selector + Harrass Mode + Fixes
v1.0 - Rewritten script, tons of updates
v1.1 - Improved script code + W usage]]

require "Collision"
require "Prodiction"

if myHero.charName ~= "DrMundo" or not VIP_USER then return end

local qRange = 1050
local wRange = 325
local eRange = 225
local wUsed = false
	
local QReady, WReady, EReady, RReady = false, false, false, false
	
local Prodict = ProdictManager.GetInstance()
local ProdictQ = Prodict:AddProdictionObject(_Q, qRange, 1900, 0.250, 80)
local ProdictQCollision = Collision(qRange, 1900, 0.250, 80)

local HKQ = string.byte("T")

local enemyHeroes = GetEnemyHeroes()

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 1250
	Menu()
	PrintChat("<font color='#FFFFFF'> >> Time to Mundo! v1.1 Loaded<<</font>")
end

function PluginOnTick()
	Checks()
	if ValidTarget(Target) then
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			ComboCast()
		end
		if QReady and AutoCarry.PluginMenu.Harrass then 
			CastQ(Target) 
		end
	end
	if IsKeyDown(HKQ) then MoveToCursor() end
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
end

function Menu()
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
	
end

function Checks()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
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
	if QReady and AutoCarry.PluginMenu.useQ and myHero.health > (myHero.maxHealth*(AutoCarry.PluginMenu.notQ*0.01)) then 
		CastQ(Target)
	end
	
	if WReady and AutoCarry.PluginMenu.useW and myHero.health > (myHero.maxHealth*(AutoCarry.PluginMenu.notW*0.01)) then 
		if not wUsed and CountEnemyHeroInRange(wRange) >= 1 then
			CastSpell(_W)
		elseif CountEnemyHeroInRange(wRange+200) == 0 and wUsed then
			CastSpell(_W)
		end
	end
	
	if EReady and AutoCarry.PluginMenu.useE and myHero.health > (myHero.maxHealth*(AutoCarry.PluginMenu.notE*0.01)) then
		if GetDistance(Target) <= eRange then
			CastSpell(_E)
		end
	end
end

function GetHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function CastQ(Unit)
    if GetDistance(Unit) - GetHitBoxRadius(Unit)*0.5 < qRange and ValidTarget(Unit) then
        QPos = ProdictQ:GetPrediction(Unit)
        local WillCollide = ProdictQCollision:GetMinionCollision(QPos, myHero)
        if not WillCollide then CastSpell(_Q, QPos.x, QPos.z) end
    end
end

function CastREmergency()
    if myHero.health < (myHero.maxHealth*(AutoCarry.PluginMenu.AutoRHP*0.01)) then
		if RReady then
			CastSpell(_R)
        end
    end
end

function MoveToCursor()
	if GetDistance(mousePos) > 1 or LastAnimation == "Idle1" then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		Packet('S_MOVE', {x = moveToPos.x, y = moveToPos.z}):send()
	end	
end

function OnAnimation(Unit,AnimationName)
	if Unit.isMe and LastAnimation ~= AnimationName then LastAnimation = AnimationName end
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