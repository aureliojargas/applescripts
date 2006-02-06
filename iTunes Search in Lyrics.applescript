(*
	Feb 2006, by Aurelio Marinho Jargas (http://aurelio.net/bin/as/)
	
	This script performs a text search in the lyrics of the tracks on the selected playlist.
	The found tracks are saved to the "Lyrics Search Results" playlist.
	
	License: Open Source, "as is".
	Install: Save this script under the "Library/iTunes/Scripts" folder.

	This script is useful for you? Consider making a PayPal donation to verde@aurelio.net.
*)

set ScriptName to "iTunes Search in Lyrics"
set scriptVersion to "1.0"
set resultsPlaylistName to "Lyrics Search Results"

tell application "iTunes"
	
	set selectedPlaylist to view of front window
	
	-- Prompt user for the search text
	display dialog ScriptName & return & return & "Scan lyrics of \"" & name of selectedPlaylist & "\" for: " default answer "" with icon 1
	set userText to text returned of result as string
	
	-- Create the results playlist or clear it
	try
		delete tracks of playlist resultsPlaylistName
	on error
		make new playlist with properties {name:resultsPlaylistName}
	end try
	
	-- Search in lyrics and save results to playlist
	-- Note: The uncommon "set {,} to {,} of ..." statement is a speed accelerator
	set {theLocations, theLyrics} to {location, lyrics} of file tracks of selectedPlaylist
	repeat with i from 1 to (count of theLocations)
		if userText is in item i of theLyrics then
			add {item i of theLocations} to playlist resultsPlaylistName
		end if
	end repeat
	-- This method is a little faster, but the results are incomplete, it misses some positives :/
	--duplicate (tracks of selectedPlaylist whose lyrics contains userText) to playlist resultsPlaylistName
	
	-- Select the results playlist
	set view of front window to playlist resultsPlaylistName
	
end tell