local id, e = ...
local Save={}
local addName='ChatButtonGuild'
local button
local panel= CreateFrame("Frame")

local function setMembers()--在线人数
    local num = select(2, GetNumGuildMembers())
    num = (num and num>1) and num-1 or nil
    if not button.membersText and num then
        button.membersText=e.Cstr(button, {size=10, color=true, justifyH='CENTER'})-- 10, nil, nil, true, nil, 'CENTER')
        button.membersText:SetPoint('BOTTOM', 0, 7)
    end
    if button.membersText then
        button.membersText:SetText(num or '')
    end
end

--#######
--公会信息
--#######
local guildMS= GUILD_INFO_TEMPLATE:gsub('(%%.+)', '')--公会创立
local function set_CHAT_MSG_SYSTEM()--事件, 公会新成员, 队伍新成员
    if not IsInGuild() then
        if WoWDate[e.Player.guid] then
            WoWDate[e.Player.guid].GuildInfo=nil
        end
        panel:UnregisterEvent('CHAT_MSG_SYSTEM')
    else
        if Save.guildInfo or not WoWDate[e.Player.guid].GuildInfo then
            panel:RegisterEvent('CHAT_MSG_SYSTEM')
            GuildInfo()
        else
            panel:UnregisterEvent('CHAT_MSG_SYSTEM')
        end
    end
end

local function setMsg_CHAT_MSG_SYSTEM(text)--欢迎加入, 信息
    if text:find(guildMS) then
        WoWDate[e.Player.guid].GuildInfo= text
        panel:UnregisterEvent('CHAT_MSG_SYSTEM')
    end
end

--#####
--主菜单
--#####
local function InitMenu(self, level, type)--主菜单    
    local info
    local find
    for index=1,  GetNumGuildMembers() do
        local name, rankName, rankIndex, lv, _, zone, publicNote, officerNote, isOnline, status, _, _, _, _, _, _, guid = GetGuildRosterInfo(index)
        if name and guid and isOnline and name~=e.Player.name_server then
            find=true
            local map=e.GetUnitMapName('paleyr')
            local text=e.GetPlayerInfo(nil, guid, true, true)--名称
            text=(lv and lv~=MAX_PLAYER_LEVEL) and text..' |cnGREEN_FONT_COLOR:'..lv..'|r' or text--等级
            if zone then--地区
                text= zone==map and text..e.Icon.map2 or text..' '..zone
            end
            text= rankName and text..' '..rankName..(rankIndex or '') or text
            info={
                text=text,
                notCheckable=true,
                tooltipOnButton=true,
                tooltipTitle=publicNote or '',
                tooltipText=officerNote or '',
                icon= status==1 and FRIENDS_TEXTURE_AFK or status==2 and FRIENDS_TEXTURE_DND,
                func=function()
                    e.Say(nil, name)
                end
            }
            securecall('UIDropDownMenu_AddButton', info, level)
        end
    end
    if find then
        securecall('UIDropDownMenu_AddSeparator', level)
    end
    info={
        text=e.onlyChinese and '公会信息' or GUILD_INFORMATION,
        checked=Save.guildInfo,
        tooltipOnButton=true,
        tooltipTitle= WoWDate[e.Player.guid].GuildInfo or NONE,
        func=function()
            Save.guildInfo= not Save.guildInfo and true or nil
            set_CHAT_MSG_SYSTEM()--事件, 公会新成员, 队伍新成员
        end
    }
    securecall('UIDropDownMenu_AddButton', info, level)
end

--####
--初始
--####
local function Init()
    button:SetPoint('LEFT',WoWToolsChatButtonFrame.last, 'RIGHT')--设置位置
    WoWToolsChatButtonFrame.last=button

    button.Menu=CreateFrame("Frame", id..addName..'Menu', button, "UIDropDownMenuTemplate")
    securecall('UIDropDownMenu_Initialize', button.Menu, InitMenu, 'MENU')

    setMembers()--在线人数
    button.texture:SetAtlas('UI-HUD-MicroMenu-GuildCommunities-Up')
    button.texture:SetVertexColor(e.Player.r, e.Player.g, e.Player.b)

    button:SetScript('OnMouseDown', function(self, d)
        if d=='LeftButton' then
            e.Say('/g')
        else
            ToggleDropDownMenu(1,nil,self.Menu, self, 15,0)
            --ToggleGuildFrame()
        end
    end)

    if CanReplaceGuildMaster() then--弹劾
        button.canReplaceGuildMaster=e.Cstr(button, {size=10, color=true, justifyH='CENTER'})--10, nil, nil, true, nil, 'CENTER')
        button.canReplaceGuildMaster:SetPoint('TOP')
        button.canReplaceGuildMaster:SetText('|cnGREEN_FONT_COLOR:'..GUILD_IMPEACH_POPUP_CONFIRM..'|r')
    end

    C_Timer.After(2, set_CHAT_MSG_SYSTEM)--事件, 公会新成员, 队伍新成员
end

--###########
--加载保存数据
--###########
panel:RegisterEvent("ADDON_LOADED")
panel:RegisterUnitEvent('PLAYER_GUILD_UPDATE', "player")

panel:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1==id then
            if not WoWToolsChatButtonFrame.disabled then--禁用Chat Button
                Save= WoWToolsSave[addName] or Save

                button=e.Cbtn2(nil, WoWToolsChatButtonFrame, true, false)

                Init()
                panel:RegisterEvent('PLAYER_LOGOUT')
                panel:RegisterEvent('GUILD_ROSTER_UPDATE')
            end
            panel:UnregisterEvent('ADDON_LOADED')
        end

    elseif event == "PLAYER_LOGOUT" then
        if not e.ClearAllSave then
            WoWToolsSave[addName]=Save
        end

    elseif event=='GUILD_ROSTER_UPDATE' then
        setMembers()--在线人数

    elseif event=='CHAT_MSG_SYSTEM' then
        setMsg_CHAT_MSG_SYSTEM(arg1)--欢迎加入, 信息

    elseif event=='PLAYER_GUILD_UPDATE' then
        set_CHAT_MSG_SYSTEM()--事件, 公会新成员, 队伍新成员
    end
end)