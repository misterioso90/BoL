--AA Minion Marker by BotHappy

--Feature: Put a number on every near minion showing you how many autos
--	you should do to kill it. It turns red when you can lasthit it.

function OnLoad()
	AAMinionMarker = scriptConfig("AA Minion Marker", "AAMinionMarker")
	
	AAMinionMarker:addParam("draws", "Draw Marks", SCRIPT_PARAM_ONOFF, true)
	enemyMinions = minionManager(MINION_ENEMY, 1000, player, MINION_SORT_HEALTH_ASC)
	PrintChat(" >> AA Minion Marker loaded!")
	autostokill = 0
	RGBRED = RGB(255,0,0)
	RGBGREY = RGB(255,255,255)
	RGBYELLOW = RGB(255,215,0)
	RGBGREEN = RGB(124,252,0)
end

function OnTick()
	enemyMinions:update()
end

function OnDraw()
	if AAMinionMarker.draws then
		for _, Enemy in pairs(enemyMinions.objects) do
			if ValidTarget(Enemy) then
				autostokill = math.ceil(Enemy.health/getDmg("AD",Enemy,myHero))
				DrawText3D(tostring(autostokill), Enemy.x, Enemy.y, Enemy.z, 20, Color(), true)
			end
		end
	end
end

function Color()
	if autostokill < 2 then
		return RGBRED
	elseif autostokill > 1 and autostokill < 4 then
		return RGBYELLOW
	elseif autostokill > 3 then
		return RGBGREEN
	end
end
