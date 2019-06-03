------------------------------------------------------------------
-- Load Config
------------------------------------------------------------------
function MapVote.LoadConfig()
	-- Store global values
	local old_MAP_SET_1 = MAP_SET_1
	local old_MAP_SET_2 = MAP_SET_2
	local old_MAP_SET_3 = MAP_SET_3
	local old_MAP_SET_4 = MAP_SET_4
	local old_MAP_NOMINATE = MAP_NOMINATE
	local old_MAP_RANDOM = MAP_RANDOM
	local old_MAP_EXTEND = MAP_EXTEND
	local old_CONFIG = CONFIG

	-- Temporary Constants
	MAP_SET_1 = 1
	MAP_SET_2 = 2
	MAP_SET_3 = 3
	MAP_SET_4 = 4
	MAP_NOMINATE = 100
	MAP_RANDOM = 101
	MAP_EXTEND = 102

	CONFIG = {}
	include("./config.lua")
	
	-- Cleanup the config formatting
	for i=1, #CONFIG.VoteSelections do
		local v = CONFIG.VoteSelections[i]
		if not istable(v) then
			CONFIG.VoteSelections[i] = {v}
		end
	end
	for k, v in pairs(CONFIG.MapSets) do
		v.title = tostring( v.title or "" )
		v.cooldown = tonumber( v.cooldown or 0 )
		v.cooldown_local = tobool( v.cooldown_local )

		if v.cooldown < 0 then
			v.cooldown = #v.maps + v.cooldown
		end
	end

	MapVote.Config = CONFIG

	-- Restore global values
	MAP_SET_1 = old_MAP_SET_1
	MAP_SET_2 = old_MAP_SET_2
	MAP_SET_3 = old_MAP_SET_3
	MAP_SET_4 = old_MAP_SET_4
	MAP_NOMINATE = old_MAP_NOMINATE
	MAP_RANDOM = old_MAP_RANDOM
	MAP_EXTEND = old_MAP_EXTEND
	CONFIG = old_CONFIG
end
MapVote.LoadConfig()