property ScriptName : "iTunes Find Artwork-less"
property scriptVersion : "1.0"
property scriptDescription : "Find the songs with no Album Artwork set"

(*

Aug 2006, by Aurelio Marinho Jargas (verde@aurelio.net)

Instructions:
	Select some tracks in iTunes and run this script.
	It will find the tracks that don't have Album Artwork. 
	The found tracks are saved to the "* Missing Artwork" playlist.

Install:	
	Save this file on your "Library/Scripts/Applications/iTunes/" folder.

License:
	Open Source, "as is".

More scripts:
	http://aurelio.net/en	

	
	****************************************
	*
	*	This script is useful for you?
	*	It saves your precious time?
	*
	*	Consider making a small donation to me.
	*	PayPal: verde@aurelio.net
	*
	*	http://aurelio.net/en/donate.html
	*
	****************************************
	
*)


-- USER CONFIG
--
-- You may change the results playlist name
set resultsPlaylistName to "* Missing Artwork"
--
-- END


on show_error(theMessage)
	try -- Tiger
		display alert ScriptName message theMessage as warning buttons {"OK"} default button 1
	on error -- Panther
		set theHeading to "* " & ScriptName & " *" & return & return
		display dialog theHeading & theMessage with icon 2 buttons {"OK"} default button 1
	end try
end show_error


tell application "iTunes"
	
	-- Get the selected songs in iTunes
	set selectedTracks to the selection of front window
	
	-- If no song selected, get all the songs of the selected playlist
	if selectedTracks is {} then
		try
			set selectedPlaylist to view of front window
			set selectedTracks to file tracks of selectedPlaylist
		end try
	end if
	
	-- Continue only if we've got some tracks
	if selectedTracks is {} then
		my show_error("Please first select the desired tracks")
		
		-- Shoot on the foot!
	else if name of view of front window is resultsPlaylistName then
		my show_error("Please choose another playlist, you can't search on" & return & resultsPlaylistName)
		
	else
		
		-- Create the results playlist or clear it
		try
			delete tracks of playlist resultsPlaylistName
		on error
			make new playlist with properties {name:resultsPlaylistName}
		end try
		
		-- Save results to playlist
		repeat with thisTrack in selectedTracks
			if (count artworks of thisTrack) is 0 then
				duplicate thisTrack to playlist resultsPlaylistName
			end if
		end repeat
		
		-- Select the results playlist
		set view of front window to playlist resultsPlaylistName
	end if
	
end tell