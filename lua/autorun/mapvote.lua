include( "mapvote/shared.lua" )

if SERVER then
	AddCSLuaFile( "autorun/mapvote.lua" )
	AddCSLuaFile( "mapvote/shared.lua" )
	AddCSLuaFile( "mapvote/cl_vgui.lua" )
	AddCSLuaFile( "mapvote/cl_init.lua" )

	include( "mapvote/sv_resources.lua" )
	include( "mapvote/config_parser.lua" )
	include( "mapvote/init.lua" )
	
elseif CLIENT then
	include( "mapvote/cl_vgui.lua" )
	include( "mapvote/cl_init.lua" )
end

MapVote.Debug("Initialized...")