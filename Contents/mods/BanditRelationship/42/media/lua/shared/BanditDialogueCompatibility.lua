BanditDialogueCompatibility = BanditDialogueCompatibility or {}

local getGameVersion = function()
    return getCore():getGameVersion():getMajor()
end

BanditDialogueCompatibility.GetGameVersion = getGameVersion

BanditDialogueCompatibility.GetRelationsUIOpenKey = function()
    if getGameVersion() >= 42 then
        local options = PZAPI.ModOptions:getOptions("BanditDialogue")
        return options:getOption("RELATIONS"):getValue()
    else
        return getCore():getKey("RELATIONS")
    end
end
