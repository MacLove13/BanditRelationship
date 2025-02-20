local config = {
    keyBind   = nil,
    checkBox  = nil,
    textEntry = nil,
    multiBox  = nil,
    comboBox  = nil,
    colorPick = nil,
    slider    = nil,
    button    = nil
}

local options = PZAPI.ModOptions:create("BanditDialogue", getText("UI_BanditDeialogue_OptionsMenu_title"))
options:addTitle(getText("UI_BanditDeialogue_OptionsMenu_RelationshipMenutitle"))
config.keyBind = options:addKeyBind("RELATIONS", getText("UI_BanditDeialogue_OptionsMenu_keybing"), Keyboard.KEY_Z, getText("UI_BanditDeialogue_OptionsMenu_keybing"))
