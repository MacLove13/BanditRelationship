local OpennedRelationshipMenu = false

-- =========================
-- 1) SOBRE a janela "Sobre"
-- =========================
AboutUI = ISCollapsableWindow:derive("AboutUI")

function AboutUI:new(x, y, width, height, title)
    local o = {}
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.title = title or "Sobre"
    o.resizable = false
    return o
end

function AboutUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:createChildren()
end

function AboutUI:createChildren()
    ISCollapsableWindow.createChildren(self)

    -- Cria um painel interno para desenhar o texto
    self.mainPanel = ISPanel:new(0, 16, self.width, self.height - 16)
    self.mainPanel:initialise()
    self.mainPanel:instantiate()
    self.mainPanel.noBackground = false
    self:addChild(self.mainPanel)

    -- Podemos sobrescrever o render do mainPanel para exibir texto fixo
    function self.mainPanel:render()
        self:drawText("Este é o texto de Sobre.\nAqui você coloca informações sobre o mod, versão, etc.", 
                      10, 10, 1, 1, 1, 1, UIFont.Medium)
    end
end

function AboutUI.show()
    local ui = AboutUI:new(200, 200, 300, 150, "Sobre o Mod")
    ui:initialise()
    ui:addToUIManager()
end

-- ==================================
-- 2) A janela principal BanditDialogueUI
-- ==================================
BanditDialogueUI = ISCollapsableWindow:derive("BanditDialogueUI")

-- Variável estática para indicar se estamos selecionando posição no mapa
-- (poderia ficar noutro lugar, mas deixamos aqui para exemplo).
BanditDialogueUI.selectedBanditForMovement = nil

function BanditDialogueUI:new(x, y, width, height, title)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.title = title or "Bandit UI"      -- texto que vai aparecer na barra
    o.resizable = false                 -- se quiser impedir redimensionar
    return o
end

function BanditDialogueUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:createChildren()
end

function BanditDialogueUI:createChildren()
    -- Chama a criação base (cria barra, botões de colapsar/fechar etc.)
    ISCollapsableWindow.createChildren(self)

    -- Painel principal com scroll para lista de bandidos
    self.mainPanel = ISPanel:new(0, 16, self.width, self.height - 16)
    self.mainPanel:initialise()
    self.mainPanel:instantiate()
    self.mainPanel:noBackground()  -- ou self.mainPanel.noBackground = true
    self:addChild(self.mainPanel)

    -- 3) Se quiser um botão na própria barra, crie e posicione:
    self.infoButton = ISButton:new(self.width - 70, 2, 40, 14, "Info", self, BanditDialogueUI.onInfo)
    self.infoButton:initialise()
    self:addChild(self.infoButton)

    -- Sobrescrevemos a função render do mainPanel para desenhar a lista
    function self.mainPanel:render()
        -- Posição inicial de desenho
        local yOffset = 10

        -- Exemplo de título
        self:drawText("Relacionamentos:", 10, yOffset, 1, 1, 1, 1, UIFont.Large)
        yOffset = yOffset + 30

        -- Ordena os bandidos pelos mais próximos do player
        local sortedBandits = BanditDialogueUI.getSortedBanditsByDistance()
        for _, entry in ipairs(sortedBandits) do
            local id   = entry.id
            local info = entry.info

            local zombie = findZombieByID(id)
            if not zombie then
                break
            end

            local brain = BanditBrain.Get(zombie)
            if not brain then
                break
            end

            -- Nome do bandido
            self:drawText(info.name .. " (" .. brain.program.name .. ")" or ("ID: "..tostring(id)), 10, yOffset, 1, 1, 1, 1, UIFont.Medium)
            yOffset = yOffset + 25

            -- Barra (vida ou "relação")
            local barX = 10
            local barY = yOffset
            local barWidth = 140
            local barHeight = 10

            self:drawRect(barX, barY, barWidth, barHeight, 0.5, 0.5, 0.5, 0.5)

            local relation = info.relation or 0
            if relation > 100 then relation = 100 end
            if relation < -100 then relation = -100 end
            local fillWidth = math.abs(relation) / 100 * barWidth

            if relation >= 0 then
                self:drawRect(barX, barY, fillWidth, barHeight, 1, 0, 1, 0)
            else
                self:drawRect(barX, barY, fillWidth, barHeight, 1, 1, 0, 0)
            end

            -- 3 botões ao lado
            -- (Você poderia, em vez de desenhar, adicionar ISButton. 
            --  Mas para cada bandido, teria que gerenciar children dinamicamente.
            --  Exemplo rápido desenhando e verificando clique - ou criando botões.)
            -- A seguir está como CRIAR se preferir.
            if not self.parent.buttons then self.parent.buttons = {} end
            if not self.parent.buttons[id] then
                self.parent.buttons[id] = {}

                -- Botão 1
                local btn1 = ISButton:new(barX + barWidth + 60, barY - 5, 40, 20, "Seguir", self.parent, BanditDialogueUI.onBanditButton)
                btn1.internalData = {banditID=id, action="botao1"}
                btn1:initialise()
                self.parent:addChild(btn1)
                self.parent.buttons[id][1] = btn1

                -- Botão 2
                local btn2 = ISButton:new(barX + barWidth + 55, barY - 5, 40, 20, "B2", self.parent, BanditDialogueUI.onBanditButton)
                btn2.internalData = {banditID=id, action="botao2"}
                btn2:initialise()
                self.parent:addChild(btn2)
                self.parent.buttons[id][2] = btn2

                -- Botão 3 - este será o de "ir até onde eu clicar"
                local btn3 = ISButton:new(barX + barWidth + 100, barY - 5, 40, 20, "Go", self.parent, BanditDialogueUI.onBanditButton)
                btn3.internalData = {banditID=id, action="moveTo"}
                btn3:initialise()
                self.parent:addChild(btn3)
                self.parent.buttons[id][3] = btn3
            else
                -- Atualiza posição (caso haja scroll/resizing)
                local btns = self.parent.buttons[id]
                btns[1]:setX(barX + barWidth + 10);   btns[1]:setY(barY + 10)
                btns[2]:setX(barX + barWidth + 55);   btns[2]:setY(barY + 10)
                btns[3]:setX(barX + barWidth + 100);  btns[3]:setY(barY + 10)
            end

            yOffset = yOffset + barHeight + 20

            -- Desenha linha horizontal separando
            self:drawRect(5, yOffset, self.width - 10, 1, 1, 1, 1, 1)  
            yOffset = yOffset + 10
        end

        -- A altura total “interna” passa a ser yOffset, caso exceda self.height
        self:setScrollHeight(yOffset + 10)
    end

    -- Botão "Info" na barra
    self.infoButton = ISButton:new(self.width - 70, 2, 40, 14, "Info", self, BanditDialogueUI.onInfo)
    self.infoButton:initialise()
    self.infoButton:instantiate()
    self.infoButton.borderColor = {r=1, g=1, b=1, a=1}
    self:addChild(self.infoButton)
end

-- Chamado ao clicar no Botão Info da barra
function BanditDialogueUI:onInfo()
    print("Botão Info clicado!")
    AboutUI.show()  -- Abre a janela de 'Sobre'
end

-- Chamado ao clicar nos botões B1, B2, ou Go
function BanditDialogueUI:onBanditButton(button)
    local data = button.internalData
    if data.action == "moveTo" then
        -- Exemplo: setar para que o próximo clique no mundo defina o destino
        BanditDialogueUI.selectedBanditForMovement = data.banditID
        print("Selecione no mapa onde o bandido deve ir. (Exemplo)")
    else
        local isoZ = findZombieByID(data.banditID)
        if isoZ then
            print("Bandit founded")
        else
            print("Bandit not founded")
        end

        -- Outras ações que quiser (B1, B2)  
        print("Executa ação:", data.action, "para bandido:", data.banditID)
    end
end

-- Se você quiser “capturar” clique no mapa, pode fazer algo como:
-- (Código simplificado de exemplo)
local function onMouseDownOnGameWorld(x, y)
    if BanditDialogueUI.selectedBanditForMovement then
        local id = BanditDialogueUI.selectedBanditForMovement
        BanditDialogueUI.selectedBanditForMovement = nil
        print("Bandido", id, "vai se mover para:", x, y)
        -- Aqui chamaria a lógica de movimento do bandido
        -- ...
    end
end
Events.OnMouseDown.Add(onMouseDownOnGameWorld)

-- ------------------------------------
-- Funções auxiliares
-- ------------------------------------

-- Exemplo de função que retorna bandidos ordenados pela distância ao player
function BanditDialogueUI.getSortedBanditsByDistance()
    local sorted = {}
    local player = getSpecificPlayer(0)

    -- Garante que existe worldData e data
    local playa = getPlayer();
    local worldData = playa:getModData()
    local data = worldData.BanditRelationships
    if not data then
        return sorted -- Se por algum motivo ainda estiver nil, retorna vazio
    end

    -- Se não há player (ou seja, singleplayer sem player carregado?), só retorna todos sem distância
    if not player then
        for id, info in pairs(data) do
            table.insert(sorted, {id=id, info=info, dist=999999})
        end
        return sorted
    end

    -- Caso exista um player, calcule a distância
    local px, py = player:getX(), player:getY()

    for id, info in pairs(data) do
        local bx = info.x or 0
        local by = info.y or 0

        local dx = bx - px
        local dy = by - py
        local dist = math.sqrt(dx*dx + dy*dy)

        table.insert(sorted, {id=id, info=info, dist=dist})
    end

    -- Ordena por distância
    table.sort(sorted, function(a,b) return a.dist < b.dist end)
    return sorted
end

function BanditDialogueUI.show()
    if not OpennedRelationshipMenu then
        local ui = BanditDialogueUI:new(100, 100, 300, 400, "Minha Janela")
        ui:initialise()
        ui:addToUIManager()

        OpennedRelationshipMenu = true
    end
end

function BanditDialogueUI:close()
    OpennedRelationshipMenu = false -- Reseta a variável quando a janela for fechada
    self:removeFromUIManager() -- Remove a janela do UI Manager
end

function findZombieByID(id)
    local cell = getCell()
    if not cell then return nil end

    local zombieList = cell:getZombieList()
    if not zombieList then return nil end

    for i = 0, zombieList:size() - 1 do
        local z = zombieList:get(i)
        if z and BanditUtils.GetCharacterID(z) == id then
            return z
        end
    end

    return nil -- não achou
end
