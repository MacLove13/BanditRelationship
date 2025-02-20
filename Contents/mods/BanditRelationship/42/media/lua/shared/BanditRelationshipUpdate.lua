local function OnZombieDead(zombie)
    if not zombie:getVariableBoolean("Bandit") then return end
        
    local bandit = zombie

    -- hostility against civilians (clan=0) is handled by other mods
    local brain = BanditBrain.Get(bandit)
    if brain.clan == 0 then return end

    BanditRelationships.removeBandit(bandit)
end

Events.OnZombieDead.Add(OnZombieDead)
