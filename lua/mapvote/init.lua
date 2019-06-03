util.AddNetworkString( "MapVote_Start" )
util.AddNetworkString( "MapVote_Update" )
util.AddNetworkString( "MapVote_Vote" )
util.AddNetworkString( "MapVote_Stop" )
util.AddNetworkString( "MapVote_Message" )
util.AddNetworkString( "MapVote_NominateList" )

MapVote.LoadConfig()

if MapVote.Config.RTV_Enabled then
	include("sv_rtv.lua")
end

-- Constants
local MAP_SET_1 = 1
local MAP_SET_2 = 2
local MAP_SET_3 = 3
local MAP_SET_4 = 4
local MAP_NOMINATE = 100
local MAP_RANDOM = 101
local MAP_EXTEND = 102


MapVote.MapSets = {}
MapVote.Cache = {}

MapVote.InProgress = false
MapVote.MapChanging = false
MapVote.PlayerVotes = {}

------------------------------------------------------------------
-- Messsage
------------------------------------------------------------------
function MapVote.Message(ply, ...)

	net.Start( "MapVote_Message" )
	net.WriteTable( {...} )
	net.Send( ply )
end

function MapVote.MessageAll(...)
	net.Start( "MapVote_Message" )
	net.WriteTable( {...} )
	net.Broadcast()
end
------------------------------------------------------------------
-- Override Gamemode Features
------------------------------------------------------------------
if engine.ActiveGamemode() == "terrortown" then
	include("ttt_override.lua")
end

------------------------------------------------------------------
-- Helper Functions
------------------------------------------------------------------
local function shuffle(t)
	local n = #t
	while n >= 2 do 
		local k = math.random(n)
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end
	return t
end

------------------------------------------------------------------
-- Main Functions
------------------------------------------------------------------
function MapVote.Start()
    if MapVote.InProgress then return end
	if MapVote.MapChanging then return end
    MapVote.Debug "Starting Vote"
	MapVote.InProgress = true
	
	-- Prepare the selections
	MapVote.VoteSelections = MapVote.GenerateVoteList()

	-- Prepare votes
	MapVote.PlayerVotes = {}
	MapVote.ValidateVotes()

	-- Lock votes of players who nominated
	for vote_id, map_data in pairs(MapVote.VoteSelections) do
		local ply = map_data.nominate_ply
		if map_data.nominated and IsValid(ply) then
			local data = MapVote.PlayerVotes[ply]
			data.locked = true
			data.vote = map_data.vote_id
			MapVote.PlayerVotes[ply].vote_id = vote_id
		end
	end

	timer.Create( "MapVote_Stop", MapVote.Config.VoteDuration, 1, MapVote.Stop )

	net.Start( "MapVote_Start" )
	net.WriteUInt(timer.TimeLeft( "MapVote_Stop" ), 16)
	net.WriteTable(MapVote.VoteSelections)
	net.WriteTable(MapVote.PlayerVotes)
	net.Broadcast()


end

function MapVote.Stop()
	if not MapVote.InProgress then return end
	MapVote.InProgress = false

	MapVote.ValidateVotes()
	local winner_id = MapVote.WinningVote()
	local winner = MapVote.VoteSelections[winner_id]

	net.Start( "MapVote_Stop" )
	net.WriteUInt(winner_id,8)
	net.Broadcast()

	if winner.extend then
		MapVote.MessageAll("Map is going to be extended")
        MapVote.RTV_Succeeded = false
		MapVote.RTV_Votes = {}
		MapVote.RTV_BeginTime = os.time() + MapVote.Config.RTV_Wait 
		MapVote.LoadSets()
		MapVote.Extend()
	elseif winner.random then
		MapVote.MessageAll("Random map won the vote")
		MapVote.MapChanging = true
        timer.Simple(4, function() MapVote.SwitchMap( winner ) end)
	else
		MapVote.MessageAll(winner.name," won the vote")
        MapVote.MapChanging = true
		timer.Simple(4, function() MapVote.SwitchMap( winner ) end)
	end

end

function MapVote.ValidateVotes()
	-- Remove NULL players
	for ply, vote_data in pairs(MapVote.PlayerVotes) do
		if not IsValid(ply) then
			vote_data[ply] = nil
		end
	end
	-- Guarantee that entries consist all players
	for k,ply in pairs(player.GetAll()) do
		MapVote.PlayerVotes[ply] = MapVote.PlayerVotes[ply] or { vote_id=-1, locked=false, time=0 }
	end
end

function MapVote.PlayerVote( ply, vote_id )
	if not MapVote.InProgress then return end
	if not IsValid(ply) then return end

	if not MapVote.PlayerVotes[ply] then
		MapVote.ValidateVotes()
	end

	if MapVote.PlayerVotes[ply].locked then return end
	if os.time() - MapVote.PlayerVotes[ply].time < 0.5 then return end
	if MapVote.PlayerVotes[ply].vote_id == vote_id then return end
	if not MapVote.VoteSelections[vote_id] then return end
	
	MapVote.PlayerVotes[ply].time = os.time()
	MapVote.PlayerVotes[ply].vote_id = vote_id

	net.Start( "MapVote_Update" )
	net.WriteEntity( ply )
	net.WriteTable( MapVote.PlayerVotes )
	net.Broadcast()
end

function MapVote.WinningVote()

	local votes_count = {}
	local vote_max = 0
	for ply,v in pairs(MapVote.PlayerVotes) do
		local vote_id = v.vote_id
		if vote_id < 0 then continue end
		votes_count[vote_id] = (votes_count[vote_id] or 0) + 1
		if votes_count[vote_id] > vote_max then
			vote_max = votes_count[vote_id]
		end
	end
	local winners = {}
	for vote_id, count in pairs(votes_count) do
		if count >= vote_max then
			winners[#winners + 1] = vote_id
		end
	end
	if #winners > 0 then
		return table.Random( winners )
	else
		return (table.Random( MapVote.VoteSelections )).vote_id
	end
end
------------------------------------------------------------------
-- Network
------------------------------------------------------------------

hook.Add("PlayerInitialSpawn", "MapVote", function( ply )
	if not MapVote.InProgress then return end
 	MapVote.ValidateVotes()

	net.Start( "MapVote_Start" )
	net.WriteUInt(timer.TimeLeft( "MapVote_Stop" ), 16)
	net.WriteTable(MapVote.VoteSelections)
	net.WriteTable(MapVote.PlayerVotes)
	net.Send( ply )

	net.Start( "MapVote_Update" )
	net.WriteEntity( ply )
	net.WriteTable( MapVote.PlayerVotes )
	net.Broadcast()
end)

net.Receive( "MapVote_Vote", function( len, ply )
	if not MapVote.InProgress then return end
	
	local vote_id = net.ReadUInt( 8 )
	MapVote.PlayerVote( ply, vote_id )
end )

------------------------------------------------------------------
-- Nominations
------------------------------------------------------------------

function MapVote.MaxNominations()
	if MapVote.Cache.MaxNominations then return MapVote.Cache.MaxNominations end

	local max_nominations = 0
	for _, selection in pairs(MapVote.Config.VoteSelections) do
		if table.HasValue( selection, MAP_NOMINATE ) then
			max_nominations = max_nominations + 1
		end
	end

	MapVote.Cache.MaxNominations = max_nominations
	return max_nominations
end

function MapVote.ValidateNominations()
	local map_nominate_set = MapVote.MapSets[MAP_NOMINATE]

	for i=#map_nominate_set,1,-1 do
		local data = map_nominate_set[i]
		if not IsValid(data.nominate_ply) then
			local map_data = table.remove(map_nominate_set, i)
			MapVote.AvailableNominations[map_data.name].nominated = false

		end
	end


end

function MapVote.NominateMap( ply, map_name )
	local map_nominate_set = MapVote.MapSets[MAP_NOMINATE]

	if MapVote.InProgress then return false, "Map vote is in progress" end
	if MapVote.MaxNominations() == 0 then return false, "Nominations are disabled" end
	if not MapVote.AvailableNominations[map_name] then return false, "Invalid map, type !nominate to retrieve available maps" end
	if MapVote.AvailableNominations[map_name].nominated then return false, "Map is already nominated" end
	
	MapVote.ValidateNominations()
	if #map_nominate_set >= MapVote.MaxNominations()  then return false, "No available nomination slots" end
	
	if PS and MapVote.Config.Nominate_Cost > 0 then
		local cost = MapVote.Config.Nominate_Cost
		if not ply:PS_HasPoints(cost) then
			return false, "You need to have "..cost.." points to nominate a map"
		end
		ply:PS_TakePoints(cost)
	end

	for i=1, #map_nominate_set do
		local data = map_nominate_set[i]
		if data.nominate_ply == ply then
			if not MapVote.Config.Nominate_AllowRenomination then return false, "You have already nominated a map" end
			if os.time() - data.nominate_time < 30 then return false, "Wait before you nominate different map" end

			table.remove(map_nominate_set, i)
			break
		end
	end
	

	if PS and MapVote.Config.Nominate_Cost > 0 then
		ply:PS_TakePoints(cost)
	end

	local map_data = MapVote.AvailableNominations[map_name]

	map_data.nominate_ply = ply
	map_data.nominate_time = os.time()
	map_data.nominated = true

	map_nominate_set[#map_nominate_set + 1] = map_data

	MapVote.NominateListRequests = {}
	return true
end

------------------------------------------------------------------
-- Chat
------------------------------------------------------------------
MapVote.NominateListRequests = {} -- Mainly to stop DoS attacks
hook.Add( "PlayerSay", "MapVote_Chat", function( ply, text, public )
	local args = string.Explode( " ", text )
	local cmd = string.lower( table.remove( args, 1 ) )
	if MapVote.Config.Nominate_Enabled and cmd == string.lower(MapVote.Config.Nominate_Command) then
		if args[1] then
			local map = string.lower( args[1] )
			local succ, err = MapVote.NominateMap( ply, map )
			if not succ then
				MapVote.Message(ply, err)
			else
				MapVote.MessageAll(ply, " has nominated ", map)
			end
		else
			if MapVote.NominateListRequests[ply] and os.time() - MapVote.NominateListRequests[ply] < 5 then 
				MapVote.Message(ply, "Wait before you make another request")
				return "" 
			end
			MapVote.NominateListRequests[ply] = os.time()

			net.Start( "MapVote_NominateList" )
			net.WriteTable( MapVote.AvailableNominations )
			net.Send(ply)

			MapVote.Message(ply, "Check your console for the list")
		end
		return ""
	end
end )

------------------------------------------------------------------
-- Votelist related stuff
------------------------------------------------------------------

function MapVote.GenerateVoteList()
	MapVote.ValidateNominations()
	local votelist = {}
	local inlist = {}
	
	for k, selection in ipairs(MapVote.Config.VoteSelections) do
		for j, set_key in ipairs(selection) do
			local set = MapVote.MapSets[set_key]
			--print(#votelist + 1, set_key, set and #set)
			if set_key == MAP_EXTEND then
				local map_data = {extend=true, name="Extend map"}
				map_data.vote_id = #votelist + 1
				votelist[map_data.vote_id] = map_data
			elseif not set then
				MapVote.Debug("Invalid map set "..set_key)
			elseif #set > 0 then
				local map_data = set[1]
				while #set > 0 and inlist[map_data.name] do
					table.remove(set,1)
					map_data = set[1]
				end
				if map_data then
					inlist[map_data.name] = true
					map_data.vote_id = #votelist + 1
					if set_key == MAP_RANDOM then map_data.random = true end
					votelist[map_data.vote_id] = map_data
					table.remove(set,1)
					break
				end
			end
		end
	end
	return votelist
end

function MapVote.MapHistory( map_name_as_keys, set )
	local t = util.JSONToTable( file.Read( "mapvote_history.txt", "DATA" ) or "[]" )
	-- Filter map to set
	if set and set > 0 then
		local tmp = {}
		for k, map_data in pairs(t) do
			if map_data.set == set then
				tmp[#tmp + 1] = map_data
			end
		end
		t = tmp
	end

	-- Inverting the table switches map set generation time from n^2 to nlogn 
	if map_name_as_keys then
		local tmp = {}
		for k, map_data in ipairs(t) do
			if tmp[map_data.name] then continue end
			
			tmp[map_data.name] = map_data
			map_data.cooldown_index = k
		end 
		t = tmp
	end

	return t
end

function MapVote.MaxCooldown()
	if MapVote.Cache.MaxCooldown then return MapVote.Cache.MaxCooldown end

	local max_cooldown = 0
	for _, v in pairs(MapVote.Config.MapSets) do
		local cooldown = v.cooldown
		if max_cooldown < cooldown then
			max_cooldown = cooldown
		end
	end

	MapVote.Cache.MaxCooldown = max_cooldown
	return max_cooldown
end

function MapVote.SwitchMap( map_data )
	local map_history = MapVote.MapHistory()

	local map_data = {name=map_data.name, set=map_data.set}

	table.insert( map_history, 1, map_data )
	
	-- Cleanup old entries
	if #map_history > (MapVote.MaxCooldown() + 30) then -- Add extra 30 to be safe
		for i=MapVote.MaxCooldown()+1, #map_history do
			map_history[i] = nil
		end
	end

	file.Write("mapvote_history.txt", util.TableToJSON(map_history))
	RunConsoleCommand( "changelevel", map_data.name )
end


function MapVote.LoadSets()
	MapVote.MapSets = {}

    local available_maps = {}
    maps = file.Find( "maps/*", "GAME" )
    for k, map in pairs( file.Find( "maps/*", "GAME" ) ) do
        local map = string.lower( map )
        if string.GetExtensionFromFilename( map ) == "bsp" then
            available_maps[string.StripExtension( map )] = true
        end
    end

	local cur_map = string.lower( game.GetMap() )
	local global_map_history = MapVote.MapHistory( true )	
	
	local nominate_set = {}
	local random_set = {}
	for set_key,set in pairs( MapVote.Config.MapSets) do
		local map_history = global_map_history
		local maps = {}
		local cooldown = set.cooldown

		if set.cooldown_local then
			map_history = MapVote.MapHistory( true, set_key )
		end

		for k,map_name in pairs(set.maps) do
			if map_history[map_name] and map_history[map_name].cooldown_index <= cooldown then continue end
			if map_name == cur_map then continue end
            if not available_maps[string.lower(map_name)] then continue end

			local map_data = {name=map_name, set=set_key}
			maps[#maps + 1] = map_data
			-- Random Map Set
			if table.HasValue( MapVote.Config.RandomMap_Sets, set_key) then
				random_set[map_name] = map_data
			end
			-- Nomination Set
			if table.HasValue( MapVote.Config.Nominate_Sets, set_key) then
				map_data.nominated = false
				nominate_set[map_name] = map_data
			end
		end

		MapVote.MapSets[set_key] = shuffle( maps )
	end

	MapVote.AvailableNominations = nominate_set

	local rset = {}
	for k,map_data in pairs(random_set) do rset[#rset+1] = map_data end
	MapVote.MapSets[MAP_RANDOM] = shuffle(rset)
	MapVote.MapSets[MAP_NOMINATE] = {}

	--file.Write("mapvote_debug.txt",util.TableToJSON(MapVote.MapSets))
end
-- Preload the sets
MapVote.LoadSets()