if GetResourceState('ox_core') ~= 'started' then return end

local file = ('imports/%s.lua'):format(IsDuplicityVersion() and 'server' or 'client')
local import = LoadResourceFile('ox_core', file)
local chunk = assert(load(import, ('@@ox_core/%s'):format(file)))
chunk()

AddEventHandler('ox:playerLoaded', function()
    OnPlayerLoaded()
end)

AddEventHandler('ox:playerLogout', function()
    OnPlayerUnload()
end)

function handleVehicleKeys(veh)
    local plate = GetVehicleNumberPlateText(veh)
    -- ox_core doesn't have a vehicle key system, so we'll just leave this empty so people can fill it out on their own.
end

function hasPlyLoaded()
    return player and true or false
end

function DoNotification(text, nType)
    lib.notify({ title = "Notification", description = text, type = nType, })
end
