--[[HP Helper by BotHappy

	Features: It prints the life of your enemies
	
	GREEN --- LIFE>50%
	ORANGE --- 25%>LIFE>50%
	RED --- LIFE<25%
	GREY --- DEAD
	BLUE --- NOT VISIBLE (MISSING)
	
	Version: v0.1 - Release
]]

function OnLoad()
	Variables()
	Menus()
	PrintChat(" >> HP Helper loaded!")
end

function OnDraw()
	if RoamerHelper.drawlife and GetNumberEnemies() > 0 then
		for i, hero in pairs(EnemyHeroes) do
			DrawRectangleOutline(CalculateXBox(), 5, BoxWidth(), 35, ARGB(255,255,0,0), 1)
			DrawTextA(hero.charName, 13, CalculateXtext(i) , 6, ColorDraw(hero), "center")
			DrawTextA("Lvl "..tostring(hero.level), 13, CalculateXtext(i), 16, ColorDraw(hero), "center")
			DrawTextA(tostring(math.round(hero.health).."/"..tostring(math.round(hero.maxHealth))), 13, CalculateXtext(i), 26, ColorDraw(hero), "center")
		end
	end
end


function CalculateXBox()
	return (WINDOW_W/2)-(GetNumberEnemies()*(460/5))/2
end

function BoxWidth()
	return GetNumberEnemies()*(460/5)
end

function CalculateXtext(i)
	return CalculateXBox()+BoxWidth()-i*(BoxWidth())/GetNumberEnemies()+40
end

function GetNumberEnemies()
	local enemies = 0
	for i=1, heroManager.iCount, 1 do
		local hero = heroManager:getHero(i)
		if hero.team ~= myHero.team then
			enemies = enemies+1
		end
	end
	return enemies
end

function ColorDraw(hero)
	if not hero.visible then
		return ARGB(255,130,0,255)
	elseif hero.health >= hero.maxHealth*0.5 then
		return ARGB(255,0,255,55)
	elseif hero.health < hero.maxHealth*0.5 and hero.health >= hero.maxHealth*0.25 then
		return ARGB(255,255,125,0)
	elseif hero.health < hero.maxHealth*0.25 and not hero.dead then
		return ARGB(255,255,0,0)
	elseif hero.dead then
		return ARGB(255,128,128,128)
	end
end

function Variables()
	EnemyHeroes = GetEnemyHeroes()
end

function Menus()
	RoamerHelper = scriptConfig(" HP Helper", " HPHelper0.1")
	
	RoamerHelper:addParam("drawlife", "Draw Lifebars", SCRIPT_PARAM_ONOFF, true)
end