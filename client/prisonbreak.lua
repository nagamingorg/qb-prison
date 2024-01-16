local currentGate = 0
local requiredItemsShowed = false
local requiredItems = {}
local inRange = false
local securityLockdown = false
local PlayerJob = {}
local Gates = {
    [1] = {
        gatekey = 13,
        coords = vector3(1845.99, 2604.7, 45.58),
        hit = false,
    },
    [2] = {
        gatekey = 14,
        coords = vector3(1819.47, 2604.67, 45.56),
        hit = false,
    },
    [3] = {
        gatekey = 15,
        coords = vector3(1804.74, 2616.311, 45.61),
        hit = false,
    }
}

local prisonPoly = PolyZone:Create({
  vector2(1812.8409423828, 2488.8833007813),
  vector2(1808.3549804688, 2474.6867675781),
  vector2(1762.1049804688, 2427.0930175781),
  vector2(1748.4509277344, 2420.1403808594),
  vector2(1667.9564208984, 2408.2248535156),
  vector2(1652.3533935547, 2410.3054199219),
  vector2(1558.7917480469, 2469.4399414063),
  vector2(1551.2701416016, 2483.2243652344),
  vector2(1547.6010742188, 2576.23046875),
  vector2(1548.4105224609, 2591.34375),
  vector2(1576.4735107422, 2667.3779296875),
  vector2(1585.4289550781, 2679.7072753906),
  vector2(1649.0562744141, 2741.4594726563),
  vector2(1662.2185058594, 2748.1357421875),
  vector2(1762.4670410156, 2751.8334960938),
  vector2(1775.8333740234, 2746.7290039063),
  vector2(1829.2827148438, 2703.3413085938),
  vector2(1834.5283203125, 2688.322265625),
  vector2(1809.7009277344, 2611.9575195313),
  vector2(1818.537109375, 2611.9541015625),
  vector2(1818.8004150391, 2596.931640625),
  vector2(1844.8937988281, 2597.1130371094),
  vector2(1845.3977050781, 2568.2805175781),
  vector2(1832.6966552734, 2568.2883300781),
  vector2(1832.5364990234, 2579.4790039063),
  vector2(1825.7023925781, 2578.9375),
  vector2(1825.796875, 2591.5773925781),
  vector2(1808.3248291016, 2591.5007324219),
  vector2(1808.1002197266, 2569.1997070313),
  vector2(1806.4140625, 2535.3442382813)
}, {
  name='prisonYard',
  minZ = 43,
  maxZ = 70,
  debugPoly = true,
  gridDivisions = 30
})

-- Functions

--- This will be triggered once a hack is done on a gate
--- @param success boolean
--- @return nil
local function OnHackDone(success)
    Config.OnHackDone(success, currentGate, Gates[currentGate])
end

--- This will draw 3d text at the given location with the given text
--- @param x number
--- @param y number
--- @param z number
--- @param text string
--- @return nil
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x,y,z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Events

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('electronickit:UseElectronickit', function()
    if currentGate ~= 0 and not securityLockdown and not Gates[currentGate].hit then
        local hasItem = QBCore.Functions.HasItem('gatecrack')
        if hasItem then
            TriggerEvent('inventory:client:requiredItems', requiredItems, false)
            QBCore.Functions.Progressbar('hack_gate', Lang:t('info.connecting_device'), math.random(5000, 10000), false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = 'anim@gangops@facility@servers@',
                anim = 'hotwire',
                flags = 16,
            }, {}, {}, function() -- Done
                StopAnimTask(PlayerPedId(), 'anim@gangops@facility@servers@', 'hotwire', 1.0)
                TriggerEvent('mhacking:show')
                TriggerEvent('mhacking:start', math.random(5, 9), math.random(10, 18), OnHackDone)
            end, function() -- Cancel
                StopAnimTask(PlayerPedId(), 'anim@gangops@facility@servers@', 'hotwire', 1.0)
                QBCore.Functions.Notify(Lang:t('error.cancelled'), 'error')
            end)
        else
            QBCore.Functions.Notify(Lang:t('error.item_missing'), 'error')
        end
    end
end)

RegisterNetEvent('prison:client:SetLockDown', function(isLockdown)
    securityLockdown = isLockdown
    if not securityLockdown or not inJail then return end
    TriggerEvent('chat:addMessage', {
        color = {255, 0, 0},
        multiline = true,
        args = {'HOSTAGE', Lang:t('error.security_activated')}
    })
end)

RegisterNetEvent('prison:client:PrisonBreakAlert', function()
    local coords = vector3(Config.Locations['middle'].coords.x, Config.Locations['middle'].coords.y, Config.Locations['middle'].coords.z)
    local alertData = {title = Lang:t('info.police_alert_title'), coords = {x = coords.x, y = coords.y, z = coords.z}, description = Lang:t('info.police_alert_description')}
    TriggerEvent('qb-phone:client:addPoliceAlert', alertData)
    TriggerEvent('police:client:policeAlert', coords, Lang:t('info.police_alert_description'))

    local BreakBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    TriggerServerEvent('prison:server:JailAlarm')
    SetBlipSprite(BreakBlip , 161)
    SetBlipScale(BreakBlip , 3.0)
    SetBlipColour(BreakBlip, 3)
    PulseBlip(BreakBlip)
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', 0, 0, 1)
    Wait(100)
    PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', 1 )
    Wait(100)
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', 0, 0, 1)
    Wait(100)
    PlaySoundFrontend( -1, 'Beep_Red', 'DLC_HEIST_HACKING_SNAKE_SOUNDS', 1 )
    Wait((1000 * 60 * 5))
    RemoveBlip(BreakBlip)
end)

RegisterNetEvent('prison:client:SetGateHit', function(key, isHit)
    Gates[key].hit = isHit
end)

RegisterNetEvent('prison:client:JailAlarm', function(toggle)
    if toggle then
        local alarmIpl = GetInteriorAtCoordsWithType(1787.004,2593.1984,45.7978, 'int_prison_main')

        RefreshInterior(alarmIpl)
        EnableInteriorProp(alarmIpl, 'prison_alarm')

        CreateThread(function()
            while not PrepareAlarm('PRISON_ALARMS') do
                Wait(100)
            end
            StartAlarm('PRISON_ALARMS', true)
        end)
    else
        local alarmIpl = GetInteriorAtCoordsWithType(1787.004,2593.1984,45.7978, 'int_prison_main')

        RefreshInterior(alarmIpl)
        DisableInteriorProp(alarmIpl, 'prison_alarm')

        CreateThread(function()
            while not PrepareAlarm('PRISON_ALARMS') do
                Wait(100)
            end
            StopAllAlarms(true)
        end)
    end
end)

-- Threads

CreateThread(function()
    Wait(500)
    requiredItems = {
        [1] = {name = QBCore.Shared.Items['electronickit']['name'], image = QBCore.Shared.Items['electronickit']['image']},
        [2] = {name = QBCore.Shared.Items['gatecrack']['name'], image = QBCore.Shared.Items['gatecrack']['image']},
    }
    while true do
        inRange = false
        currentGate = 0
        local sleep = 1000
        if PlayerJob.type ~= 'leo' then
            local pos = GetEntityCoords(PlayerPedId())
            for k in pairs(Gates) do
                local dist =  #(pos - Gates[k].coords)
                if dist < 1.5 then
                    currentGate = k
                    inRange = true
                    if securityLockdown then
                        sleep = 0
                        DrawText3D(Gates[k].coords.x, Gates[k].coords.y, Gates[k].coords.z, '~r~SYSTEM LOCKDOWN')
                    elseif Gates[k].hit then
                        sleep = 0
                        DrawText3D(Gates[k].coords.x, Gates[k].coords.y, Gates[k].coords.z, 'SYSTEM BREACH')
                    elseif not requiredItemsShowed then
                        requiredItemsShowed = true
                        TriggerEvent('inventory:client:requiredItems', requiredItems, true)
                    end
                end
            end

            if not inRange then
                if requiredItemsShowed then
                    requiredItemsShowed = false
                    TriggerEvent('inventory:client:requiredItems', requiredItems, false)
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
      local pos = GetEntityCoords(PlayerPedId(), true)
      local insidePrisonZone = prisonPoly:isPointInside(pos)
      if insidePrisonZone and inJail then
        DisableControlAction(0, 24, true) -- Attack
        DisableControlAction(0, 257, true) -- Attack 2
        DisableControlAction(0, 25, true) -- Aim
        DisableControlAction(0, 263, true) -- Melee Attack 1
        DisableControlAction(0, 264, true) -- Melee Attack 2
      elseif not insidePrisonZone and inJail then
        inJail = false
        jailTime = 0
        RemoveBlip(currentBlip)
        RemoveBlip(CellsBlip)
        CellsBlip = nil
        RemoveBlip(TimeBlip)
        TimeBlip = nil
        RemoveBlip(ShopBlip)
        ShopBlip = nil
        TriggerServerEvent('prison:server:SecurityLockdown')
        TriggerEvent('prison:client:PrisonBreakAlert')
        TriggerServerEvent('prison:server:SetJailStatus', 0)
        TriggerServerEvent('prison:server:GiveJailItems', true)
        QBCore.Functions.Notify(Lang:t('error.escaped'), 'error')
      end
      Wait(1000)
    end
end)
