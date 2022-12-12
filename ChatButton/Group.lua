local id, e = ...
local addName= 'ChatButtonGroup'
local Save={
    mouseUP='%s求拉, 3Q',
    mouseDown='1',
}

local panel=e.Cbtn2(nil, WoWToolsChatButtonFrame, true, false)
panel:SetPoint('LEFT',WoWToolsChatButtonFrame.last, 'RIGHT')--设置位置
WoWToolsChatButtonFrame.last=panel

local roleAtlas={
    TANK='groupfinder-icon-role-large-tank',
    HEALER='groupfinder-icon-role-large-heal',
    DAMAGER='groupfinder-icon-role-large-dps',
    NONE='socialqueuing-icon-group',
}

local function setType(text)--使用,提示
    if not panel.typeText then
        panel.typeText=e.Cstr(panel, 10, nil, nil, true)
        panel.typeText:SetPoint('BOTTOM',0,2)
    end
    if panel.type and text:find('%w') then--处理英文
        text=panel.type:gsub('/','')
    else
        text= text==RAID_WARNING and COMMUNITIES_NOTIFICATION_SETTINGS_DIALOG_SETTINGS_LABEL or text--团队通知->通知
        text=e.WA_Utf8Sub(text, 1)
    end

    panel.typeText:SetText(text)
    panel.typeText:SetShown(IsInGroup())
end

local function setGroupTips()--队伍信息提示
    local isInGroup= IsInGroup()
    local isInRaid= IsInRaid()
    local isInInstance= IsInInstance()
    local num=GetNumGroupMembers()

    if not panel.type then
        if isInRaid then
            panel.type=SLASH_RAID2
            setType(RAID)--使用,提示
        elseif isInGroup then
            panel.type=SLASH_PARTY1
            setType(HUD_EDIT_MODE_SETTING_UNIT_FRAME_GROUPS)--使用,提示
        end
    end

    if isInGroup and not panel.membersText then--人数
        panel.membersText=e.Cstr(panel, 10, nil, nil, true)
        panel.membersText:SetPoint('TOPLEFT', 3, -3)
    end
    if panel.membersText then
        panel.membersText:SetText(isInGroup and num or '')
    end

    local subgroup, combatRole
    local tab=e.GroupGuid[UnitGUID('player')]
    if tab then
        subgroup= tab and tab.subgroup
        combatRole=tab.combatRole
    end

    if subgroup and not panel.subgroupTexture then--小队号
        panel.subgroupTexture=e.Cstr(panel, 10, nil, nil, true, nil, 'RIGHT')
        panel.subgroupTexture:SetPoint('TOPRIGHT',-6,-3)
        panel.subgroupTexture:SetTextColor(0,1,0)
    end
    if panel.subgroupTexture then
        panel.subgroupTexture:SetText(subgroup or '')
    end

    if isInRaid and not isInInstance and not panel.textureNotInstance then--在副本外, 在团时, 提示
        panel.textureNotInstance=panel:CreateTexture(nil,'BACKGROUND')
        panel.textureNotInstance:SetAllPoints(panel)
        panel.textureNotInstance:SetAtlas('socket-punchcard-red-background')
    end
    if panel.textureNotInstance then
        panel.textureNotInstance:SetShown(isInRaid and not isInInstance)
    end

    if isInGroup then--职责提示
        panel.texture:SetAtlas( roleAtlas[combatRole] or roleAtlas['NONE'])
    else
        panel.texture:SetAtlas('socialqueuing-icon-group')
    end
    --panel.texture:SetDesaturated(not isInGroup)
    --panel.texture:SetShown(isInGroup)

    if panel.typeText then
        panel.typeText:SetShown(isInGroup)
    end
end

local function setText(text)--处理%s
    local groupTab=e.GroupGuid[UnitGUID('player')]
    if text:find('%%s') and groupTab.subgroup then
        text= text:format(groupTab.subgroup..' '..GROUP..' ')
    else
        text= text:gsub('%%s','')
    end
    return text
end


--#####
--对话框
--#####
StaticPopupDialogs[id..addName..'CUSTOM']={--区域,设置对话框
    text=id..'    '..addName..'\n\n'..CUSTOM..SEND_MESSAGE..'\n\n|cnGREEN_FONT_COLOR:%s\n%%s|r '..AUTOCOMPLETE_LABEL_GROUP..LFG_LIST_CROSS_FACTION:format(RAID),
    whileDead=1,
    hideOnEscape=1,
    exclusive=1,
	timeout = 60,
    hasEditBox=1,
    button1=SLASH_CHAT_MODERATE2:gsub('/',''),
    button2=CANCEL,
    OnShow = function(self, data)
        self.editBox:SetWidth(self:GetWidth()-30)
        if Save[data.type] then
            self.editBox:SetText(Save[data.type])
        end
	end,
    OnAccept = function(self, data)
		local text= self.editBox:GetText()
        if text:gsub(' ','')=='' then
            Save[data.type]=nil
        else
            Save[data.type]=text
        end
    end,
    EditBoxOnTextChanged=function(self, data)
        local text= self:GetText()
        if text:gsub(' ','')=='' then
            self:GetParent().button1:SetText(REMOVE)
        else
            self:GetParent().button1:SetText(SLASH_CHAT_MODERATE2:gsub('/',''))
        end
    end,
    EditBoxOnEscapePressed = function(s)
        s:GetParent():Hide()
    end,
}



--#####
--主菜单
--#####
local chatType={
    {text= RAID, type= SLASH_RAID2},--/raid
    {text= HUD_EDIT_MODE_SETTING_UNIT_FRAME_GROUPS, type= SLASH_PARTY1},--/p
    {text= RAID_WARNING, type= 	SLASH_RAID_WARNING1},--/rw
    {text= INSTANCE, type= SLASH_INSTANCE_CHAT1},--/i
}
local function InitMenu(self, level, type)--主菜单
    local info
    if type then
        local tab2={
            {type= 'mouseUP', text= KEY_MOUSEWHEELUP},
            {type= 'mouseDown', text= KEY_MOUSEWHEELDOWN},
        }
        for _, tab in pairs(tab2) do
            local text=(Save[tab.type] or tab.text)
            if Save[tab.type] then
                text=setText(text)--处理%s
            end
            info={
                text= text,
                notCheckable=true,
                tooltipOnButton=true,
                tooltipTitle=tab.text,
                func=function()
                    StaticPopup_Show(id..addName..'CUSTOM', tab.text, nil , {type=tab.type})
                end
            }
            UIDropDownMenu_AddButton(info, level)
        end
    else
        local isInGroup= IsInGroup()
        local isInRaid= IsInRaid()
        local isInInstance= IsInInstance()
        local num=GetNumGroupMembers()
        local le=UnitIsGroupAssistant('player') or  UnitIsGroupLeader('player')

        for _, tab in pairs(chatType) do
            info={
                text=tab.text,
                notCheckable=true,
                tooltipOnButton=true,
                tooltipTitle=tab.type,
                func=function()
                    e.Say(tab.type)
                    panel.type=tab.type
                    setType(tab.text)--使用,提示
                end
            }
            if (tab.text==RAID and not isInRaid)--设置颜色
                or (tab.text==HUD_EDIT_MODE_SETTING_UNIT_FRAME_GROUPS and not isInGroup)
                or (tab.text== INSTANCE and (not isInInstance or num<2))
                or (tab.text==RAID_WARNING and (not isInRaid or not le))
            then
                info.colorCode='|cff606060'
            elseif tab.text==RAID and not isInInstance then--在副本外,团
                info.colorCode='|cffff0000'
            end
            UIDropDownMenu_AddButton(info, level)
        end

        UIDropDownMenu_AddSeparator(level)
        info={
            text=((Save.mouseDown or Save.mouseUP) and e.Icon.mid or '').. (e.onlyChinse and '自定义' or CUSTOM),
            notCheckable=true,
            menuList='CUSTOM',
            hasArrow=true,
        }
        UIDropDownMenu_AddButton(info, level)
    end
end
--####
--初始
--####
local function Init()
    panel.Menu=CreateFrame("Frame",nil, panel, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(panel.Menu, InitMenu, 'MENU')

    if IsInRaid() then
        panel.type=SLASH_RAID2
        setType(RAID)--使用,提示
    elseif IsInGroup() then
        panel.type=SLASH_PARTY1
        setType(HUD_EDIT_MODE_SETTING_UNIT_FRAME_GROUPS)--使用,提示
    end

    panel.texture:SetAtlas('socialqueuing-icon-group')
    panel:SetScript('OnMouseDown', function(self, d)
        if d=='LeftButton' and panel.type then
            e.Say(panel.type)
        else
            ToggleDropDownMenu(1,nil,self.Menu, self, 15,0)
        end
    end)

    panel:SetScript('OnMouseWheel', function(self, d)--发送自定义信息
        local text= d==1 and Save.mouseUP or d==-1 and Save.mouseDown
        if text then
            text=setText(text)--处理%s
            e.Chat(text, nil, true)
        end
    end)

    C_Timer.After(0.3, function() setGroupTips() end)--队伍信息提示
end

--###########
--加载保存数据
--###########
panel:RegisterEvent("ADDON_LOADED")
panel:RegisterEvent("PLAYER_LOGOUT")

panel:RegisterEvent('GROUP_LEFT')
panel:RegisterEvent('GROUP_ROSTER_UPDATE')

panel:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1==id then
        if WoWToolsChatButtonFrame.disabled then--禁用Chat Button
            panel:UnregisterAllEvents()
        else
            Save= WoWToolsSave and WoWToolsSave[addName] or Save
            Init()
        end

    elseif event == "PLAYER_LOGOUT" then
        if not e.ClearAllSave then
            if not WoWToolsSave then WoWToolsSave={} end
            WoWToolsSave[addName]=Save
        end

    elseif event=='GROUP_ROSTER_UPDATE' or event=='GROUP_LEFT' then
        C_Timer.After(0.3, function() setGroupTips() end)--队伍信息提示

    elseif event=='PLAYER_REGEN_ENABLED' then
        set_Shift_Click_facur()--Shift+点击设置焦点
    end
end)