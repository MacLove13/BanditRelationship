BanditDialogues = BanditDialogues or {
    categories = {},
    dialogOptions = {}
}

BanditDialogues.dialogues = {}

------------------------------------------------
--- Add Dialogs
------------------------------------------------
--- Add dialog with player and bandit to topic
--- @param topic string - example: "friendly"
--- @param playerLine string - Player speak
--- @param banditLine string - Bandit speak
--- @param earnBoreMin int - Min Bored to change
--- @param earnBoreMax int - Max Bored to change
--- @param earnRelationMin int - Min Relation to change
--- @param earnRelationMax int - Max Relation to change
--- @param jokeResponse string - Response to Joke only
--- @param skillName string - Perks key to grant XP (e.g. "Carpentry"), optional
--- @param skillXPMin int - Min XP to grant, optional
--- @param skillXPMax int - Max XP to grant, optional

function BanditDialogues.addDialogue(topic, playerLine, banditLine, earnBoreMin, earnBoreMax, earnRelationMin, earnRelationMax, jokeResponse, skillName, skillXPMin, skillXPMax)
    -- Se a categoria não existir, cria
    if not BanditDialogues.dialogues[topic] then
        BanditDialogues.dialogues[topic] = {}
    end

    table.insert(BanditDialogues.dialogues[topic], {
        player = playerLine,
        bandit = banditLine,
        earnBoreMin = earnBoreMin,
        earnBoreMax = earnBoreMax,
        earnRelationMin = earnRelationMin,
        earnRelationMax = earnRelationMax,
        jokeResponse = jokeResponse,
        skillName = skillName,
        skillXPMin = skillXPMin or 0,
        skillXPMax = skillXPMax or 0,
    })
end

------------------------------------------------
--- Add Dialog Categories
------------------------------------------------
--- Create dialog category
--- @param insideCategory string - example: "friendly-one"
--- @param uniqueId string - example: "friedly"
--- @param name string - Topic name
--- @param minRelation int - Min Relationship to see this topic

function BanditDialogues.addCategory(insideCategory, uniqueId, name, minRelation)
    if not BanditDialogues.categories[uniqueId] then
        BanditDialogues.categories[uniqueId] = {}
    end

    table.insert(BanditDialogues.categories[uniqueId], {
        unique_id = uniqueId,
        inside_category = insideCategory,
        name = name,
        min_relation = minRelation
    })
end

------------------------------------------------
--- Add Dialog Speak Option (Topic)
------------------------------------------------
--- Create dialog speak option (Topic)
--- @param insideCategory string - example: "friendly"
--- @param uniqueId string - example: "friedly-one"
--- @param name string - Topic name
--- @param minRelation int - Min Relationship to see this topic
--- @param requiredProfessions table - Optional list of profession strings required to see this option

function BanditDialogues.addDialogOption(insideCategory, uniqueId, name, minRelation, requiredProfessions)
    if not BanditDialogues.dialogOptions[uniqueId] then
        BanditDialogues.dialogOptions[uniqueId] = {}
    end

    -- Adiciona a nova categoria dentro da lista correspondente ao uniqueId
    table.insert(BanditDialogues.dialogOptions[uniqueId], {
        unique_id = uniqueId,
        inside_category = insideCategory,
        name = name,
        min_relation = minRelation,
        required_professions = requiredProfessions,
    })
end

------------------------------------------------
--- Select random speak
------------------------------------------------
function BanditDialogues.getRandomDialogue(topic)
    local list = BanditDialogues.dialogues[topic]
    if not list or #list == 0 then 
        return nil 
    end

    local rnd = ZombRand(#list) + 1
    return list[rnd]
end

------------------------------------------------
--- Execute dialog
------------------------------------------------
function BanditDialogues.generateRandomInteger(min, max)
    return min + ZombRand((max - min) + 1)
end

------------------------------------------------
--- Delayed Action
------------------------------------------------
function DelayAction(seconds, callback)
    local timer = 0
    local function onTick()
        timer = timer + 1 / 60 -- Atualiza o tempo baseado em frames (60 FPS)
        if timer >= seconds then
            Events.OnTick.Remove(onTick) -- Remove o evento após execução
            callback() -- Executa a função desejada
        end
    end
    Events.OnTick.Add(onTick) -- Adiciona o evento que executará a cada frame
end

------------------------------------------------
--- Execute random dialogue
------------------------------------------------
function BanditDialogues.doRandomDialogue(player, zombie, topic)
    local brain = BanditBrain.Get(zombie)
    if not brain or (brain.program.name ~= "Companion" and brain.program.name ~= "CompanionGuard") then
        return
    end

    local relationship = BanditRelationships.getRelationship(player, brain)
    if relationship.dayMood == nil then
        BanditRelationships.removeBandit(brain)
        relationship = BanditRelationships.getRelationship(player, brain)
    end

    topic = topic or "none"

    if topic == "reset-relationship" then
        BanditRelationships.removeBandit(brain)
        relationship = BanditRelationships.getRelationship(player, brain)

        zombie:addLineChatElement("Relation reseted", 0.1, 0.8, 0.1)
        return
    end

    if topic == "know-profession" then
        player:Say(getText("IGUI_BanditDialog_Question_WhatsYourProfession"))
        zombie:addLineChatElement(getText("IGUI_BanditDialog_Answer_WhatsYourProfession") .. getText("IGUI_Profession_" .. relationship.profession), 0.1, 0.8, 0.1)

        local randRelation = BanditDialogues.generateRandomInteger(-1, 1)
        BanditRelationships.modifyRelationship(player, brain, randRelation)
        return
    end

    if topic == "friendly-about-day" then
        topic = relationship.dayMood
    end

    local dlg = BanditDialogues.getRandomDialogue(topic)

    if not dlg then
        player:Say("Nao ha falas para o topico '" .. topic .. "' ainda.")
        return
    end

    player:Say(dlg.player)
    zombie:addLineChatElement(dlg.bandit, 0.1, 0.8, 0.1)

    if topic == "jokes-one" then
        DelayAction(3, function()
            zombie:addLineChatElement(dlg.jokeResponse, 0.1, 0.8, 0.1)
        end)
    end

    local randBore = BanditDialogues.generateRandomInteger(dlg.earnBoreMin, dlg.earnBoreMax)
    local randRelation = BanditDialogues.generateRandomInteger(dlg.earnRelationMin, dlg.earnRelationMax)

    BanditRelationships.modifyRelationship(player, brain, randRelation)
    
    local stats = player:getStats()
    stats:set(CharacterStat.BOREDOM, math.max(0, stats:get(CharacterStat.BOREDOM) - randBore))

    -- Grant skill XP if the dialogue is tied to a profession skill
    if dlg.skillName and dlg.skillXPMin and dlg.skillXPMax and dlg.skillXPMax > 0 then
        local xpAmount = BanditDialogues.generateRandomInteger(dlg.skillXPMin, dlg.skillXPMax)
        if xpAmount > 0 then
            local perk = Perks[dlg.skillName]
            if perk then
                player:getXp():AddXP(perk, xpAmount)
            end
        end
    end
end

------------------------------------------------
--- Get relationship for a companion zombie, or nil if not a companion
------------------------------------------------
function BanditDialogues.getCompanionRelationship(player, zombie)
    local brain = BanditBrain.Get(zombie)
    if not brain or (brain.program.name ~= "Companion" and brain.program.name ~= "CompanionGuard") then
        return nil
    end
    return BanditRelationships.getRelationship(player, brain)
end

------------------------------------------------
--- Check if a category has any visible options for the given bandit
------------------------------------------------
function BanditDialogues.categoryHasVisibleOptions(category_uniqueId, relationship)
    -- Check direct dialogue options
    for _, dialogList in pairs(BanditDialogues.dialogOptions) do
        for _, dialog in ipairs(dialogList) do
            if dialog.inside_category == category_uniqueId then
                local professionOk = true
                if dialog.required_professions and relationship then
                    professionOk = false
                    for _, prof in ipairs(dialog.required_professions) do
                        if prof == relationship.profession then
                            professionOk = true
                            break
                        end
                    end
                end
                if professionOk then
                    return true
                end
            end
        end
    end

    -- Check subcategories recursively
    for _, categoryList in pairs(BanditDialogues.categories) do
        for _, category in ipairs(categoryList) do
            if category.inside_category == category_uniqueId then
                if BanditDialogues.categoryHasVisibleOptions(category.unique_id, relationship) then
                    return true
                end
            end
        end
    end

    return false
end

------------------------------------------------
--- Load Submenus for categories
------------------------------------------------
function BanditDialogues.loadSubMenusForCategory(player, context, category_uniqueId, zombie)
    local addedCategories = {}
    local friendlyOption = nil
    local friendlyContext = nil

    local brain = BanditBrain.Get(zombie)
    if not brain or (brain.program.name ~= "Companion" and brain.program.name ~= "CompanionGuard") then
        return
    end

    local relationship = BanditRelationships.getRelationship(player, brain)

    for uniqueId, categoryList in pairs(BanditDialogues.categories) do
        for _, category in ipairs(categoryList) do
            if relationship.relation >= category.min_relation then
                if category.inside_category == category_uniqueId and not addedCategories[category.unique_id] then
                    if BanditDialogues.categoryHasVisibleOptions(category.unique_id, relationship) then
                        friendlyOption = context:addOption(category.name)
                        friendlyContext = context:getNew(context)
                        context:addSubMenu(friendlyOption, friendlyContext)

                        addedCategories[category.unique_id] = true

                        BanditDialogues.loadSubMenusForCategory(player, friendlyContext, category.unique_id, zombie)
                        BanditDialogues.loadDialogOptionsForCategory(player, friendlyContext, category.unique_id, zombie)
                    end
                end
            end
        end
    end
end

------------------------------------------------
--- Load dialog options for category
------------------------------------------------
function BanditDialogues.loadDialogOptionsForCategory(player, context, category_uniqueId, zombie)
    local addedDialogOptions = {}

    local relationship = BanditDialogues.getCompanionRelationship(player, zombie)

    for dialogUniqueId, dialogList in pairs(BanditDialogues.dialogOptions) do
        for _, dialog in ipairs(dialogList) do
            if dialog.inside_category == category_uniqueId and not addedDialogOptions[dialog.unique_id] then

                -- Check profession requirement
                local professionOk = true
                if dialog.required_professions and relationship then
                    professionOk = false
                    for _, prof in ipairs(dialog.required_professions) do
                        if prof == relationship.profession then
                            professionOk = true
                            break
                        end
                    end
                end

                if professionOk then
                    context:addOption(dialog.name, player, function()
                        BanditDialogues.doRandomDialogue(player, zombie, dialog.unique_id)
                    end)
                    addedDialogOptions[dialog.unique_id] = true
                end
            end
        end
    end
end

------------------------------------------------
--- Mount Dialogue menu in Context Menu
------------------------------------------------
function BanditDialogues.addDialogueMenu(playerID, context, worldobjects, test)
    local world = getWorld()
    local gamemode = world:getGameMode()
    local player = getSpecificPlayer(playerID)
    local square = BanditCompatibility.GetClickedSquare()

    local zombie = square:getZombie()
    if not zombie then
        local squareS = square:getS()
        if squareS then
            zombie = squareS:getZombie()
            if not zombie then
                local squareW = square:getW()
                if squareW then
                    zombie = squareW:getZombie()
                end
            end
        end
    end

    if zombie == nil then return end

    local brain = BanditBrain.Get(zombie)
    if not brain or (brain.program.name ~= "Companion" and brain.program.name ~= "CompanionGuard") then
        return
    end

    local option = context:addOption(getText("IGUI_BanditDialog_SpeakWith") .. " " .. brain.fullname)
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)

    local friendlyOption = nil
    local friendlyContext = nil

    BanditDialogues.loadSubMenusForCategory(player, subMenu, "none", zombie)
end

Events.OnPreFillWorldObjectContextMenu.Add(BanditDialogues.addDialogueMenu)

------------------------------------------------
--- Create Categories and Dialogs
------------------------------------------------
function BanditDialogues.loadDialogues()
    for k in pairs(BanditDialogues.categories) do
        BanditDialogues.categories[k] = nil
    end

    for k in pairs(BanditDialogues.dialogOptions) do
        BanditDialogues.dialogOptions[k] = nil
    end

    -- Categories
    -- addCategory(insideCategory, uniqueId, name, minRelation)
    -- addDialogOption(insideCategory, uniqueId, name, minRelation)
    -- addDialogue(topic, playerLine, banditLine, earnBoreMin, earnBoreMax, earnRelationMin, earnRelationMax)

    -- ===================================================================================
    -- Know
    BanditDialogues.addCategory("none", "know", getText("IGUI_BanditDialog_Category_Know"), -100)

    BanditDialogues.addDialogOption("none", "know-new-bandit", getText("IGUI_BanditDialog_Category_KnowNew"), 0)

    BanditDialogues.addDialogOption("know", "know-profession", getText("IGUI_BanditDialog_Option_AskProfession"), 0)
    BanditDialogues.addDialogOption("know", "know-one", getText("IGUI_BanditDialog_Option_AskLife"), 0)
    BanditDialogues.addDialogOption("know", "know-two", getText("IGUI_BanditDialog_Option_AskFamily"), 0)

    BanditDialogues.addDialogue("know-two", getText("IGUI_BanditDialog_Question_WhatHappenedFamily"), getText("IGUI_BanditDialog_Answer_SonPeterOutThere"), 3, 6, -2, 3)
    BanditDialogues.addDialogue("know-two", getText("IGUI_BanditDialog_Question_DidYouTryFindThem"), getText("IGUI_BanditDialog_Answer_HadToStopHoping"), 3, 5, -1, 3)
    BanditDialogues.addDialogue("know-two", getText("IGUI_BanditDialog_Question_DidYouHaveKids"), getText("IGUI_BanditDialog_Answer_DaughterSeven"), 4, 7, -3, 2)
    BanditDialogues.addDialogue("know-two", getText("IGUI_BanditDialog_Question_WereYouMarried"), getText("IGUI_BanditDialog_Answer_DivorcedDoesntMatter"), 2, 5, 0, 3)

    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_WhereWereYou"), getText("IGUI_BanditDialog_Answer_Traffic"), 2, 4, 0, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_MetSomeone"), getText("IGUI_BanditDialog_Answer_BetterThisWay"), 2, 5, -1, 4)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_MissSomething"), getText("IGUI_BanditDialog_Answer_FightingForFood"), 3, 5, 0, 4)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_LikedJob"), getText("IGUI_BanditDialog_Answer_HatedAdmit"), 1, 3, 1, 5)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_LostSomeone"), getText("IGUI_BanditDialog_Answer_DontWantToTalk"), 4, 6, -3, 2)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_StayAlive"), getText("IGUI_BanditDialog_Answer_DontWantToDie"), 2, 4, 0, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_BackToNormal"), getText("IGUI_BanditDialog_Answer_DontBelieve"), 2, 5, -2, 2)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_FuturePlans"), getText("IGUI_BanditDialog_Answer_Survive"), 3, 5, 0, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_WhatForFun"), getText("IGUI_BanditDialog_Answer_Poker"), 2, 4, 2, 5)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_FoundSafePlace"), getText("IGUI_BanditDialog_Answer_NoSafePlace"), 3, 6, -2, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_Skills"), getText("IGUI_BanditDialog_Answer_LearnedShooting"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_LivedBefore"), getText("IGUI_BanditDialog_Answer_SmallApartment"), 2, 4, 1, 4)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_Hope"), getText("IGUI_BanditDialog_Answer_KeepMoving"), 3, 5, -1, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_Cure"), getText("IGUI_BanditDialog_Answer_NeverReachUs"), 2, 4, -1, 2)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_Routine"), getText("IGUI_BanditDialog_Answer_RepeatCycle"), 3, 6, 0, 4)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_MostAnnoying"), getText("IGUI_BanditDialog_Answer_HumansWorse"), 2, 5, -2, 2)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_WeirdExperience"), getText("IGUI_BanditDialog_Answer_ZombieDoor"), 2, 4, 2, 5)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_IntactCity"), getText("IGUI_BanditDialog_Answer_TooGoodToBeTrue"), 3, 5, 1, 4)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_TrustPeople"), getText("IGUI_BanditDialog_Answer_OnlyIfFood"), 2, 4, -1, 4)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_MostMissed"), getText("IGUI_BanditDialog_Answer_SleepingSafe"), 3, 6, 0, 5)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_HopefulPeople"), getText("IGUI_BanditDialog_Answer_NeverSawAgain"), 2, 5, -2, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_OneThingBack"), getText("IGUI_BanditDialog_Answer_GoodSleep"), 3, 5, 0, 5)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_OptimistBefore"), getText("IGUI_BanditDialog_Answer_LookWhereItLed"), 2, 4, -1, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_StillHope"), getText("IGUI_BanditDialog_Answer_HopeDoesntFeed"), 3, 5, -1, 3)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_MetWorseThanZombies"), getText("IGUI_BanditDialog_Answer_HumansWorseThanZombies_1"), 3, 6, -3, 2)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_MetWorseThanZombies"), getText("IGUI_BanditDialog_Answer_HumansWorseThanZombies_2"), 3, 6, -3, 2)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_BelieveLuck"), getText("IGUI_BanditDialog_Answer_LuckFood"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_WorstExperience"), getText("IGUI_BanditDialog_Answer_TrappedForDays"), 4, 6, -2, 2)

    -- ===================================================================================
    -- Friendly
    BanditDialogues.addCategory("none", "friendly", getText("IGUI_BanditDialog_Category_Friendly"), 0)

    -- Submenu 1
    BanditDialogues.addDialogOption("friendly", "friendly-about-day", getText("IGUI_BanditDialog_Question_AboutDay"), 0)
    -- Responses in Dialogs/DialogsAboutDay
    
    -- Submenu 2
    BanditDialogues.addDialogOption("friendly", "friendly-two", getText("IGUI_BanditDialog_Option_HowAreYou"), 0)

    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Good"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Surviving"), 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_NotGreat"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Tired"), 1, 3, 0, 4)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Down"), -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Great"), 3, 6, 2, 5)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Lonely"), 0, 2, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Hungry"), 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Afraid"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Hopeful"), 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Worried"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Lost"), -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_JustTired"), 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Anxious"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Sad"), -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Confused"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Frustrated"), -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_HopefulAgain"), 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Optimistic"), 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Pessimistic"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Nervous"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Calm"), 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Relaxed"), 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Tense"), 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", getText("IGUI_BanditDialog_Question_HowAreYou"), getText("IGUI_BanditDialog_Answer_Relieved"), 2, 5, 1, 4)

    -- Submenu 3: Small Talk
    BanditDialogues.addDialogOption("friendly", "friendly-smalltalk", getText("IGUI_BanditDialog_Option_SmallTalk"), 0)
    BanditDialogues.addDialogue("friendly-smalltalk", getText("IGUI_BanditDialog_Question_NiceToSeeYou"), getText("IGUI_BanditDialog_Answer_NiceToSeeYou"), 2, 4, 1, 3)
    BanditDialogues.addDialogue("friendly-smalltalk", getText("IGUI_BanditDialog_Question_YouLookWell"), getText("IGUI_BanditDialog_Answer_YouLookWell"), 2, 4, 1, 3)
    BanditDialogues.addDialogue("friendly-smalltalk", getText("IGUI_BanditDialog_Question_HowIsLife"), getText("IGUI_BanditDialog_Answer_CouldBeWorse"), 1, 3, 0, 2)
    BanditDialogues.addDialogue("friendly-smalltalk", getText("IGUI_BanditDialog_Question_AnythingInteresting"), getText("IGUI_BanditDialog_Answer_SameOldApocalypse"), 1, 3, 0, 2)
    BanditDialogues.addDialogue("friendly-smalltalk", getText("IGUI_BanditDialog_Question_GladYoureAround"), getText("IGUI_BanditDialog_Answer_MeToo"), 3, 5, 2, 5)

    -- Submenu 4: Weather
    BanditDialogues.addDialogOption("friendly", "friendly-weather", getText("IGUI_BanditDialog_Option_Weather"), 0)
    BanditDialogues.addDialogue("friendly-weather", getText("IGUI_BanditDialog_Question_NiceWeather"), getText("IGUI_BanditDialog_Answer_AlmostForget"), 1, 3, 0, 2)
    BanditDialogues.addDialogue("friendly-weather", getText("IGUI_BanditDialog_Question_BrutalHeat"), getText("IGUI_BanditDialog_Answer_MakesEverythingHarder"), 1, 3, 0, 2)
    BanditDialogues.addDialogue("friendly-weather", getText("IGUI_BanditDialog_Question_RainNotStopping"), getText("IGUI_BanditDialog_Answer_ZombiesSlowInRain"), 1, 3, 1, 3)
    BanditDialogues.addDialogue("friendly-weather", getText("IGUI_BanditDialog_Question_ChillyToday"), getText("IGUI_BanditDialog_Answer_ColdKeepsSlower"), 1, 3, 1, 3)
    BanditDialogues.addDialogue("friendly-weather", getText("IGUI_BanditDialog_Question_FoggyMorning"), getText("IGUI_BanditDialog_Answer_StaySharpFog"), 1, 3, 0, 2)

    -- Submenu 5: Hear a story (requires relation >= 5)
    BanditDialogues.addDialogOption("friendly", "friendly-story", getText("IGUI_BanditDialog_Option_HearStory"), 5)
    BanditDialogues.addDialogue("friendly-story", getText("IGUI_BanditDialog_Question_TellMeStory"), getText("IGUI_BanditDialog_Answer_Story_RoadTrip"), 5, 8, 2, 5)
    BanditDialogues.addDialogue("friendly-story", getText("IGUI_BanditDialog_Question_TellMeStory"), getText("IGUI_BanditDialog_Answer_Story_Dog"), 5, 8, 2, 6)
    BanditDialogues.addDialogue("friendly-story", getText("IGUI_BanditDialog_Question_TellMeStory"), getText("IGUI_BanditDialog_Answer_Story_Chickens"), 4, 7, 1, 4)
    BanditDialogues.addDialogue("friendly-story", getText("IGUI_BanditDialog_Question_TellMeStory"), getText("IGUI_BanditDialog_Answer_Story_Lost"), 4, 7, 2, 5)
    BanditDialogues.addDialogue("friendly-story", getText("IGUI_BanditDialog_Question_TellMeStory"), getText("IGUI_BanditDialog_Answer_Story_NightShift"), 4, 7, 1, 4)
    BanditDialogues.addDialogue("friendly-story", getText("IGUI_BanditDialog_Question_TellMeStory"), getText("IGUI_BanditDialog_Answer_Story_Concert"), 5, 8, 2, 5)
    BanditDialogues.addDialogue("friendly-story", getText("IGUI_BanditDialog_Question_TellMeStory"), getText("IGUI_BanditDialog_Answer_Story_Neighbor"), 4, 7, 1, 4)


    -- ===================================================================================
    -- Jokes
    BanditDialogues.addCategory("none", "jokes", getText("IGUI_BanditDialog_Category_Jokes"), 20)

    -- Submenu 1: Hear a joke (bandit tells)
    BanditDialogues.addDialogOption("jokes", "jokes-one", getText("IGUI_BanditDialog_Option_TellJoke"), 0)
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellJoke"), getText("IGUI_BanditDialog_Answer_BlueDot"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Bluebluereta"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellAnotherJoke"), getText("IGUI_BanditDialog_Answer_MathBook"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_MathProblems"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellDoctorJoke"), getText("IGUI_BanditDialog_Answer_Tomato"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Treat"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellSchoolJoke"), getText("IGUI_BanditDialog_Answer_HistoryBook"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_SadChapters"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellFunnyJoke"), getText("IGUI_BanditDialog_Answer_Duck"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Quack"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellShortJoke"), getText("IGUI_BanditDialog_Answer_Chicken"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_CrossRoad"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellSillyJoke"), getText("IGUI_BanditDialog_Answer_YellowDot"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Fandangos"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellZombieJoke"), getText("IGUI_BanditDialog_Answer_ZombieChef"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_DeadbeatChef"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellAtomJoke"), getText("IGUI_BanditDialog_Answer_AtomsLie"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_AtomsLie"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellDentistJoke"), getText("IGUI_BanditDialog_Answer_UsedToHateDentist"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_NoDentistNow"))

    -- Submenu 2: Player tells a joke (bandit reacts)
    BanditDialogues.addDialogOption("jokes", "jokes-player-tells", getText("IGUI_BanditDialog_Option_PlayerTellsJoke"), 0)
    BanditDialogues.addDialogue("jokes-player-tells", getText("IGUI_BanditDialog_Question_WantToHearJoke"), getText("IGUI_BanditDialog_Answer_JokeLaugh"), 3, 6, 2, 5)
    BanditDialogues.addDialogue("jokes-player-tells", getText("IGUI_BanditDialog_Question_WantToHearJoke"), getText("IGUI_BanditDialog_Answer_JokeNeutral"), 1, 3, -1, 1)
    BanditDialogues.addDialogue("jokes-player-tells", getText("IGUI_BanditDialog_Question_WantToHearJoke"), getText("IGUI_BanditDialog_Answer_JokeSurprised"), 3, 6, 2, 5)
    BanditDialogues.addDialogue("jokes-player-tells", getText("IGUI_BanditDialog_Question_WantToHearJoke"), getText("IGUI_BanditDialog_Answer_JokeNeededThat"), 3, 6, 2, 5)
    BanditDialogues.addDialogue("jokes-player-tells", getText("IGUI_BanditDialog_Question_WantToHearJoke"), getText("IGUI_BanditDialog_Answer_JokeBad"), 2, 4, -2, 0)


    -- ===================================================================================
    -- Survive
    BanditDialogues.addCategory("friendly", "survive", getText("IGUI_BanditDialog_Category_Survive"), 15)

    -- Submenu 1
    BanditDialogues.addDialogOption("survive", "survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), 0)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_1"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_2"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_3"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_4"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_5"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_6"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_7"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_8"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_9"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_10"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_11"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_12"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_13"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_14"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_15"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_16"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_17"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_18"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_19"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_20"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_21"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_22"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_23"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_24"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_25"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_26"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_27"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_28"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_29"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_30"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_31"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_32"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_33"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_34"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_35"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_36"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_37"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_38"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_39"), 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", getText("IGUI_BanditDialog_Question_AnySurviveHint"), getText("IGUI_BanditDialog_Answer_AnySurviveHint_40"), 2, 5, 1, 5)

    -- ===================================================================================
    -- Personal (requires relation >= 30)
    BanditDialogues.addCategory("friendly", "personal", getText("IGUI_BanditDialog_Category_Personal"), 30)

    -- Submenu 1: Past
    BanditDialogues.addDialogOption("personal", "personal-past", getText("IGUI_BanditDialog_Option_PersonalPast"), 0)
    BanditDialogues.addDialogue("personal-past", getText("IGUI_BanditDialog_Question_WhatWasYourFamily"), getText("IGUI_BanditDialog_Answer_FamilyCloseThought"), 3, 6, 1, 5)
    BanditDialogues.addDialogue("personal-past", getText("IGUI_BanditDialog_Question_WhereDidYouGrowUp"), getText("IGUI_BanditDialog_Answer_SmallTownQuiet"), 2, 5, 1, 4)
    BanditDialogues.addDialogue("personal-past", getText("IGUI_BanditDialog_Question_CloseFriendsBefore"), getText("IGUI_BanditDialog_Answer_AFewWonderWhere"), 2, 4, 0, 3)
    BanditDialogues.addDialogue("personal-past", getText("IGUI_BanditDialog_Question_WishDoneDifferently"), getText("IGUI_BanditDialog_Answer_ToldThemMoreOften"), 3, 6, 1, 5)
    BanditDialogues.addDialogue("personal-past", getText("IGUI_BanditDialog_Question_HappiestMemory"), getText("IGUI_BanditDialog_Answer_CampingTrip"), 3, 7, 2, 6)

    -- Submenu 2: Missing
    BanditDialogues.addDialogOption("personal", "personal-missing", getText("IGUI_BanditDialog_Option_PersonalMissing"), 0)
    BanditDialogues.addDialogue("personal-missing", getText("IGUI_BanditDialog_Question_StillLookingForSomeone"), getText("IGUI_BanditDialog_Answer_TryNotToThink"), 3, 5, -1, 3)
    BanditDialogues.addDialogue("personal-missing", getText("IGUI_BanditDialog_Question_LostSomeoneClose"), getText("IGUI_BanditDialog_Answer_TalkingDoesntHelp"), 4, 7, -2, 2)
    BanditDialogues.addDialogue("personal-missing", getText("IGUI_BanditDialog_Question_WhatWouldYouSay"), getText("IGUI_BanditDialog_Answer_SorryForNotBeing"), 4, 6, 1, 5)
    BanditDialogues.addDialogue("personal-missing", getText("IGUI_BanditDialog_Question_IsAnyoneLookingForYou"), getText("IGUI_BanditDialog_Answer_ProbablyNot"), 3, 5, -2, 2)

    -- Submenu 3: Fears
    BanditDialogues.addDialogOption("personal", "personal-fears", getText("IGUI_BanditDialog_Option_PersonalFears"), 0)
    BanditDialogues.addDialogue("personal-fears", getText("IGUI_BanditDialog_Question_KeepsYouUpAtNight"), getText("IGUI_BanditDialog_Answer_SilenceMeansWrong"), 3, 5, 0, 4)
    BanditDialogues.addDialogue("personal-fears", getText("IGUI_BanditDialog_Question_AfraidOfDying"), getText("IGUI_BanditDialog_Answer_AloneScalesMore"), 3, 6, 1, 5)
    BanditDialogues.addDialogue("personal-fears", getText("IGUI_BanditDialog_Question_BiggestFearNow"), getText("IGUI_BanditDialog_Answer_LosingMindBecomeOne"), 3, 6, -1, 4)
    BanditDialogues.addDialogue("personal-fears", getText("IGUI_BanditDialog_Question_EverFeelHopeless"), getText("IGUI_BanditDialog_Answer_KeepGoingAnyway"), 3, 6, 1, 5)

    BanditDialogues.addCategory("none", "debug", "[Debug]", -100)
    BanditDialogues.addDialogOption("debug", "reset-relationship", "Reset Relation", -100)

    -- ===================================================================================
    -- Expertise (profession-locked, requires relation >= 15)
    BanditDialogues.addCategory("friendly", "expertise", getText("IGUI_BanditDialog_Category_Expertise"), 15)

    -- Carpentry (Carpenter)
    BanditDialogues.addDialogOption("expertise", "skill-carpentry", getText("IGUI_BanditDialog_Option_AskAboutCarpentry"), 0, {"Carpenter"})
    BanditDialogues.addDialogue("skill-carpentry", getText("IGUI_BanditDialog_Q_SkillCarpentry_1"), getText("IGUI_BanditDialog_A_SkillCarpentry_1"), 3, 6, 1, 4, nil, "Carpentry", 10, 20)
    BanditDialogues.addDialogue("skill-carpentry", getText("IGUI_BanditDialog_Q_SkillCarpentry_2"), getText("IGUI_BanditDialog_A_SkillCarpentry_2"), 2, 5, 1, 4, nil, "Carpentry", 8, 18)
    BanditDialogues.addDialogue("skill-carpentry", getText("IGUI_BanditDialog_Q_SkillCarpentry_3"), getText("IGUI_BanditDialog_A_SkillCarpentry_3"), 3, 6, 2, 5, nil, "Carpentry", 12, 22)

    -- Mechanics (Mechanic)
    BanditDialogues.addDialogOption("expertise", "skill-mechanics", getText("IGUI_BanditDialog_Option_AskAboutMechanics"), 0, {"Mechanic"})
    BanditDialogues.addDialogue("skill-mechanics", getText("IGUI_BanditDialog_Q_SkillMechanics_1"), getText("IGUI_BanditDialog_A_SkillMechanics_1"), 3, 6, 1, 4, nil, "Mechanics", 10, 20)
    BanditDialogues.addDialogue("skill-mechanics", getText("IGUI_BanditDialog_Q_SkillMechanics_2"), getText("IGUI_BanditDialog_A_SkillMechanics_2"), 2, 5, 1, 4, nil, "Mechanics", 8, 18)
    BanditDialogues.addDialogue("skill-mechanics", getText("IGUI_BanditDialog_Q_SkillMechanics_3"), getText("IGUI_BanditDialog_A_SkillMechanics_3"), 3, 6, 2, 5, nil, "Mechanics", 12, 22)

    -- Cooking (Cook)
    BanditDialogues.addDialogOption("expertise", "skill-cooking", getText("IGUI_BanditDialog_Option_AskAboutCooking"), 0, {"Cook"})
    BanditDialogues.addDialogue("skill-cooking", getText("IGUI_BanditDialog_Q_SkillCooking_1"), getText("IGUI_BanditDialog_A_SkillCooking_1"), 3, 6, 1, 4, nil, "Cooking", 10, 20)
    BanditDialogues.addDialogue("skill-cooking", getText("IGUI_BanditDialog_Q_SkillCooking_2"), getText("IGUI_BanditDialog_A_SkillCooking_2"), 2, 5, 1, 4, nil, "Cooking", 8, 18)
    BanditDialogues.addDialogue("skill-cooking", getText("IGUI_BanditDialog_Q_SkillCooking_3"), getText("IGUI_BanditDialog_A_SkillCooking_3"), 3, 6, 2, 5, nil, "Cooking", 12, 22)

    -- Farming (Farmer)
    BanditDialogues.addDialogOption("expertise", "skill-farming", getText("IGUI_BanditDialog_Option_AskAboutFarming"), 0, {"Farmer"})
    BanditDialogues.addDialogue("skill-farming", getText("IGUI_BanditDialog_Q_SkillFarming_1"), getText("IGUI_BanditDialog_A_SkillFarming_1"), 3, 6, 1, 4, nil, "Farming", 10, 20)
    BanditDialogues.addDialogue("skill-farming", getText("IGUI_BanditDialog_Q_SkillFarming_2"), getText("IGUI_BanditDialog_A_SkillFarming_2"), 2, 5, 1, 4, nil, "Farming", 8, 18)
    BanditDialogues.addDialogue("skill-farming", getText("IGUI_BanditDialog_Q_SkillFarming_3"), getText("IGUI_BanditDialog_A_SkillFarming_3"), 3, 6, 2, 5, nil, "Farming", 12, 22)

    -- First Aid (Doctor, Nurse, Firefighter)
    BanditDialogues.addDialogOption("expertise", "skill-firstaid", getText("IGUI_BanditDialog_Option_AskAboutFirstAid"), 0, {"Doctor", "Nurse", "Firefighter"})
    BanditDialogues.addDialogue("skill-firstaid", getText("IGUI_BanditDialog_Q_SkillFirstAid_1"), getText("IGUI_BanditDialog_A_SkillFirstAid_1"), 3, 6, 1, 4, nil, "Doctor", 10, 20)
    BanditDialogues.addDialogue("skill-firstaid", getText("IGUI_BanditDialog_Q_SkillFirstAid_2"), getText("IGUI_BanditDialog_A_SkillFirstAid_2"), 2, 5, 1, 4, nil, "Doctor", 8, 18)
    BanditDialogues.addDialogue("skill-firstaid", getText("IGUI_BanditDialog_Q_SkillFirstAid_3"), getText("IGUI_BanditDialog_A_SkillFirstAid_3"), 3, 6, 2, 5, nil, "Doctor", 12, 22)

    -- Electrical (Engineer, Programmer)
    BanditDialogues.addDialogOption("expertise", "skill-electrical", getText("IGUI_BanditDialog_Option_AskAboutElectrical"), 0, {"Engineer", "Programmer"})
    BanditDialogues.addDialogue("skill-electrical", getText("IGUI_BanditDialog_Q_SkillElectrical_1"), getText("IGUI_BanditDialog_A_SkillElectrical_1"), 3, 6, 1, 4, nil, "Electricity", 10, 20)
    BanditDialogues.addDialogue("skill-electrical", getText("IGUI_BanditDialog_Q_SkillElectrical_2"), getText("IGUI_BanditDialog_A_SkillElectrical_2"), 2, 5, 1, 4, nil, "Electricity", 8, 18)
    BanditDialogues.addDialogue("skill-electrical", getText("IGUI_BanditDialog_Q_SkillElectrical_3"), getText("IGUI_BanditDialog_A_SkillElectrical_3"), 3, 6, 2, 5, nil, "Electricity", 12, 22)

    -- Aiming (Soldier, Police)
    BanditDialogues.addDialogOption("expertise", "skill-aiming", getText("IGUI_BanditDialog_Option_AskAboutAiming"), 0, {"Soldier", "Police"})
    BanditDialogues.addDialogue("skill-aiming", getText("IGUI_BanditDialog_Q_SkillAiming_1"), getText("IGUI_BanditDialog_A_SkillAiming_1"), 3, 6, 1, 4, nil, "Aiming", 10, 20)
    BanditDialogues.addDialogue("skill-aiming", getText("IGUI_BanditDialog_Q_SkillAiming_2"), getText("IGUI_BanditDialog_A_SkillAiming_2"), 2, 5, 1, 4, nil, "Aiming", 8, 18)
    BanditDialogues.addDialogue("skill-aiming", getText("IGUI_BanditDialog_Q_SkillAiming_3"), getText("IGUI_BanditDialog_A_SkillAiming_3"), 3, 6, 2, 5, nil, "Aiming", 12, 22)
end

BanditDialogues.loadDialogues()
BanditDialogsAboutDay.loadDialogues()
