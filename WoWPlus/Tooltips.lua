local id, e = ...
local addName=MOUSE_LABEL..INFO
local Save={setDefaultAnchor=true,  }
local panel=CreateFrame("Frame")

local function setInitItem(self, hide)--创建物品
    if not self.textLeft then--左上角字符
        self.textLeft=e.Cstr(self, 16)
        self.textLeft:SetPoint('BOTTOMLEFT', self, 'TOPLEFT')
        --self.textLeft:SetPoint('TOPLEFT', self, 'BOTTOMLEFT')下
    end
    if not self.text2Left then--左上角字符2
        self.text2Left=e.Cstr(self, 16)
        self.text2Left:SetPoint('LEFT', self.textLeft, 'RIGHT', 5, 0)
    end
    if not self.textRight then--右上角字符
        self.textRight=e.Cstr(self, 16)
        self.textRight:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT')
        --self.textRight:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT')--下
    end
    if not self.backgroundColor then--背景颜色
        self.backgroundColor=self:CreateTexture(nil,'BACKGROUND')
        self.backgroundColor:SetAllPoints(self)
    end
    if not self.itemModel then--3D模型
        self.itemModel=CreateFrame("PlayerModel", nil, self)
        self.itemModel:SetFacing(0.35)
        self.itemModel:SetPoint("TOPRIGHT", self, 'TOPLEFT')
        self.itemModel:SetSize(250, 250)
    end

    if not self.Portrait then--右上角图标
        self.Portrait=self:CreateTexture(nil, 'BORDER')
        self.Portrait:SetPoint('TOPRIGHT',-2, -3)
        self.Portrait:SetSize(40,40)
        --self.Portrait:SetMask(e.Icon.mask)
    end

    if hide then
        self.textLeft:SetText('')
        self.text2Left:SetText('')
        self.textRight:SetText('')
        self.itemModel:ClearModel()
        self.itemModel:SetShown(false)
        self.Portrait:SetShown(false)
        self.backgroundColor:SetShown(false)
        self.creatureDisplayID=nil--物品
        if self.playerModel then
            self.playerModel:ClearModel()
            self.playerModel:SetShown(false)
            self.playerModel.guid=nil
        end
    end
end

--[[

local function setItemCooldown(self, itemID)--物品冷却
    local startTime, duration, enable = GetItemCooldown(itemID)
    if duration>4 and enable==1 then
        local t=GetTime()
        if startTime>t then t=t+86400 end
        t=t-startTime
        t=duration-t
        self:AddDoubleLine(ON_COOLDOWN, SecondsToTime(t), 1,0,0, 1,0,0)
    end
end

]]

--[[

local function setSpellCooldown(self, spellID)--法术冷却
    local startTime, duration, enable = GetSpellCooldown(spellID)
    if duration and duration>4 and enable==1 and gcdMS~=duration then
        local t=GetTime()
        if startTime>t then t=t+86400 end
        t=t-startTime
        t=duration-t
        self:AddDoubleLine(ON_COOLDOWN, SecondsToTime(t), 1,0,0, 1,0,0)
    end
end

]]


local function GetSetsCollectedNum(setID)--套装收集数
    local info=C_TransmogSets.GetSetPrimaryAppearances(setID) or {}
    local numCollected,numAll=0,0
    for _,v in pairs(info) do
        numAll=numAll+1
        if v.collected then
            numCollected=numCollected + 1
        end
    end
    if numAll>0 then
        if numCollected==numAll then
            return '|cnGREEN_FONT_COLOR:'..COLLECTED..'|r'
        elseif numCollected>0 and numCollected~=numAll then
            return '|cnYELLOW_FONT_COLOR:'..numCollected..'/'..numAll..COLLECTED..'|r'
        elseif numCollected==0 then
            return  '|cnRED_FONT_COLOR:'..NOT_COLLECTED..'|r'
        end
    end
end


local function setMount(self, mountID)--坐骑    
    local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected=C_MountJournal.GetMountInfoByID(mountID)
    self:AddDoubleLine(MOUNTS..'ID: '..mountID, spellID and SUMMON..ABILITIES..'ID: '..spellID)
    if isFactionSpecific then
        self:AddDoubleLine(not faction and ' ' or LFG_LIST_CROSS_FACTION:format(faction==0 and e.Icon.horde2..THE_HORDE or e.Icon.alliance2..THE_ALLIANCE or ''), ' ')
    end
    local creatureDisplayInfoID, description, source, isSelfMount, mountTypeID, uiModelSceneID, animID, spellVisualKitID, disablePlayerMountPreview = C_MountJournal.GetMountInfoExtraByID(mountID)
    if creatureDisplayInfoID then
        self:AddDoubleLine(MODEL..'ID: '..creatureDisplayInfoID, TUTORIAL_TITLE61_DRUID..': '..(isSelfMount and YES or NO))
    end
    if source then
        self:AddDoubleLine(source,' ')
    end
    if creatureDisplayInfoID and self.creatureDisplayID~=creatureDisplayInfoID then--3D模型
        self.itemModel:SetShown(true)
        self.itemModel:SetDisplayInfo(creatureDisplayInfoID)
        self.itemModel:SetAnimation(animID)
        self.creatureDisplayID=creatureDisplayInfoID
    end

    self.text2Left:SetText(isCollected and '|cnGREEN_FONT_COLOR:'..COLLECTED..'|r' or '|cnRED_FONT_COLOR:'..NOT_COLLECTED..'|r')
end

local function setPet(self, speciesID)--宠物
    if not speciesID or speciesID <= 0 then
        return
    end
    local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    self:AddLine(' ')

    if obtainable then--收集数量
        local text, numCollected= e.GetPetCollected(speciesID)
        local numPets, numOwned = C_PetJournal.GetNumPets()
        if numPets and numOwned and numPets>0 then
            self.textRight:SetText(e.MK(numOwned,3)..(numPets>3 and '/'..e.MK(numPets,3).. (' %i%%'):format(numOwned/numPets*100) or ''))
            text= numCollected and numCollected==0 and  text or ' '
            if numCollected and numCollected>0 and not UnitAffectingCombat('player') then
                local text2
                for index= 1 ,numOwned do
                    local petID, speciesID2, _, _, level = C_PetJournal.GetPetInfoByIndex(index)
                    if speciesID2==speciesID and petID and level then
                        local rarity = select(5, C_PetJournal.GetPetStats(petID))
                        local col= rarity and select(4, GetItemQualityColor(rarity-1))
                        if col then
                        text2= text2 and text2..' ' or ''
                        text2= text2..'|c'..col..level..'|r'
                        end
                    end
                end
                if text2 then
                    self.textLeft:SetText(text2)
                end
            end
        end
        self:AddDoubleLine(text, companionID and 'NPC: '..companionID or ' ')
    end
    self:AddDoubleLine(PET..': '..speciesID, MODEL..': '..creatureDisplayID)--ID

    local tab = C_PetJournal.GetPetAbilityListTable(speciesID)--技能图标
    table.sort(tab, function(a,b) return a.level< b.level end)
    local abilityIconA, abilityIconB = '', ''
    for k, info in pairs(tab) do
        local icon, type = select(2, C_PetJournal.GetPetAbilityInfo(info.abilityID))
        icon='|TInterface\\TargetingFrame\\PetBadge-'..PET_TYPE_SUFFIX[type]..':0|t|T'..icon..':0|t'..info.level.. ((k~=3 or k~=6) and '  ' or '')
        if k>3 then
            abilityIconA=abilityIconA..icon
        else
            abilityIconB=abilityIconB..icon
        end
    end
    self:AddDoubleLine(abilityIconA, abilityIconB)    
    self:AddLine(' ')
    self:AddLine(tooltipSource,nil,nil,nil, true)
    --self.Portrait:SetTexture('Interface\\TargetingFrame\\PetBadge-'..PET_TYPE_SUFFIX[petType])--宠物类型图标
    if petType then
        self.Portrait:SetTexture("Interface\\TargetingFrame\\PetBadge-"..PET_TYPE_SUFFIX[petType])
        self.Portrait:SetShown(true)
    end
    if creatureDisplayID and self.creatureDisplayID~=creatureDisplayID then--3D模型
        self.itemModel:SetDisplayInfo(creatureDisplayID)
        self.itemModel:SetShown(true)
        self.creatureDisplayID=creatureDisplayID
    end
end


--############
--设置,物品信息
--############

local function setItem(self, ItemLink)    
    local itemName, _, itemQuality, itemLevel, _, _, _, _, _, _, _, _, _, bindType, expacID, setID = GetItemInfo(ItemLink)
    local itemID, itemType, itemSubType, itemEquipLoc, itemTexture, classID, subclassID = GetItemInfoInstant(ItemLink)
    itemID = itemID or ItemLink:match(':(%d+):')
    local r, g, b, hex= 1,1,1,e.Player.col
    if itemQuality then
        r, g, b, hex= GetItemQualityColor(itemQuality)
        hex=hex and '|c'..hex
    end
    if expacID then--版本数据
        self:AddDoubleLine(e.GetExpansionText(expacID))
    end
    self:AddDoubleLine(itemID and ITEMS..': '.. itemID or ' ' , itemTexture and '|T'..itemTexture..':0|t'..itemTexture)--ID, texture
    if classID and subclassID then
        self:AddDoubleLine((itemType and itemType..' classID'  or 'classID') ..': '..classID, (itemSubType and itemSubType..' subID' or 'subclassID')..': '..subclassID)
    end
    --self.Portrait:SetTexture(itemTexture)
    --self.Portrait:SetShown(true)

    local specTable = GetItemSpecInfo(ItemLink) or {}--专精图标
    local specTableNum=#specTable
    if specTableNum>0 then
        --local num=math.modf(specTableNum/2)
        local specA=''
        local class
        table.sort(specTable, function (a2, b2) return a2<b2 end)
        for k,  specID in pairs(specTable) do
            local icon2, _, classFile=select(4, GetSpecializationInfoByID(specID))
            icon2='|T'..icon2..':0|t'
            specA = specA..((k>1 and class~=classFile) and '  ' or '')..icon2
            class=classFile
        end
        self:AddDoubleLine(specA, ' ')
    end

    local spellName, spellID = GetItemSpell(ItemLink)--物品法术
    if spellName and spellID then
        local spellTexture=GetSpellTexture(spellID)
        self:AddDoubleLine((itemName~=spellName and hex..'['..spellName..']|r'..SPELLS or SPELLS)..': '..spellID, spellTexture and spellTexture~=itemTexture  and '|T'..spellTexture..':0|t'..spellTexture or ' ')
    end

    if classID==2 or classID==4 then
        itemLevel= GetDetailedItemLevelInfo(ItemLink) or itemLevel--装等
        if itemLevel and itemLevel>1 then
            local slot=itemEquipLoc and e.itemSlotTable[itemEquipLoc]--比较装等
            if slot then
                self:AddDoubleLine(_G[itemEquipLoc], TRADESKILL_FILTER_SLOTS..': '..slot)--栏位
                local slotLink=GetInventoryItemLink('player', slot)
                local text
                if slotLink then
                    local slotItemLevel= GetDetailedItemLevelInfo(slotLink)
                    if slotItemLevel then
                        local num=itemLevel-slotItemLevel
                        if num>0 then
                            text=itemLevel..e.Icon.up2..'|cnGREEN_FONT_COLOR:+'..num..'|r'
                        elseif num<0 then
                            text=itemLevel..e.Icon.down2..'|cnRED_FONT_COLOR:'..num..'|r'
                        end
                    end
                else
                    text=itemLevel..e.Icon.up2
                end
                text= text and hex..text..'|r' or ''
                self.textLeft:SetText(text)
            end
        end

        local appearanceID, sourceID =C_TransmogCollection.GetItemInfo(ItemLink)--幻化
        local visualID
        if sourceID then
            local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
            if sourceInfo then
                visualID=sourceInfo.visualID
                self.text2Left:SetText(sourceInfo.isCollected and '|cnGREEN_FONT_COLOR:'..COLLECTED..'|r' or '|cnRED_FONT_COLOR:'..NOT_COLLECTED..'|r')
            end
        end
        if appearanceID and self.creatureDisplayID~=appearanceID then
            self.itemModel:SetItemAppearance(appearanceID, visualID)
            self.itemModel:SetShown(true)
            self.creatureDisplayID=appearanceID
        end
        if bindType==LE_ITEM_BIND_ON_EQUIP or bindType==LE_ITEM_BIND_ON_USE then--绑定装备,使用时绑定
            self.Portrait:SetAtlas(e.Icon.unlocked)
        end
    else
        if setID then--套装
            local collectedNum= GetSetsCollectedNum(setID)
            if collectedNum then
                self.text2Left:SetText(collectedNum)
            end
        elseif C_ToyBox.GetToyInfo(itemID) then--玩具
            self.text2Left:SetText(PlayerHasToy(itemID) and '|cnGREEN_FONT_COLOR:'..COLLECTED..'|r' or '|cnRED_FONT_COLOR:'..NOT_COLLECTED..'|r')
        else
            local mountID = C_MountJournal.GetMountFromItem(itemID)--坐骑物品
            local speciesID = select(13, C_PetJournal.GetPetInfoByItemID(itemID))
            if mountID then
                setMount(self, mountID)--坐骑
            elseif speciesID then
                setPet(self, speciesID)--宠物
            end
        end
    end

    local bag= GetItemCount(ItemLink)--物品数量
    local bank= GetItemCount(ItemLink,true) - bag
    if bag==0 and bank==0 then
        self.textRight:SetText('|cnRED_FONT_COLOR:0|r'..e.Icon.bank2..' |cnRED_FONT_COLOR:'..bag..e.Icon.bag2..'|r')
    else
        self.textRight:SetText(hex..bank..e.Icon.bank2..' '..bag..e.Icon.bag2..'|r')
    end
    if C_Item.IsItemKeystoneByID(itemID) then--挑战
        local numPlayer=1 --帐号数据 --{score=总分数,itemLink={超连接}, weekLevel=本周最高, weekNum=本周次数, all=总次数},
        for guid, info in pairs(e.WoWSave) do
            local find
            for linkItem, _ in pairs(info.Keystone.itemLink) do
               self:AddDoubleLine(' ', linkItem)
               find=true
            end
            if find then
                self:AddDoubleLine(e.GetPlayerInfo(nil, guid, true), guid==e.Player.guid and e.Icon.star2)
            end
        end
       
    else
        local bagAll,bankAll,numPlayer=0,0,0--帐号数据
        for guid, info in pairs(e.WoWSave) do
            if guid~=e.Player.guid then
                local tab=info.Item[itemID]
                if tab then
                    self:AddDoubleLine(e.GetPlayerInfo(nil, guid, true), e.Icon.bag2..tab.bag..(tab.bank>0 and ' '..e.Icon.bank2..tab.bank or ''))
                    bagAll=bagAll +tab.bag
                    bankAll=bankAll +tab.bank
                    numPlayer=numPlayer +1
                end
            end
        end
        if numPlayer>1 then
            self:AddDoubleLine(numPlayer..CHARACTER..e.Icon.wow2..e.MK(bagAll+bankAll, 3), e.Icon.bag2..e.MK(bagAll,3)..(bankAll>0 and ' '..e.Icon.bank2..e.MK(bankAll, 3) or ''))
        end
    end

    --setItemCooldown(self, itemID)--物品冷却

    self.backgroundColor:SetColorTexture(r, g, b, 0.15)--颜色
    self.backgroundColor:SetShown(true)
    self:Show()
end

local function setSpell(self, spellID)--法术
     self.textRight:SetText(spellID)
    
    
    local spellID = select(2, self:GetSpell())
    local spellTexture= spellID and  GetSpellTexture(spellID)
    if not spellID then
        return
    end
    self:AddDoubleLine(SPELLS..'ID: '..spellID, spellTexture and '|T'..spellTexture..':0|t'..spellTexture)
    --self.Portrait:SetTexture(spellTexture)
    --self.Portrait:SetShown(true)

    local mountID = C_MountJournal.GetMountFromSpell(spellID)--坐骑
    if mountID then
        setMount(self, mountID)
    end

    --setSpellCooldown(self, spellID)--法术冷却

end

local function setCurrency(self, currencyID)--货币
    local info2 = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if info2 then
        if not self.Portrait then
            setInitItem(self, hide)--创建物品
        end
        self:AddDoubleLine(TOKENS..'ID: '..currencyID, EMBLEM_SYMBOL..'ID: '..info2.iconFileID)
        self.Portrait:SetTexture(info2.iconFileID)
        self.Portrait:SetShown(true)
    end
    local factionID = C_CurrencyInfo.GetFactionGrantedByCurrency(currencyID)--派系声望
    if factionID and factionID>0 then
        local name= GetFactionInfoByID(factionID)
        if name then
            self:AddDoubleLine(REPUTATION, name)
        end
    end

    local all,numPlayer=0,0
    for guid, info in pairs(e.WoWSave) do--帐号数据
        if guid~=e.Player.guid then
            local quantity=info.Currency[currencyID]
            if quantity then
                self:AddDoubleLine(e.GetPlayerInfo(nil, guid, true), e.MK(quantity, 3))
                all=all+quantity
                numPlayer=numPlayer+1
            end
        end
    end
    if numPlayer>1 then
        self:AddDoubleLine(e.Icon.wow2..numPlayer..CHARACTER, e.MK(all,3))
    end
    self:Show()
end
--[[
local function setAchievement(self, achievementID)--成就
    local _, _, points, completed, _, _, _, _, flags, icon = GetAchievementInfo(achievementID)
    self.textLeft:SetText(points..RESAMPLE_QUALITY_POINT)--点数
    self.text2Left:SetText(completed and '|cnGREEN_FONT_COLOR:'..	CRITERIA_COMPLETED..'|r' or '|cnRED_FONT_COLOR:'..	ACHIEVEMENTFRAME_FILTER_INCOMPLETE..'|r')--否是完成
    if flags== 0x20000 then
        self.textRight:SetText(e.Icon.wow2)
    end
    local str= flags== 0x4000 and GUILD or flags==0x20000 and e.Icon.wow2..'WoW'..SHARE_QUEST_ABBREV
    if str then
        self:AddDoubleLine(ACHIEVEMENTS..'ID: '..achievementID..(icon and ' '..EMBLEM_SYMBOL..'ID: '..icon or ''), str, nil,nil,nil, 1,0,1)
    else
        self:AddDoubleLine(ACHIEVEMENTS..'ID: '..achievementID, icon and EMBLEM_SYMBOL..'ID: '..icon)
    end
    if icon then
        self.Portrait:SetTexture(icon)
        self.Portrait:SetShown(true)
    end
end
]]
local function setQuest(self, questID)
    self:AddDoubleLine(e.GetExpansionText(nil, questID))--任务版本
    self:AddDoubleLine(QUESTS_LABEL..'ID:', questID)
end



--###########
--宠物面板提示
--###########
local function setBattlePet(self, speciesID, level, breedQuality, maxHealth, power, speed, customName)
    if not speciesID or speciesID <= 0 then
        return
    end
    local speciesName, speciesIcon, _, companionID, tooltipSource, _, _, _, _, _, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    if not self.model then--3D模型
        self.model=CreateFrame("PlayerModel", nil, self)
        self.model:SetFacing(0.35)
        self.model:SetPoint("TOPRIGHT", self, 'TOPLEFT')
        self.model:SetSize(260, 260)
    end
    self.model:SetDisplayInfo(creatureDisplayID)
    if obtainable then
        local numCollected, limit = C_PetJournal.GetNumCollectedInfo(speciesID)
        if numCollected==0 then
            BattlePetTooltipTemplate_AddTextLine(self, ITEM_PET_KNOWN:format(0, limit), 1,0,0)
        end
    end
    BattlePetTooltipTemplate_AddTextLine(self, PET..'ID: '..speciesID..'                  |T'..speciesIcon..':0|t'..speciesIcon)
    BattlePetTooltipTemplate_AddTextLine(self, 'NPCID: '..companionID..'                  '..MODEL..'ID: '..creatureDisplayID)--..'    '..	WILD_PETS:gsub(PET,'')..': '..e.GetYesNo(isWild)..'         '..TRADE..': '..e.GetYesNo(isTradeable))
    local tab = C_PetJournal.GetPetAbilityListTable(speciesID)--技能图标
    table.sort(tab, function(a,b) return a.level< b.level end)
    local abilityIcon=''
    for k, info in pairs(tab) do
        local icon, type = select(2, C_PetJournal.GetPetAbilityInfo(info.abilityID))
        if abilityIcon~='' then
            if k==4 then
                abilityIcon=abilityIcon..'   '
            end
            abilityIcon=abilityIcon..' '
        end
        abilityIcon=abilityIcon..'|TInterface\\TargetingFrame\\PetBadge-'..PET_TYPE_SUFFIX[type]..':0|t|T'..icon..':0|t'..info.level
    end
    BattlePetTooltipTemplate_AddTextLine(self, abilityIcon)
    
        BattlePetTooltipTemplate_AddTextLine(self, ' ')--来源提示
        BattlePetTooltipTemplate_AddTextLine(self, tooltipSource)
    
    if PetJournalSearchBox and PetJournalSearchBox:IsVisible() then--设置搜索
        PetJournalSearchBox:SetText(speciesName)
    end
    if not self.backgroundColor then--背景颜色
        self.backgroundColor=self:CreateTexture(nil,'BACKGROUND')
        self.backgroundColor:SetAllPoints(self)
        self.backgroundColor:SetAlpha(0.15)
    end
    if (breedQuality ~= -1) then--设置背影颜色
        self.backgroundColor:SetColorTexture(ITEM_QUALITY_COLORS[breedQuality].r, ITEM_QUALITY_COLORS[breedQuality].g, ITEM_QUALITY_COLORS[breedQuality].b, 0.15)
    end
    self.backgroundColor:SetShown(breedQuality~=-1)
end

--####
--Buff
--####
local function setBuff(type, self, ...)--Buff
    local _, icon, sourceUnit, spellId
    if type=='Buff' then
        _, icon, _, _, _, _, sourceUnit, _, _, spellId= UnitBuff(...)
    elseif type=='Debuff' then
        _, icon, _, _, _, _, sourceUnit, _, _, spellId = UnitDebuff(...)
    elseif type=='Aura' then
        _, icon, _, _, _, _, sourceUnit, _, _, spellId=UnitAura(...)
    end
    local unitInfo
    if sourceUnit=='player' then
        unitInfo=e.Player.col..COMBATLOG_FILTER_STRING_ME..'|r'
    elseif sourceUnit=='pet' then
        unitInfo = sourceUnit and '|c'..select(4,GetClassColor(UnitClassBase(sourceUnit)))..PET..'|r' or PET
    elseif sourceUnit and UnitIsPlayer(sourceUnit) then
        unitInfo = e.GetPlayerInfo(sourceUnit, nil, true)
    end
    self:AddDoubleLine((unitInfo or type)..' ID: '..spellId, EMBLEM_SYMBOL..'ID: '..icon)

    local mountID = C_MountJournal.GetMountFromSpell(spellId)
    if mountID then
        setMount(self, mountID)
    end

    if sourceUnit then
        local r, g ,b , hex= GetClassColor(UnitClassBase(sourceUnit))
        if r and g and b then
           self.backgroundColor:SetColorTexture(r, g, b, 0.3)
            --self.backgroundColor:SetShown(true)
        end
        if not UnitIsUnit(sourceUnit, 'player') then
            SetPortraitTexture(self.Portrait, sourceUnit)
            self.Portrait:SetShown(true)
        end
    end
    self:Show()
end


--####
--声望
--####
local setFriendshipFaction=function(self, friendshipID)--friend声望
    local repInfo = C_GossipInfo.GetFriendshipReputation(friendshipID);
	if ( repInfo and repInfo.friendshipFactionID and repInfo.friendshipFactionID > 0) then
        local icon = (repInfo.texture and repInfo.texture>0) and repInfo.texture
        if icon then
            self.Portrait:SetShown(true)
            self.Portrait:SetTexture(icon)
            self:AddDoubleLine(INDIVIDUALS..REPUTATION..'ID: '..friendshipID, icon  and EMBLEM_SYMBOL..'ID: '..icon)
        else
            self:AddDoubleLine(INDIVIDUALS..REPUTATION..'ID: '..friendshipID)
        end
        self:Show()
    end
end

local function setMajorFactionRenown(self, majorFactionID)--名望
	local info = C_MajorFactions.GetMajorFactionData(majorFactionID)
    if info then
        if info.textureKit then
            self.Portrait:SetShown(true)
            self.Portrait:SetAtlas('MajorFactions_Icons_'..info.textureKit..'512')
        end
        self:AddDoubleLine(RENOWN_LEVEL_LABEL..'ID '..majorFactionID, MAJOR_FACTION_RENOWN_LEVEL_TOAST:format(info.renownLevel)..' '..('%i%%'):format(info.renownReputationEarned/info.renownLevelThreshold*100))
        self:Show()
    end
end


--#########
--生命条提示
--#########
local function set_Unit_Health_Bar(self, unit)
    local value= unit and UnitHealth(unit)
    local max= unit and UnitHealthMax(unit)
    local r, g, b, left, right
    local text
    if value and max then
        if value <= 0 then
            text = '|A:poi-soulspiritghost:0:0|a'..'|cnRED_FONT_COLOR:'.. DEAD..'|r'
        else
            local hp = value / max * 100;
            text = ('%i%%'):format(hp)..'  ';
            if hp<30 then
                text = '|A:GarrisonTroops-Health-Consume:0:0|a'..'|cnRED_FONT_COLOR:' .. text..'|r'
            elseif hp<60 then
                text='|cnGREEN_FONT_COLOR:'..text..'|r'
            elseif hp<90 then
                text='|cnYELLOW_FONT_COLOR:'..text..'|r'
            end
            left =e.MK(value, 0)
        end
        right = e.MK(max, 2)
        r, g, b = GetClassColor(select(2, UnitClass(unit)))
        self:SetStatusBarColor(r, g, b)
    end
    if not self.text and text then
        self.text= e.Cstr(self)
        self.text:SetPoint('CENTER', self, 'CENTER')--生命条
        self.text:SetJustifyH("CENTER");
    end
    if self.text then
        self.text:SetText(text or '');
        
    end
    if not self.textLeft and right then
        self.textLeft = e.Cstr(self)
        self.textLeft:SetPoint('TOPLEFT', self, 'BOTTOMLEFT')--生命条
        self.textLeft:SetJustifyH("LEFT");
        self.textRight = e.Cstr(self)
        self.textRight:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT')--生命条
        self.textRight:SetJustifyH("Right");
    end
    if self.textLeft then 
        self.textLeft:SetText(left or '')
        self.textRight:SetText(right or '')
        if r and g and b then
            self.textLeft:SetTextColor(r,g,b)
            self.textRight:SetTextColor(r,g,b)
        end
    end
end

--#######
--设置单位
--#######
local function setPlayerInfo(unit, guid)--设置玩家信息
    local info=e.UnitItemLevel[guid]
    if info then
        if info.itemLevel and info.itemLevel>1 then
            e.tips.textLeft:SetText(info.col..info.itemLevel..'|r')--设置装等
        end

        local icon= info.specID and select(4, GetSpecializationInfoByID(info.specID))--设置天赋
        if icon then
            e.tips.text2Left:SetText("|T"..icon..':0|t')
        end

        if e.Player.servers[info.realm] then--设置服务器
            e.tips.textRight:SetText(info.col..info.realm..'|r'..(info.realm~=e.Player.server and '|cnGREEN_FONT_COLOR:*|r' or''))

        elseif info.realm and not e.Player.servers[info.realm] then--不同
            e.tips.textRight:SetText(info.col..info.realm..'|r|cnRED_FONT_COLOR:*|r')

        elseif UnitIsUnit('player', unit) or UnitIsSameServer(unit) then--同
            e.tips.textRight:SetText(info.col..e.Player.server..'|r')
        end
        if info.r and info.b and info.g then
            e.tips.backgroundColor:SetColorTexture(info.r, info.g, info.b, 0.2)--背景颜色
            e.tips.backgroundColor:SetShown(true)
        end
    end
end


local function setUnitInfo(self, unit)--设置单位提示信息
    local name=UnitName(unit)
    local isPlayer = UnitIsPlayer(unit)
    local guid = UnitGUID(unit)

    --设置单位图标  
    local englishFaction = isPlayer and UnitFactionGroup(unit)
    if isPlayer then
        if (englishFaction=='Alliance' or englishFaction=='Horde') then--派系
            self.Portrait:SetAtlas(englishFaction=='Alliance' and e.Icon.alliance or e.Icon.horde)
            self.Portrait:SetShown(true)
        end
        
        if CheckInteractDistance(unit, 1) then--取得装等
            NotifyInspect(unit);
        end
        --getPlayerInfo(unit, guid)--取得玩家信息
        setPlayerInfo(unit, guid)--取得玩家信息

        local isWarModeDesired=C_PvP.IsWarModeDesired()
        
        local reason=UnitPhaseReason(unit)
        if reason then
            if reason==0 then--不同了阶段
                self.textLeft:SetText(ERR_ARENA_TEAM_PLAYER_NOT_IN_TEAM_SS:format('', MAP_BAR_THUNDER_ISLE_TITLE0:gsub('1','')))
            elseif reason==1 then--不在同位面
                self.textLeft:SetText(ERR_ARENA_TEAM_PLAYER_NOT_IN_TEAM_SS:format('', e.L['LAYER']))
            elseif reason==2 then--战争模式
                self.textLeft:SetText(isWarModeDesired and ERR_PVP_WARMODE_TOGGLE_OFF or ERR_PVP_WARMODE_TOGGLE_ON)
            elseif reason==3 then
                self.textLeft:SetText(PLAYER_DIFFICULTY_TIMEWALKER)
            end
        end

    
        local isInGuild=IsPlayerInGuildFromGUID(guid)
        local col = e.UnitItemLevel[guid] and e.UnitItemLevel[guid].col or '|c'..select(4,GetClassColor(UnitClassBase(unit)))
        local line=GameTooltipTextLeft1--名称
        
        local text=line:GetText()
        if text then
            text=text:gsub('(%-.+)','')
            text=text:gsub(name, e.Icon.toRight2..name..e.Icon.toLeft2)
            line:SetText(col..text..'|r')
        end
        line=isInGuild and GameTooltipTextLeft2
        if line then
            local text=line:GetText()
            if text then
                line:SetText(e.Icon.guild2..col..text:gsub('(%-.+)','')..'|r')
            end
        end


        line=isInGuild and GameTooltipTextLeft3 or GameTooltipTextLeft2
        if line then
            local className, classFilename= UnitClass(unit);--职业名称
            local sex = UnitSex(unit)
            local raceName, raceFile= UnitRace(unit)
            local level=UnitLevel(unit)
            text= sex==2 and '|A:charactercreate-gendericon-male-selected:0:0|a' or '|A:charactercreate-gendericon-female-selected:0:0|a'
            level= MAX_PLAYER_LEVEL>level and '|cnGREEN_FONT_COLOR:'..level..'|r' or level
            className= col and col..className..'|r' or className
            text= text..LEVEL..' '..level..'  '..e.Race(nil, raceFile, sex)..raceName..' '..e.Class(nil, classFilename)..className..(UnitIsPVP(unit) and  '  (|cnRED_FONT_COLOR:PvP|r)' or '  (|cnGREEN_FONT_COLOR:PvE|r)')
            text= col and col..text..'|r' or text
            line:SetText(text)
        end

        
        local isSelf=UnitIsUnit('player', unit)--我
        local isGroupPlayer= (not isSelf and e.GroupGuid[guid]) and true or nil--队友

        local num= isInGuild and 4 or 3
        for i=num, e.tips:NumLines() do
            line=_G["GameTooltipTextLeft"..i]
            if line then
                if i==num then
                    if isSelf and (e.Layer or isWarModeDesired) then--位面ID, 战争模式
                        line:SetText(e.Layer and '|A:nameplates-holypower2-on:0:0|a'..col..e.L['LAYER']..' '..e.Layer..'|r' or ' ')
                        if isWarModeDesired then
                            line=_G["GameTooltipTextRight"..i]
                            if line then
                                line:SetText(PVP_LABEL_WAR_MODE)
                                line:SetShown(true)
                            end
                        end
                    elseif isGroupPlayer then----队友位置
                        local mapID= C_Map.GetBestMapForUnit(unit)--地图ID
                        local mapInfo= mapID and C_Map.GetMapInfo(mapID)
                        if mapInfo and mapInfo.name and _G["GameTooltipTextRight"..i] then
                            if mapInfo.name ~=e.GetUnitMapName('player') then
                                line=_G["GameTooltipTextRight"..i]
                                line:SetText(mapInfo.name..e.Icon.map2)
                                line:SetShown(true)
                            else
                                line:Hide()
                            end
                        end
                    else
                        line:Hide()
                    end
               -- else
                 --  line:Hide()
                end
            end
        end

    elseif (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then--宠物TargetFrame.lua
        setPet(self, UnitBattlePetSpeciesID(unit))

    else
        local r,g,b, hex = GetClassColor(UnitClassBase(unit))--颜色
        hex= hex and '|c'..hex or ''
        if GameTooltipTextLeft1 then GameTooltipTextLeft1:SetTextColor(r,g,b) end
        if GameTooltipTextLeft2 then GameTooltipTextLeft2:SetTextColor(r,g,b) end
        if GameTooltipTextLeft3 then GameTooltipTextLeft3:SetTextColor(r,g,b) end
        if GameTooltipTextLeft4 then GameTooltipTextLeft4:SetTextColor(r,g,b) end
        --if not UnitAffectingCombat('player') or not e.Layer then--位面,NPCID
            local zone, npc = select(5, strsplit("-",guid))--位面,NPCID
            if zone then
                self:AddDoubleLine(e.L['LAYER']..' '..zone, 'NPC '..npc, r,g,b, r,g,b)--, server and FRIENDS_LIST_REALM..server)
                --self.textLeft:SetText(hex..npc..'|r')
                e.Layer=zone
            end
        --end

        --怪物, 图标
        if UnitIsQuestBoss(unit) then--任务
            e.tips.Portrait:SetAtlas('UI-HUD-UnitFrame-Target-PortraitOn-Boss-Quest')
            e.tips.Portrait:SetShown(true)

        elseif UnitIsBossMob(unit) then--世界BOSS
            self.textLeft:SetText(hex..BOSS..'|r')
            e.tips.Portrait:SetAtlas('UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare')
            e.tips.Portrait:SetShown(true)
        else
            local classification = UnitClassification(unit);--TargetFrame.lua
            if classification == "rareelite" then--稀有, 精英
                self.textLeft:SetText(hex..GARRISON_MISSION_RARE..'|r')
                self.Portrait:SetAtlas('UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare')
                e.tips.Portrait:SetShown(true)

            elseif classification == "rare" then--稀有
                self.textLeft:SetText(hex..GARRISON_MISSION_RARE..'|r')
                e.tips.Portrait:SetAtlas('UUnitFrame-Target-PortraitOn-Boss-Rare-Star')
                e.tips.Portrait:SetShown(true)
            end
        end

        local type=UnitCreatureType(unit)--生物类型
        if type and not type:find(COMBAT_ALLY_START_MISSION) then
            self.textRight:SetText(hex..type..'|r') 
        end
    end

    set_Unit_Health_Bar(GameTooltipStatusBar,unit)--生命条提示

    if e.tips.playerModel.guid~=guid then--3D模型
        e.tips.playerModel:SetUnit(unit)
        e.tips.playerModel.guid=guid
    end
    e.tips.playerModel:SetShown(true)
end

local function setUnitInit(self)--设置默认提示位置
    if not Save.disabled then
        if not e.tips.playerModel then--单位3D模型
            e.tips.playerModel=CreateFrame("PlayerModel", nil, e.tips)
            e.tips.playerModel:SetFacing(-0.35)
            e.tips.playerModel:SetPoint("BOTTOM", e.tips, 'TOP', 0, -12)
            e.tips.playerModel:SetSize(100, 100)
            e.tips.playerModel:SetShown(false)
        end
        panel:RegisterEvent('INSPECT_READY')
    else
        panel:UnregisterEvent('INSPECT_READY')
    end
end


local function setCVar(reset, tips)
    local tab={
        ['missingTransmogSourceInItemTooltips']={
            value='1',
            msg=TRANSMOGRIFY..SOURCES..': '..SHOW,
        },
        ['nameplateOccludedAlphaMult']={
            value='0.15',
            msg=SPELL_FAILED_LINE_OF_SIGHT..'('..SHOW_TARGET_CASTBAR_IN_V_KEY..')'..CHANGE_OPACITY,
        },
        ['dontShowEquipmentSetsOnItems']={
            value='0',
            msg=EQUIPMENT_SETS:format(SHOW)
        },
        ['UberTooltips']={
            value='1',
            msg=SPELL_MESSAGES..': '..SHOW,
        },
        ["alwaysCompareItems"]={--总是比较物品
             value= "1",
             msg=ALWAYS..COMPARE_ACHIEVEMENTS:gsub(ACHIEVEMENTS, ITEMS)
        }
    }
    if tips then
        for name, info in pairs(tab) do
            e.tips:AddDoubleLine(name..': '..info.value..' (|cff00ff00'..C_CVar.GetCVar(name)..'|r)', info.msg)
        end
        return
    end
    for name, info in pairs(tab) do
        if reset then
            local defaultValue = C_CVar.GetCVarDefault(name)
            local value = C_CVar.GetCVar(name)
            if defaultValue~=value then
                C_CVar.SetCVar(name, defaultValue)
                print(id, addName, '|cnGREEN_FONT_COLOR:'..RESET_TO_DEFAULT..'|r', name, defaultValue, info.msg)
            end
        elseif Save.setCVar then
            local value = C_CVar.GetCVar(name)
            if value~=info.value then
                C_CVar.SetCVar(name, info.value)
                print(id,addName ,name, info.value..'('..value..')', info.msg)
            end
        end
    end
end

--####
--初始
--####
local function Init()
    setInitItem(ItemRefTooltip)
    setInitItem(e.tips)
    e.tips:HookScript("OnHide", function(self)--隐藏
        setInitItem(self, true)
    end)
    ItemRefTooltip:HookScript("OnHide", function (self)--隐藏
        setInitItem(self, true)
    end)

    hooksecurefunc('GameTooltip_AddQuestRewardsToTooltip', setQuest)--世界任务ID GameTooltip_AddQuest

    --TooltipUtil.lua
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip,date)
        local itemLink=select(2, TooltipUtil.GetDisplayedItem(tooltip))
        if itemLink and (tooltip==e.tips or tooltip==ItemRefTooltip) then
            if itemLink then
                setItem(tooltip, itemLink)
            end
        end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip,date)
        local spellID= select(2, TooltipUtil.GetDisplayedSpell(tooltip))
        if spellID and (tooltip==e.tips or tooltip==ItemRefTooltip) then
            setSpell(tooltip, linkID)
        end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip,date)
        local unit= select(2, TooltipUtil.GetDisplayedUnit(tooltip))
        if unit and (tooltip==e.tips or tooltip==ItemRefTooltip) then
            setUnitInfo(tooltip, unit)
        end
    end)
    
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Mount, function(tooltip,date)
        if date and date.id and (tooltip==e.tips or tooltip==ItemRefTooltip) then
            setMount(tooltip, date.id)--坐骑   
        end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, function(tooltip,date)
            if date and date.id and (tooltip==e.tips or tooltip==ItemRefTooltip) then
                setItem(tooltip, date.id)
            end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency,  function(tooltip,date)
        if date and date.id and (tooltip==e.tips or tooltip==ItemRefTooltip) then
            setCurrency(tooltip, date.id)--货币
        end
    end)
   
  
    --****
    --位置
    --****
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(self, parent)
        if Save.setDefaultAnchor then
            self:ClearAllPoints();
            self:SetOwner(parent, 'ANCHOR_CURSOR_LEFT')
        elseif Save.setAnchor and Save.AnchorPoint then
            self:ClearAllPoints();
            self:SetPoint(Save.AnchorPoint[1], UIParent, Save.AnchorPoint[3], Save.AnchorPoint[4], Save.AnchorPoint[5])
        end
    end)

    --#########
    --生命条提示
    --#########
    GameTooltipStatusBar:SetScript("OnValueChanged", function(self)
        local unit= select(2, TooltipUtil.GetDisplayedUnit(GameTooltip))
        if unit then
            set_Unit_Health_Bar(self, unit)
        end
    end);

    --####
    --声望
    --####
    hooksecurefunc(ReputationBarMixin, 'ShowMajorFactionRenownTooltip', function(self)--Major名望, 没测试ReputationFrame.lua
        setMajorFactionRenown(e.tips, self.factionID)
    end)
    hooksecurefunc(ReputationBarMixin, 'ShowFriendshipReputationTooltip', function(self, friendshipID)--个人声望 ReputationFrame.lua
        setFriendshipFaction(e.tips, friendshipID)
    end)
    hooksecurefunc(ReputationBarMixin, 'OnEnter', function(self)--角色栏,声望
        if self.friendshipID or not self.factionID or (C_Reputation.IsMajorFaction(self.factionID) and not C_MajorFactions.HasMaximumRenown(self.factionID)) then
            return
        end

        local isParagon = C_Reputation.IsFactionParagon(self.factionID)--奖励			
        local completedParagon--完成次数
        if ( isParagon ) then--奖励
            local currentValue, threshold, _, _, tooLowLevelForParagon = C_Reputation.GetFactionParagonInfo(self.factionID)
            if not tooLowLevelForParagon then
                local completed= math.modf(currentValue/threshold)--完成次数
                if completed>0 then
                    completedParagon=QUEST_REWARDS.. ' '..completed..' '..VOICEMACRO_LABEL_CHARGE1
                end
            end
        end

        if not self.Container.Name:IsTruncated() then
            local name, description, standingID, barMin, barMax, barValue, _, _, isHeader, _, hasRep, _, _, factionID, _, _ = GetFactionInfoByID(self.factionID)
            if factionID and not isHeader or (isHeader and hasRep) then
                e.tips:SetOwner(self, "ANCHOR_RIGHT");
                e.tips:AddLine(name..' '..standingID..'/'..MAX_REPUTATION_REACTION, 1,1,1)
                e.tips:AddLine(description, nil,nil,nil, true)
                e.tips:AddLine(' ')
                local gender = UnitSex("player");
                local factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender)
                local barColor = FACTION_BAR_COLORS[standingID]
                factionStandingtext=barColor:WrapTextInColorCode(factionStandingtext)--颜色
                if barValue and barMax then
                    if barMax==0 then
                        e.tips:AddLine(factionStandingtext..' '..('%i%%'):format( (barMin-barValue)/barMin*100), 1,1,1)
                    else
                        e.tips:AddLine(factionStandingtext..' '..e.MK(barValue, 3)..'/'..e.MK(barMax, 3)..' '..('%i%%'):format(barValue/barMax*100), 1,1,1)
                    end
                    e.tips:AddLine(' ')
                end
                
                e.tips:AddDoubleLine(REPUTATION..'ID: '..self.factionID or factionID, completedParagon)
                e.tips:Show();
            end
        else
            e.tips:AddDoubleLine(REPUTATION..'ID: '..(self.factionID or factionID), completedParagon)
            e.tips:Show()
        end
    end)

    
    --####
    --Buff
    --####
    hooksecurefunc(e.tips, "SetUnitBuff", function(...)
        setBuff('Buff', ...)
    end)
    hooksecurefunc(e.tips, "SetUnitDebuff", function(...)
        setBuff('Debuff', ...)
    end)
    hooksecurefunc(e.tips, "SetUnitAura", function(...)
        setBuff('Aura', ...)
    end)

    --###########
    --宠物面板提示
    --###########
    hooksecurefunc("BattlePetToolTip_Show", function(...)--BattlePetTooltip.lua 
        setBattlePet(BattlePetTooltip, ...)
    end)

    hooksecurefunc('FloatingBattlePet_Show', function(...)--FloatingPetBattleTooltip.lua
        setBattlePet(FloatingBattlePetTooltip, ...)
    end)

    hooksecurefunc(e.tips,"SetCompanionPet", function(self, petGUID)--设置宠物信息
        local speciesID= petGUID and C_PetJournal.GetPetInfoByPetID(petGUID)
        setPet(self, speciesID)--宠物
    end)


    --##########
    --设置 panel
    --##########
    panel.name = addName;--添加新控制面板
    panel.parent =id;
    InterfaceOptions_AddCategory(panel)
    
    panel.setDefaultAnchor=CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")--设置默认提示位置
    panel.setDefaultAnchor.Text:SetText(DEFAULT..RESAMPLE_QUALITY_POINT..': '..FOLLOW..MOUSE_LABEL)
    panel.setDefaultAnchor:SetPoint('TOPLEFT')
    panel.setDefaultAnchor:SetChecked(Save.setDefaultAnchor)--提示位置            
    panel.setDefaultAnchor:SetScript('OnClick', function()
        if Save.setDefaultAnchor then
            Save.setDefaultAnchor=nil
        else
            Save.setDefaultAnchor=true
            Save.setAnchor=nil
            panel.Anchor:SetChecked(false)
        end
    end)

    panel.Anchor=CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")--指定提示位置
    panel.Anchor.Text:SetText(COMBAT_ALLY_START_MISSION)--指定
    panel.Anchor:SetPoint('LEFT', panel.setDefaultAnchor.Text, 'RIGHT', 20, 0)
    panel.Anchor:SetChecked(Save.setAnchor)
    panel.Anchor:SetScript('OnClick', function(self)
        if Save.setAnchor then
            Save.setAnchor=nil
        else
            Save.setAnchor=true
            Save.setDefaultAnchor=nil
            panel.setDefaultAnchor:SetChecked(false)
        end
    end)
    panel.Anchor.select=e.Cbtn(panel,true)
    panel.Anchor.select:SetPoint('LEFT', panel.Anchor.Text, 'RIGHT')
    panel.Anchor.select:SetSize(80, 25)
    panel.Anchor.select:SetText(SETTINGS)
    
    panel.Anchor.select:SetScript('OnClick',function(self)
        if not self.frame then
            self.frame=CreateFrame('Frame',nil, UIParent)
            if Save.AnchorPoint and Save.AnchorPoint[1] and Save.AnchorPoint[3] and Save.AnchorPoint[4] and Save.AnchorPoint[5] then
                self.frame:SetPoint(Save.AnchorPoint[1], UIParent, Save.AnchorPoint[3], Save.AnchorPoint[4], Save.AnchorPoint[5])
            else
                self.frame:SetPoint('BOTTOMRIGHT', 0, 90)
            end
            self.frame:SetSize(140,140)
            self.frame.texture=self.frame:CreateTexture(nil,'ARTWORK')
            self.frame.texture:SetAllPoints(self.frame)
            self.frame.texture:SetAtlas('ForgeBorder-CornerBottomRight')
            self.frame.texture2=self.frame:CreateTexture(nil, 'BACKGROUND')
            self.frame.texture2:SetAllPoints(self.frame)
            self.frame.texture2:SetAtlas('Adventures-Missions-Shadow')
        else
            if self.frame:IsShown() then
                self.frame:SetShown(false)
            else
                self.frame:SetShown(true)
            end
        end
        self.frame:RegisterForDrag("LeftButton", "RightButton")
        self.frame:SetClampedToScreen(true)
        self.frame:SetMovable(true)
        self.frame:SetScript("OnDragStart", function(self2) self2:StartMoving() end);
        self.frame:SetScript("OnDragStop", function(self2)
                ResetCursor();
                self2:StopMovingOrSizing();
                Save.AnchorPoint={self2:GetPoint(1)}
        end);
        self.frame:SetScript('OnMouseUp',function()
            ResetCursor()
        end)
    end)

    panel.inCombatHideTips=CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")--设置默认提示位置
    panel.inCombatHideTips.Text:SetText(HUD_EDIT_MODE_SETTING_ACTION_BAR_VISIBLE_SETTING_IN_COMBAT..': '..HIDE)
    panel.inCombatHideTips:SetPoint('TOPLEFT', panel.setDefaultAnchor, 'BOTTOMLEFT', 0, -2)
    panel.inCombatHideTips:SetScript('OnClick', function()
        Save.inCombatHideTips = not  Save.inCombatHideTips and true or nil
    end)
    panel.inCombatHideTips:SetChecked( Save.inCombatHideTips)

    --设置CVar
    panel.CVar=CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    panel.CVar.Text:SetText(SETTINGS..' CVar')
    panel.CVar:SetPoint('TOPLEFT', panel.inCombatHideTips, 'BOTTOMLEFT', 0, -30)
    panel.CVar:SetChecked(Save.setCVar)
    panel.CVar:SetScript('OnClick', function()
        if Save.setCVar then
            Save.setCVar=nil
            setCVar(true)
        else
            Save.setCVar=true
            setCVar()
        end
    end)
    panel.CVar:SetScript('OnEnter',function(self)
        e.tips:SetOwner(self, "ANCHOR_LEFT")
        e.tips:ClearLines()
        e.tips:AddDoubleLine(id, addName)
        e.tips:AddLine(' ')
        setCVar(nil, true)
        e.tips:Show()
    end)
    panel.CVar:SetScript('OnLeave', function() e.tips:Hide() end)
    
    
    setUnitInit(self)--设置默认提示位置
    setCVar()--设置CVar
end

--加载保存数据
panel:RegisterEvent("ADDON_LOADED")

panel:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1==id then
            Save= WoWToolsSave and WoWToolsSave[addName] or Save

            if  WoWToolsSave then--清除旧版本数据
                WoWToolsSave['Boss_Killed']=nil
                WoWToolsSave['WoW-All-Save']=nil
            end

            local sel=e.CPanel(addName, not Save.disabled)
            sel:SetScript('OnClick', function()
                Save.disabled= not Save.disabled and true or nil               
                print(id, addName, e.GetEnabeleDisable(not Save.disabled), REQUIRES_RELOAD)
            end)
            sel:SetScript('OnEnter', function(self2)
                e.tips:SetOwner(self2, "ANCHOR_LEFT")
                e.tips:ClearLines()
                e.tips:AddDoubleLine('Tooltip')
                e.tips:Show()
            end)
            sel:SetScript('OnLeave', function() e.tips:Hide() end)
            
            if Save.disabled then
                panel:UnregisterAllEvents()
            else
                Init()--初始
            end
            panel:RegisterEvent("PLAYER_LOGOUT")

        elseif arg1=='Blizzard_AchievementUI' then--成就ID
            if not Save.disabled then
                hooksecurefunc(AchievementTemplateMixin, 'Init', function(self2,elementData)--Blizzard_AchievementUI.lua
                    local category = elementData.category;
                    local achievementID,  description, icon, _
                    if self2.index then
                        achievementID, _, _, _, _, _, _, description, _, icon= GetAchievementInfo(category, self2.index);
                    else
                        achievementID, _, _, _, _, _, _, description, _, icon = GetAchievementInfo(self2.id);
                    end
                    self2.HiddenDescription:SetText(description..' ID: '..achievementID..(icon and ' |T'..icon..':0|t'..icon or ''))
                end)
            end
        end

    elseif event == "PLAYER_LOGOUT" then
        if not e.ClearAllSave then
            if not WoWToolsSave then WoWToolsSave={} end
            WoWToolsSave[addName]=Save
        end
    end
end)