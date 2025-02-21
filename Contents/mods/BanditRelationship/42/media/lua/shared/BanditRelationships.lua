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
        data[id] = BanditRelationships.createRelationship(bandit)
    end

    return data[id]
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
        data[id] = BanditRelationships.createRelationship(bandit)
    end

    local rel = data[id].relation
    rel = rel + amount

    if rel > 100 then 
        rel = 100 
    elseif rel < -100 then 
        rel = -100
    end

    data[id].relation = rel

    print ("Relation changed to " .. rel)
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
        data[id] = BanditRelationships.createRelationship(bandit)
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

function BanditRelationships.removeBanditById(banditId)
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
    local id = banditId

    if data[id] then
        data[id] = nil
    else
        print("Bandido not founded in table (ID: "..tostring(id)..").")
    end
end

function BanditRelationships.createRelationship(bandit)
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
        local childrens = BanditRelationships.getRandomNumberOfChildren()

        data[id] = {
            knows = false,
            relation = 0,
            banditId = bandit.id,
            name = bandit.fullname,
            profession = BanditRelationships.getRandomProfession(),
            maritalStatus = BanditRelationships.getRandomMaritalStatus(),
            numberOfChildren = childrens,
            hasChildren = childrens > 0,
            personalitie = BanditRelationships.getRandomPersonality(),
            dayMood = BanditRelationships.getRandomDayMood()
        }
    end

    return data[id]
end

function BanditRelationships.getRandomProfession()
    local professions = {
        "Lawyer",
        "Banker",
        "Student",
        "Teacher",
        "Dancer",
        "Actor",
        "Engineer",
        "Doctor",
        "Nurse",
        "Police",
        "Firefighter",
        "Cook",
        "Driver",
        "Journalist",
        "Architect",
        "Designer",
        "Programmer",
        "Scientist",
        "Mechanic",
        "Farmer",
        "Veterinarian",
        "Pharmacist",
        "Psychologist",
        "Dentist",
        "Pilot",
        "Soldier",
        "Artist",
        "Musician",
        "Writer",
        "Librarian",
        "Geologist",
        "Astronomer",
        "Historian",
        "Economist",
        "Mathematician",
        "Physicist",
        "Chemist",
        "Biologist",
        "Sociologist",
        "Barista",
        "Photographer",
        "Carpenter",
        "Clerk",
        "Cashier"
    }
    return professions[ZombRand(#professions) + 1]
end

function BanditRelationships.getRandomDayMood()
    local dayMoods = {
        "day-good",
        "day-shit",
        "day-bad",
        "day-wonderful",
        "day-sucks",
        "day-boring",
        "day-normal"
    }
    return dayMoods[ZombRand(#dayMoods) + 1]
end

function BanditRelationships.getRandomMaritalStatus()
    local statuses = {
        "Single",
        "Married",
        "Divorced",
        "Separated"
    }
    return statuses[ZombRand(#statuses) + 1]
end

function BanditRelationships.getRandomNumberOfChildren()
    return ZombRand(0, 5) -- Random number between 0 and 4
end

function BanditRelationships.getRandomPersonality()
    local personalities = { "Calm", "Aggressive", "Stressed", "Friendly", "Hostile", "Sad" }
    return personalities[ZombRand(#personalities) + 1]
end

Events.OnGameStart.Add(BanditRelationships.initModData)


