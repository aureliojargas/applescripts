(*
	Abr 2006, by Aurelio Marinho Jargas (http://aurelio.net/bin/as/)
    
	This script changes the titles of the selected iPhoto pictures, 
	setting a number sequence with optional prefix & suffix text.
	So those ugly DSC02345 will turn to "Beach Party 01",
	"Beach Party 02" and so on... 
	
	Tip: Then you can export your pictures using the title as the
	filename, making pretty archives and nice CDs to your family.
	
	License: Open Source, "as is".
	Tested on Tiger / iPhoto 5 (should work in all versions)
	
	Install:
		Save this script under the "Library/Scripts/Applications/iPhoto" folder.
		Create the folder if necessary.
		Make sure "Script Menu" is activated in /Applications/AppleScript/AppleScript Utility.app
		
	This script is useful for you? Consider making a PayPal donation to verde@aurelio.net.
*)

set ScriptName to "iPhoto Set Sequential Title"
set scriptVersion to "1.0"

-- The default settings. You may change them if desired.
set thePrefix to "Photo "
set theSuffix to ""
set theStart to 1
set thePadding to 3


on composeTitle(thePadding, thePrefix, theNumber, theSuffix)
	set theNumber to "00000000000000000000" & theNumber -- :)
	set theNumber to items -thePadding thru -1 of theNumber as text
	return thePrefix & theNumber & theSuffix
end composeTitle

tell application "iPhoto"
	
	set ScriptName to "[ " & ScriptName & " ]" & return & return
	
	-- Get selected pictures
	set thePics to selection
	try
		id of item 1 of thePics -- only pictures hade IDs
	on error
		display dialog ScriptName & "First you must select the pictures" buttons {"Ouch!"} with icon 0
		return
	end try
	
	-- This first part is a loop that only ends when all the settings are fine and the user pres Set Titles button
	
	repeat
		-- Dialog with pretty settings and live sample of results
		set theSettings to tab & "Prefix" & tab & ": " & thePrefix & return & tab & "Suffix" & tab & ": " & theSuffix & return & tab & "Init on" & tab & ": " & theStart & return & tab & "Digits" & tab & ": " & thePadding
		set theSample to my composeTitle(thePadding, thePrefix, theStart, theSuffix)
		
		display dialog ScriptName & "Settings:" & return & return & theSettings & return & return & "First photo will be titled: " & return & return & tab & theSample buttons {"Quit", "Change Settings", "Set Titles"} with icon 1
		set theAction to the button returned of result
		
		if theAction is "Quit" then
			return
			
		else if theAction is "Set titles" then
			exit repeat
			
		else if theAction is "Change Settings" then
			
			-- The configuration process is a Wizard-like navigation, in 4 steps
			-- The user can leave any time by pressing the Done button
			
			repeat
				display dialog ScriptName & "Changing Settings - Step 1 of 4" & return & return & "New PREFIX:" buttons {"Done", "Next"} default answer thePrefix with icon 1
				set {thePrefix, theAction} to the {text returned, button returned} of result
				
				if theAction is "Done" then exit repeat
				
				display dialog ScriptName & "Changing Settings - Step 2 of 4" & return & return & "New SUFFIX:" buttons {"Done", "Next"} default answer theSuffix with icon 1
				set {theSuffix, theAction} to the {text returned, button returned} of result
				
				if theAction is "Done" then exit repeat
				
				display dialog ScriptName & "Changing Settings - Step 3 of 4" & return & return & "The STARTING number:" buttons {"Done", "Next"} default answer theStart with icon 1
				set {theNewStart, theAction} to the {text returned, button returned} of result
				try
					set theStart to theNewStart as number
				end try
				
				if theAction is "Done" then exit repeat
				
				display dialog ScriptName & "Changing Settings - Step 4 of 4" & return & return & "The number of DIGITS:" buttons {"Done"} default answer thePadding with icon 1
				set theNewPadding to the text returned of result
				try
					set thePadding to theNewPadding as number
				end try
				if thePadding is greater than 20 then set thePadding to 20
				
				exit repeat
			end repeat
		end if
	end repeat
	
	-- Great, now we have all the user settings. Let's do it!	
	
	set i to theStart
	repeat with thisPic in thePics
		set the title of thisPic to my composeTitle(thePadding, thePrefix, i, theSuffix)
		set i to i + 1
	end repeat
end tell