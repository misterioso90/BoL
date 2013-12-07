
--Lee Sin Jumper by BotHappy

if myHero.charName ~= "LeeSin" then return end

function OnLoad()
	Variables()
	PrintChat("<font color='#FFFFFF'> >> Lee Sin Jumper loaded! << </font>")
end

function OnTick()
	Checks()
	if IsKeyDown(GetKey(KEY)) then WardJump() end
	Reset()
end

function OnDraw()
	DrawCircle(myHero.x, myHero.y, myHero.z, WardRange, 0xFF00FF)
end

function Variables()
	KEY = "G"
	WardTable = {}
	WardReady = false
	--Trinket ID for future updates
	----3340,3350,3361,3362 - Warding Totem, Greater Totem, Greater Stealth Totem, Greater Vision Totem
	
	SWard, VWard, SStone, RSStone, Wriggles = 2044, 2043, 2049, 2045, 3154
	SWardSlot, VWardSlot, SStoneSlot, RSStoneSlot, WrigglesSlot = nil, nil, nil, nil, nil
	RSStoneReady, SStoneReady, SWardReady, VWardReady, WrigglesReady = false, false, false, false, false
	WardRange = 600
	wRange = 700
	
end

function Checks()
	W1Ready = ((myHero:CanUseSpell(_W) == READY) and myHero:GetSpellData(_W).name == "BlindMonkWOne")
	
	--Ward Check
	SWardSlot = GetInventorySlotItem(SWard)
	VWardSlot = GetInventorySlotItem(VWard)
	SStoneSlot = GetInventorySlotItem(SStone) 
	RSStoneSlot = GetInventorySlotItem(RSStone)
	WrigglesSlot = GetInventorySlotItem(Wriggles)
	--Ward Checks
	RSStoneReady = (RSStoneSlot ~= nil and CanUseSpell(RSStoneSlot) == READY)
	SStoneReady = (SStoneSlot ~= nil and CanUseSpell(SStoneSlot) == READY)
	SWardReady = (SWardSlot ~= nil and CanUseSpell(SWardSlot) == READY)
	VWardReady = (VWardSlot ~= nil and CanUseSpell(VWardSlot) == READY)
	WrigglesReady = (WrigglesSlot ~= nil and CanUseSpell(WrigglesSlot) == READY)
	--Got a ward to place to jump
	GotWard = WrigglesReady or RSStoneReady or SStoneReady or SWardReady or VWardReady
end

function Reset()
	if not IsKeyDown(GetKey(KEY)) then
		for k,v in pairs(WardTable) do WardTable[k]=nil end
		WardReady = false
	end
end

function WardJump()
	MoveToCursor()
	local Coordenates = mousePos
	if W1Ready and GetDistance(Coordenates) <= WardRange and GotWard and not WardReady then
		if RSStoneReady then
			CastSpell(RSStoneSlot, Coordenates.x, Coordenates.z)
			WardReady = true
		elseif SStoneReady and not WardReady then
			CastSpell(SStoneSlot, Coordenates.x, Coordenates.z)
			WardReady = true
		elseif WrigglesReady and not WardReady then
			CastSpell(WrigglesSlot, Coordenates.x, Coordenates.z)
			WardReady = true
		elseif SWardReady and not WardReady then
			CastSpell(SWardSlot, Coordenates.x, Coordenates.z)
			WardReady = true
		elseif VWardReady and not WardReady then
			CastSpell(VWardSlot, Coordenates.x, Coordenates.z)
			WardReady = true
		end
	end
	if W1Ready and WardReady then
		for _, Ward in ipairs(WardTable) do
			if GetDistance(Ward) < wRange then
				CastSpell(_W, Ward)
			end
		end
	end
end

function MoveToCursor()
	if GetDistance(mousePos) then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*300
		myHero:MoveTo(moveToPos.x, moveToPos.z)
	end	
end

function OnCreateObj(Object)
	if Object and Object.valid and (string.find(Object.name, "Ward") ~= nil or string.find(Object.name, "Wriggle") ~= nil) then 
		table.insert(WardTable, Object) 
	end
end