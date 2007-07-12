(*
	Made by Aurelio Jargas
	http://aurelio.net/soft
	
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
		
Install:	
	Save this file on your "Library/Scripts/Applications/iTunes/" folder.

	For detailed information on installation, read
	http://aurelio.net/soft/applescript-install.html

License:
	Open Source, "as is", no warranty.

History:
	May 2005 version 1.0
		- Debut release
	July 2007 version 1.1
		- Now the Composer tag is also available for editing (thanks Gaetano Vocca)
		- Now substitutions occur for every line of multiline texts (thanks Seth Johnson)
	
Get more scripts for free:
	http://aurelio.net/soft
	
*)

property runCount : 0
set myVersion to "1.1"
set myName to "iTunes SED"

set myUrl to "http://aurelio.net/soft/"
set donateUrl to "http://aurelio.net/soft/donate.html"

set allColumns to {"Song Name", "Artist", "Album", "Comments", "Composer"}

on substitute(sedCommand, theText)
	return do shell script "echo " & quoted form of theText & " | tr '\\r' '\\n' | sed -e " & quoted form of sedCommand
end substitute

if runCount is 0 then
	display dialog "Thank you for downloading my " & myName & " script!" & return & return & "You can visit my website and get more free AppleScripts to use with iTunes, iPhoto and Address Book!" buttons {"Later", "OK"} default button 2 with icon 1
	if button returned of result as text is "OK" then open location myUrl
end if

tell application "iTunes"
	try
		-- Get the selected songs in iTunes
		set userTracks to the selection of front window
		
		-- Continue only if we've got some tracks
		if userTracks is {} then
			display dialog myName & return & return & "Please first select the desired tracks" with icon 2 buttons {"OK"} default button 1
			return
		end if
		
		set runCount to runCount + 1
		set totalTracks to count of userTracks
		
		-- Hey user! Choose a column
		set userColumn to choose from list allColumns with prompt "SED will be used on:"
		if userColumn is false then return -- User pressed Cancel
		set userColumn to userColumn as text
		
		-- Hey user! Type the new value for the column
		display dialog myName & return & return & "Type the full SED command to be applied to \"" & userColumn & "\"" default answer "s/this/that/" buttons {"Cancel", "Run SED"} default button 2 with icon 1
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
			else if userColumn is "Composer" then
				set the composer of theTrack to my substitute(userText, composer of theTrack)
			end if
		end repeat
	end try
end tell
if runCount mod 10 is 0 then
	display dialog "Thank you for using my " & myName & " script for so long: " & runCount & " times." & return & return & "How about giving me a little hand to improve this script?" & return & return & "Donate 3 or 5 dollars to make an independent programmer very happy today!" buttons {"Later", "OK"} default button 2 with icon 1
	if button returned of result as text is "OK" then open location donateUrl
end if
