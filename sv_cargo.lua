local jobRoutes = lib.require('sv_routes')
local Config = lib.require('config')
local storedRoute = {}

local function setCargoVehicle(source, truck, prop)
    local cargoVeh = CreateVehicle(joaat(truck), Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, Config.VehicleSpawn.w, true, false)
    local ped = GetPlayerPed(source)

    while not DoesEntityExist(cargoVeh) do Wait(10) end 

    while GetVehiclePedIsIn(ped, false) ~= cargoVeh do
        TaskWarpPedIntoVehicle(ped, cargoVeh, -1)
        Wait(100)
    end

    local crate = CreateObject(joaat(prop), Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z-5.0, true, true, false)
    while not DoesEntityExist(crate) do Wait(10) end 

    return cargoVeh, crate
end

lib.callback.register('randol_cargo:server:beginRoute', function(source)
    local src = source
    local Player = GetPlayer(src)
    local roll = math.random(#jobRoutes)
    local MY_ROUTE = jobRoutes[roll]
    if storedRoute[src] then return false end

    local vehicle, crate = setCargoVehicle(src, MY_ROUTE.vehicle, MY_ROUTE.prop)

    storedRoute[src] = {
        vehicle = vehicle,
        prop = MY_ROUTE.prop,
        attach = MY_ROUTE.attach,
        payout = math.random(MY_ROUTE.payout.min, MY_ROUTE.payout.max), 
        route = MY_ROUTE.routes[math.random(#MY_ROUTE.routes)], 
        complete = false,
        crateHandle = crate,
    }

    TriggerClientEvent('randol_cargo:client:startRoute', src, storedRoute[src], NetworkGetNetworkIdFromEntity(vehicle), NetworkGetNetworkIdFromEntity(crate))
    return true
end)

lib.callback.register('randol_cargo:server:storeCrate', function(source, netid)
    local src = source
    local Player = GetPlayer(src)
    if not storedRoute[src] then return false end
    storedRoute[src].crateHandle = NetworkGetEntityFromNetworkId(netid)
    return true
end)

lib.callback.register('randol_cargo:server:updateRoute', function(source, CRATE_NET)
    if not CRATE_NET or not storedRoute[source] then return false end

    local src = source
    local Player = GetPlayer(src)
    local pos = GetEntityCoords(GetPlayerPed(src))
    local entity = NetworkGetEntityFromNetworkId(CRATE_NET)

    local data = storedRoute[src]
    if not data.complete then
        if #(pos - data.route) < 15.0 then
            data.complete = true
            DeleteEntity(entity)
            return true
        end
    end
    return false
end)

lib.callback.register('randol_cargo:server:finishRoute', function(source)
    if not storedRoute[source] then return false end

    local src = source
    local Player = GetPlayer(src)
    local details = storedRoute[src]
    local truck = details.vehicle

    if details.complete then
        local payment = details.payout
        DoNotification(src, ('You were paid $%s'):format(payment), 'success')
        AddMoney(Player, 'cash', payment, 'cargo-job')
    else
        DoNotification(src, 'You ended your run without completing the route so you weren\'t paid.', 'error')
        local entity = storedRoute[src].crateHandle

        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end

    if DoesEntityExist(truck) then DeleteEntity(truck) end

    storedRoute[src] = nil
    return true
end)
