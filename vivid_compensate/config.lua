-- config.lua
Config = {}

-- City Hall Location
Config.CityHall = {
    coords = vector3(-551.32, -202.52, 38.14), -- City Hall coordinates
    radius = 2.0,
    marker = {
        type = 1,
        scale = vector3(1.0, 1.0, 1.0),
        color = {r = 0, g = 255, b = 0, a = 100}
    }
}

-- Admin groups that can use compensation commands
Config.AdminGroups = {
    'god',
    'admin',
    'superadmin',
    'mod',
    'moderator'
}

-- Alternative: Use ACE permissions instead of groups
Config.UseAcePermissions = false -- Set to true to use ACE permissions instead
Config.AcePermission = "compensation.admin" -- The ACE permission required

-- Add your license here for testing (temporary)
Config.AdminLicenses = {
    -- "license:your_license_here", -- Add your license identifier here for testing
}

-- Discord webhook for logging (optional)
Config.DiscordWebhook = ""

-- Maximum items per compensation stash
Config.MaxSlots = 50

-- Database table name
Config.TableName = 'player_compensation'