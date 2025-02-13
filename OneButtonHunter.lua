local GT = GetTime

OBH = {}
OBH.t = CreateFrame("GameTooltip", "OBH_T", UIParent, "GameTooltipTemplate")
OBH.f = CreateFrame("Frame", "OBH_Events", UIParent)
OBH.f:RegisterEvent("START_AUTOREPEAT_SPELL")
OBH.f:RegisterEvent("STOP_AUTOREPEAT_SPELL")
OBH.auto = false
OBH.next = nil;
OBH.f:SetScript("OnEvent", function(self, event) 
	if OBH.auto then
		OBH.auto = false
		OBH.next = nil
	else
		OBH.next = GT() + UnitRangedDamage("player")
		OBH.auto = true
	end
end)
OBH.f:SetScript("OnUpdate", function(self, elapsed) 
	if OBH.auto then
		local time = GT()
		if OBH.next<time then
			OBH.next = time + UnitRangedDamage("player")
		end
	end
end)
if GetLocale() == "deDE" then
	OBH.name = {
		[1] = "Schnellfeuer",
		[2] = "Schnelle Schüsse",
		[3] = "Gezielter Schuss",
		[4] = "Mehrfachschuss",
		[5] = "Automatischer Schuss",
		[6] = "Anlegen: Erhöht das Distanzangriffstempo um (%d+)%%%."
	}
else
	OBH.name = {
		[1] = "Rapid Fire",
		[2] = "Quick Shots",
		[3] = "Aimed Shot",
		[4] = "Multi-Shot",
		[5] = "Auto Shot",
		[6] = "Equip: Increases ranged attack speed by (%d+)%%%."
	}
end
OBH.Quiver = nil
function OBH:GetQuiverSpeed()
	OBH_T:SetOwner(UIParent, "ANCHOR_NONE")
	OBH_T:ClearLines()
	OBH_T:SetInventoryItem("player", 23)
	local msg = OBH_TTextLeft4:GetText()
	if msg then
		for a in string.gfind(msg, self.name[6]) do
			self.Quiver = 1 + tonumber(a)/100;
		end
	end
	OBH_T:Hide()
end

function OBH:Active(a)
	for i=0, 32 do
		OBH_T:SetOwner(UIParent, "ANCHOR_NONE")
		OBH_T:ClearLines()
		OBH_T:SetPlayerBuff(GetPlayerBuff(i, "HELPFUL"))
		local buff = OBH_TTextLeft1:GetText()
		OBH_T:Hide()
		if (not buff) then break end
		if string.find(buff, a) then
			return true
		end
	end
	return false
end

function OBH:GetActionSlot(a)
	for i=1, 100 do
		OBH_T:SetOwner(UIParent, "ANCHOR_NONE")
		OBH_T:ClearLines()
		OBH_T:SetAction(i)
		local ab = OBH_TTextLeft1:GetText()
		OBH_T:Hide()
		if ab == a then
			return i;
		end
	end
	return 2;
end

OBH.rf = 1
OBH.qs = 1
OBH.as = 3
OBH.ts = 1  -- Trueshot cast time
OBH.tsSlot = nil  -- Trueshot action slot
OBH.autoSlot = nil
OBH.asSlot = nil

-- Add a flag for Auto Shot
OBH.autoInProgress = false

OBH.trueshotBuffer = 1  -- 0.5-second buffer
OBH.lastTrueShotTime = 0
OBH.trueShotCooldown = 0.5  -- 0.5-second cooldown after Trueshot
OBH.trueShotReady = true  -- Flag for Trueshot availability

-- Function with Multi-Shot and Trueshot
function OBH:Run()
    local currentTime = GT()
    
    if not OBH.trueShotReady and (currentTime - OBH.lastTrueShotTime) >= OBH.trueShotCooldown then
        OBH.trueShotReady = true
    end
    
    if not self.autoSlot then self.autoSlot = self:GetActionSlot(self.name[5]) end
    if not self.tsSlot then self.tsSlot = self:GetActionSlot("Trueshot") end
    
    if self.next then
        if self:Active(self.name[1]) then self.rf = 1.4 else self.rf = 1 end
        if self:Active(self.name[2]) then self.qs = 1.3 else self.qs = 1 end
        if not self.Quiver then self:GetQuiverSpeed() end
        self.as = self.ts / ((self.Quiver or 1) * (self.rf or 1) * (self.qs or 1))
        
        if (self.next - currentTime) > self.as and GetActionCooldown(self.tsSlot) == 0 and OBH.trueShotReady then
            CastSpellByName("Trueshot")
            OBH.lastTrueShotTime = currentTime
            OBH.trueShotReady = false
            return
        end
        CastSpellByName(self.name[4])  -- Multi-Shot
    else
        if not IsCurrentAction(self.autoSlot) then
            UseAction(self.autoSlot)  -- Auto Shot
        end
    end
end

-- Function without Multi-Shot, only Trueshot
function OBH:Runnomulti()
    local currentTime = GT()
    
    if not OBH.trueShotReady and (currentTime - OBH.lastTrueShotTime) >= OBH.trueShotCooldown then
        OBH.trueShotReady = true
    end

    local autoShotReady = (self.next and (self.next - currentTime) <= self.as)
    
    if not self.autoSlot then self.autoSlot = self:GetActionSlot(self.name[5]) end
    if not self.tsSlot then self.tsSlot = self:GetActionSlot("Trueshot") end
    
    if self.next then
        if self:Active(self.name[1]) then self.rf = 1.4 else self.rf = 1 end
        if self:Active(self.name[2]) then self.qs = 1.3 else self.qs = 1 end
        if not self.Quiver then self:GetQuiverSpeed() end
        self.as = self.ts / ((self.Quiver or 1) * (self.rf or 1) * (self.qs or 1))
        
        if (self.next - currentTime) > self.as and GetActionCooldown(self.tsSlot) == 0 and OBH.trueShotReady and not autoShotReady then
            CastSpellByName("Trueshot")
            OBH.lastTrueShotTime = currentTime
            OBH.trueShotReady = false
            return
        end
    else
        if not IsCurrentAction(self.autoSlot) then
            UseAction(self.autoSlot)  -- Auto Shot
        end
    end
end

