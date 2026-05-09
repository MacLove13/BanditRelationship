
----------------------------
--- On Bandit Dead -> Remove relation
----------------------------
local function OnZombieDead(zombie)
    if not zombie:getVariableBoolean("Bandit") then return end

    local brain = BanditBrain.Get(zombie)
    if not brain or brain.clan == 0 then return end

    BanditRelationships.removeBandit(brain)
end

Events.OnZombieDead.Add(OnZombieDead)
