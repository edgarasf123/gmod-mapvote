-----------------------------------------------------------------------------------------
-- Fonts
-----------------------------------------------------------------------------------------
local function loadFonts()
	surface.CreateFont( "MapVote.TitleFont", {
		font = "Open Sans",
		extended = false,
		size = 80,
		weight = 100,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	surface.CreateFont( "MapVote.TimeleftFont", {
		font = "Open Sans",
		extended = false,
		size = 40,
		weight = 100,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	surface.CreateFont( "MapVote.Selection.MapName", {
		font = "Open Sans",
		extended = false,
		size = 30,
		weight = 100,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	surface.CreateFont( "MapVote.Credits", {
		font = "Open Sans",
		extended = false,
		size = 12,
		weight = 100,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
end
loadFonts()
hook.Add("InitPostEntity", "MapVote_LoadFonts", loadFonts)

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
local PANEL = {}

local mat_default =  Material("mapvote/_default.png")
function PANEL:Init()
	self:SetText( "" )
	self.map = {name = "",  vote_id=-1}
	self.vote_win = nil
	self.map_mat = mat_default
	self.progress = 0
	self.progress_render = 0
	self.highlight = false
	self.selected = false
end

function PANEL:Paint(w,h)
	local dt_time = RealFrameTime()

	self.progress_render = self.progress_render + (self.progress - self.progress_render)*dt_time*10

	surface.SetDrawColor(127, 140, 141)
	surface.DrawRect( 0, 0, w, h )


	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.SetMaterial( self.map_mat	) -- If you use Material, cache it!
	surface.DrawTexturedRect( 0, 0, h, h )



	--surface.SetDrawColor( 255, 255, 255, 255 )
	--surface.DrawOutlinedRect( 0, 0, w, h )

	if self.highlight then
		surface.SetDrawColor(241, 196, 15)
	else
		if self.selected then
			surface.SetDrawColor(46, 204, 113)
		else
			surface.SetDrawColor(39, 174, 96)
		end
	end
	surface.DrawRect( h, 0, self.progress_render*(w-h), h )
	
	surface.SetFont( "MapVote.Selection.MapName" )
	local text_h = select(2, surface.GetTextSize( "MAPVOTE" ))
	surface.SetTextPos( h*1.1, h/2-text_h/2 )
	surface.SetTextColor( 238, 238, 238 )
	surface.DrawText( self.map.random and "Random map" or self.map.name )

	if self.vote_win == false then
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect( 0, 0, w, h )
	end
end

function PANEL:DoClick()
	MapVote.Vote( self.map.vote_id )
end
function PANEL:ToggleHighlight()
	self.highlight = not self.highlight
	if self.highlight then surface.PlaySound("buttons/blip1.wav") end
end
function PANEL:SetWin( won )
	self.vote_win = won
	
	if won then 
		local button = self
		timer.Create( "MapVote_SelectionWin", 0.3, 0, function()
			if not IsValid( button ) then
				timer.Destroy("MapVote_SelectionWin")
				return nil
			end

			button:ToggleHighlight()
		end )
	end
end
function PANEL:SetSelected( selected )
	self.selected = selected
end
function PANEL:IsSelected( )
	return self.selected
end
function PANEL:SetProgress( progress )
	self.progress = progress
end
function PANEL:AddProgress( progress )
	self.progress = self.progress + progress
end
function PANEL:SetMap(map)
	self.map = map
	map.gui_button = self
	if map.random then
		self.map_mat = Material("mapvote/_random.png")
	elseif map.extend then
		self.map_mat = Material("mapvote/_extend.png")
	elseif file.Exists( "materials/mapvote/"..map.name..".png", "GAME" ) then
		self.map_mat = Material("mapvote/"..map.name..".png")
	end
end
vgui.Register( "MapVote_Selection", PANEL, "DButton" )
-----------------------------------------------------------------------------------------
local PANEL = {}
function PANEL:Init()
	self:DockMargin(0,0,0,0)
	self:DockPadding(0,0,0,0)
	self:SetTitle( "" )
	self:ShowCloseButton(false)

	local screen_height = ScrH()
	local frame_width, frame_height = math.floor(screen_height*(4/3)*0.9),math.floor(screen_height*0.9)
	
	self:SetSize(frame_width, frame_height)
	self:Center()

	--frame:SetBackgroundBlur( true )
	-------------------------------------------------
	local title = vgui.Create( "DPanel", self )
	title:SetSize( 0, 0.1*frame_height )
	function title:Paint(width, height)
		surface.SetDrawColor(44, 62, 80)
		surface.DrawRect( 0, 0, width, height )

		surface.SetFont( "MapVote.TitleFont" )
		local text_h = select(2, surface.GetTextSize( "MAPVOTE" ))
		surface.SetTextColor( 189, 195, 199 )
		surface.SetTextPos( 50, height/2-text_h/2 )
		surface.DrawText( "MAPVOTE" )

		local timeleft_str = "Time Left: "..math.max(0,MapVote.VoteEnd-os.time())

		surface.SetFont( "MapVote.TimeleftFont" )
		local text_w, text_h = surface.GetTextSize( "Time Left: 00" )
		surface.SetTextColor( 189, 195, 199 )
		surface.SetTextPos( width-text_w-10, height-text_h )
		surface.DrawText( timeleft_str )
	end
	title:Dock( TOP )
	self.title = title
	-------------------------------------------------
	local close_button = vgui.Create( "DButton", title )
	close_button:SetSize( frame_height*0.1*0.5, frame_height*0.1*0.5)
	close_button:SetPos(frame_width-frame_height*0.1*0.5,0)
	close_button:SetText( "" )
	function close_button:Paint(w,h)
		draw.NoTexture()
		surface.SetDrawColor( 189, 195, 199 )
		surface.DrawTexturedRectRotated( w/2, h/2, 4, h*0.7, 45 )
		surface.DrawTexturedRectRotated( w/2, h/2, 4, h*0.7, -45 )
	end

	function close_button:DoClick()
		MapVote.GUI:Remove()
	end
	-------------------------------------------------
	local content = vgui.Create( "DPanel", self )
	function content:Paint(width, height)
	end
	content:DockMargin( 50,50,50,50)
	content:Dock( FILL )
	self.content = content

	-------------------------------------------------
	self:InvalidateLayout(true)


end

function PANEL:Paint(width, height)
	surface.SetDrawColor(52, 73, 94 )
	surface.DrawRect( 0, 0, width, height )

	local credits_text = "H3xCat was here"
	surface.SetFont( "MapVote.Credits" )
	local text_w, text_h = surface.GetTextSize( credits_text )
	surface.SetTextColor( 44, 62, 80 )
	surface.SetTextPos( width-text_w-5, height-text_h-5 )
	surface.DrawText( credits_text  )
end
function PANEL:SetMaps(maps)

	local c_width, c_height = self.content:GetSize()
	local b_width, b_height = c_width, math.floor(c_height / #maps)

	local button_pad = b_height*0.1
	for i = 0, #maps-1 do
		local y = (i/#maps)*c_height + button_pad/2
		local but = vgui.Create( "MapVote_Selection", self.content )
		but:SetSize( b_width, b_height-button_pad)
		but:SetPos( 0,y)
		but:SetMap(maps[i+1])
		
	end
end
vgui.Register( "MapVote_Frame", PANEL, "DFrame" )
-----------------------------------------------------------------------------------------
function MapVote.CreateGUI( maps )
	if IsValid(MapVote.GUI) then MapVote.GUI:Remove() end

	local frame = vgui.Create( "MapVote_Frame" )
	frame:MakePopup(true)
	frame:SetMaps(maps)

	MapVote.GUI = frame
end

--MapVote.CreateGUI( {"gm_flatgrass","gm_construct"} )