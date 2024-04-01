if not lib.checkDependency('ND_Core', '2.0.0') then return end

NDCore = exports["ND_Core"]

function GetPlayer(id)
    return NDCore:getPlayer(id)
end

function DoNotification(src, text, nType)
    local player = NDCore:getPlayer(src)
    return player and player.notify({ type = nType, description = text })
end

function AddMoney(player, moneyType, amount)
    player.addMoney(moneyType, amount, "cargo-delivery")
end
