local id, e = ...
local addName= POWER_TYPE_FOOD
local Save={
    items={},
    noUseItems={}
}

local panel=e.Cbtn2(nil, WoWToolsMountButton, true, nil)
panel.itemID=5512--治疗石
if not C_Item.IsItemDataCachedByID(panel.itemID) then C_Item.RequestLoadItemDataByID(panel.itemID) end

--#######
--图标冷却
--#######
local function set_Cooldown(self)--图标冷却
    if self.itemID then
        local start, duration = GetItemCooldown(self.itemID)
        e.Ccool(self, start, duration, nil, true, nil, true)--冷却条
    end
end

local function set_Item_Count(self)
    self.count:SetText(GetItemCount(self.itemID))
    self.texture:SetDesaturated(self.count==0)
end

--#########
--提示, 事件
--#########
local function set_Button_Init(self)
    if not C_Item.IsItemDataCachedByID(self.itemID) then C_Item.RequestLoadItemDataByID(self.itemID) end

    panel:SetAttribute("type", "item")
    panel:SetAttribute("item", C_Item.GetItemNameByID(self.itemID))
    panel.texture:SetTexture(C_Item.GetItemIconByID(self.itemID))

    self:SetScript("OnEnter",function(self2)
        e.tips:SetOwner(self2, "ANCHOR_LEFT")
        e.tips:ClearLines()
        e.tips:SetItemByID(self2.itemID)
        e.tips:AddLine(' ')
        if self==panel then
            e.tips:AddDoubleLine(MAINMENU or SLASH_TEXTTOSPEECH_MENU, e.Icon.right)
        else
            e.tips:AddDoubleLine(DISABLE, 'Shift+'..e.Icon.right)
        end
        e.tips:Show()
    end)
    self:SetScript("OnLeave",function() e.tips:Hide() end)

    self.count= e.Cstr(self,nil, nil,nil, true)
    self:RegisterEvent('BAG_UPDATE_DELAYED')
    self:RegisterEvent('BAG_UPDATE_COOLDOWN')
    if self~=panel then
        self:SetScript("OnEvent", function(self2, event)
           if event=='BAG_UPDATE_DELAYED' then
                set_Item_Count(self2)
            elseif event=='BAG_UPDATE_COOLDOWN' then
                set_Cooldown(self2)--图标冷却
            end
        end)
        self:SetScript('OnMouseDown',function(self2, d)
            if d=='RightButton' and IsShiftKeyDown() then
                Save.noUseItems[self2.itemID]=true
                print(id, addName, DISABLE, ITEMS, REQUIRES_RELOAD)
            end
        end)
    end

    set_Item_Count(self2)
    set_Cooldown(self)--图标冷却
end

local function find_Item_Type(class, subclass)
    local tab={}
    for bag=0, NUM_BAG_SLOTS do
        for slot=1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink and info.itemID then
                local classID, subclassID = GetItemInfo(info.hyperlink)
                if classID==class and subclassID==subclass then
                    if not C_Item.IsItemDataCachedByID(info.itemID) then C_Item.RequestLoadItemDataByID(info.itemID) end
                    table.insert(tab, info.itemID)
                end
            end
        end
    end
    return tab
end
local Button={}
local function set_Item_Button()
    local tab=find_Item_Type()
end

--#####
--主菜单
--#####
local function InitMenu(self, level, type)--主菜单

end

--####
--初始
--####
local function Init()
    if Save.point then
        panel:SetPoint(Save.point[1], UIParent, Save.point[3], Save.point[4], Save.point[5])
    else
        panel:SetPoint('RIGHT', WoWToolsOpenItemsButton, 'LEFT')
    end
    local size=e.toolsFrame.size or 30
    panel:SetSize(size,size)
    
    set_Button_Init(panel)--提示, 事件
    
    if Save.autoAdd then
        set_Item_Button()
    end

    panel.Menu=CreateFrame("Frame",nil, panel, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(panel.Menu, InitMenu, 'MENU')

    panel:RegisterForDrag("RightButton")
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:SetScript("OnDragStart", function(self,d )
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        ResetCursor()
        self:StopMovingOrSizing()
        Save.point={self:GetPoint(1)}
        Save.point[2]=nil
    end)
    panel:SetScript("OnMouseDown", function(self,d)
        ToggleDropDownMenu(1,nil,self.Menu, self, 15,0)
    end)
    panel:SetScript("OnMouseUp", function(self, d)
        ResetCursor()
    end)
end

--###########
--加载保存数据
--###########
panel:RegisterEvent("ADDON_LOADED")

panel:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1== id then
        Save= WoWToolsSave and WoWToolsSave[addName..'Tools'] or Save
        if not e.toolsFrame.disabled then
            Init()--初始
        else
            panel:UnregisterAllEvents()
        end
        panel:RegisterEvent("PLAYER_LOGOUT")

    elseif event == "PLAYER_LOGOUT" then
        if not e.ClearAllSave then
            if not WoWToolsSave then WoWToolsSave={} end
            WoWToolsSave[addName..'Tools']=Save
        end

    elseif event=='BAG_UPDATE_DELAYED' then
        set_Item_Count(self)

    elseif event=='BAG_UPDATE_COOLDOWN' then
        set_Cooldown(self)--图标冷却
    end
end)