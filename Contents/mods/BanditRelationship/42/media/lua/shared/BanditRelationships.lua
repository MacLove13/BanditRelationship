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
        print("ERROR: Player not founded.")
        return
    end

    local worldData = playa:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end
    local data = worldData.BanditRelationships

    local id = bandit.id 
    
    if not data[id] then
        data[id] = {
            knows = false,
            relation = 0, 
            banditId = bandit.id,
            name = bandit.fullname,
        }
    end

    local rel = data[id].relation
    rel = rel + amount

    if rel > 100 then 
        rel = 100 
    elseif rel < -100 then 
        rel = -100
    end

    data[id].relation = rel
end

function BanditRelationships.knowBandit(player, bandit)
    local playa = getSpecificPlayer(0)
    if not playa then
        print("ERROR: Player not founded.")
        return
    end

    local worldData = playa:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end

    local data = worldData.BanditRelationships
    local id = bandit.id
    
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
        print("ERROR: Player not founded.")
        return
    end
    
    local worldData = playa:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end

    local data = worldData.BanditRelationships
    local id = bandit.id

    if data[id] then
        data[id] = nil
        print("Bandit '" .. bandit.fullname .. "' removed at BanditRelationships.")
    else
        print("Bandido not founded in table (ID: "..tostring(id)..").")
    end
end

Events.OnGameStart.Add(BanditRelationships.initModData)






