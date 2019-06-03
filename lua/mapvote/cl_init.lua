MapVote.InProgress = false
MapVote.VoteSelections = {}
MapVote.PlayerVotes = {}
MapVote.VoteEnd = 0

------------------------------------------------------------------
-- Messsage
------------------------------------------------------------------
net.Receive( "MapVote_Message", function( len )
	chat.AddText( Color(255, 255, 255),"[",Color(255, 255, 102),"MapVote", Color(255,255,255),"] ",unpack(net.ReadTable()) )
end )

------------------------------------------------------------------
-- Network
------------------------------------------------------------------
net.Receive( "MapVote_Start", function( len )
	MapVote.InProgress = true
	MapVote.VoteEnd = os.time() + net.ReadUInt( 16)
	MapVote.VoteSelections = net.ReadTable()
	MapVote.PlayerVotes = net.ReadTable()

	MapVote.CreateGUI( MapVote.VoteSelections )
	MapVote.UpdateVotes(  )

end )
net.Receive( "MapVote_Stop", function( len )
	local win_selection = net.ReadUInt(8)
	MapVote.InProgress = false

	if IsValid(MapVote.GUI) then
		for k,v in pairs(MapVote.VoteSelections) do
			local but = v.gui_button
			if not but then continue end
			
			but:SetWin(k == win_selection)
		end
	end

	timer.Simple(3, function()
		if IsValid(MapVote.GUI) then 
			MapVote.GUI:Remove()
		end
	end)
	
end )
net.Receive( "MapVote_Update", function( len )
	local ply = net.ReadEntity()
	MapVote.PlayerVotes = net.ReadTable()
	
	if ply == LocalPlayer() then
		surface.PlaySound( "ui/buttonclickrelease.wav" )
	end

	MapVote.UpdateVotes()

end )

net.Receive( "MapVote_NominateList", function( len )
	MapVote.NominateList = net.ReadTable()
	local maps = {}
	for k,v in pairs(MapVote.NominateList) do
		maps[#maps + 1] = v.name
	end
	table.sort(maps, function(a,b) print(a,b) return a<b end )

	MsgC( Color( 255, 255, 0 ), "Available maps for nomination: \n" )
	for k,v in pairs(maps) do
		MsgC( "\t", Color( 255, 255, 255 ), v, "\n" )
	end
end )


------------------------------------------------------------------
-- Main Functions
------------------------------------------------------------------
function MapVote.Vote( vote_id )
	net.Start("MapVote_Vote")
	net.WriteUInt( vote_id, 8 )
	net.SendToServer()
end


function MapVote.UpdateVotes(  )
	if not IsValid(MapVote.GUI) then return end
	local vote_count = table.Count(MapVote.PlayerVotes)

	for k,v in pairs(MapVote.VoteSelections) do
		local but = v.gui_button
		if not but then continue end
		but:SetSelected( false )
		but:SetProgress( 0 )
	end

	for ply, vote_data in pairs(MapVote.PlayerVotes) do
		if vote_data.vote_id < 0 then continue end
		local but = MapVote.VoteSelections[vote_data.vote_id].gui_button
		if not but then continue end

		if ply == LocalPlayer() and not but:IsSelected( ) then
			but:SetSelected( true )
		end
		but:AddProgress( 1/vote_count )
	end
	
end