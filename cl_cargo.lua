local Config = lib.require('config')

local isHired, droppingOff, showText = false, false, false
local CRATE_OBJECT, cargoPed, DropOffZone, jobBlip, startPoint
local routeData = {}

local CARGO_BLIP = AddBlipForCoord(Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z)
SetBlipSprite(CARGO_BLIP, 615)
SetBlipDisplay(CARGO_BLIP, 4)
SetBlipScale(CARGO_BLIP, 0.8)
SetBlipAsShortRange(CARGO_BLIP, true)
SetBlipColour(CARGO_BLIP, 52)
BeginTextCommandSetBlipName("STRING")
AddTextComponentSubstringPlayerName("Cargo Delivery")
EndTextCommandSetBlipName(CARGO_BLIP)

local function showCargoScaleform(bool)
    local scaleform = lib.requestScaleformMovie('MIDSIZED_MESSAGE', 1000)
    local info = Config.DeliveryInfo
    BeginScaleformMovieMethod(scaleform, 'SHOW_COND_SHARD_MESSAGE')
    if bool then info = Config.ReturnInfo end

    PushScaleformMovieMethodParameterString(info.title)
    PushScaleformMovieMethodParameterString(info.msg)
    EndScaleformMovieMethod()
    PlaySoundFrontend(-1, info.audioName, info.audioRef, 0)
    local sec = info.sec
    while sec > 0 do
        Wait(1)
        sec -= 0.01
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
    end
    SetScaleformMovieAsNoLongerNeeded(scaleform)
end

local function finishRoute()
    if not isHired then return end
    local ped = cache.ped
    local success = lib.callback.await('randol_cargo:server:finishRoute', false)
    if success then
        if DropOffZone then DropOffZone:remove() end
        if DoesBlipExist(jobBlip) then RemoveBlip(jobBlip) end
        isHired = false
        CRATE_OBJECT = nil
        table.wipe(routeData)
    end
end

local function nearZone(point)
    DrawMarker(1, point.coords.x, point.coords.y, point.coords.z - 1, 0, 0, 0, 0, 0, 0, 6.0, 6.0, 1.5, 79, 194, 247, 165, 0, 0, 0,0)
    
    if point.isClosest and point.currentDistance <= 4 then
        if not showText then
            showText = true
            lib.showTextUI('**E** - Deliver Cargo', {position = "left-center"})
        end
        if isHired and cache.vehicle and IsEntityAttachedToEntity(cache.vehicle, CRATE_OBJECT) then
            if IsControlJustPressed(0, 38) and not droppingOff then
                droppingOff = true
                FreezeEntityPosition(cache.vehicle, true)
                lib.hideTextUI()
                if lib.progressCircle({
                    duration = 5000,
                    position = 'bottom',
                    label = "Dropping cargo..",
                    useWhileDead = true,
                    canCancel = false,
                    disable = { move = true, car = true, mouse = false, combat = true, },
                }) then
                    DropOffZone:remove()
                    DropOffZone = nil
                    RemoveBlip(jobBlip)
                    NetworkFadeOutEntity(CRATE_OBJECT, 0, 1)
                    Wait(500)
                    local success = lib.callback.await('randol_cargo:server:updateRoute', false, NetworkGetNetworkIdFromEntity(CRATE_OBJECT))
                    if success then
                        FreezeEntityPosition(cache.vehicle, false)
                        droppingOff = false
                        showCargoScaleform(true)
                    end
                end
            end
        end
    elseif showText then
        showText = false
        lib.hideTextUI()
    end
end

local function setRoute(route)
    jobBlip = AddBlipForCoord(route.x, route.y, route.z)
    SetBlipSprite(jobBlip, 615)
    SetBlipDisplay(jobBlip, 4)
    SetBlipScale(jobBlip, 1.0)
    SetBlipFlashes(jobBlip, false)
    SetBlipAsShortRange(jobBlip, true)
    SetBlipColour(jobBlip, 3)
    SetBlipRoute(jobBlip, true)
    SetBlipRouteColour(jobBlip, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Delivery Point")
    EndTextCommandSetBlipName(jobBlip)

    DropOffZone = lib.points.new({ coords = vec3(route.x, route.y, route.z), distance = 30, nearby = nearZone, })
    isHired = true
    showCargoScaleform()
end

local function yeetPed()
    if DoesEntityExist(cargoPed) then
        DeleteEntity(cargoPed)
        cargoPed = nil
    end
end

local function spawnPed()
    if DoesEntityExist(cargoPed) then return end

    lib.requestModel(joaat(Config.Ped), 5000)
    cargoPed = CreatePed(0, Config.Ped, Config.PedCoords, false, false)
    SetEntityAsMissionEntity(cargoPed, true, true)
    SetPedFleeAttributes(cargoPed, 0, 0)
    SetBlockingOfNonTemporaryEvents(cargoPed, true)
    SetEntityInvincible(cargoPed, true)
    FreezeEntityPosition(cargoPed, true)

    exports['qb-target']:AddTargetEntity(cargoPed, { 
        options = {
            { 
                icon = "fa-solid fa-truck-moving",
                label = "Start Cargo Delivery",
                canInteract = function() return not isHired end,
                action = function()
                    if IsAnyVehicleNearPoint(Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, 5.0) then 
                        DoNotification('A vehicle is blocking the spawn.', 'error') 
                        return 
                    end
                    local success = lib.callback.await('randol_cargo:server:beginRoute', false)
                end,
            },
            { 
                icon = "fa-solid fa-clipboard-check",
                label = "Finish Delivery",
                canInteract = function() return isHired end,
                action = function()
                    finishRoute()
                end,
            },
        }, 
        distance = 1.5, 
    })
end

RegisterNetEvent('randol_cargo:client:startRoute', function(data, vehNet, crateNet)
    if GetInvokingResource() then return end
    routeData = data
    local veh = NetworkGetEntityFromNetworkId(vehNet)
    local rnd = tostring(math.random(1000, 9999))
    CRATE_OBJECT = NetworkGetEntityFromNetworkId(crateNet)

    SetVehicleNumberPlateText(veh, "CARG"..rnd)
    TriggerEvent('randol_cargo:handleVehicleKeys', veh)
    SetVehicleEngineOn(veh, true, true)
    SetVehicleExtra(veh, 2, true)
    SetVehicleExtra(veh, 3, true)

    if Config.Fuel.enable then
        exports[Config.Fuel.script]:SetFuel(veh, 100.0)
    else
        Entity(veh).state.fuel = 100
    end

    if NetworkGetEntityOwner(CRATE_OBJECT) ~= cache.playerId then
        while NetworkGetEntityOwner(CRATE_OBJECT) ~= cache.playerId do -- I'm not proud of it either, trust me.
            NetworkRequestControlOfEntity(CRATE_OBJECT)
            Wait(10)
        end
    end

    local x, y, z = routeData.attach.x, routeData.attach.y, routeData.attach.z
    AttachEntityToEntity(CRATE_OBJECT, veh, GetEntityBoneIndexByName(veh, 'bodyshell'), x, y, z, 0, 0, 0, 1, 1, 0, 1, 0, 1)
    FreezeEntityPosition(CRATE_OBJECT, true)
    setRoute(routeData.route)
end)

local function createStartPoint()
    startPoint = lib.points.new({
        coords = Config.PedCoords.xyz,
        distance = 30,
        onEnter = spawnPed,
        onExit = yeetPed,
    })
end

function OnPlayerLoaded()
    createStartPoint()
end

function OnPlayerUnload()
    if DoesEntityExist(cargoPed) then DeleteEntity(cargoPed) end
    if DoesBlipExist(jobBlip) then RemoveBlip(jobBlip) end
    if startPoint then startPoint:remove() end
    if DropOffZone then DropOffZone:remove() end
    if isHired then isHired = false end
    table.wipe(routeData)
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource or not hasPlyLoaded() then return end
    createStartPoint()
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName then
        if DropOffZone then DropOffZone:remove() end
        if DoesEntityExist(cargoPed) then DeleteEntity(cargoPed) end
    end 
end)
