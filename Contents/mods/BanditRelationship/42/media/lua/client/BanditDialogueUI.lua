local OpennedRelationshipMenu = false

----------------------------
--- About Window
----------------------------
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

    self.mainPanel = ISPanel:new(0, 16, self.width, self.height - 16)
    self.mainPanel:initialise()
    self.mainPanel:instantiate()
    self.mainPanel.noBackground = false
    self:addChild(self.mainPanel)

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

----------------------------
--- Main Bandit UI Window
----------------------------
BanditDialogueUI = ISCollapsableWindow:derive("BanditDialogueUI")
BanditDialogueUI.selectedBanditForMovement = nil

function BanditDialogueUI:new(x, y, width, height, title)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.title = title or "Bandit UI"
    o.resizable = false
    return o
end

function BanditDialogueUI:initialise()
    ISCollapsableWindow.initialise(self)
    self:createChildren()
end

function BanditDialogueUI:createChildren()
    ISCollapsableWindow.createChildren(self)

    self.mainPanel = ISPanel:new(0, 16, self.width, self.height - 16)
    self.mainPanel:initialise()
    self.mainPanel:instantiate()
    self.mainPanel:noBackground()
    self:addChild(self.mainPanel)

    -- self.infoButton = ISButton:new(self.width - 70, 2, 40, 14, "Info", self, BanditDialogueUI.onInfo)
    -- self.infoButton:initialise()
    -- self:addChild(self.infoButton)

    function self.mainPanel:render()
        local yOffset = 10

        self:drawText(getText("UI_BanditDeialogue_OptionsMenu_Relationships"), 10, yOffset, 1, 1, 1, 1, UIFont.Large)
        yOffset = yOffset + 30

        local sortedBandits = BanditDialogueUI.getSortedBanditsByDistance()

        for _, entry in ipairs(sortedBandits) do
            local id   = entry.id
            local info = entry.info

            local zombie = findZombieByID(id)
            if not zombie then
                BanditRelationships.removeBanditById(id)
                break
            end

            local brain = BanditBrain.Get(zombie)
            if not brain then
                BanditRelationships.removeBanditById(id)
                break
            end

            self:drawText(info.name .. " (" .. brain.program.name .. ")" or ("ID: "..tostring(id)), 10, yOffset, 1, 1, 1, 1, UIFont.Medium)
            yOffset = yOffset + 25

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

            if not self.parent.buttons then self.parent.buttons = {} end
            if not self.parent.buttons[id] then
                self.parent.buttons[id] = {}

                -- Button 1
                local btn1 = ISButton:new(barX + barWidth + 100, barY - 5, 40, 20, getText("UI_BanditDeialogue_OptionsMenu_RelationshipRemove"), self.parent, BanditDialogueUI.onBanditButton)
                btn1.internalData = {banditID=id, action="remove"}
                btn1:initialise()
                self.parent:addChild(btn1)
                self.parent.buttons[id][1] = btn1

                -- Button 2
                -- local btn2 = ISButton:new(barX + barWidth + 55, barY - 5, 40, 20, "B2", self.parent, BanditDialogueUI.onBanditButton)
                -- btn2.internalData = {banditID=id, action="botao2"}
                -- btn2:initialise()
                -- self.parent:addChild(btn2)
                -- self.parent.buttons[id][2] = btn2

                -- -- Button 3
                -- local btn3 = ISButton:new(barX + barWidth + 100, barY - 5, 40, 20, "Go", self.parent, BanditDialogueUI.onBanditButton)
                -- btn3.internalData = {banditID=id, action="moveTo"}
                -- btn3:initialise()
                -- self.parent:addChild(btn3)
                -- self.parent.buttons[id][3] = btn3
            else
                local btns = self.parent.buttons[id]
                btns[1]:setX(barX + barWidth + 80);   btns[1]:setY(barY + 10)
                -- btns[2]:setX(barX + barWidth + 55);   btns[2]:setY(barY + 10)
                -- btns[3]:setX(barX + barWidth + 100);  btns[3]:setY(barY + 10)
            end

            yOffset = yOffset + barHeight + 20

            self:drawRect(5, yOffset, self.width - 10, 1, 1, 1, 1, 1)  
            yOffset = yOffset + 10
        end

        self:setScrollHeight(yOffset + 10)
    end

    -- "Info" Button in bar
    -- self.infoButton = ISButton:new(self.width - 70, 2, 40, 14, "Info", self, BanditDialogueUI.onInfo)
    -- self.infoButton:initialise()
    -- self.infoButton:instantiate()
    -- self.infoButton.borderColor = {r=1, g=1, b=1, a=1}
    -- self:addChild(self.infoButton)
end

----------------------------
--- Open info window
----------------------------
function BanditDialogueUI:onInfo()
    AboutUI.show()
end

----------------------------
--- Button Interaction
----------------------------
function BanditDialogueUI:onBanditButton(button)
    local data = button.internalData
    if data.action == "moveTo" then
        -- Exemplo: setar para que o próximo clique no mundo defina o destino
        -- BanditDialogueUI.selectedBanditForMovement = data.banditID
        -- print("Selecione no mapa onde o bandido deve ir. (Exemplo)")
    elseif data.action == "remove" then
        local zombie = findZombieByID(data.banditID)
        local brain = BanditBrain.Get(zombie)

        BanditRelationships.removeBandit(brain)
    else
        -- local isoZ = findZombieByID(data.banditID)
        -- if isoZ then
        --     print("Bandit founded")
        -- else
        --     print("Bandit not founded")
        -- end

        -- -- Outras ações que quiser (B1, B2)  
        -- print("Executa ação:", data.action, "para bandido:", data.banditID)
    end
end

----------------------------
--- On click in World (Button Interaction)
----------------------------
local function onMouseDownOnGameWorld(x, y)
    if BanditDialogueUI.selectedBanditForMovement then
        local id = BanditDialogueUI.selectedBanditForMovement
        BanditDialogueUI.selectedBanditForMovement = nil
        print("Bandit", id, "Goto position:", x, y)
        -- Aqui chamaria a lógica de movimento do bandido
        -- ...
    end
end
Events.OnMouseDown.Add(onMouseDownOnGameWorld)


----------------------------
--- Order bandits in Relationship list
----------------------------
function BanditDialogueUI.getSortedBanditsByDistance()
    local sorted = {}
    local player = getSpecificPlayer(0)
    local playa = getPlayer();
    local worldData = playa:getModData()
    local data = worldData.BanditRelationships

    if not data then
        return sorted
    end

    if not player then
        for id, info in pairs(data) do
            table.insert(sorted, {id=id, info=info, dist=999999})
        end
        return sorted
    end

    local px, py = player:getX(), player:getY()

    for id, info in pairs(data) do
        local bx = info.x or 0
        local by = info.y or 0

        local dx = bx - px
        local dy = by - py
        local dist = math.sqrt(dx*dx + dy*dy)

        table.insert(sorted, {id=id, info=info, dist=dist})
    end

    table.sort(sorted, function(a,b) return a.dist < b.dist end)
    return sorted
end

----------------------------
--- Show Main UI
----------------------------
function BanditDialogueUI.show()
    if not OpennedRelationshipMenu then
        local ui = BanditDialogueUI:new(100, 100, 300, 400, getText("UI_BanditDeialogue_OptionsMenu_RelationshipsTitle"))
        ui:initialise()
        ui:addToUIManager()

        OpennedRelationshipMenu = true
    end
end

----------------------------
--- Close Main UI
----------------------------
function BanditDialogueUI:close()
    OpennedRelationshipMenu = false
    self:removeFromUIManager()
end

----------------------------
--- Extra Function: Find Zombie by BanditID
----------------------------
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
