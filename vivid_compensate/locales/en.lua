-- locales/en.lua
local Translations = {
    error = {
        no_permission = 'You do not have permission to use this command',
        player_not_found = 'Player not found',
        no_compensation = 'You have no pending compensation',
        stash_error = 'Error accessing compensation stash'
    },
    success = {
        compensation_created = 'Compensation stash created for player %s',
        compensation_collected = 'You have collected your compensation items',
        compensation_cleared = 'Compensation cleared for player %s'
    },
    info = {
        compensation_pending = 'You have pending compensation! Visit City Hall to collect it.',
        compensation_available = 'Press [E] to collect your compensation',
        compensation_menu = 'Compensation Collection'
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})