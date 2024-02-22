return {
    Debug = false,
    Fuel = {
        enable = false, -- I use ox_fuel so I set this to false and use statebag to set the fuel
        script = 'LegacyFuel',
    },
    Ped = 'mp_m_weapexp_01',
    PedCoords = vec4(-413.96, 6171.53, 30.48, 320.39),
    VehicleSpawn = vec4(-411.37, 6175.33, 31.48, 228.09),
    DeliveryInfo = { 
        title = 'Cargo Delivery', 
        msg = 'Deliver the cargo to the set location.', 
        sec = 3, 
        audioName = 'Boss_Message_Orange', audioRef = 'GTAO_Boss_Goons_FM_Soundset'
    },
    ReturnInfo = { 
        title = 'Delivery Complete', 
        msg = 'Return back to the warehouse to get paid.', 
        sec = 7, 
        audioName = 'Mission_Pass_Notify', audioRef = 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS'
    }
}
