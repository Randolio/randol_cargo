if GetResourceState('ox_core') ~= 'started' then return end

local file = ('imports/%s.lua'):format(IsDuplicityVersion() and 'server' or 'client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))
chunk()

function GetPlayer(id)
    return Ox.GetPlayer(id)
end

function DoNotification(src, text, nType)
    TriggerClientEvent('ox_lib:notify', src, { type = nType, description = text })
end

function AddMoney(Player, moneyType, amount)
    if moneyType == 'cash' then
        exports.ox_inventory:AddItem(Player.source, 'money', amount) -- support for ox_inventory because why do you need to use anything else at this point...
    else
        -- ox_core doesn't have a bank system, so we'll just leave this empty so people can fill it out on their own.
    end
end
