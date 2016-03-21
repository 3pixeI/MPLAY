CreateClientConVar( 'mplay_repeat', 0, true, true )
CreateClientConVar( 'mplay_volume', .5, true, true )

surface.CreateFont( 'MPLAY_Title', {
		font = '8BIT WONDER Nominal',
		size = 25,
		antialias = false
	} )

function LoadMPLAY( )
	local read = file.Read( 'mplay_playlist.txt', 'DATA' )
	if read ~= nil and read ~= '' then
		MPLAY.PlayList = util.JSONToTable( read )
	end
end

function SaveMPLAY( )
	local tab = MPLAY.PlayList or { }
	file.Write( 'mplay_playlist.txt', util.TableToJSON( tab ) )
end

function ResetMPLAY( )
	RunConsoleCommand( 'stop_mplay' )

	MPLAY = { };
	MPLAY.PlayList = {
		[ 1 ] = 'https://www.youtube.com/watch?v=O5_LSaVB8So',
	}

	LoadMPLAY( )
	SaveMPLAY( )
end

hook.Add( 'Initialize', 'MPLAY', function( )
	ResetMPLAY( )
end )

function openMPLAY( )
	local radius = 100;

	MPLAY.Main = vgui.Create( "DFrame" );
	local m = MPLAY.Main;
	m:SetPos( 0, 0 );
	m:SetSize( ScrW( ), ScrH( ) );
	m:MakePopup( );
	m:SetDraggable( false )
	m:SetTitle( '' );
	m.Paint = function( self, nW, nH )
		draw.RoundedBox( 0, 0, 0, nW, nH, Color( 0, 0, 0, 125 ) );

		local x, y = ( ScrW( ) * .5 ), ( ScrH( ) * .5 );
		local wSize = 5;
		local minSize, maxSize = radius * 2, ScrW( ) * 1.5;
		local seg = math.Round( ( ( radius * 2 ) * math.pi ) / 2 );

		MPLAY.Radius = MPLAY.Radius or radius * .5;
		MPLAY.FFTable = MPLAY.FFTable or { };
		MPLAY.FFTSable = MPLAY.FFTSable or { };
		MPLAY.BH = MPLAY.BH or 0

		if MPLAY.Radius < radius then
			MPLAY.Radius = Lerp( 0.03, MPLAY.Radius, radius )
		end

		if ( MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) ) then
			MPLAY.Music:FFT( MPLAY.FFTable, FFT_256 );
		end

		MPLAY.BackCol = MPLAY.BackCol or Color( 0, 0, 0, 100 );
		draw.RoundedBox( 0, 0, 0, nW, nH, MPLAY.BackCol );

		local rCol = HSVToColor( math.sin( CurTime( ) * .4 ) * 360, 1, 1 )
		rCol.a = 100;
		draw.NoTexture( );
		
		surface.SetDrawColor( rCol );

		for i = 0, seg do
			local rad = ( ( ( i / wSize * 1.5 ) / seg )  * 360 );
			local deg = math.deg( rad );
			
			local num = math.Round( math.sin( i ) * 32 )

			if MPLAY.FFTable[ num / 2 ] then
				MPLAY.BH = MPLAY.FFTable[ num / 2 ] * 3000
			end

			local size = math.Clamp( MPLAY.BH, MPLAY.Radius * 2, maxSize );
			MPLAY.FFTSable[ num ] = Lerp( .004, MPLAY.FFTSable[ num ] or 0, size );

			surface.DrawTexturedRectRotated( x, y, wSize, MPLAY.FFTSable[ num ], deg );
		end;

		if math.Round( MPLAY.Radius ) < radius then
			if MPLAY.BackCol.r > 0 then MPLAY.BackCol.r = Lerp( 0.005, MPLAY.BackCol.r, 0 ) end
			if MPLAY.BackCol.g > 0 then MPLAY.BackCol.g = Lerp( 0.005, MPLAY.BackCol.g, 0 ) end
			if MPLAY.BackCol.b > 0 then MPLAY.BackCol.b = Lerp( 0.005, MPLAY.BackCol.b, 0 ) end
			if MPLAY.BackCol.a > 0 then MPLAY.BackCol.a = Lerp( 0.005, MPLAY.BackCol.a, 100 ) end
		end

		if ( MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) ) then
			draw.SimpleText( 'PLAY', 'MPLAY_Title', ScrW( )/2, ScrH( )/2 - 2, color_white, 1, 1 )
			if MPLAY.FFTSable[ table.GetWinningKey( MPLAY.FFTSable ) ] > radius * 4.5 and math.Round( MPLAY.Radius ) >= radius then
				MPLAY.Radius = Lerp( 0.8, MPLAY.Radius, radius * .5 )

				MPLAY.BackCol.r = Lerp( 0.2, MPLAY.BackCol.r, 255 )
				MPLAY.BackCol.g = Lerp( 0.2, MPLAY.BackCol.g, 255 )
				MPLAY.BackCol.b = Lerp( 0.2, MPLAY.BackCol.b, 255 )
				MPLAY.BackCol.a = Lerp( 0.2, MPLAY.BackCol.a, 100 )
			end
		else
			for k, v in pairs( MPLAY.FFTable ) do
				if MPLAY.FFTable[ k ] ~= 0 then
					MPLAY.FFTable[ k ] = 0;
				end
			end

			draw.SimpleText( 'MPLAY', 'MPLAY_Title', ScrW( )/2, ScrH( )/2, color_white, 1, 1 )
		end
	end
	m.Think = function( )
		if m:GetWide( ) ~= ScrW( ) then
			m:SetWide( ScrW( ) )
			m:SetSize( ScrW( ), ScrH( ) )
		end

		if m:GetTall( ) ~= ScrH( ) then
			m:SetTall( ScrH( ) )
			m:SetSize( ScrW( ), ScrH( ) )
		end
	end

	local n = m:Add( 'DPanel' )
	n:SetPos( ScrW( ) * .5 - ( radius * 1.2 ) * .5, ScrH( ) * .5 + 10 )
	n:SetSize( radius * 1.2, 20 )
	n.ST = CurTime( )
	n.Paint = function( self, nW, nH )
		if ( MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) ) then
			local t = CurTime( ) - self.ST

			surface.SetFont( 'DermaDefault' )
			local tw, th = surface.GetTextSize( MPLAY.PlayList[ MPLAY.NowPlay ] or '' )
			local x = math.sin( t * .3 ) ^ 2 * ( ( tw + 10 ) * .5 )
			if x < 0 then x = x * .5 end

			draw.SimpleText( MPLAY.PlayList[ MPLAY.NowPlay ] or '', 'DermaDefault', x, nH/2, color_white, 1, 1 )
		end
	end

	local p = m:Add( 'DPanel' )
	p:SetPos( 5, 5 )
	p:SetSize( 227, 48 )
	p.Paint = function( self, nW, nH )
		draw.NoTexture( )
		surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
		surface.DrawRect( 0, 0, nW, nH )

		draw.RoundedBox( 0, 0, nH - 7, nW, 7, Color( 0, 0, 0, 175 ) )

		if ( MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) ) then
			draw.RoundedBox( 0, 0, nH - 7, ( MPLAY.Music:GetTime( ) / MPLAY.Music:GetLength( ) ) * nW, 7, Color( 255, 255, 255, 175 ) )
		end
	end

	local pb = p:Add( 'DButton' )
	pb:SetSize( 32, 32 )
	pb:SetPos( 5, 5 )
	pb:SetText( '' )
	pb.Paint = function( self, nW, nH )
		surface.SetMaterial( Material( 'icon16/control_start_blue.png', 'vertexlitgeneric' ) )
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( 0, 0, nW, nH )
	end
	pb.DoClick = function( )
		RunConsoleCommand( 'prev_mplay' )
	end

	local psb = p:Add( 'DButton' )
	psb:SetSize( 32, 32 )
	psb:SetPos( 5 + 32 + 5, 5 )
	psb:SetText( '' )
	psb.Paint = function( self, nW, nH )
		if ( MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) ) then
			surface.SetMaterial( Material( 'icon16/control_stop_blue.png', 'vertexlitgeneric' ) )
		else
			surface.SetMaterial( Material( 'icon16/control_play_blue.png', 'vertexlitgeneric' ) )
		end

		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( 0, 0, nW, nH )
	end
	psb.DoClick = function( )
		if ( MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) ) then
			RunConsoleCommand( 'stop_mplay' )
		else
			RunConsoleCommand( 'play_mplay' )
		end
	end

	local nb = p:Add( 'DButton' )
	nb:SetSize( 32, 32 )
	nb:SetPos( 5 + 32 + 5 + 32 + 5, 5 )
	nb:SetText( '' )
	nb.Paint = function( self, nW, nH )
		surface.SetMaterial( Material( 'icon16/control_end_blue.png', 'vertexlitgeneric' ) )
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( 0, 0, nW, nH )
	end
	nb.DoClick = function( )
		RunConsoleCommand( 'next_mplay' )
	end

	local rb = p:Add( 'DButton' )
	rb:SetSize( 32, 32 )
	rb:SetPos( 5 + 32 + 5 + 32 + 5 + 32 + 5, 5 )
	rb:SetText( '' )
	rb.Paint = function( self, nW, nH )
		if ( GetConVarNumber( 'mplay_repeat', 0 ) == 0 ) then
			surface.SetMaterial( Material( 'icon16/control_repeat.png', 'vertexlitgeneric' ) )
		else
			surface.SetMaterial( Material( 'icon16/control_repeat_blue.png', 'vertexlitgeneric' ) )
		end

		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( 0, 0, nW, nH )
	end
	rb.DoClick = function( )
		if ( GetConVarNumber( 'mplay_repeat', 0 ) == 0 ) then
			RunConsoleCommand( 'mplay_repeat', 1 )
		else
			RunConsoleCommand( 'mplay_repeat', 0 )
		end
	end

	local plb = p:Add( 'DButton' )
	plb:SetSize( 32, 32 )
	plb:SetPos( 5 + 32 + 5 + 32 + 5 + 32 + 5 + 32 + 5, 5 )
	plb:SetText( '' )
	plb.Paint = function( self, nW, nH )
		surface.SetMaterial( Material( 'icon16/control_eject_blue.png', 'vertexlitgeneric' ) )
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( 0, 0, nW, nH )
	end
	plb.DoClick = function( )
		openPlayList( )
	end

	local vb = p:Add( 'DButton' )
	vb:SetSize( 32, 32 )
	vb:SetPos( 5 + 32 + 5 + 32 + 5 + 32 + 5 + 32 + 5 + 32 + 5, 5 )
	vb:SetText( '' )
	vb.Paint = function( self, nW, nH )
		surface.SetMaterial( Material( 'icon16/control_equalizer_blue.png', 'vertexlitgeneric' ) )
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( 0, 0, nW, nH )
	end
	vb.DoClick = function( )
		Derma_StringRequest( 'Set MPLAY Volume',
			'0 ~ 1',
			GetConVarNumber( 'mplay_volume', 0 ),
			function( text )
				local n = tonumber( text )
				if type( n ) == 'number' then
					if n < 0 then
						n = 0
					end

					if n > 1 then
						n = 1
					end

					RunConsoleCommand( 'mplay_volume', n )
				end
			end,
			function( text ) end,
			'Set',
			'Cancel'
		)
	end
end

function openPlayList( )
	local PlayList = vgui.Create( 'DFrame' )
	PlayList:SetTitle( 'PlayList' )
	PlayList:MakePopup( )
	PlayList:SetSize( 225, 350 )
	PlayList:SetPos( ScrW( ) - 230, ScrH( ) / 2 - 350 / 2)
	gui.SetMousePos( ScrW( ) - 230 + 1, ScrH( ) / 2 - 350 / 2 + 1 )
	PlayList:SetIcon( 'icon16/music.png' )
	PlayList.Think = function( self )
		local px, py = PlayList:GetPos( )

		if input.IsMouseDown( MOUSE_LEFT ) or input.IsMouseDown( MOUSE_RIGHT ) or input.IsMouseDown( MOUSE_MIDDLE ) or input.IsMouseDown( MOUSE_4 ) or input.IsMouseDown( MOUSE_5 ) then
			local mx, my = gui.MousePos( )
			if mx > px + PlayList:GetWide( ) or mx < px then
				PlayList:Remove( )
			end

			if my > py + PlayList:GetTall( ) or my < py then
				PlayList:Remove( )
			end
		end
	end
	PlayList.Paint = function( self, nW, nH )
		draw.RoundedBox( 0, 0, 0, nW, nH, Color( 0, 0, 0, 200 ) )
	end
	PlayList.Selected = { }

	local pl = PlayList:Add( 'DPanelList' )
	pl:SetSize( PlayList:GetWide( ) - 10, PlayList:GetTall( ) - 65 )
	pl:SetPos( 5, 30 )
	pl.Paint = function( self, nW, nH )
		draw.RoundedBox( 0, 0, 0, nW, nH, Color( 255, 255, 255, 5 ) )
	end
	pl.Refresh = function( self )
		self:Clear( )

		for k, v in pairs( MPLAY.PlayList ) do
			local p = vgui.Create( 'DPanel' )
			p:SetSize( self:GetWide( ), 30 )
			p.Paint = function( self, nW, nH )
				if MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) and MPLAY.PlayList[ MPLAY.NowPlay ] == v then
					draw.RoundedBox( 0, 0, 0, nW, nH, Color( 75, 150, 75, 50 ) )
				else
					draw.RoundedBox( 0, 0, 0, nW, nH, Color( 255, 255, 255, 5 ) )
				end

				draw.SimpleText( v, 'DermaDefault', 10, nH/2, color_white, 0, 1 )
			end
			p.OnMousePressed = function( )
				if MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) and MPLAY.PlayList[ MPLAY.NowPlay ] == v then
					RunConsoleCommand( 'stop_mplay' )
				else
					MPLAY.NowPlay = k
					MPLAY.PlayURL = MPLAY.PlayList[ MPLAY.NowPlay ]
					SelectMusic( )
				end
			end
			p:SetCursor( 'hand' )

			local b = p:Add( 'DButton' )
			b:SetSize( p:GetTall( ), p:GetTall( ) )
			b:SetPos( p:GetWide( ) - p:GetTall( ), 0 )
			b:SetText( '' )
			b.Paint = function( self, nW, nH )
				if PlayList.Selected[ k ] then
					draw.RoundedBox( 0, 0, 0, nW, nH, Color( 75, 150, 75, 255 ) )
				else
					draw.RoundedBox( 0, 0, 0, nW, nH, Color( 100, 100, 100, 255 ) )
				end
			end
			b.DoClick = function( self )
				if PlayList.Selected[ k ] then
					PlayList.Selected[ k ] = nil
				else
					PlayList.Selected[ k ] = v
				end
			end

			self:AddItem( p )
		end
	end

	local del = PlayList:Add( 'DButton' )
	del:SetSize( 50, 25 )
	del:SetPos( PlayList:GetWide( ) - del:GetWide( ) - 5, PlayList:GetTall( ) - 30 )
	del:SetText( 'Del' )
	del.DoClick = function( self )
		if PlayList.Selected[ MPLAY.NowPlay ] then
			RunConsoleCommand( 'stop_mplay' )
		end

		for k, v in pairs( PlayList.Selected ) do
			MPLAY.PlayList[ k ] = nil
		end
		MPLAY.PlayList = table.ClearKeys( MPLAY.PlayList )
		SaveMPLAY( )

		pl:Refresh( )
	end

	local add = PlayList:Add( 'DButton' )
	add:SetSize( 50, 25 )
	add:SetPos( PlayList:GetWide( ) - add:GetWide( ) - 5 - del:GetWide( ) - 5, PlayList:GetTall( ) - 30 )
	add:SetText( 'Add' )
	add.DoClick = function( )
		Derma_StringRequest( 'Add MPLAY Music',
			'Enter music download link or YouTube link',
			'http://',
			function( text )
				table.insert( MPLAY.PlayList, text )
				MPLAY.PlayList = table.ClearKeys( MPLAY.PlayList )
				SaveMPLAY( )

				if pl ~= nil and pl:IsValid( ) then
					pl:Refresh( )
				end
			end,
			function( text ) end,
			'Add Music',
			'Cancel'
		)
	end

	pl:Refresh( )
end

hook.Add( 'Think', 'MPLAY', function( )
	if MPLAY then
		if MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) then
			if MPLAY.Music:GetState( ) == GMOD_CHANNEL_PAUSED then
				RunConsoleCommand( 'stop_mplay' )
			end

			if MPLAY.Music:GetState( ) == GMOD_CHANNEL_STALLED then
				RunConsoleCommand( 'next_mplay' )
			end

			if MPLAY.Music:GetState( ) == GMOD_CHANNEL_STOPPED then
				RunConsoleCommand( 'stop_mplay' )
			end

			if MPLAY.Music:GetVolume( ) ~= GetConVarNumber( 'mplay_volume', 0 ) then
				MPLAY.Music:SetVolume( GetConVarNumber( 'mplay_volume', 0 ) )
			end
		end
	end
end )

function PlayMusic( )
	timer.Simple( .1, function( )
		RunConsoleCommand( 'stop_mplay' )

		sound.PlayURL( MPLAY.PlayURL or '', '', function( ch )
			if IsValid( ch ) then
				ch:Play( )
				ch:SetVolume( GetConVarNumber( 'mplay_volume', 0 ) )

				MPLAY.Music = ch

				timer.Create( 'MPLAY', ch:GetLength( ) - .5, 1, function( )
					RunConsoleCommand( 'stop_mplay' )

					if GetConVarNumber( 'mplay_repeat', 0 ) == 0 then
						NextMusic( )
					else
						RunConsoleCommand( 'play_mplay' )
					end
				end )
			else
				LocalPlayer( ):ChatPrint( 'URL Error!' )
			end
		end )
	end )
end

function SelectMusic( )
	RunConsoleCommand( 'stop_mplay' )

	MPLAY.NowPlay = MPLAY.NowPlay or 1

	if table.Count( MPLAY.PlayList ) > 0 then
		if string.find( MPLAY.PlayList[ MPLAY.NowPlay ], 'youtube' ) and string.find( MPLAY.PlayList[ MPLAY.NowPlay ], 'http' ) then
			http.Fetch( 'http://www.youtubeinmp3.com/fetch/?format=JSON&video=' .. MPLAY.PlayList[ MPLAY.NowPlay ], function( body )
				local tab = util.JSONToTable( body )
				MPLAY.PlayURL = tab.link or ''
				PlayMusic( )
			end, function( )
				MPLAY.PlayURL = ''
			end )
		else
			MPLAY.PlayURL = MPLAY.PlayList[ MPLAY.NowPlay ] or ''
			PlayMusic( )
		end
	else
		LocalPlayer( ):ChatPrint( "ERROR! PlayList Table Empty." );
	end
end

function NextMusic( )
	MPLAY.NowPlay = MPLAY.NowPlay or 0
	MPLAY.NowPlay = MPLAY.NowPlay + 1

	if MPLAY.NowPlay > table.Count( MPLAY.PlayList ) then
		MPLAY.NowPlay = 1
	end

	SelectMusic( )
end

function PrevMusic( )
	MPLAY.NowPlay = MPLAY.NowPlay or 0
	MPLAY.NowPlay = MPLAY.NowPlay - 1

	if MPLAY.NowPlay < 1 then
		MPLAY.NowPlay = table.Count( MPLAY.PlayList )
	end

	SelectMusic( )
end

concommand.Add( "open_mplay", function( )
	openMPLAY( )
end );

concommand.Add( 'reset_mplay', function( )
	ResetMPLAY( )
end );

concommand.Add( 'stop_mplay', function( )
	if ( MPLAY.Music ~= nil and MPLAY.Music:IsValid( ) ) then
		MPLAY.Music:Stop( );
		timer.Remove( 'MPLAY' )
	end
end );

concommand.Add( 'play_mplay', function( ply, cmd, args )
	RunConsoleCommand( 'stop_mplay' )
	SelectMusic( )
end )

concommand.Add( 'next_mplay', function( )
	RunConsoleCommand( 'stop_mplay' )
	NextMusic( )
end )

concommand.Add( 'prev_mplay', function( )
	RunConsoleCommand( 'stop_mplay' )
	PrevMusic( )
end )