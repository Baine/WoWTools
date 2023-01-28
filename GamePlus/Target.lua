local id, e= ...
local addName= TARGET..COMBAT_ALLY_START_MISSION
local Save= {creatureNum= e.Player.husandro}

local panel= CreateFrame("Frame")
local isPvPArena, isIns

--########################
--怪物目标, 队员目标, 总怪物
--########################

--local distanceSquared, checkedDistance = UnitDistanceSquared(u)
local function set_CreatureNum()
    local k,T,F=0,0,0

    local nameplates= C_NamePlate.GetNamePlates() or {}
    for _, nameplat in pairs(nameplates) do
        local u = nameplat.namePlateUnitToken or (nameplat.UnitFrame and nameplat.UnitFrame.unit)
        local t= u and u..'target'
        if t and UnitExists(u) and not UnitIsDeadOrGhost(u) and not UnitInParty(u) and not UnitIsUnit(u,'player') and (not isPvPArena or (isPvPArena and UnitIsPlayer(u))) then
            if UnitCanAttack('player',u) then
                k=k+1
                if UnitIsUnit(t,'player') then
                    T=T+1
                end
            elseif UnitIsUnit(t,'player') then
                F=F+1
            end
        end
    end
    if IsInGroup() then
        local raid=IsInRaid()
        for i=1, GetNumGroupMembers() do
            local u
            if raid then--团                         
                u='raid'..i
            else--队里
                u='party'..i
            end
            local t=u..'-target'
            if UnitExists(u) and not UnitIsDeadOrGhost(u) and UnitIsUnit(t, 'player') and not UnitIsUnit(u,'player') then
                F=F+1
            end
        end
    end

    panel.Text:SetText((T==0 and '-' or T)..' |cff00ff00'..(F==0 and '-' or F)..'|r '..(k==0 and '-' or k))
end

--#########
--任务，数量
--#########
local THREAT_TOOLTIP_str= THREAT_TOOLTIP:gsub('%%d', '%%d+')--"%d%% 威胁"

local function find_Text(text)
    if text:find('(%d+/%d+)') then
        local min, max= text:match('(%d+)/(%d+)')
        min, max= tonumber(min), tonumber(max)
        if min and max and max> min then
            return max- min
        end
        return true
    elseif text:find('[%d%.]+%%') and not text:find(THREAT_TOOLTIP_str) then
        local value= text:match('([%d%.]+%%)')
        if value and value~='100%' then
            return value
        end
        return true
    end
end
local function Get_Quest_Progress(unit)--GameTooltip.lua --local questID= line and line.id
    if not UnitIsPlayer(unit) then
        local tooltipData = C_TooltipInfo.GetUnit(unit)
        for i = #tooltipData.lines, 5, -1 do
            local line = tooltipData.lines[i]
            TooltipUtil.SurfaceArgs(line)
            local text= line.leftText and find_Text(line.leftText)
            if text then
                return text~=true and text
            end
        end
    end
end

local function set_NAME_PLATE_UNIT_ADDED(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if plate then
        local text= Get_Quest_Progress(unit)
        if text and not plate.questProgress then
            local frame= plate.UnitFrame and plate.UnitFrame.healthBar or plate
            plate.questProgress= e.Cstr(frame, 10, nil, nil, nil, nil,'LEFT')
            plate.questProgress:SetPoint('LEFT', frame, 'RIGHT', 2,0)
        end
        if plate.questProgress then
            plate.questProgress:SetText(text or '')
        end
    end
end

local function set_UNIT_QUEST_LOG_CHANGED()
    local plates= C_NamePlate.GetNamePlates() or {}
    for _, plate in pairs(plates) do
        if plate.questProgress then
            local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
            local text= unit and Get_Quest_Progress(unit)
            plate.questProgress:SetText(text or '')
        end
    end
end

local function set_NAME_PLATE_UNIT_REMOVED(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if plate and plate.questProgress then
        plate.questProgress:SetText('')
    end
end

--####
--事件
--####
local function set_Register_Event()
    panel:UnregisterAllEvents()
    if Save.disabled then
        if panel.Texture then
            panel.Texture:SetShown(false)
        end
        if panel.Text then
            panel.Text:SetText('')
        end
    else
        panel:RegisterEvent('PLAYER_TARGET_CHANGED')
        panel:RegisterEvent('PLAYER_ENTERING_WORLD')
        panel:RegisterEvent('RAID_TARGET_UPDATE')
        panel:RegisterUnitEvent('UNIT_FLAGS', 'target')

        panel:RegisterEvent('PLAYER_REGEN_DISABLED')
        panel:RegisterEvent('PLAYER_REGEN_ENABLED')

        if Save.creatureNum then
            panel:RegisterEvent('UNIT_TARGET')

            panel:RegisterEvent('NAME_PLATE_UNIT_ADDED')
            panel:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
            if not isIns  then
                panel:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
                panel:RegisterEvent('SCENARIO_UPDATE')
                panel:RegisterEvent('SCENARIO_CRITERIA_UPDATE')
                panel:RegisterEvent('SCENARIO_COMPLETED')
            end

        elseif panel.Text then
            panel.Text:SetText('')
        end
    end

    panel:RegisterEvent('PLAYER_LOGOUT')
end


--####
--初始
--####
local function Init()
    panel:SetSize(40, 20)

    panel.Texture= panel:CreateTexture(nil, 'BACKGROUND')
    panel.Texture:SetAtlas('common-icon-rotateright')
    panel.Texture:SetAllPoints(panel)

    panel.Text= e.Cstr(panel, 10, nil, nil, {1,1,1}, 'BORDER', 'RIGHT')
    panel.Text:SetPoint('RIGHT', -8, 0)
    --panel.Text:SetShadowOffset(2, -2)
end

panel:RegisterEvent('ADDON_LOADED')
panel:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1==id then
            Save= WoWToolsSave and WoWToolsSave[addName] or Save

            --添加控制面板        
            local sel=e.CPanel(e.onlyChinse and '目标指示' or addName, not Save.disabled, true)
            sel:SetScript('OnMouseDown', function()
                Save.disabled= not Save.disabled and true or nil
                print(id, addName, e.GetEnabeleDisable(not Save.disabled), e.onlyChinse and '需要重新加载' or REQUIRES_RELOAD)
            end)
            sel:SetScript('OnEnter', function(self2)
                e.tips:SetOwner(self2, "ANCHOR_LEFT")
                e.tips:AddDoubleLine(e.onlyChinse and '显示敌方姓名板' or BINDING_NAME_NAMEPLATES, e.GetEnabeleDisable(C_CVar.GetCVarBool("nameplateShowEnemies")))
                e.tips:Show()
            end)
            sel:SetScript('OnLeave', function() e.tips:Hide() end)

            local sel2=CreateFrame("CheckButton", nil, sel, "InterfaceOptionsCheckButtonTemplate")
            sel2.text:SetText(e.onlyChinse and '怪物数量' or CREATURE..AUCTION_HOUSE_QUANTITY_LABEL)
            sel2:SetPoint('LEFT', sel.text, 'RIGHT')
            sel2:SetChecked(Save.creatureNum)
            sel2:SetScript('OnMouseDown', function()
                Save.creatureNum= not Save.creatureNum and true or nil
                if panel.Text then
                    set_Register_Event()
                    if Save.creatureNum then
                        set_CreatureNum()
                    end
                end
            end)
            sel2:SetScript('OnEnter', function(self2)
                e.tips:SetOwner(self2, "ANCHOR_LEFT")
                e.tips:ClearLines()
                e.tips:AddDoubleLine('|cffffffff'..(e.onlyChinse and '怪物目标' or CREATURE..TARGET), e.onlyChinse and '你' or YOU)
                e.tips:AddDoubleLine('|cnGREEN_FONT_COLOR:'..(e.onlyChinse and '队友目标' or PLAYERS_IN_GROUP ..TARGET), e.onlyChinse and '你' or YOU)
                e.tips:AddDoubleLine('|cffffffff'..(e.onlyChinse and '怪物' or CREATURE), e.onlyChinse and '数量' or AUCTION_HOUSE_QUANTITY_LABEL)
                e.tips:AddLine(' ')
                e.tips:AddDoubleLine(e.onlyChinse and '任务' or QUESTS_LABEL, e.onlyChinse and '数量' or AUCTION_HOUSE_QUANTITY_LABEL)
                e.tips:AddLine(' ')
                e.tips:AddDoubleLine(e.onlyChinse and '显示敌方姓名板' or BINDING_NAME_NAMEPLATES, e.GetEnabeleDisable(C_CVar.GetCVarBool("nameplateShowEnemies")))
                e.tips:Show()
            end)
            sel2:SetScript('OnLeave', function() e.tips:Hide() end)

            set_Register_Event()
            if not Save.disabled then
                Init()
            end
        end

    elseif event == "PLAYER_LOGOUT" then
        if not e.ClearAllSave then
            if not WoWToolsSave then WoWToolsSave={} end
            WoWToolsSave[addName]=Save
        end

    elseif event=='PLAYER_TARGET_CHANGED' or event=='PLAYER_ENTERING_WORLD' or event=='RAID_TARGET_UPDATE' or (event=='UNIT_FLAGS' and arg1=='target') then
        C_Timer.After(0.15, function()
            local plate = C_NamePlate.GetNamePlateForUnit("target")
            if plate then
                local frame
                if plate.UnitFrame then
                    if plate.UnitFrame.RaidTargetFrame and plate.UnitFrame.RaidTargetFrame.RaidTargetIcon:IsShown() then
                        frame= plate.UnitFrame.RaidTargetFrame
                    elseif plate.UnitFrame.ClassificationFrame and plate.UnitFrame.ClassificationFrame.classificationIndicator:IsShown() then
                        frame= plate.UnitFrame.ClassificationFrame.classificationIndicator
                    elseif plate.UnitFrame.healthBar then
                        frame= plate.UnitFrame.healthBar
                    end
                end

                panel:ClearAllPoints()
                panel:SetPoint('RIGHT', frame or plate, 'LEFT')

                if Save.creatureNum then
                    set_CreatureNum()
                end
            end
            panel:SetShown(plate and true or false)
        end)

        if event=='PLAYER_ENTERING_WORLD' then
            isPvPArena= C_PvP.IsBattleground() or C_PvP.IsArena()
            isIns= IsInInstance()
            set_Register_Event()

        end

    elseif event=='PLAYER_REGEN_DISABLED' then--颜色
        panel.Texture:SetVertexColor(1,0,0)

    elseif event=='PLAYER_REGEN_ENABLED' then
        panel.Texture:SetVertexColor(1,1,1)

        panel:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
                panel:RegisterEvent('SCENARIO_UPDATE')
                panel:RegisterEvent('SCENARIO_CRITERIA_UPDATE')
                panel:RegisterEvent('SCENARIO_COMPLETED')
    elseif event=='UNIT_QUEST_LOG_CHANGED' or event=='SCENARIO_UPDATE' or event=='SCENARIO_CRITERIA_UPDATE' or event=='SCENARIO_COMPLETED'then
        set_UNIT_QUEST_LOG_CHANGED()

    else
        if not isIns and arg1 then
            if event=='NAME_PLATE_UNIT_ADDED' then
                set_NAME_PLATE_UNIT_ADDED(arg1)
            elseif event=='NAME_PLATE_UNIT_REMOVED' then
                set_NAME_PLATE_UNIT_REMOVED(arg1)
            end
        end
        if self:IsShown() then
            set_CreatureNum()
        end
    end
end)