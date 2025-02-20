BanditDialogues = BanditDialogues or {
    categories = {},
    dialogOptions = {}
}

-- Tabela principal de diálogos, dividida por tópico
BanditDialogues.dialogues = {
    normal_speak   = {},
    friendly_speak = {},
    hostile_speak  = {},
}

------------------------------------------------
-- 1) Adicionar diálogos com table.insert
------------------------------------------------
--- Adiciona um novo par de falas (player/bandit) a um tópico
---@param topic string - ex: "normal_speak"
---@param playerLine string - falas do jogador
---@param banditLine string - falas do bandido
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

function BanditDialogues.addCategory(insideCategory, uniqueId, name, minRelation)
    -- Se a categoria não existir, cria a lista vazia
    if not BanditDialogues.categories[uniqueId] then
        BanditDialogues.categories[uniqueId] = {}
    end

    -- Adiciona a nova categoria dentro da lista correspondente ao uniqueId
    table.insert(BanditDialogues.categories[uniqueId], {
        unique_id = uniqueId,
        inside_category = insideCategory,
        name = name,
        min_relation = minRelation
    })
end

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
-- 2) Funções de escolha do diálogo
------------------------------------------------
--- Pega um par de fala aleatório de uma categoria
function BanditDialogues.getRandomDialogue(topic)
    local list = BanditDialogues.dialogues[topic]
    if not list or #list == 0 then 
        return nil 
    end

    local rnd = ZombRand(#list) + 1
    return list[rnd]
end

------------------------------------------------
-- 3) Executar o diálogo
------------------------------------------------
function BanditDialogues.generateRandomInteger(min, max)
    return min + ZombRand((max - min) + 1)
end

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

function BanditDialogues.doRandomDialogue(player, zombie, topic)
    local brain = BanditBrain.Get(zombie)
    if not brain or (brain.program.name ~= "Companion" and brain.program.name ~= "CompanionGuard") then
        return
    end

    topic = topic or "none"
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
-- 4) Menu de contexto
------------------------------------------------
function BanditDialogues.loadSubMenusForCategory(player, context, category_uniqueId, zombie)
    local addedCategories = {}
    local friendlyOption = nil
    local friendlyContext = nil

    local brain = BanditBrain.Get(zombie)
    if not brain or (brain.program.name ~= "Companion" and brain.program.name ~= "CompanionGuard") then
        return
    end

    local knows, relation = BanditRelationships.getRelationship(player, brain)

    for uniqueId, categoryList in pairs(BanditDialogues.categories) do
        for _, category in ipairs(categoryList) do
            if relation >= category.min_relation then
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

    -- Tenta encontrar um "zombie" com a variável Bandit
    local brain = BanditBrain.Get(zombie)
    if not brain or (brain.program.name ~= "Companion" and brain.program.name ~= "CompanionGuard") then
        return
    end

    -- Cria uma opção "Falar com ..."
    local option = context:addOption("Falar com " .. brain.fullname)
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)

    local friendlyOption = nil -- subMenu:addOption("Ser amigavel")
    local friendlyContext = nil -- subMenu:getNew(subMenu)
    -- subMenu:addSubMenu(friendlyOption, friendlyContext)

    BanditDialogues.loadSubMenusForCategory(player, subMenu, "none", zombie)

    -- Opção de conversa aleatória
    -- friendlyContext:addOption("Bater papo", player, function() 
    --     BanditDialogues.doRandomDialogue(player, zombie)
    -- end)

    -- -- Exemplo de outras opções usando BanditDialogues
    -- friendlyContext:addOption("Elogiar", player, function()
    --     BanditDialogues.doRandomDialogue(player, zombie)
    -- end)

    -- subMenu:addOption("Insultar (Rel-6)", player, function()
    --     BanditDialogues.doRandomDialogue(player, zombie, "hostile_speak")
    -- end)
end

Events.OnPreFillWorldObjectContextMenu.Add(BanditDialogues.addDialogueMenu)

------------------------------------------------
-- 5) Exemplos de diálogos iniciais
------------------------------------------------
-- Você pode registrar diálogos iniciais chamando addDialogue em tempo de carga:
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
    BanditDialogues.addDialogOption("friendly", "friendly-one", "Como vai o seu dia?", 0)
    BanditDialogues.addDialogue("friendly-one", "Como vai seu dia?", "Esta tudo bem.", 2, 5, 1, 5)
    BanditDialogues.addDialogue("friendly-one", "Como vai seu dia?", "Uma merda.", -1, -5, -5, -10)
    BanditDialogues.addDialogue("friendly-one", "Como vai seu dia?", "Ja tive dias melhores.", 0, 1, 0, 2)
    BanditDialogues.addDialogue("friendly-one", "Como vai seu dia?", "Estamos no apocalipse, nao podia ser melhor.", 0, -5, -5, -10)

    -- Submenu 2
    BanditDialogues.addDialogOption("friendly", "friendly-two", "Como voce esta?", 0)


    -- ===================================================================================
    -- Jokes
    BanditDialogues.addCategory("none", "jokes", "Piadas", 20)

    -- Submenu 1
    BanditDialogues.addDialogOption("jokes", "jokes-one", "Me conte uma piada", 0)
    BanditDialogues.addDialogue("jokes-one", "Me conte uma piada.", "O que e um ponto azul voando?", 2, 5, 1, 5, "Uma bluebluereta")

    -- Submenu 2
    BanditDialogues.addDialogOption("jokes", "jokes-two", "Contar uma piada", 0)

    -- ===================================================================================
    -- Survive
    BanditDialogues.addCategory("friendly", "survive", "Sobrevivencia", 15)

    -- Submenu 1
    BanditDialogues.addDialogOption("survive", "survive-one", "Tem alguma dica?", 0)
end

BanditDialogues.loadDialogues()
