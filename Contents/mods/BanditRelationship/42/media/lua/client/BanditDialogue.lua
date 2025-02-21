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

function BanditDialogues.addDialogue(topic, playerLine, banditLine, earnBoreMin, earnBoreMax, earnRelationMin, earnRelationMax, jokeResponse)
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

function BanditDialogues.addDialogOption(insideCategory, uniqueId, name, minRelation)
    if not BanditDialogues.dialogOptions[uniqueId] then
        BanditDialogues.dialogOptions[uniqueId] = {}
    end

    -- Adiciona a nova categoria dentro da lista correspondente ao uniqueId
    table.insert(BanditDialogues.dialogOptions[uniqueId], {
        unique_id = uniqueId,
        inside_category = insideCategory,
        name = name,
        min_relation = minRelation
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
    local currentBoredom = stats:getBoredom()
    local newBoredom = math.max(0, currentBoredom - randBore)
    stats:setBoredom(newBoredom)
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

------------------------------------------------
--- Load dialog options for category
------------------------------------------------
function BanditDialogues.loadDialogOptionsForCategory(player, context, category_uniqueId, zombie)
    local addedDialogOptions = {}

    for dialogUniqueId, dialogList in pairs(BanditDialogues.dialogOptions) do
        for _, dialog in ipairs(dialogList) do
            if dialog.inside_category == category_uniqueId and not addedDialogOptions[dialog.unique_id] then
                
                context:addOption(dialog.name, player, function() 
                    BanditDialogues.doRandomDialogue(player, zombie, dialog.unique_id)
                end)

                addedDialogOptions[dialog.unique_id] = true
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
    local generator = square:getGenerator()

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

    local option = context:addOption("Falar com " .. brain.fullname)
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
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_Regret"), getText("IGUI_BanditDialog_Answer_CantChangePast"), 3, 6, -2, 2)
    BanditDialogues.addDialogue("know-one", getText("IGUI_BanditDialog_Question_TimeTravel"), getText("IGUI_BanditDialog_Answer_Bunker"), 2, 4, 2, 5)
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

    -- BanditDialogues.addDialogOption("know", "know-two", "Perguntar sobre a familia", 0)
    -- BanditDialogues.addDialogue("know-two", "O que aconteceu com sua familia?", "Meu filho Peter deve estar por ai, mas os outros... bem, voce sabe.", 2, 5, 1, 5)
    
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


    -- ===================================================================================
    -- Jokes
    BanditDialogues.addCategory("none", "jokes", getText("IGUI_BanditDialog_Category_Jokes"), 20)

    -- Submenu 1
    BanditDialogues.addDialogOption("jokes", "jokes-one", getText("IGUI_BanditDialog_Option_TellJoke"), 0)
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellJoke"), getText("IGUI_BanditDialog_Answer_BlueDot"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Bluebluereta"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellAnotherJoke"), getText("IGUI_BanditDialog_Answer_MathBook"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_MathProblems"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellDoctorJoke"), getText("IGUI_BanditDialog_Answer_Tomato"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Treat"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellSchoolJoke"), getText("IGUI_BanditDialog_Answer_HistoryBook"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_SadChapters"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellFunnyJoke"), getText("IGUI_BanditDialog_Answer_Duck"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Quack"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellShortJoke"), getText("IGUI_BanditDialog_Answer_Chicken"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_CrossRoad"))
    BanditDialogues.addDialogue("jokes-one", getText("IGUI_BanditDialog_Question_TellSillyJoke"), getText("IGUI_BanditDialog_Answer_YellowDot"), 2, 5, 1, 5, getText("IGUI_BanditDialog_Joke_Fandangos"))


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

    BanditDialogues.addCategory("none", "debug", "[Debug]", -100)
    BanditDialogues.addDialogOption("debug", "reset-relationship", "Reset Relation", -100)
end

BanditDialogues.loadDialogues()
BanditDialogsAboutDay.loadDialogues()
