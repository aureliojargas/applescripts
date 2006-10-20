(*
	Oct 2006, by Aurelio Marinho Jargas (http://aurelio.net/bin/as/)
	
	iPhoto SED brings the power of SED's substitute command s/// to iPhoto,
	so you can make smart batch changes on the pictures Title and Comments.
	Abuse from regular expressions, back references, modifiers, multiple
	commands. It's SED babe!
	
	Initial release.
	
Tips:
	To remove symbols and strange chars use
	s/[^A-Za-z0-9., -]//g
	
	To add a prefix use
	s/^/The Nice Prefix /

	To add a suffix use
	s/$/The Nice Suffix /
			
Install:	
	Save this file on your "Library/Scripts/Applications/iPhoto/" folder.

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

set ScriptName to "iPhoto SED"

on substitute(sedCommand, theText)
	return do shell script "echo " & quoted form of theText & " | sed -e " & quoted form of sedCommand
end substitute

tell application "iPhoto"
	
	-- Get selected pictures
	set thePics to selection
	try
		id of item 1 of thePics -- only pictures have ID
	on error
		display dialog ScriptName & return & return & "First you must select the pictures" buttons {"Ouch!"} with icon 2
		return
	end try
	
	-- Hey user! Wake up!
	set userChoices to display dialog ScriptName & " - " & (count selection) & " pictures selected" & return & return & "Type the full SED command:" default answer "s/this/that/" buttons {"Quit", "Edit Comments", "Edit Title"} default button 3 with icon 1
	set userText to the text returned of the userChoices as string
	set userAction to the button returned of the userChoices as string
	
	--- Do it!
	if userAction is "Edit Title" then
		repeat with thisPic in thePics
			set the title of thisPic to my substitute(userText, title of thisPic)
		end repeat
	else if userAction is "Edit Comments" then
		repeat with thisPic in thePics
			set the comment of thisPic to my substitute(userText, comment of thisPic)
		end repeat
	end if
end tell