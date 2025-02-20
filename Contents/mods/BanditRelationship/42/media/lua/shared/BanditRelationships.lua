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
        "Advogado",
        "Bancário",
        "Estudante",
        "Professor",
        "Dançarino",
        "Ator",
        "Engenheiro",
        "Médico",
        "Enfermeiro",
        "Policial",
        "Bombeiro",
        "Cozinheiro",
        "Motorista",
        "Jornalista",
        "Arquiteto",
        "Designer",
        "Programador",
        "Cientista",
        "Mecânico",
        "Agricultor",
        "Veterinário",
        "Farmacêutico",
        "Psicólogo",
        "Dentista",
        "Piloto",
        "Soldado",
        "Artista",
        "Músico",
        "Escritor",
        "Bibliotecário",
        "Geólogo",
        "Astrônomo",
        "Historiador",
        "Economista",
        "Matemático",
        "Físico",
        "Químico",
        "Biólogo",
        "Sociólogo",
        "Barista",
        "Fotógrafo",
        "Carpinteiro",
        "Eletricista",
        "Encanador",
        "Marceneiro",
        "Padeiro",
        "Garçom",
        "Recepcionista",
        "Secretário",
        "Advogado Criminal",
        "Advogado Civil",
        "Engenheiro de Software",
        "Engenheiro Civil",
        "Engenheiro Elétrico",
        "Engenheiro Mecânico",
        "Engenheiro Químico",
        "Engenheiro de Produção",
        "Engenheiro Ambiental",
        "Engenheiro de Telecomunicações",
        "Engenheiro de Alimentos",
        "Engenheiro de Materiais",
        "Engenheiro de Minas",
        "Engenheiro de Petróleo",
        "Engenheiro de Segurança do Trabalho",
        "Engenheiro de Transportes",
        "Engenheiro de Controle e Automação",
        "Engenheiro de Computação",
        "Engenheiro de Energia",
        "Engenheiro de Instrumentação",
        "Engenheiro de Manutenção",
        "Engenheiro de Processos",
        "Engenheiro de Projetos",
        "Engenheiro de Qualidade",
        "Engenheiro de Sistemas",
        "Engenheiro de Suprimentos",
        "Engenheiro de Vendas",
        "Engenheiro de Produção Mecânica",
        "Engenheiro de Produção Civil",
        "Engenheiro de Produção Elétrica",
        "Engenheiro de Produção Química",
        "Engenheiro de Produção de Alimentos",
        "Engenheiro de Produção de Materiais",
        "Engenheiro de Produção de Minas",
        "Engenheiro de Produção de Petróleo",
        "Engenheiro de Produção de Segurança do Trabalho",
        "Engenheiro de Produção de Transportes",
        "Engenheiro de Produção de Controle e Automação",
        "Engenheiro de Produção de Computação",
        "Engenheiro de Produção de Energia",
        "Engenheiro de Produção de Instrumentação",
        "Engenheiro de Produção de Manutenção",
        "Engenheiro de Produção de Processos",
        "Engenheiro de Produção de Projetos",
        "Engenheiro de Produção de Qualidade",
        "Engenheiro de Produção de Sistemas",
        "Engenheiro de Produção de Suprimentos",
        "Engenheiro de Produção de Vendas",
        "Balconista",
        "Caixa de mercado",
    }
    return professions[ZombRand(#professions) + 1]
end

function BanditRelationships.getRandomDayMood()
    local dayMood = {
        "day-good",
        "day-shit",
        "day-bad",
        "day-wonderful",
        "day-sucks",
        "day-boring",
        "day-normal"
    }
    return professions[ZombRand(#professions) + 1]
end

function BanditRelationships.getRandomMaritalStatus()
    local statuses = {
        "Solteiro",
        "Casado",
        "Divorciado",
        "Separado"
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


