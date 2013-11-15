--[[Basic script which draws the estimated time
which is needed to kill someone with autoattacks.

v1.0 Release
v1.1 Added Menu + IE support
v1.2 Added Lethality masteryv
v1.3 Added Vayne (Estimation) + BOTkR

Author: BotHappy

TODO
>>Nothing!

]]

local Vayne = false

if myHero.charName == "Vayne" then
	Vayne=true
end

local IEid = 3031
local BOTkRid = 3153
local iebought = 1
local BOTkRdmg = 0
local Vaynedmg = 0
local Lethality = 1

function OnLoad()
	AAtoKill = scriptConfig("AAs to Kill", "aatokill")
	
	AAtoKill:addParam("drawaa", "Draw time to kill", SCRIPT_PARAM_ONOFF, true)
	AAtoKill:addParam("usecrits", "Use crits at calculations", SCRIPT_PARAM_ONOFF, true)
	AAtoKill:addParam("autos", "Estimate AAs to kill", SCRIPT_PARAM_ONOFF, true)
	AAtoKill:addParam("lethality", "Lethality Points", SCRIPT_PARAM_SLICE, 0, 0, 2, 0)
	PrintChat(">> Draw AA's to Kill loaded")

end

function OnTick()

	if myHero.range < 350 then
		Lethality = 1 + 0.1*AAtoKill.lethality
	else
		Lethality = 1 + 0.05*AAtoKill.lethality
	end

end

function OnDraw()
	for _, Enemy in pairs(GetEnemyHeroes()) do
        if ValidTarget(Enemy) and Enemy.visible and AAtoKill.drawaa then
			local timetokill
			if AAtoKill.usecrits then
				timetokill = string.format("%4.1f", CRIT(Enemy)) .. "s to dead"
				DrawText3D(tostring(timetokill), Enemy.x, Enemy.y, Enemy.z, 20, RGB(255, 255, 255), true)
			else
				timetokill = string.format("%4.1f", DPS(Enemy)) .. "s to dead"
				DrawText3D(tostring(timetokill), Enemy.x, Enemy.y, Enemy.z, 20, RGB(255, 255, 255), true)
			end
			if AAtoKill.autos then
				autostokill = "AAs to kill:" .. string.format("%4.0f", 1+(Enemy.health/(myHero:CalcDamage(Enemy, myHero.totalDamage) + Vaynedmg + BOTkRdmg + (Lethality*iebought*myHero:CalcDamage(Enemy, myHero.totalDamage)*myHero.critChance))))
				DrawText3D(tostring(autostokill), Enemy.x+10, Enemy.y, Enemy.z+65, 20, RGB(255, 255, 255), true)
			end
        end
    end
end

function DPS(Enemy)
	return Enemy.health/ (myHero:CalcDamage(Enemy, myHero.totalDamage) * myHero.attackSpeed)
end

function CRIT(Enemy)
	if GetInventorySlotItem(IEid) ~=nil then
		iebought = 1.5
	else
		iebought = 1
	end
	
	if GetInventorySlotItem(BOTkRid) ~=nil then
		BOTkRdmg = myHero:CalcDamage(Enemy, (Enemy.health)*0.05)
	else
		BOTkRdmg = 0
	end
	
	if Vayne then
		WAble = (myHero:CanUseSpell(_W) == READY)
		Vaynedmg = (((3+(myHero:GetSpellData(_W).level))*0.01)*Enemy.maxHealth)/3
	else
		Vaynedmg = 0
	end
	
	return Enemy.health/ ((myHero:CalcDamage(Enemy, myHero.totalDamage) + (Lethality*iebought*myHero:CalcDamage(Enemy, myHero.totalDamage)*myHero.critChance) + BOTkRdmg + Vaynedmg) * myHero.attackSpeed)
end