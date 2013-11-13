--[[Galibot the Gatekeeper by BotHappy


v1.0 First Release
v1.1 Orbwalking added

TODO

*Cast W at Allies (AutoShield)
*Improve Combo Mechanics
*AutoR
*Farming
]]

require "Prodiction"

if myHero.charName ~= "Galio" then return end

if not VIP_USER then
	return
end

--Variables
local RangeQ = 940
local WidthQ = 235

local RangeW = 800

local RangeE = 1180
local WidthE = 200

local RangeR = 600

local Prodict = ProdictManager.GetInstance()
local ProdictQ, ProdictE

local QAble, WAble, EAble, RAble = false, false, false, false
local QMana, WMana, EMana, RMana = 0,0,0,0

local lastAnimation = nil
local lastAttack = 0
local lastAttackCD = 0
local lastWindUpTime = 0

local IgniteSlot = nil

local ts = {}

local GalioConfig = {}
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
	

--Main Code
function OnLoad()
	CheckIgnite()
	ts = TargetSelector(TARGET_LESS_CAST, RangeE+150, DAMAGE_MAGIC)
	
	GalioConfig = scriptConfig("Galio Options", "GalioCONFIG1.1")
	
	local HKQ = string.byte("X")
	local HKE = string.byte("C")
	local HKCombo = string.byte("T")
	
	GalioConfig:addParam("Q", "Cast Q", SCRIPT_PARAM_ONKEYDOWN, false, HKQ)
	GalioConfig:addParam("E", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	GalioConfig:addParam("Combo", "Cast Combo", SCRIPT_PARAM_ONKEYDOWN, false, HKCombo)
	--GalioConfig:addParam("CharNum", "AutoR when X enemies in range", SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
	--GalioConfig:addParam("AllyNum", "AutoR when X allies near", SCRIPT_PARAM_SLICE, 1, 0, 5, 0)
	GalioConfig:addParam("UseQ", "Use Q at Combo", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("UseW", "Use W at Combo", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("UseE", "Use E at Combo", SCRIPT_PARAM_ONOFF, true)
	--GalioConfig:addParam("UseR", "Use R at Combo", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("KSq", "AutoKS with Q", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("KSe", "AutoKS with E", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("Ignite", "AutoIgnite KS", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("draws", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:addParam("UseOrbwalk", "Use Orbwalk", SCRIPT_PARAM_ONOFF, true)
	GalioConfig:permaShow("Q")
	GalioConfig:permaShow("E")
	GalioConfig:permaShow("Combo")
	--GalioConfig:permaShow("UseR")
	GalioConfig:addTS(ts)
	
	ts.name = "Galio"
	
	ProdictQ = Prodict:AddProdictionObject(_Q, RangeQ, 1000, 0.1, WidthQ, myHero, CastQ)
	ProdictE = Prodict:AddProdictionObject(_E, RangeE, 1000, 0.1, WidthE, myHero, CastE)
	
	PrintChat(">> Galibot the Gatekeeper 1.1 loaded")
end

function OnTick()
	Checks()
	ts:update()
	AutoIgniteKS()
	if GalioConfig.KSe then
		KSe()
	end
	if GalioConfig.KSq then
		KSq()
	end
	if IsKeyDown(GetKey("C")) or IsKeyDown(GetKey("X")) then
		moveToCursor()
	end
	if ts.target ~= nil and GalioConfig.Q then
		ProdictQ:EnableTarget(ts.target, true)
	end
	if ts.target ~= nil and GalioConfig.E then
		ProdictE:EnableTarget(ts.target, true)
	end
	if GalioConfig.UseOrbwalk and IsKeyDown(GetKey("T")) then
		if ts.target ~= nil then
			OrbWalking(ts.target)
		else
			moveToCursor()
		end
	end
	if ts.target ~= nil and GalioConfig.Combo then
		ComboCast(ts.target)
		--if GalioConfig.UseR and CountEnemyHeroInRange(RangeR) >= GalioConfig.CharNum then
		--	CastSpell(_R)
		--end
	end
end

function OnDraw()
	if GalioConfig.draws then
		if ts.target ~= nil then
			local dist = getHitBoxRadius(ts.target)/2
			
			if GetDistance(ts.target) - dist < RangeQ then
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x7F006E)
			end
			if GetDistance(ts.target) - dist < RangeE then
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, dist, 0x5F9F9F)
			end
		end
		if QAble then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeQ, 0xFFFFFF)
		end
		if WAble then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeW, 0x7F006E)
		end
		if EAble then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeE, 0x99FF00)
		end
		if RAble then
			DrawCircle(myHero.x, myHero.y, myHero.z, RangeR, 0xCCFF00)
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

--Added functions, code...

-- function GetAllies()
	-- local NumAllies = 0
	-- for i = 1, heroManager.iCount do
		-- local Enemy = heroManager:getHero(i)
		-- if Enemy.team ~= myHero.team and DistanceToHit(Enemy) < RangeR then
			-- --Get number. GetAllyHeroes() could help here.
		-- end
	-- end
-- end

-- function GetEnemies()
	-- local NumEnemies = 0
	-- for i = 1, heroManager.iCount do
		-- local Ally = heroManager:getHero(i)
		-- if Ally.team == myHero.team and DistanceToHit(Ally) < RangeR+300 then
			-- --Get number. GetEnemyHeroes() could help here.
		-- end
	-- end
-- end

function ComboCast(Target)
	UseItems(Target)
	if QAble and GalioConfig.UseQ and DistanceToHit(Target) <RangeQ and myHero.mana >= QMana then
		ProdictQ:EnableTarget(Target, true)
	end
	
	if EAble and GalioConfig.UseE and DistanceToHit(Target) <RangeE and myHero.mana >= EMana then
		ProdictE:EnableTarget(Target, true)
	end
	
	if WAble and GalioConfig.UseW and myHero.mana >= WMana then
		CastSpell(_W, myHero)
	end
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

function CastE(unit, pos)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < RangeE then
		CastSpell(_E, pos.x, pos.z)
	end
end

function CastQ(unit, pos)
	if GetDistance(pos) - getHitBoxRadius(unit)/2 < RangeQ then
		CastSpell(_Q, pos.x, pos.z)
	end
end

function KSq()
    for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if QAble and ValidTarget(Enemy, 1100, true) and Enemy.health < getDmg("Q",Enemy,myHero) - 50 then
			ProdictQ:EnableTarget(Enemy, true)
		end
    end
end

function KSe()
    for i = 1, heroManager.iCount do
		local Enemy = heroManager:getHero(i)
		if QAble and ValidTarget(Enemy, 1200, true) and Enemy.health < getDmg("E",Enemy,myHero) - 50 then
			ProdictQ:EnableTarget(Enemy, true)
		end
    end
end

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
	if GalioConfig.Ignite and IgniteAble then
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
