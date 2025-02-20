BanditDialogueKeyPressed = BanditDialogueKeyPressed or {}

function BanditDialogueKeyPressed.OnKeyPressed(keynum)
    if keynum == BanditDialogueCompatibility.GetRelationsUIOpenKey() then
        BanditDialogueUI.show()
    end
end

Events.OnKeyPressed.Add(BanditDialogueKeyPressed.OnKeyPressed)
