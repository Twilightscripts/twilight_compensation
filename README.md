Twilight Compensation System
A comprehensive compensation system for QBCore/Qbox servers that allows administrators to create item stashes for players who have experienced losses due to server issues, bugs, or other incidents.
Features

Admin Commands: Create, view, and clear compensation stashes
Player Collection: Interactive zone at City Hall for players to collect compensation
Inventory Integration: Full ox_inventory support with stash system
Permission System: Flexible admin permissions (groups or ACE)
Database Persistence: MySQL storage for compensation records

Dependencies

qb-core/qbox - Core framework
ox_inventory - Inventory system
oxmysql - Database queries
ox_target - Enhanced interaction system

Installation

Download and Extract: Place the twilight-compensation folder in your server's resources directory
Database Setup: The script automatically creates the required database table on first run
Add to server.cfg:
cfgensure twilight-compensation

Configure Permissions: Edit config.lua to set up admin groups or ACE permissions

Configuration
Admin Permissions
Use QBCore groups
Config.AdminGroups = {
    'god',
    'admin',
    'superadmin',
    'mod',
    'moderator'
}

City Hall Location
luaConfig.CityHall = {
    coords = vector3(-551.32, -202.52, 38.14),
    radius = 2.0,
    marker = {
        type = 1,
        scale = vector3(1.0, 1.0, 1.0),
        color = {r = 0, g = 255, b = 0, a = 100}
    }
}


https://discord.gg/Bx22Trwsd2
