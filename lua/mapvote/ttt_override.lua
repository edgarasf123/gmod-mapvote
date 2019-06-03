hook.Add("PostGamemodeLoaded", "MapVote_TTTOveride", function()
	function CheckForMapSwitch()
		local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
		SetGlobalInt("ttt_rounds_left", rounds_left)
	end
end)

function MapVote.Extend()
	SetGlobalInt("ttt_rounds_left", GetConVar("ttt_round_limit"):GetInt())
	PrepareRound()
end

function MapVote.PrepareToVote()
	if MapVote.InProgress then return end
	if GetGlobalInt("ttt_rounds_left", 6) <= 1 then return end
	SetGlobalInt("ttt_rounds_left", 1)
end

hook.Add("TTTDelayRoundStartForVote", "MapVote_Check", function()
	local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6))

	if rounds_left <= 0 then        
		MapVote.Start()
		return true, MapVote.Config.VoteDuration + 3
	end
end)