
------------------------------------------------------------------
-- Rock The Vote
------------------------------------------------------------------

MapVote.RTV_Votes = {}
MapVote.RTV_BeginTime = os.time() + MapVote.Config.RTV_Wait 
MapVote.RTV_Succeeded = false
function MapVote.RTV_Vote( ply )
	if MapVote.RTV_Succeeded then 
 		MapVote.Message( ply, Color(255,255,255), "Rock the vote already succeeded!" )
		return nil 
	end

	if os.time() < MapVote.RTV_BeginTime then 
 		MapVote.Message( ply, Color(255,255,255), "Too early to rock the vote!" )
		return nil 
	end

	if MapVote.RTV_Votes[ply] and MapVote.RTV_Votes[ply].vote and os.time() - MapVote.RTV_Votes[ply].time < 60 then 
 		MapVote.Message( ply, Color(255,255,255), "You already rocked the vote!" )
		return nil 
	end


	MapVote.RTV_Votes[ply] = {vote=true, time=os.time()}
	MapVote.MessageAll( ply, " rocked the vote! (" .. MapVote.RTV_TotalVotes() .. "/" .. MapVote.RTV_RequiredVotes() .. ")" )

	MapVote.RTV_Check()
end
function MapVote.RTV_Check()

	if not MapVote.RTV_Succeeded and MapVote.RTV_TotalVotes() >= MapVote.RTV_RequiredVotes() then
        MapVote.RTV_Succeeded = true
        MapVote.RTV_Votes = {}
		MapVote.MessageAll( Color(255,255,255), "Rock the vote succeeded, map vote will start at the end of the round." )
		MapVote.PrepareToVote()
	end

end
function MapVote.RTV_TotalVotes()

	local rtv_count = 0
	for ply,data in pairs(MapVote.RTV_Votes) do
		if IsValid(ply) and data.vote then
			rtv_count = rtv_count + 1
		end
	end
	return rtv_count
end

function MapVote.RTV_RequiredVotes()
	local total_count = #player.GetAll()
	return math.max( math.ceil(MapVote.Config.RTV_WinRatio*total_count), MapVote.Config.RTV_MinVotes)
end

hook.Add("PlayerDisconnected", "MapVote_RTV_Check", MapVote.RTV_Check)
hook.Add("PlayerInitialSpawn", "MapVote_RTV_Check", MapVote.RTV_Check)
------------------------------------------------------------------
-- Chat
------------------------------------------------------------------
hook.Add( "PlayerSay", "MapVote_RTV", function( ply, text, public )
	if not MapVote.Config.RTV_Enabled then return end
	
	local args = string.Explode( " ", text )
	local cmd = string.lower( table.remove( args, 1 ) )
	if ( cmd == string.lower( MapVote.Config.RTV_Command) ) then
		MapVote.RTV_Vote( ply )
		return ""
	end
end )