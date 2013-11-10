--[[Simple Minion Marker

Author: BotHappy

TODO
* Fix FPS drops
]]

local Minions = {}

function OnLoad()
	PrintChat(">> Simple Minion Marker loaded")
end


function OnTick()
	GetMinions()
end

function OnDraw()
	for i, minion in pairs(Minions) do
		if minion.obj == nil or minion.obj.dead or GetDistance(myHero,minion.obj) > (myHero.range + 300) then --Additional Range
			Minions[i] = nil
		elseif minion.obj.health <= getDmg("AD",minion.obj,myHero) then
			DrawCircle(Minions[i].obj.x, Minions[i].obj.y, Minions[i].obj.z, 90, 0x19A712)
		end
	end
end

function GetMinions()
	for i = 1, objManager.maxObjects, 1 do
		local Object = objManager:getObject(i)
		if Object ~= nil and Object.team ~= myHero.team and Object.type == "obj_AI_Minion" and string.find(Object.charName, "Minion") then
			if not Object.dead and GetDistance(Object, myHero) <= myHero.range + 300 then
				if Minions[Object.name] == nil then
					Minions[Object.name] = { obj = Object }
				end
			else
				Minions[Object.name] = {obj = nil}
			end
		end
	end
end