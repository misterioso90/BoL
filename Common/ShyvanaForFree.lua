--Shyvana Tiem for free users by BotHappy

--Name it as "SidasAutoCarryPlugin - Shyvana.lua"


if myHero.charName ~= "Shyvana" then return end


local QRange = 125
local WRange = 325
local ERange = 925
local RRange = 1000
local QAble, WAble, EAble, RAble = false, false, false, false

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
local ignite = nil

function PluginOnLoad() 
	AutoCarry.SkillsCrosshair.range = 1100
	PrintChat(" Shyvana Tiem FOR NONVIPS")
end

function PluginOnTick()
	Checks()
	Menu()
	if Target then
		if (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
			ComboCast()
		end
		if AutoCarry.PluginMenu.Harrass and EAble then
			CastSpell(_E, Target.x, Target.z)
		end
	end
end    

function Checks()
	QAble = (myHero:CanUseSpell(_Q) == READY)
	WAble = (myHero:CanUseSpell(_W) == READY)
	EAble = (myHero:CanUseSpell(_E) == READY)
	RAble = (myHero:CanUseSpell(_R) == READY)
	Target = AutoCarry.GetAttackTarget()
end

function Menu()
	local HKE = string.byte("T")
	AutoCarry.PluginMenu:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useR", "Use R in combo", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("drawW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawE", "Draw E Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawR", "Draw R Range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("Harrass", "Harrass with E", SCRIPT_PARAM_ONKEYDOWN, false, HKE)
	AutoCarry.PluginMenu:permaShow("Harrass")
end

function ComboCast()
	UseItems(Target)
	if QAble and AutoCarry.PluginMenu.useQ then
		if GetDistance(Target) <= QRange  and AutoCarry.shotFired then
			CastSpell(_Q)
		end
	end
	if WAble and AutoCarry.PluginMenu.useW then CastSpell(_W) end
	if EAble and AutoCarry.PluginMenu.useE then  CastSpell(_E, Target.x, Target.z) end
	if RAble and AutoCarry.PluginMenu.useR then  CastSpell(_R)  end  
end

function PluginOnDraw()
	if not myHero.dead then
		if (WAble or WActive) and AutoCarry.PluginMenu.drawW then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0x7CFC00)
		end
		if EAble and AutoCarry.PluginMenu.drawE then 
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x00FFFF)
		end
		if RAble and AutoCarry.PluginMenu.drawR then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF0000)
		end
	end
end

-- By Sida ( all credits )
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