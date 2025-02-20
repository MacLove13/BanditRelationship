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

    topic = topic or "none"

    if topic == "friendly-about-day" then
        topic = relationship.dayMood
    end

    local dlg = BanditDialogues.getRandomDialogue(topic)


    if not dlg then
        player:Say("Nao ha falas para o topico '" .. topic .. "' ainda.")
        return
    end

    player:Say(dlg.player) -- fala do jogador
    zombie:addLineChatElement(dlg.bandit, 0.1, 0.8, 0.1) -- fala do bandido

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
    BanditDialogues.addCategory("none", "know", "Conhecer mais", 0)

    BanditDialogues.addDialogOption("know", "know-one", "Perguntar algo sobre a vida", 0)
    BanditDialogues.addDialogue("know-one", "Do que voce trabalhava?", "Em um maldito escritorio de advocacia", 2, 5, 1, 5)
    BanditDialogues.addDialogue("know-one", "Você tinha família?", "Sim... eu os perdi logo no começo.", 3, 6, -2, 4)
    BanditDialogues.addDialogue("know-one", "Onde você estava quando tudo começou?", "Trancado no trânsito, como sempre.", 2, 4, 0, 3)
    BanditDialogues.addDialogue("know-one", "Você tinha filhos?", "Não... acho que isso me ajudou a sobreviver.", 1, 3, 1, 3)
    BanditDialogues.addDialogue("know-one", "Já encontrou alguém que conhecia antes?", "Não... e talvez seja melhor assim.", 2, 5, -1, 4)
    BanditDialogues.addDialogue("know-one", "O que você sente falta do mundo antigo?", "De não ter que lutar por cada refeição.", 3, 5, 0, 4)
    BanditDialogues.addDialogue("know-one", "Você gostava do que fazia?", "Odeio admitir, mas sim... e agora nada disso importa.", 1, 3, 1, 5)
    BanditDialogues.addDialogue("know-one", "Já perdeu alguém próximo?", "Sim... prefiro não falar sobre isso.", 4, 6, -3, 2)
    BanditDialogues.addDialogue("know-one", "O que te mantém vivo?", "A simples vontade de não morrer.", 2, 4, 0, 3)
    BanditDialogues.addDialogue("know-one", "Acha que um dia tudo voltará ao normal?", "Sério? Você ainda acredita nisso?", 2, 5, -2, 2)
    BanditDialogues.addDialogue("know-one", "Tem algum plano para o futuro?", "Futuro? Meu plano é chegar ao fim do dia.", 3, 5, 0, 3)
    BanditDialogues.addDialogue("know-one", "Já encontrou alguma comunidade?", "Sim, algumas... mas nem todas valiam a pena.", 2, 4, 1, 5)
    BanditDialogues.addDialogue("know-one", "O que fazia para se divertir?", "Jogava pôquer... hoje em dia jogo com a sorte.", 2, 4, 2, 5)
    BanditDialogues.addDialogue("know-one", "Tem alguma lembrança especial?", "Uma foto da minha irmã... foi a única coisa que guardei.", 4, 6, -1, 3)
    BanditDialogues.addDialogue("know-one", "Já encontrou um lugar seguro?", "Lugar seguro? Isso não existe mais.", 3, 6, -2, 3)
    BanditDialogues.addDialogue("know-one", "Tem algum talento útil?", "Acho que aprendi a atirar... na prática.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("know-one", "Antes disso tudo, onde você morava?", "Num apartamento apertado... sinto até saudade.", 2, 4, 1, 4)
    BanditDialogues.addDialogue("know-one", "Já teve que fazer algo que se arrepende?", "Todos temos... mas não adianta remoer o passado.", 3, 6, -2, 2)
    BanditDialogues.addDialogue("know-one", "O que faria se pudesse voltar no tempo?", "Compraria um bunker... e muita comida.", 2, 4, 2, 5)
    BanditDialogues.addDialogue("know-one", "Já pensou em se entregar?", "Muitas vezes... mas ainda estou aqui.", 4, 6, -3, 3)
    BanditDialogues.addDialogue("know-one", "O que te dá esperança?", "Nada... mas sigo em frente mesmo assim.", 3, 5, -1, 3)
    BanditDialogues.addDialogue("know-one", "Você acredita que há uma cura?", "Se existe, nunca vai chegar até nós.", 2, 4, -1, 2)
    BanditDialogues.addDialogue("know-one", "Como é sua rotina hoje em dia?", "Acordar, caçar, tentar não morrer... repetir.", 3, 6, 0, 4)
    BanditDialogues.addDialogue("know-one", "O que mais te irrita nesse novo mundo?", "As pessoas... os zumbis são mais previsíveis.", 2, 5, -2, 2)
    BanditDialogues.addDialogue("know-one", "Já teve alguma experiência bizarra?", "Já vi um zumbi tentando abrir uma porta por horas...", 2, 4, 2, 5)
    BanditDialogues.addDialogue("know-one", "O que faria se encontrasse uma cidade intacta?", "Eu desconfiaria. Lugar bom demais é armadilha.", 3, 5, 1, 4)
    BanditDialogues.addDialogue("know-one", "Você confia nas pessoas?", "Depende... você tem comida?", 2, 4, -1, 4)
    BanditDialogues.addDialogue("know-one", "O que mais sente falta de antes?", "De dormir sem medo de não acordar.", 3, 6, 0, 5)
    BanditDialogues.addDialogue("know-one", "Já encontrou alguém com esperanças de reconstruir tudo?", "Já... e nunca mais vi ele.", 2, 5, -2, 3)
    BanditDialogues.addDialogue("know-one", "Se pudesse ter uma coisa do mundo antigo, o que seria?", "Uma noite de sono tranquila.", 3, 5, 0, 5)
    BanditDialogues.addDialogue("know-one", "Qual foi sua pior experiência desde o apocalipse?", "Ficar preso numa loja cercado de zumbis por 3 dias.", 4, 6, -2, 2)
    BanditDialogues.addDialogue("know-one", "Você era otimista antes?", "Sim... e olha onde isso me levou.", 2, 4, -1, 3)
    BanditDialogues.addDialogue("know-one", "Já pensou em criar um grupo?", "Grupos são complicados... prefiro evitar problemas.", 2, 5, 0, 3)
    BanditDialogues.addDialogue("know-one", "Tem alguma habilidade incomum?", "Eu consigo abrir fechaduras. Isso já me salvou antes.", 2, 4, 2, 5)
    BanditDialogues.addDialogue("know-one", "Você ainda tem esperanças?", "Esperança não enche o estômago.", 3, 5, -1, 3)
    BanditDialogues.addDialogue("know-one", "Já encontrou alguém pior que os zumbis?", "Muitas vezes. Humanos podem ser muito piores.", 3, 6, -3, 2)
    BanditDialogues.addDialogue("know-one", "Você acredita em sorte?", "Se acreditar trouxesse comida, eu acreditaria.", 2, 5, 1, 5)

    BanditDialogues.addDialogOption("know", "know-two", "Perguntar sobre a familia", 0)
    BanditDialogues.addDialogue("know-two", "O que aconteceu com sua familia?", "Meu filho Peter deve estar por ai, mas os outros... bem, voce sabe.", 2, 5, 1, 5)
    

    -- ===================================================================================
    -- Friendly
    BanditDialogues.addCategory("none", "friendly", getText("IGUI_BanditDialog_Category_Friendly"), 0)

    -- Submenu 1
    BanditDialogues.addDialogOption("friendly", "friendly-about-day", "Como vai o seu dia?", 0)
    -- Responses in Dialogs/DialogsAboutDay
    DialogsAboutDay.loadDialogues()
    
    -- Submenu 2
    BanditDialogues.addDialogOption("friendly", "friendly-two", "Como voce esta?", 0)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou bem, obrigado por perguntar.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Já estive melhor, mas estou sobrevivendo.", 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Não muito bem, mas vou ficar bem.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou cansado, mas ainda de pé.", 1, 3, 0, 4)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco desanimado.", -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou ótimo, obrigado por perguntar.", 3, 6, 2, 5)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco solitário.", 0, 2, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou com fome, mas estou bem.", 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou com medo, mas vou continuar lutando.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo esperançoso hoje.", 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou um pouco preocupado com o futuro.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco perdido.", -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou bem, apenas cansado.", 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco ansioso.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco triste.", -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco confuso.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco frustrado.", -1, 2, -2, 1)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco esperançoso.", 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco otimista.", 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco pessimista.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco nervoso.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco calmo.", 1, 4, 0, 3)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco relaxado.", 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco tenso.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco aliviado.", 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco preocupado.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco animado.", 2, 5, 1, 4)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco entediado.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco exausto.", 0, 3, -1, 2)
    BanditDialogues.addDialogue("friendly-two", "Como você está?", "Estou me sentindo um pouco revigorado.", 2, 5, 1, 4)

    -- ===================================================================================
    -- Jokes
    BanditDialogues.addCategory("none", "jokes", "Piadas", 20)

    -- Submenu 1
    BanditDialogues.addDialogOption("jokes", "jokes-one", "Me conte uma piada", 0)
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada.", "O que e um ponto azul voando?", 2, 5, 1, 5, "Uma bluebluereta")
    BanditDialogues.addDialogue("jokes-one", "Me conte outra piada.", "Por que o livro de matemática se suicidou?", 2, 5, 1, 5, "Porque ele tinha muitos problemas.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de médico.", "O que o tomate foi fazer no hospital?", 2, 5, 1, 5, "Ele foi se tratar.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de escola.", "Por que o livro de história estava sempre deprimido?", 2, 5, 1, 5, "Porque ele tinha muitos capítulos tristes.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de frutas.", "O que a banana falou para o tomate?", 2, 5, 1, 5, "Eu quebro você no meio.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de animais.", "Por que o cachorro não gosta de assistir TV?", 2, 5, 1, 5, "Porque ele já viu tudo em preto e branco.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de comida.", "Por que o pão não entende as piadas?", 2, 5, 1, 5, "Porque ele é meio duro.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de esportes.", "Por que o jogador de futebol foi ao banco?", 2, 5, 1, 5, "Para tirar o extrato.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de tecnologia.", "Por que o computador foi ao médico?", 2, 5, 1, 5, "Porque ele estava com um vírus.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de música.", "Por que o músico foi preso?", 2, 5, 1, 5, "Porque ele tocou uma nota falsa.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de matemática.", "Por que o número 6 tem medo do número 7?", 2, 5, 1, 5, "Porque 7 8 9.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de ciências.", "Por que o átomo foi preso?", 2, 5, 1, 5, "Porque ele quebrou a lei.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de geografia.", "Por que o mapa foi ao terapeuta?", 2, 5, 1, 5, "Porque ele estava perdido.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de história.", "Por que o faraó não gostava de piadas?", 2, 5, 1, 5, "Porque ele estava sempre em negação.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de química.", "Por que o hidrogênio e o oxigênio foram ao bar?", 2, 5, 1, 5, "Para fazer H2O.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de física.", "Por que o elétron não pode ser convidado para festas?", 2, 5, 1, 5, "Porque ele é muito negativo.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de astronomia.", "Por que o astronauta quebrou com a namorada?", 2, 5, 1, 5, "Porque ele precisava de espaço.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de biologia.", "Por que a célula foi ao psicólogo?", 2, 5, 1, 5, "Porque ela estava dividida.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de literatura.", "Por que o escritor foi ao hospital?", 2, 5, 1, 5, "Porque ele estava com um bloqueio.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de arte.", "Por que o pintor foi preso?", 2, 5, 1, 5, "Porque ele foi pego em flagrante.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de teatro.", "Por que o ator foi ao banco?", 2, 5, 1, 5, "Para fazer uma cena.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de dança.", "Por que o dançarino foi ao médico?", 2, 5, 1, 5, "Porque ele estava com um passo errado.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de fotografia.", "Por que o fotógrafo foi ao banco?", 2, 5, 1, 5, "Para tirar uma foto.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de cinema.", "Por que o diretor foi ao hospital?", 2, 5, 1, 5, "Porque ele estava com um corte.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de televisão.", "Por que o apresentador foi ao banco?", 2, 5, 1, 5, "Para fazer um programa.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de rádio.", "Por que o locutor foi ao médico?", 2, 5, 1, 5, "Porque ele estava com uma frequência.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de jornal.", "Por que o jornalista foi ao banco?", 2, 5, 1, 5, "Para fazer uma matéria.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de revista.", "Por que o editor foi ao médico?", 2, 5, 1, 5, "Porque ele estava com uma edição.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de internet.", "Por que o blogueiro foi ao banco?", 2, 5, 1, 5, "Para fazer um post.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de redes sociais.", "Por que o influenciador foi ao médico?", 2, 5, 1, 5, "Porque ele estava com uma tendência.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de marketing.", "Por que o publicitário foi ao banco?", 2, 5, 1, 5, "Para fazer uma campanha.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de vendas.", "Por que o vendedor foi ao médico?", 2, 5, 1, 5, "Porque ele estava com uma oferta.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada engraçada.", "O que o pato disse para a pata?", 2, 5, 1, 5, "Vem quá!")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada curta.", "Por que a galinha atravessou a rua?", 2, 5, 1, 5, "Para chegar do outro lado.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada boba.", "O que é um pontinho amarelo na estrada?", 2, 5, 1, 5, "Um fandangos.")
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada de animais.", "Por que o elefante não usa computador?", 2, 5, 1, 5, "Porque ele tem medo do mouse.")

    -- Submenu 2
    BanditDialogues.addDialogOption("jokes", "jokes-two", "Contar uma piada", 0)

    -- ===================================================================================
    -- Survive
    BanditDialogues.addCategory("friendly", "survive", "Sobrevivencia", 15)

    -- Submenu 1
    BanditDialogues.addDialogOption("survive", "survive-one", "Tem alguma dica?", 0)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um plano de fuga.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Nunca confie em estranhos.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha seus suprimentos organizados.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite fazer barulho desnecessário.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha uma arma reserva.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a cozinhar com ingredientes simples.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha-se em forma, você pode precisar correr.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Conheça bem a área ao redor do seu abrigo.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um kit de primeiros socorros.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Economize munição, use armas brancas quando possível.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um esconderijo seguro.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite áreas densamente povoadas.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha-se hidratado, a água é essencial.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a fazer fogo sem fósforos.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um mapa da região.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite confrontos desnecessários.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha-se calmo em situações de perigo.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a identificar plantas comestíveis.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha uma fonte de luz.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite viajar sozinho.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha suas ferramentas afiadas.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a construir abrigos improvisados.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um plano B.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite consumir alimentos estragados.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha-se aquecido em climas frios.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a pescar e caçar.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um sinalizador de emergência.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite beber água não tratada.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha-se informado sobre o clima.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a costurar e reparar roupas.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um apito para sinalização.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite áreas com muitos zumbis.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha-se em silêncio para evitar atenção.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a fazer armadilhas.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um rádio para comunicação.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite locais abertos durante tempestades.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Mantenha-se alerta a qualquer movimento.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Aprenda a nadar.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Sempre tenha um canivete multifuncional.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("survive-one", "Tem alguma dica de sobrevivência?", "Evite consumir água salgada.", 2, 5, 1, 5)    
end

BanditDialogues.loadDialogues()
