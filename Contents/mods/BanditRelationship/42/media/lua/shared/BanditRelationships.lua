BanditRelationships = BanditRelationships or {}

function BanditRelationships.initModData()
    local playa = getSpecificPlayer(0)
    local worldData = playa:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end
end

function BanditRelationships.getRelationship(player, bandit)
    local playa = getSpecificPlayer(0)
    local worldData = playa:getModData()
    local data = worldData.BanditRelationships

    local id = bandit.id

    -- Se ainda não existir, inicializa a relação
    if not data[id] then
        data[id] = { 
            knows = false,
            relation = 0,
            banditId = id,
            name = bandit.fullname
        }
    end

    return data[id].knows, data[id].relation
end

function BanditRelationships.modifyRelationship(player, bandit, amount)
    local playa = getSpecificPlayer(0)
    if not playa then
        print("ERRO: Nenhum player encontrado.")
        return
    end

    local worldData = playa:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end
    local data = worldData.BanditRelationships

    local id = bandit.id  -- ou tostring(bandit.id)
    
    -- Se ainda não existir, inicializa
    if not data[id] then
        data[id] = {
            knows = false,
            relation = 0, 
            banditId = bandit.id,
            name = bandit.fullname,
        }
    end

    -- Modifica o relacionamento
    local rel = data[id].relation
    rel = rel + amount

    -- Limita entre -100 e 100
    if rel > 100 then 
        rel = 100 
    elseif rel < -100 then 
        rel = -100
    end

    data[id].relation = rel

    print("Relação com " .. bandit.fullname .. ": " .. rel)
end

function BanditRelationships.knowBandit(player, bandit)
    local playa = getSpecificPlayer(0)
    if not playa then
        print("ERRO: Nenhum player encontrado.")
        return
    end

    local worldData = playa:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end

    local data = worldData.BanditRelationships
    local id = bandit.id  -- ou tostring(bandit.id)
    
    -- Se ainda não existir, inicializa
    if not data[id] then
        data[id] = {
            knows = true,
            relation = 0, 
            banditId = bandit.id,
            name = bandit.fullname,
        }
    end

    data[id].relation = 5
    data[id].knows = true
end

function BanditRelationships.removeBandit(bandit)
    local playa = getSpecificPlayer(0)
    if not playa then
        print("ERRO: Nenhum player encontrado.")
        return
    end
    
    local worldData = playa:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end

    local data = worldData.BanditRelationships
    local id = bandit.id  -- ou tostring(bandit.id), se você usa string

    -- Se o ID existir na tabela, removemos (nil).
    if data[id] then
        data[id] = nil
        print("Bandido '" .. bandit.fullname .. "' foi removido de BanditRelationships.")
    else
        print("Bandido não encontrado na tabela (ID: "..tostring(id)..").")
    end
end

Events.OnGameStart.Add(BanditRelationships.initModData)






