-- server/main.lua
local QBCore = exports['qb-core']:GetCoreObject()

-- Database initialization
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]]..Config.TableName..[[` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `identifier` varchar(50) NOT NULL,
            `stash_id` varchar(100) NOT NULL,
            `items` longtext DEFAULT NULL,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            `created_by` varchar(50) DEFAULT NULL,
            `collected` tinyint(1) DEFAULT 0,
            PRIMARY KEY (`id`),
            UNIQUE KEY `identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

-- Helper function to check admin permission
local function IsAdmin(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        print("^1[COMPENSATION] Player not found for source: " .. source)
        return false 
    end
    
    -- Debug information
    print("^3[COMPENSATION DEBUG] Checking permissions for: " .. Player.PlayerData.name)
    print("^3[COMPENSATION DEBUG] Player License: " .. Player.PlayerData.license)
    print("^3[COMPENSATION DEBUG] Player CitizenID: " .. Player.PlayerData.citizenid)
    
    -- If using ACE permissions
    if Config.UseAcePermissions then
        local hasAce = IsPlayerAceAllowed(source, Config.AcePermission)
        print("^3[COMPENSATION DEBUG] ACE Permission (" .. Config.AcePermission .. "): " .. tostring(hasAce))
        if hasAce then return true end
    end
    
    -- Check multiple permission methods for compatibility
    local permission = QBCore.Functions.GetPermission(source)
    print("^3[COMPENSATION DEBUG] QBCore Permission: " .. tostring(permission))
    
    -- Method 1: Check QBCore permission system
    if permission then
        for _, adminGroup in pairs(Config.AdminGroups) do
            if permission == adminGroup then
                print("^2[COMPENSATION DEBUG] Permission match found: " .. adminGroup)
                return true
            end
        end
    end
    
    -- Method 2: Check player metadata/permissions
    if Player.PlayerData.metadata and Player.PlayerData.metadata.permissions then
        print("^3[COMPENSATION DEBUG] Metadata permissions: " .. json.encode(Player.PlayerData.metadata.permissions))
        for _, adminGroup in pairs(Config.AdminGroups) do
            if Player.PlayerData.metadata.permissions[adminGroup] then
                print("^2[COMPENSATION DEBUG] Metadata permission match: " .. adminGroup)
                return true
            end
        end
    end
    
    -- Method 3: Check if player has admin ace permissions
    local hasAdminAce = IsPlayerAceAllowed(source, "admin")
    local hasCommandAce = IsPlayerAceAllowed(source, "command")
    print("^3[COMPENSATION DEBUG] Admin ACE: " .. tostring(hasAdminAce))
    print("^3[COMPENSATION DEBUG] Command ACE: " .. tostring(hasCommandAce))
    
    if hasAdminAce or hasCommandAce then
        return true
    end
    
    -- Method 4: Check QBCore admin system (some servers use this)
    if QBCore.Functions.HasPermission then
        local hasQBPerm = QBCore.Functions.HasPermission(source, 'admin')
        print("^3[COMPENSATION DEBUG] QBCore HasPermission: " .. tostring(hasQBPerm))
        if hasQBPerm then
            return true
        end
    end
    
    -- Method 5: Check if player is in admin job (fallback)
    if Player.PlayerData.job and Player.PlayerData.job.name == 'admin' then
        print("^2[COMPENSATION DEBUG] Admin job match")
        return true
    end
    
    -- Method 6: Check license-based permissions (add your license here for testing)
    if Config.AdminLicenses then
        for _, license in pairs(Config.AdminLicenses) do
            if Player.PlayerData.license == license then
                print("^2[COMPENSATION DEBUG] License match found")
                return true
            end
        end
    end
    
    print("^1[COMPENSATION DEBUG] No admin permissions found")
    return false
end

-- Helper function to send Discord log
local function SendDiscordLog(title, description, color)
    if Config.DiscordWebhook == "" then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["color"] = color or 16711680,
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({
        embeds = embed
    }), {['Content-Type'] = 'application/json'})
end

-- Command: /compensate [id]
QBCore.Commands.Add('compensate', 'Create compensation stash for a player', {
    {name = 'id', help = 'Player ID'}
}, true, function(source, args)
    print("^3[COMPENSATION] Command executed by source: " .. source)
    
    if not IsAdmin(source) then
        print("^1[COMPENSATION] Permission denied for source: " .. source)
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.no_permission'), 'error')
        return
    end
    
    print("^2[COMPENSATION] Permission granted for source: " .. source)
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.player_not_found'), 'error')
        return
    end
    
    local AdminPlayer = QBCore.Functions.GetPlayer(source)
    local stashId = 'compensation_' .. TargetPlayer.PlayerData.citizenid
    
    print("^2[COMPENSATION] Creating stash: " .. stashId)
    
    -- Register the stash first
    exports.ox_inventory:RegisterStash(stashId, 'Compensation', Config.MaxSlots, 100000)
    
    -- Create or update compensation record
    MySQL.insert('INSERT INTO `'..Config.TableName..'` (identifier, stash_id, created_by, collected) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE stash_id = VALUES(stash_id), created_by = VALUES(created_by), collected = 0, created_at = CURRENT_TIMESTAMP', {
        TargetPlayer.PlayerData.citizenid,
        stashId,
        AdminPlayer.PlayerData.citizenid,
        0
    })
    
    -- Open stash for admin
    TriggerClientEvent('ox_inventory:openInventory', source, 'stash', stashId)
    
    -- Notify admin
    TriggerClientEvent('QBCore:Notify', source, Lang:t('success.compensation_created', TargetPlayer.PlayerData.name), 'success')
    
    -- Notify target player
    TriggerClientEvent('QBCore:Notify', targetId, Lang:t('info.compensation_pending'), 'primary')
    
    -- Discord log
    SendDiscordLog(
        "Compensation Created",
        string.format("**Admin:** %s (%s)\n**Target:** %s (%s)\n**Stash ID:** %s", 
            AdminPlayer.PlayerData.name, AdminPlayer.PlayerData.citizenid,
            TargetPlayer.PlayerData.name, TargetPlayer.PlayerData.citizenid,
            stashId
        ),
        3447003
    )
end)

-- Command: /clearcompensation [id]
QBCore.Commands.Add('clearcompensation', 'Clear compensation for a player', {
    {name = 'id', help = 'Player ID'}
}, true, function(source, args)
    if not IsAdmin(source) then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.no_permission'), 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.player_not_found'), 'error')
        return
    end
    
    local AdminPlayer = QBCore.Functions.GetPlayer(source)
    
    -- Clear compensation
    MySQL.update('DELETE FROM `'..Config.TableName..'` WHERE identifier = ?', {
        TargetPlayer.PlayerData.citizenid
    })
    
    -- Clear stash
    local stashId = 'compensation_' .. TargetPlayer.PlayerData.citizenid
    exports.ox_inventory:ClearInventory(stashId)
    
    TriggerClientEvent('QBCore:Notify', source, Lang:t('success.compensation_cleared', TargetPlayer.PlayerData.name), 'success')
    
    -- Discord log
    SendDiscordLog(
        "Compensation Cleared",
        string.format("**Admin:** %s (%s)\n**Target:** %s (%s)", 
            AdminPlayer.PlayerData.name, AdminPlayer.PlayerData.citizenid,
            TargetPlayer.PlayerData.name, TargetPlayer.PlayerData.citizenid
        ),
        15158332
    )
end)

-- Command: /viewcompensation [id]
QBCore.Commands.Add('viewcompensation', 'View compensation stash for a player', {
    {name = 'id', help = 'Player ID'}
}, true, function(source, args)
    if not IsAdmin(source) then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.no_permission'), 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('error.player_not_found'), 'error')
        return
    end
    
    local stashId = 'compensation_' .. TargetPlayer.PlayerData.citizenid
    
    -- Check if compensation exists
    MySQL.query('SELECT * FROM `'..Config.TableName..'` WHERE identifier = ?', {
        TargetPlayer.PlayerData.citizenid
    }, function(result)
        if result[1] then
            TriggerClientEvent('ox_inventory:openInventory', source, 'stash', stashId)
        else
            TriggerClientEvent('QBCore:Notify', source, 'No compensation found for this player', 'error')
        end
    end)
end)

-- Server callback for checking compensation
QBCore.Functions.CreateCallback('qb-compensation:server:hasCompensation', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        print("^1[COMPENSATION] Player not found for source: " .. source)
        cb(false) 
        return 
    end
    
    print("^3[COMPENSATION] Checking compensation for: " .. Player.PlayerData.name .. " (" .. Player.PlayerData.citizenid .. ")")
    
    MySQL.query('SELECT * FROM `'..Config.TableName..'` WHERE identifier = ? AND collected = 0', {
        Player.PlayerData.citizenid
    }, function(result)
        local hasComp = result[1] ~= nil
        print("^3[COMPENSATION] Has compensation: " .. tostring(hasComp))
        cb(hasComp)
    end)
end)

-- Server callback for collecting compensation
QBCore.Functions.CreateCallback('qb-compensation:server:collectCompensation', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        print("^1[COMPENSATION] Player not found for source: " .. source)
        cb(false) 
        return 
    end
    
    local stashId = 'compensation_' .. Player.PlayerData.citizenid
    print("^3[COMPENSATION] Attempting to collect compensation for: " .. Player.PlayerData.name .. " (Stash: " .. stashId .. ")")
    
    MySQL.query('SELECT * FROM `'..Config.TableName..'` WHERE identifier = ? AND collected = 0', {
        Player.PlayerData.citizenid
    }, function(result)
        if result[1] then
            print("^2[COMPENSATION] Found compensation record, opening stash")
            
            -- Mark as collected
            MySQL.update('UPDATE `'..Config.TableName..'` SET collected = 1 WHERE identifier = ?', {
                Player.PlayerData.citizenid
            })
            
            -- Open stash for player
            TriggerClientEvent('ox_inventory:openInventory', source, 'stash', stashId)
            
            -- Discord log
            SendDiscordLog(
                "Compensation Collected",
                string.format("**Player:** %s (%s)\n**Stash ID:** %s", 
                    Player.PlayerData.name, Player.PlayerData.citizenid, stashId
                ),
                65280
            )
            
            cb(true)
        else
            print("^1[COMPENSATION] No compensation record found")
            cb(false)
        end
    end)
end)

-- Register stash
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        -- Register compensation stashes
        MySQL.query('SELECT DISTINCT stash_id FROM `'..Config.TableName..'`', {}, function(result)
            for _, v in pairs(result) do
                exports.ox_inventory:RegisterStash(v.stash_id, 'Compensation', Config.MaxSlots, 100000)
            end
        end)
    end
end)

-- Register stash when compensation is created
RegisterNetEvent('qb-compensation:server:registerStash', function(stashId)
    exports.ox_inventory:RegisterStash(stashId, 'Compensation', Config.MaxSlots, 100000)
end)