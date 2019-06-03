function MapVote.LoadResources()
	local files = file.Find( "materials/mapvote/*.png", "GAME" )
	for k,file in pairs(files) do
		resource.AddSingleFile( "materials/mapvote/"..file )
	end
end
MapVote.LoadResources()