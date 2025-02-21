local function checkNewDay()
    local player = getPlayer()
    if not player then return end

    local worldData = player:getModData()
    if not worldData.BanditRelationships then
        worldData.BanditRelationships = {}
    end
    local data = worldData.BanditRelationships

    -- Loop por todos os bandidos armazenados
    for banditId, relationship in pairs(data) do
        relationship.dayMood = BanditRelationships.getRandomDayMood()
    end
end

Events.EveryDays.Add(checkNewDay)
