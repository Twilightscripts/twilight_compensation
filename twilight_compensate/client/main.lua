-- client/main.lua
local QBCore = exports['qb-core']:GetCoreObject()
local compensationZone = nil

-- Create City Hall marker/zone
CreateThread(function()
    local coords = Config.CityHall.coords
    
    -- Create blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 408)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Compensation Collection")
    EndTextCommandSetBlipName(blip)
    
    -- Create ox_target zone if available
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = Config.CityHall.radius,
            options = {
                {
                    name = 'compensation_collect',
                    icon = 'fas fa-gift',
                    label = Lang:t('info.compensation_menu'),
                    onSelect = function()
                        -- Double-check before collecting
                        QBCore.Functions.TriggerCallback('qb-compensation:server:hasCompensation', function(hasComp)
                            if hasComp then
                                collectCompensation()
                            else
                                QBCore.Functions.Notify(Lang:t('error.no_compensation'), 'error')
                            end
                        end)
                    end,
                    -- Remove canInteract to always show the option, we'll check inside onSelect
                    distance = Config.CityHall.radius
                }
            }
        })
        
        print("^2[COMPENSATION] ox_target zone created at: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
    else
        -- Fallback to marker system
        compensationZone = coords
        print("^3[COMPENSATION] Using marker system (ox_target not available)")
        
        CreateThread(function()
            while true do
                local sleep = 1000
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - coords)
                
                if distance < 10.0 then
                    sleep = 0
                    
                    -- Draw marker
                    DrawMarker(
                        Config.CityHall.marker.type,
                        coords.x, coords.y, coords.z - 1.0,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        Config.CityHall.marker.scale.x,
                        Config.CityHall.marker.scale.y,
                        Config.CityHall.marker.scale.z,
                        Config.CityHall.marker.color.r,
                        Config.CityHall.marker.color.g,
                        Config.CityHall.marker.color.b,
                        Config.CityHall.marker.color.a,
                        false, false, 2, false, nil, nil, false
                    )
                    
                    if distance < Config.CityHall.radius then
                        -- Always show text, check compensation when pressed
                        QBCore.Functions.DrawText3D(coords.x, coords.y, coords.z + 0.3, "[E] Check Compensation")
                        
                        if IsControlJustPressed(0, 38) then -- E key
                            QBCore.Functions.TriggerCallback('qb-compensation:server:hasCompensation', function(hasComp)
                                if hasComp then
                                    collectCompensation()
                                else
                                    QBCore.Functions.Notify(Lang:t('error.no_compensation'), 'error')
                                end
                            end)
                        end
                    end
                end
                
                Wait(sleep)
            end
        end)
    end
end)

-- Function to check if player has compensation
function hasCompensation()
    local hasComp = nil
    QBCore.Functions.TriggerCallback('qb-compensation:server:hasCompensation', function(result)
        hasComp = result
    end)
    
    while hasComp == nil do
        Wait(10)
    end
    
    return hasComp
end

-- Function to collect compensation
function collectCompensation()
    QBCore.Functions.TriggerCallback('qb-compensation:server:collectCompensation', function(success)
        if success then
            QBCore.Functions.Notify(Lang:t('success.compensation_collected'), 'success')
        else
            QBCore.Functions.Notify(Lang:t('error.no_compensation'), 'error')
        end
    end)
end

-- Notification when player joins and has compensation
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    QBCore.Functions.TriggerCallback('qb-compensation:server:hasCompensation', function(result)
        if result then
            QBCore.Functions.Notify(Lang:t('info.compensation_pending'), 'primary', 5000)
        end
    end)
end)