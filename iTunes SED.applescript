(*
	May 2005, by Aurelio Marinho Jargas (http://aurelio.net/bin/as/)
	
	iTunes SED, the UNIX geeks must-have script. It brings the power of SED's
	substitute command s/// to iTunes, so you can make smart batch changes
	on the tracks ID3 info (Name, Artist, Album, ...). We've got regular
	expressions, back references, modifiers, multiple commands. It's SED babe!
	
	Tips:
		To remove the leading track number on song names, like "13 - Cool Song" use
		s/^[0-9][0-9]* - //
	
		To remove band name and track number, like "The Band - 13 - Cool Song" use
		s/.* - //
		
		To remove symbols and strange chars use
		s/[^A-Za-z0-9., -]//g
		
		To add a prefix use
		s/^/The Nice Prefix /
		
	License: Open Source, "as is".
	Install: Save this script under the "Library/iTunes/Scripts" folder.
	
	This script is useful for you? Consider making a PayPal donation to verde@aurelio.net.	
*)

set scriptVersion to "1.0"
set ScriptName to "iTunes SED"
set allColumns to {"Song Name", "Artist", "Album", "Comments"}

on substitute(sedCommand, theText)
	return do shell script "echo " & quoted form of theText & " | sed -e " & quoted form of sedCommand
end substitute


tell application "iTunes"
	try
		-- Get the selected songs in iTunes
		set userTracks to the selection of front window
		
		-- Continue only if we've got some tracks
		if userTracks is {} then
			display dialog ScriptName & return & return & "Please first select the desired tracks" with icon 2 buttons {"OK"} default button 1
		else
			set totalTracks to count of userTracks
			
			-- Hey user! Choose a column
			set userColumn to choose from list allColumns with prompt "SED will be used on:"
			if userColumn is false then return -- User pressed Cancel
			set userColumn to userColumn as text
			
			-- Hey user! Type the new value for the column
			display dialog ScriptName & return & return & "Type the full SED command to be applied to \"" & userColumn & "\"" default answer "s/this/that/" buttons {"Cancel", "Run SED"} default button 2 with icon 1
			set userText to the text returned of result as text
			
			-- Apply the new text on the selected songs
			repeat with i from 1 to totalTracks
				set theTrack to item i of userTracks
				
				-- The order of the tests is optimized to "guessed" commom use
				if userColumn is "Artist" then
					set the artist of theTrack to my substitute(userText, artist of theTrack)
				else if userColumn is "Album" then
					set the album of theTrack to my substitute(userText, album of theTrack)
				else if userColumn is "Song Name" then
					set the name of theTrack to my substitute(userText, name of theTrack)
				else if userColumn is "Comments" then
					set the comment of theTrack to my substitute(userText, comment of theTrack)
				end if
			end repeat
		end if
	end try
end tell