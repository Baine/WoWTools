local id, e = ...
local addName = WORLD_MAP
local addName2=RESET_POSITION:gsub(RESET, PLAYER)
local Save={}
local panel=CreateFrame("Frame")


--###########
--世界地图任务
--###########
local function set_WorldQuestPinMixin_RefreshVisuals(self)----WorldQuestDataProvider.lua self.tagInfo
    if Save.hide then
        if self.str then
            self.str:SetShown(false)
        end
        if self.worldQuestTypeTips then
            self.worldQuestTypeTips:SetShown(false)
        end
        return
    end
    local tagInfo=self.tagInfo
    local itemName, itemTexture, numItems, quality, _, itemID, itemLevel
    itemName, itemTexture, numItems, quality, _, itemID, itemLevel = GetQuestLogRewardInfo(1, self.questID)
    itemLevel= (itemLevel and itemLevel>1) and itemLevel
    if not itemName then
        itemName, itemTexture, numItems, _, quality = GetQuestLogRewardCurrencyInfo(1, self.questID)
    end
    if not itemName then
        itemLevel=GetQuestLogRewardMoney(self.questID)
        if itemLevel then
            itemLevel=e.MK(itemLevel/10000,1)
            itemTexture='interface\\moneyframe\\ui-goldicon'
        end
    end
    self.Texture:SetTexture(itemTexture)
    self.Texture:SetSize(45, 45)
    if not self.str then
        self.str=e.Cstr(self,26)
        self.str:SetPoint('TOP', self, 'BOTTOM', 0, 0)
    end

    local str
    str= itemLevel or (numItems and numItems>1) and numItems--数量

    if str then
        if quality and quality~=1 then
            str='|c'..select(4, GetItemQualityColor(quality))..str..'|r'
        elseif tagInfo.quality==1 then
            str='|cffa335ee'..str..'|r'
        elseif tagInfo.quality==2 then
            str='|cffe6cc80'..str..'|r'
        end
    end

    local setLevelUp
    local itemEquipLoc= itemID and select(4, GetItemInfoInstant(itemID))
    local invSlot = itemEquipLoc and e.itemSlotTable[itemEquipLoc]
    if invSlot and itemName and itemLevel and itemLevel>1 then--装等
        local itemLinkPlayer =  GetInventoryItemLink('player', invSlot)
        if itemLinkPlayer then
            local lv=GetDetailedItemLevelInfo(itemLinkPlayer)
            if lv and itemLevel-lv>0 then
                str= (str or '')..e.Icon.up2
                setLevelUp=true
            end
        end
    end

    if not setLevelUp then
        local sourceID =itemID and select(2, C_TransmogCollection.GetItemInfo(itemID))--幻化
        if sourceID then
            local collectedText, isCollected=e.GetItemCollected(nil, sourceID, true)--物品是否收集 
            if collectedText and not isCollected then
                str=(str or '')..collectedText
            end
        end
    end


    self.str:SetText(str or '')
    self.str:SetShown(str and true or false)

    if self.worldQuestType ~= Enum.QuestTagType.Normal then
        local inProgress = self.dataProvider:IsMarkingActiveQuests() and C_QuestLog.IsOnQuest(self.questID)
        local atlas= QuestUtil.GetWorldQuestAtlasInfo(self.worldQuestType, inProgress, tagInfo.tradeskillLineID, self.questID)
        if not self.worldQuestTypeTips then
            self.worldQuestTypeTips=self:CreateTexture(nil, 'OVERLAY')
            self.worldQuestTypeTips:SetPoint('TOPRIGHT', self.Texture, 'TOPRIGHT', 5, 5)
            self.worldQuestTypeTips:SetSize(30, 30)
        end
        self.worldQuestTypeTips:SetAtlas(atlas)
    end
    if self.worldQuestTypeTips then
        self.worldQuestTypeTips:SetShown(self.worldQuestType ~= Enum.QuestTagType.Normal)
    end
end

--#######
--任务日志
--#######
--local Code=IN_GAME_NAVIGATION_RANGE:gsub('d','s')--%s码    
local function Quest(self, questID)--任务
    if not HaveQuestData(questID) then return end

    self:AddDoubleLine(e.GetExpansionText(nil, questID))--任务版本

    local t=''
    local lv=C_QuestLog.GetQuestDifficultyLevel(questID)--ID
    if lv then t=t..'['..lv..']' else t=t..' 'end
    if C_QuestLog.IsComplete(questID) then t=t..'|cFF00FF00'..(e.onlyChinse and '完成' or COMPLETE)..'|r' else t=t..(e.onlyChinse and '未完成' or INCOMPLETE) end
    if t=='' then t=t..(e.onlyChinse and '任务' or QUESTS_LABEL) end
    t=t..' ID'
    self:AddDoubleLine(t, questID)

    local distanceSq= C_QuestLog.GetDistanceSqToQuest(questID)--距离
    if distanceSq then
        t= ''
        local _, x, y = QuestPOIGetIconInfo(questID)
        if x and y then
            x=math.modf(x*100) y=math.modf(y*100)
            if x and y then t='XY '..x..', '..y end
        end
        self:AddDoubleLine(t,  (e.onlyChinse and '距离' or TRACK_QUEST_PROXIMITY_SORTING)..' '..e.MK(distanceSq))--format(IN_GAME_NAVIGATION_RANGE, e.MK(distanceSq)))
    end
    if IsInGroup() then
        t= e.GetYesNo(C_QuestLog.IsPushableQuest(questID))--共享
        local t2= (e.onlyChinse and '共享' or SHARE_QUEST)..' '
        local u if IsInRaid() then u='raid' else u='party' end
        local n,acceto=GetNumGroupMembers(), 0
        for i=1, n do
            local u2
            if u=='party' and i==n then u2='player' else u2=u..i end
            if C_QuestLog.IsUnitOnQuest(u2, questID) then acceto=acceto+1 end
        end
        t2=t2..acceto..'/'..n
        self:AddDoubleLine(t2, t)
    end
    local all=C_QuestLog.GetAllCompletedQuestIDs()--完成次数
    if all and #all>0 then
        t= GetDailyQuestsCompleted() or '0'
        t=t..(e.onlyChinse and '日常' or DAILY)..' '..#all..(e.onlyChinse and '任务' or QUESTS_LABEL)
        self:AddDoubleLine(e.onlyChinse and '已完成任务' or TRACKER_FILTER_COMPLETED_QUESTS, t)
    end
    --local info=C_QuestLog.GetQuestDetailsTheme(questID)--POI图标
    --if info and info.poiIcon then e.playerTexSet(info.poiIcon, nil) end--设置图,像
    self:Show()
end

local function Coll()
    for i=1, C_QuestLog.GetNumQuestLogEntries() do
        CollapseQuestHeader(i)
    end
end
local function Exp()
    for i=1, C_QuestLog.GetNumQuestLogEntries() do
        ExpandQuestHeader(i)
    end
end
local function setMapQuestList()--世界地图,任务, 加 - + 按钮
    local f=QuestScrollFrame
    if not Save.hide and not f.btn then
        f.btn= CreateFrame("Button", nil, f)
        f.btn:SetPoint('TOP', f,'BOTTOM')
        f.btn:SetSize(20,20)
        f.btn:SetNormalAtlas('campaign_headericon_open')
        f.btn:SetPushedAtlas('campaign_headericon_openpressed')
        f.btn:SetHighlightAtlas('Forge-ColorSwatchSelection')
        f.btn:SetScript("OnMouseDown", function()
                Exp()
        end)
        f.btn:SetFrameStrata('DIALOG')

        f.btn2= CreateFrame("Button", nil, f.btn)
        f.btn2:SetPoint('BOTTOMRIGHT', f.btn, 'BOTTOMLEFT', 2, 0)
        f.btn2:SetSize(20,20)
        f.btn2:SetNormalAtlas('campaign_headericon_closed')
        f.btn2:SetPushedAtlas('campaign_headericon_closedpressed')
        f.btn2:SetHighlightAtlas('Forge-ColorSwatchSelection')
        f.btn2:SetScript("OnMouseDown", function()
                Coll()
        end)
    end
    if f.btn then
        f.btn:SetShown(not Save.hide)
        f.btn2:SetShown(not Save.hide)
    end
end

local function getPlayerXY()--当前世界地图位置
    local uiMapID= C_Map.GetBestMapForUnit("player")--当前地图        
    if uiMapID then
        local position = C_Map.GetPlayerMapPosition(uiMapID, "player")
        if position then
            local x,y
            x,y=position:GetXY()
            if x and y then
                x=('%.1f'):format(x*100)
                y=('%.1f'):format(y*100)
                return x, y
            end
        end
    end
end
local function sendPlayerPoint()--发送玩家位置
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        if  C_Map.CanSetUserWaypointOnMap(mapID) then
            local point=C_Map.GetUserWaypoint()
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            local mapPoint = UiMapPoint.CreateFromVector2D(mapID, pos)
            C_Map.SetUserWaypoint(mapPoint)
            ChatFrame_OpenChat(SELECTED_DOCK_FRAME.editBox:GetText()..C_Map.GetUserWaypointHyperlink())
            if point then
                C_Map.SetUserWaypoint(point)
            else
                C_Map.ClearUserWaypoint()
            end
            return
        else
            local x, y=getPlayerXY()
            if x and y then
                local pointText=x..' '..y
                local info=C_Map.GetMapInfo(mapID)
                if info and info.name then
                    pointText=pointText..' '..info.name
                end
                ChatFrame_OpenChat(SELECTED_DOCK_FRAME.editBox:GetText()..pointText)
                return
            end
        end
    end
    local name=GetMinimapZoneText()
    local name2
    if mapID then
        local info=C_Map.GetMapInfo(mapID)
        name2=info and info.name
    end
    if name  or name2 then
        if name2 and name~=name2 then
            name=name2..'('..name..')'
        end
        name =name or name2
        ChatFrame_OpenChat(SELECTED_DOCK_FRAME.editBox:GetText()..name)
    else
        print("Cannot set waypoints on this map")
    end
end

local function CursorPositionInt()
    local frame=WorldMapFrame
    if not Save.PlayerXY or frame.playerPostionBtn then
        if frame.playerPostionBtn then
            frame.playerPostionBtn:SetShown(Save.PlayerXY)
        end
        return
    end
    frame.playerPostionBtn= e.Cbtn(nil, nil, nil,nil,nil,true,{12,12})-- CreateFrame('Button', nil, UIParent)--实时玩家当前坐标
    if not Save.PlayerXYPoint then
        frame.playerPostionBtn:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT',-50, 5)
    else
        frame.playerPostionBtn:SetPoint(Save.PlayerXYPoint[1], UIParent, Save.PlayerXYPoint[3], Save.PlayerXYPoint[4], Save.PlayerXYPoint[5])
    end

    frame.playerPostionBtn:SetMovable(true)
    frame.playerPostionBtn:RegisterForDrag("RightButton")
    frame.playerPostionBtn:SetClampedToScreen(true)
    frame.playerPostionBtn:SetScript("OnDragStart", function(self2, d)
        if d=='RightButton' and not IsModifierKeyDown() then
            SetCursor('UI_MOVE_CURSOR')
            self2:StartMoving()
        end
    end)
    frame.playerPostionBtn:SetScript("OnDragStop", function(self2, d)
        self2:StopMovingOrSizing()
        Save.PlayerXYPoint={self2:GetPoint(1)}
        Save.PlayerXYPoint[2]=nil
        ResetCursor()
    end)
    frame.playerPostionBtn:SetScript("OnMouseUp", function(self2,d)
       if d=='LeftButton' and not IsModifierKeyDown() then
            sendPlayerPoint()--发送玩家位置
        end
        ResetCursor()
    end)
    frame.playerPostionBtn:SetScript("OnEnter",function(self2)
        e.tips:ClearLines()
        e.tips:SetOwner(self2, "ANCHOR_LEFT")
        e.tips:AddDoubleLine(id, addName2)
        e.tips:AddLine(' ')
        local can
        can= C_Map.GetBestMapForUnit("player")
        can= can and C_Map.CanSetUserWaypointOnMap(can)
        e.tips:AddDoubleLine('|A:Waypoint-MapPin-ChatIcon:0:0|a'..(e.onlyChinse and '发送位置' or RESET_POSITION:gsub(RESET, SEND_LABEL)), (not can and GetMinimapZoneText() or not can and '|cnRED_FONT_COLOR:'..(e.onlyChinse and '无' or NONE)..'|r' or '') ..e.Icon.left)
        e.tips:AddDoubleLine(e.onlyChinse and '大小' or FONT_SIZE, (Save.PlayerXYSize or 12)..e.Icon.mid)
        e.tips:AddDoubleLine(e.onlyChinse and '移动' or NPE_MOVE, e.Icon.right)
        e.tips:Show()
    end)
    frame.playerPostionBtn:SetScript("OnLeave", function()
        e.tips:Hide()
        ResetCursor()
    end)

    frame.playerPostionBtn:SetScript('OnMouseWheel',function(self, d)
        if IsModifierKeyDown() then
            return
        end
        local size=Save.PlayerXYSize or 12
        if d==1 then
            size=size+1
            size = size>72 and 72 or size
        elseif d==-1 then
            size=size-1
            size= size<8 and 8 or size
        end
        Save.PlayerXYSize=size
        e.Cstr(nil, size, nil, self.Text)
        print(id,addName, e.onlyChinse and '大小' or FONT_SIZE, size)
    end)

    frame.playerPostionBtn.Text=e.Cstr(frame.playerPostionBtn, Save.PlayerXYSize)
    frame.playerPostionBtn.Text:SetPoint('RIGHT')

    local timeElapsed = 0
    frame.playerPostionBtn:HookScript("OnUpdate", function (self, elapsed)
        timeElapsed = timeElapsed + elapsed
        if timeElapsed > 0.3 then
            timeElapsed = 0
            local x, y =getPlayerXY()
            if x and y then
                self.Text:SetText(x.. ' '..y)
            else
                self.Text:SetText('..')
            end
        end
    end)
end

local function setOnEnter(self)--地图ID提示
    local frame=WorldMapFrame
    e.tips:SetOwner(self, "ANCHOR_LEFT")
    e.tips:ClearLines()
    e.tips:AddDoubleLine(id, addName)
    e.tips:AddLine(' ')
    if e.Layer then
        e.tips:AddDoubleLine(e.L['LAYER'], e.Layer)
    end
    local uiMapID = frame.mapID or frame:GetMapID("current")
    if uiMapID then
        local info = C_Map.GetMapInfo(uiMapID)
        if info then
            e.tips:AddDoubleLine(info.name, 'mapID '..info.mapID or uiMapID)--地图ID
            local uiMapGroupID = C_Map.GetMapGroupID(uiMapID)
            if uiMapGroupID then
                e.tips:AddDoubleLine(e.onlyChinse and '区域' or FLOOR, 'uiMapGroupID g'..uiMapGroupID)
            end
        end
        local areaPoiIDs=C_AreaPoiInfo.GetAreaPOIForMap(uiMapID)
        if areaPoiIDs then
            for _,areaPoiID in pairs(areaPoiIDs) do
                local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, areaPoiID)
                if poiInfo and (poiInfo.areaPoiID or poiInfo.widgetSetID) then
                    e.tips:AddDoubleLine((poiInfo.atlasName and '|A:'..poiInfo.atlasName..':0:0|a' or '')
                    .. poiInfo.name
                    ..(poiInfo.widgetSetID and 'widgetSetID '..poiInfo.widgetSetID or ''),
                    'areaPoiID '..(poiInfo.areaPoiID or NONE))
                end
            end
        end
        if IsInInstance() then--副本数据
            local instanceID, _, LfgDungeonID =select(8, GetInstanceInfo())
            if instanceID then
                e.tips:AddDoubleLine(e.onlyChinse and '副本' or INSTANCE, instanceID)
                if LfgDungeonID then
                    e.tips:AddDoubleLine(e.onlyChinse and '随机副本' or (SLASH_RANDOM3:gsub('/','')..INSTANCE), LfgDungeonID)
                end
            end
        end
        local x,y =getPlayerXY()
        if x and y then
            local playerCursorMapName
            local uiMapIDPlayer= C_Map.GetBestMapForUnit("player")
            if uiMapIDPlayer and uiMapIDPlayer~=uiMapID then
                local info2 = C_Map.GetMapInfo(uiMapIDPlayer)
                playerCursorMapName=info2 and info2.name
            end
            e.tips:AddLine(' ')
            if playerCursorMapName then
                e.tips:AddDoubleLine(e.Icon.player..playerCursorMapName, 'XY: '..x..' '..y)
            else
                e.tips:AddDoubleLine(e.onlyChinse and '位置' or (RESET_POSITION:gsub(RESET, e.Icon.player)), 'XY: '..x..' '..y)
            end
        end
    end
    e.tips:AddLine(' ')
    e.tips:AddDoubleLine(addName, e.GetEnabeleDisable(not Save.hide)..e.Icon.left)
    e.tips:AddDoubleLine(addName2, e.GetEnabeleDisable(Save.PlayerXY)..e.Icon.right)
    e.tips:Show()
end

local function setMapIDText(self)
    local m=''
    if not Save.hide then
        local uiMapID = self.mapID or self:GetMapID("current")
        m= uiMapID or m
        if uiMapID then
            local uiMapGroupID=C_Map.GetMapGroupID(uiMapID)
            if uiMapGroupID then
                m='g'..uiMapGroupID..'  '..m
            end
            local areaPoiIDs=C_AreaPoiInfo.GetAreaPOIForMap(uiMapID)
            if areaPoiIDs then
                for _,areaPoiID in pairs(areaPoiIDs) do
                    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, areaPoiID)
                    if poiInfo and (poiInfo.areaPoiID or poiInfo.widgetSetID) and poiInfo.atlasName then
                        m='|A:'..poiInfo.atlasName..':0:0|a'..m
                    end
                end
            end
            if IsInInstance() then
                local instanceID, _, LfgDungeonID =select(8, GetInstanceInfo())
                if instanceID then
                    m=INSTANCE..instanceID..'  '..m
                    if LfgDungeonID then
                        m=SLASH_RANDOM3:gsub('/','')..LfgDungeonID..'  '..m
                    end
                end
            end
            if not self.mapInfoBtn.mapID then--字符
                self.mapInfoBtn.mapID=e.Cstr(self.BorderFrame.TitleContainer, nil, WorldMapFrameTitleText)
                self.mapInfoBtn.mapID:SetPoint('RIGHT', self.mapInfoBtn, 'LEFT')
            end
        end
        if e.Layer then
            m = e.Layer..' '..m
        end
    end
    if self.mapInfoBtn.mapID then
        self.mapInfoBtn.mapID:SetText(m)
    end
    self.playerPosition:SetShown(not Save.hide)
end

local function set_Map_ID(self)--显示地图ID
    if not self.mapInfoBtn then
        self.mapInfoBtn=e.Cbtn(self.BorderFrame.TitleContainer)
        if IsAddOnLoaded('Mapster') then
            self.mapInfoBtn:SetPoint('RIGHT', self.BorderFrame.TitleContainer, 'RIGHT', -140,0)
        else
            self.mapInfoBtn:SetPoint('RIGHT', self.BorderFrame.TitleContainer, 'RIGHT', -50,0)
        end

        self.mapInfoBtn:SetNormalAtlas(Save.hide and e.Icon.disabled or e.Icon.map)
        self.mapInfoBtn:SetSize(22,22)
        self.mapInfoBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        self.mapInfoBtn:SetScript('OnEnter', setOnEnter)
        self.mapInfoBtn:SetScript('OnLeave', function() e.tips:Hide() end)
        self.mapInfoBtn:SetScript('OnMouseDown', function(self2, d)
            if d=="LeftButton" then
                Save.hide= not Save.hide and true or nil
                setMapIDText(self)
                setMapQuestList()--世界地图,任务, 加 - + 按钮
                print(id, addName, e.GetShowHide(not Save.hide), e.onlyChinse and ' 刷新' or REFRESH)
                self.mapInfoBtn:SetNormalAtlas(Save.hide and e.Icon.disabled or e.Icon.map)
            elseif d=='RightButton' then--实时玩家当前坐标
                if Save.PlayerXY then
                    Save.PlayerXY=nil
                    print(id, addName, addName2..":", e.GetEnabeleDisable(Save.PlayerXY), '|cnGREEN_FONT_COLOR:'..NEED..'/reload|r')
                else
                    Save.PlayerXY=true
                    print(id, addName, addName2..":", e.GetEnabeleDisable(Save.PlayerXY))
                end
                CursorPositionInt()
            end
        end)
    end

    if not self.playerPosition then--玩家坐标
        self.playerPosition=e.Cbtn(self.BorderFrame.TitleContainer)
        self.playerPosition:SetPoint('LEFT', self.BorderFrame.TitleContainer, 'LEFT', 75, -2)
        self.playerPosition:SetSize(22, 22)
        self.playerPosition:SetNormalAtlas(e.Icon.player:match('|A:(.-):'))
        self.playerPosition:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        self.playerPosition:SetScript('OnLeave', function() e.tips:Hide() end)
        self.playerPosition:SetScript('OnEnter', function(self2)
            e.tips:SetOwner(self2, "ANCHOR_LEFT")
            e.tips:ClearLines()
            e.tips:AddDoubleLine(id, addName)
            e.tips:AddLine(' ')
            local can
            can= C_Map.GetBestMapForUnit("player")
            can= can and C_Map.CanSetUserWaypointOnMap(can)
            e.tips:AddDoubleLine('|A:Waypoint-MapPin-ChatIcon:0:0|a'..(e.onlyChinse and '发送位置' or RESET_POSITION:gsub(RESET, SEND_LABEL)), (not can and GetMinimapZoneText() or not can and '|cnRED_FONT_COLOR:'..(e.onlyChinse and '无' or NONE)..'|r' or '')..e.Icon.left)
            e.tips:AddDoubleLine(e.onlyChinse and '返回当前地图' or (PREVIOUS..REFORGE_CURRENT..WORLD_MAP), e.Icon.right)
            e.tips:Show()
        end)
        self.playerPosition:SetScript('OnMouseDown', function(self2, d)
            if d=='RightButton' then--返回当前地图                
	            self:SetMapID(MapUtil.GetDisplayableMapForPlayer())
            elseif d=='LeftButton' then
                sendPlayerPoint()--发送玩家位置
            end
        end)
        self.playerPosition.Text=e.Cstr(self.playerPosition, nil ,WorldMapFrameTitleText)--玩家当前坐标
        self.playerPosition.Text:SetPoint('LEFT',self.playerPosition, 'RIGHT')
        local timeElapsed2=0
        self.playerPosition:HookScript("OnUpdate", function (self2, elapsed)
            timeElapsed2 = timeElapsed2 + elapsed
            if timeElapsed2 > 0.15 then
                timeElapsed2 = 0
                local text=''
                local x, y= getPlayerXY()--玩家当前坐标
                if x and y then
                    text=x..' '..y
                end
                x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()--当前世界地图位置            
                if x and y then
                    text = text~='' and text..' |cnGREEN_FONT_COLOR:' or text
                    text = text..('%.1f'):format(x*100)..' '..('%.1f'):format(y*100)
                end
                self.playerPosition.Text:SetText(text)
            end
        end)

        --####
        --缩放
        --####
        self.ZoomIn= e.Cbtn(self.playerPosition, nil, nil, nil, nil, true, {18,18})--放大
        self.ZoomIn:SetAlpha(0.3)
        self.ZoomIn:SetPoint('RIGHT',self.playerPosition, 'LEFT', -2, 0)
        self.ZoomIn:SetNormalAtlas('UI-HUD-Minimap-Zoom-In')
        self.ZoomIn:SetScript('OnMouseDown', function(s)
            local n= Save.scale or 1
            n= n+ 0.05
            n= n>2 and 2 or n
            Save.scale=n
            WorldMapFrame:SetScale(n)
            print(id, addName, e.onlyChinse and '缩放' or UI_SCALE, n)
        end)
        self.ZoomOut= e.Cbtn(self.playerPosition, nil, nil, nil, nil, true, {18,18})--缩小
        self.ZoomOut:SetPoint('RIGHT',self.ZoomIn, 'LEFT')
        self.ZoomOut:SetAlpha(0.3)
        self.ZoomOut:SetNormalAtlas('UI-HUD-Minimap-Zoom-Out')
        self.ZoomOut:SetScript('OnMouseDown', function(s)
            local n= Save.scale or 1
            n= n- 0.05
            n= n< 0.5 and 0.5 or n
            Save.scale=n
            WorldMapFrame:SetScale(n)
            print(id, addName, e.onlyChinse and '缩放' or UI_SCALE, n)
        end)
    end

    setMapIDText(self)
end

local function set_AreaPOIPinMixin_OnAcquired(poiInfo)--地图POI提示 AreaPOIDataProvider.lua
    if not poiInfo or Save.hide then
        if poiInfo and poiInfo.Str then
            poiInfo.Str:SetText('')
        end
        return
    end

    local t=''
    if poiInfo.widgetSetID==399 then --托尔加斯特
        local R={}
        local sets = C_UIWidgetManager.GetAllWidgetsBySetID(399) or {}
        for _,v in ipairs(sets) do
            local widgetInfo = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(v.widgetID)
            if widgetInfo and widgetInfo.shownState == Enum.WidgetShownState.Shown then
                R[widgetInfo.orderIndex] = widgetInfo.text
            end
        end
        for i,v in pairs(R) do
            if i%2 ==0 then
                local name = string.gsub(v,'|n','')
                local leveltext =string.gsub(R[i+1],'|n','')
                R[i] = string.format("%s-%s",name,leveltext)
                R[i+1] = nil
            end
        end
        t=C_AreaPoiInfo.GetAreaPOIInfo(1543,6640).name
        for _,v in pairs(R) do
            t=t..'\n '..v
        end
    elseif poiInfo.name then
        t=poiInfo.name
        local ds=poiInfo.description
        if not t or #t<1 or t:find(COVENANT_UNLOCK_TRANSPORT_NETWORK) or (ds and ds:find(ANIMA_DIVERSION_ORIGIN_TOOLTIP )) then
            if poiInfo.Str then poiInfo.Str:SetText('') end
            return
        end
        t=t:match('%((.+)%)') or t
        t=t:match('（(.+)）') or t
        t=t:match(',(.+)') or t
        t=t:match(UNITNAME_SUMMON_TITLE14:gsub('%%s','%(%.%+%)')) or t
        t=t:gsub(PET_ACTION_MOVE_TO,'')
        t=t:gsub(SPLASH_BATTLEFORAZEROTH_8_1_0_FEATURE2_TITLE..':','')
        t=t:gsub(SPLASH_BATTLEFORAZEROTH_8_1_0_FEATURE2_TITLE..'：','')
    end

    if t~='' and not poiInfo.Str then
        poiInfo.Str=e.Cstr(poiInfo, 10, nil, nil, nil, nil, 'CENTER')
        poiInfo.Str:SetPoint('BOTTOM', poiInfo, 'TOP', 0, -3)
    end

    if poiInfo.areaPoiID and C_AreaPoiInfo.IsAreaPOITimed(poiInfo.areaPoiID) then
        local seconds= C_AreaPoiInfo.GetAreaPOISecondsLeft(poiInfo.areaPoiID)
        if seconds and seconds>0 then
            t= t~='' and t..'\n' or t
            t= t..'|cnGREEN_FONT_COLOR:'..SecondsToTime(seconds)..'|r'
        end
    end
    if poiInfo.Str then
        poiInfo.Str:SetText(t)
    end
end



--####
--初始
--####
local function Init()
    hooksecurefunc(WorldQuestPinMixin, 'RefreshVisuals', set_WorldQuestPinMixin_RefreshVisuals)--世界地图任务
    hooksecurefunc(WorldMapFrame, 'OnMapChanged', set_Map_ID)--Blizzard_WorldMap.lua
    CursorPositionInt()
    hooksecurefunc(AreaPOIPinMixin,'OnAcquired', set_AreaPOIPinMixin_OnAcquired)--地图POI提示 AreaPOIDataProvider.lua

    --#######
    --任务日志
    --#######
    setMapQuestList()--世界地图,任务, 加 - + 按钮
    hooksecurefunc("QuestMapLogTitleButton_OnEnter", function(self)--任务日志 显示ID
        if Save.hide or not self.questLogIndex then
            return
        end
        local info = C_QuestLog.GetInfo(self.questLogIndex)
        if not info or not info.questID then return end
        Quest(e.tips, info.questID)
    end)

    hooksecurefunc('QuestMapLogTitleButton_OnClick',function(self, button)--任务日志 展开所有, 收起所有--QuestMapFrame.lua
        if Save.hide or ChatEdit_TryInsertQuestLinkForQuestID(self.questID) then
            return
        end
        if self.questID and not C_QuestLog.IsQuestDisabledForSession(self.questID) and button == "RightButton" then
            UIDropDownMenu_AddSeparator()
            local info= {
                text= (e.onlyChinse and '显示' or SHOW)..'|A:campaign_headericon_open:0:0|a'..(e.onlyChinse and '全部' or ALL),
                notCheckable=true,
                func= Exp,
            }
            UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
            info ={
                notCheckable=true,
                text= (e.onlyChinse and '隐藏' or HIDE)..'|A:campaign_headericon_closed:0:0|a'..(e.onlyChinse and '全部' or ALL),
                func= Coll,
            }
            UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

            UIDropDownMenu_AddSeparator()
            local text= '|cnRED_FONT_COLOR:'..(e.onlyChinse and '放弃|A:groupfinder-icon-redx:0:0|a所有任务' or (ABANDON_QUEST..'|A:groupfinder-icon-redx:0:0|a'..ALL))..' #'..select(2, C_QuestLog.GetNumQuestLogEntries())..'|r'
            info={
                text= text,
                tooltipOnButton=true,
                tooltipTitle= '|cffff0000'..(e.onlyChinse and '危险！' or VOICEMACRO_1_Sc_0)..'|r',
                tooltipText= id..' '..addName,
                notCheckable=true,
                func= function()
                    StaticPopupDialogs[id..addName.."ABANDON_QUEST"] = {
                        text = ABANDON_QUEST_CONFIRM,
                        button1 = text,
                        button2 = e.onlyChinse and '取消' or CANCEL,
                        OnAccept = function(self2)
                            local n=0
                            for index=1 , C_QuestLog.GetNumQuestLogEntries() do
                                local questInfo=C_QuestLog.GetInfo(index)
                                if questInfo and questInfo.questID and C_QuestLog.CanAbandonQuest(questInfo.questID) then
                                    local linkQuest=GetQuestLink(questInfo.questID)
                                    C_QuestLog.SetSelectedQuest(questInfo.questID)
                                    C_QuestLog.SetAbandonQuest();
                                    C_QuestLog.AbandonQuest()
                                    n=n+1
                                    if linkQuest then
                                        print(id, addName,  e.onlyChinse and '放弃|A:groupfinder-icon-redx:0:0|a' or (ABANDON_QUEST_ABBREV..'|A:groupfinder-icon-redx:0:0|a'), linkQuest, n)
                                    end
                                end
                                if IsModifierKeyDown() then
                                    break
                                end
                            end
                            PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
                        end,
                        timeout = 0,
                        whileDead = 1,
                        exclusive = 1,
                        hideOnEscape = 1
                    }
                    StaticPopup_Show(id..addName.."ABANDON_QUEST", '\n'..text)
                end
            }
            UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
        end
    end)

    if Save.scale and Save.scale~=1 then--缩放
        WorldMapFrame:SetScale(Save.scale)
    end
end

--加载保存数据
panel:RegisterEvent("ADDON_LOADED")
panel:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1==id then
            Save= WoWToolsSave and WoWToolsSave[addName] or Save

            --添加控制面板        
            local sel=e.CPanel(e.onlyChinse and '地图' or addName, not Save.disabled)
            sel:SetScript('OnMouseDown', function()
                Save.disabled= not Save.disabled and true or nil
                print(id, addName, e.GetEnabeleDisable(not Save.disabled), e.onlyChinse and '需要重新加载' or REQUIRES_RELOAD)
            end)

            if Save.disabled then
                panel:UnregisterAllEvents()
            else
                Init()
            end
            panel:RegisterEvent("PLAYER_LOGOUT")

    elseif event == "PLAYER_LOGOUT" then
        if not e.ClearAllSave then
            if not WoWToolsSave then WoWToolsSave={} end
            WoWToolsSave[addName]=Save
        end
    end
end)