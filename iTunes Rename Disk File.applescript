(*
	iTunes Rename Disk File (http://aurelio.net/bin/as/)
	by Aurelio Marinho Jargas
	10 May, 2005 - version 1.0
	
	This script will rename the disk files of the selected songs on iTunes,
	based on the song info such as Artist or Album name. The user can
	choose a default filename format or make its own. All the renames
	attempted are logged for user inspection. It also can remove blank
	spaces and symbols from the filename.

	Details: 
	- The file extension is kept unchanged.
	- The file is not moved to another folder, just renamed.
	- The default strings for empty values are configurable.
	- Removes special characters ":" and "/".
	- Other forbidden characters are configurable.
	- User chooses filenames with blank spaces or not.
	- Detects duplicate filenames.
	- Also runs in "dry run" mode, safe for tests.
	- A complete log is generated at the end.
	- The user-defined format can include:
		Song name, Track number, Artist name, Album name and Year

	License: Open Source, Public Domain, "as is", etc.
	Install: Save this script under the "Library/iTunes/Scripts" folder.
	
	Inspired by Lee S. Edwards rename script.
	Similar script: http://applescript.plaidcow.net/iTunes/RenameFiles/

	This script is useful for you? Consider making a PayPal donation to verde@aurelio.net.
	
*)

-------------------------------------------------- USER CONFIG HERE

-- Setting this to "true" the script executes but the files are not renamed.
-- It's good for developer tests.
set DryRun to false

-- Setting RemoveSymbols to "true" will remove from the file name all the characters listed in ForbiddenChars.
-- Setting RemoveSymbols to "false" preserves all characters.
-- You can remove from ForbiddenChars a few characters you may want to preserve.
-- Note: No matter which are the settings, the special chars ":" and "/" are *always* removed.
set RemoveSymbols to true
set ForbiddenChars to "~'`\"@#$%^&*+=(){}[]<>.;,\\|?!"

-- Default texts for empty fields
-- These strings are used when the related field of the track is empty
set MissingFieldValues to {SongName:"Unnamed Song", ArtistName:"Unknown Artist", AlbumName:"Unknown Album", TrackNumber:"00", SongYear:"1900"}

-------------------------------------------------- END OF USER CONFIG


set ScriptName to "iTunes Rename Disk File"
set scriptVersion to "1.0"

set LogLines to {}
set UseBlanks to true
set DialogTitle to ScriptName & " v" & scriptVersion
set CustomFormatName to "<custom format>"

-- (S)ong name, (9) Track number, (A)rtist name, Al(B)um name, (Y)ear
set DefaultFileMasks to {"S", "9 - S", "A - S", "B - 9 - S", "A - B - 9 - S", "A - Y - B - 9 - S", "B - 9 - A - S"}

-- Default names for the song fields (used in dialogs only)
set DefaultFieldNames to {TrackNumber:"01", SongName:"Song Name", ArtistName:"Artist Name", AlbumName:"Album Name", SongYear:"Year"}


tell application "iTunes"
	-- Get the selected tracks as a list of references
	set theTracks to the selection of front window
	if theTracks is {} then error "No tracks are selected in the iTunes front window."
	
	-- Ask user for the desired file name format
	set DefaultFileMasksExpanded to my expandTheseMasks(DefaultFileMasks)
	set the end of DefaultFileMasksExpanded to CustomFormatName
	set ChosenFormat to choose from list DefaultFileMasksExpanded with prompt Â
		DialogTitle & " - " & (count of theTracks) & " tracks selected" OK button name "Rename"
	if ChosenFormat is false then return -- User pressed Cancel
	set ChosenFormat to first item of ChosenFormat
	
	-- User defined format
	if ChosenFormat is CustomFormatName then
		set FileMask to ""
		repeat until FileMask is not ""
			display dialog (DialogTitle & " - Custom Format" & return & return & Â
				"    S   " & tab & "Song name" & return & Â
				"    9   " & tab & "Track number" & return & Â
				"    A   " & tab & "Artist name" & return & Â
				"    B   " & tab & "Album name" & return & Â
				"    Y   " & tab & "Year" & return & return) Â
				default answer "A - B - 9 - S"
			set FileMask to text returned of result as string
		end repeat
		set FileMaskExpanded to my expandFileMask(FileMask, {})
	else
		-- Save the chosen format
		set FileMaskExpanded to ChosenFormat
		set FilemaskIndex to my getListItemIndex(DefaultFileMasksExpanded, FileMaskExpanded)
		set FileMask to item FilemaskIndex of DefaultFileMasks
	end if
	
	-- Ask user for blank spaces or not
	display dialog DialogTitle & return & return & Â
		"Some users do prefer file names with blank spaces others don't. " & Â
		"How about you?" & return & return & Â
		"No spaces: " & return & "    " & my removeBlanks(FileMaskExpanded) & return & return & Â
		"Use spaces: " & return & "    " & FileMaskExpanded & return & return Â
		buttons {"Cancel", "No blank spaces", "Use blank spaces"} default button 3 with icon 2
	if button returned of result is "No blank spaces" then Â
		set UseBlanks to false
	
	-- Begin log report
	set the end of LogLines to DialogTitle & return & "Log started at " & (current date) & return
	if UseBlanks is false then set FileMaskExpanded to my removeBlanks(FileMaskExpanded)
	set the end of LogLines to "File Format: " & FileMaskExpanded & return & return
	
	-- Set the new name for each track
	repeat with thisTrack in theTracks
		
		set FilePath to the location of thisTrack
		if FilePath is missing value then
			display dialog ("Rename for: " & (name of thisTrack as string) & return & Â
				"Skipped because disk file does not exist") Â
				buttons {"Cancel All Renames", "OK"} default button 2
			if button returned of result is "Cancel All Renames" then return
			set the end of LogLines to (name of thisTrack as string) & "   --->   FILE NOT FOUND" & return
			
		else
			-- First populate the record with the default missing values
			-- Then extract each field value of the track (if necessary) and save on the record
			copy my MissingFieldValues to TrackInfo
			
			considering case
				
				-- song name
				if "S" is in FileMask then
					set theValue to name of thisTrack as string
					if theValue is not "" then set SongName of TrackInfo to theValue
				end if
				
				-- track number
				if "9" is in FileMask then
					set theValue to track number of thisTrack as string
					if theValue is not missing value then
						if (count of theValue) is 1 then set theValue to "0" & theValue -- zero pad
						set TrackNumber of TrackInfo to theValue
					end if
				end if
				
				-- album name
				if "B" is in FileMask then
					set theValue to album of thisTrack as string
					if theValue is not "" then set AlbumName of TrackInfo to theValue
				end if
				
				-- artist name
				if "A" is in FileMask then
					set theValue to artist of thisTrack as string
					if theValue is not "" then set ArtistName of TrackInfo to theValue
				end if
				
				-- song year
				if "Y" is in FileMask then
					set theValue to year of thisTrack as string
					if theValue is not "0" then set SongYear of TrackInfo to theValue
				end if
			end considering
			
			-- Expand the mask tokens with track info
			set NewName to my expandFileMask(FileMask, TrackInfo)
			set NewName to my fixFileName(NewName)
			if UseBlanks is false then Â
				set NewName to my removeBlanks(NewName)
			
			-- Finder will change the file name
			tell application "Finder"
				set OriginalName to name of FilePath as string
				set FileExtension to name extension of FilePath as string
				
				-- Keep the original file extension (if any)
				if FileExtension is not "" then set NewName to NewName & "." & FileExtension
				
				set FilePath to FilePath as alias
				try
					-- Always change the file name (don't use IF because A=a)
					if DryRun is false then set name of FilePath to NewName
					-- Save log
					set the end of LogLines to OriginalName & "   --->   " & NewName & return
					
				on error error_message number error_number
					-- Oops, an error occurred
					tell application "iTunes"
						if the error_number is -48 then
							beep
							display dialog ("Disk File:  " & (name of FilePath as string) & return & Â
								"Rename to: " & NewName & return & Â
								"Failed  because a duplicate name would result") Â
								buttons {"OK"} default button 1
						else
							display dialog error_message buttons {"Cancel"} default button 1
						end if
					end tell
				end try
			end tell
		end if
	end repeat
	
	set the end of LogLines to return & "Log ended at " & (current date) & return
	
	-- Dry Run note
	set ExtraMessage to ""
	if DryRun is true then
		set ExtraMessage to return & return & Â
			"*ATTENTION* No rename was really made, we're on Dry Run mode."
	end if
	
	-- Final dialog	
	display dialog (DialogTitle & " - Done!" & return & return & Â
		((count of theTracks) as string) & " file renames were attempted.") & Â
		ExtraMessage & return & return Â
		buttons {"View Log", "OK"} default button 1 with icon 1
	
	-- Open log text in TextEdit (with large width)
	if button returned of result is "View Log" then
		tell application "TextEdit"
			launch
			activate
			make new document at beginning with properties {text:LogLines as string}
			set bounds of front window to {100, 100, 800, 400}
		end tell
	end if
	
end tell


-- Expand all the File Mask special tokens to its names
on expandFileMask(theMask, theData)
	set theText to ""
	if theData is {} then set theData to my DefaultFieldNames
	repeat with char in items of theMask
		set char to char as text
		considering case
			if char is "9" then
				set theText to theText & TrackNumber of theData
			else if char is "S" then
				set theText to theText & SongName of theData
			else if char is "A" then
				set theText to theText & ArtistName of theData
			else if char is "B" then
				set theText to theText & AlbumName of theData
			else if char is "Y" then
				set theText to theText & SongYear of theData
			else
				set theText to theText & char
			end if
		end considering
	end repeat
	return theText
end expandFileMask

-- Expand all the File Masks in a list
on expandTheseMasks(theMaskList)
	set AllNames to {}
	repeat with theMask in theMaskList
		set thisName to my expandFileMask(theMask, {})
		set the end of AllNames to thisName
	end repeat
	return AllNames
end expandTheseMasks

on removeBlanks(theText)
	-- Squeeze consecutive blanks to one
	repeat while "  " is in theText
		set theText to my replaceString(theText, "  ", " ")
	end repeat
	-- Blanks around separator are removed
	set theText to my replaceString(theText, " -", "-")
	set theText to my replaceString(theText, "- ", "-")
	-- Other blanks are converted to underlines
	set theText to my replaceString(theText, " ", "_")
	return theText
end removeBlanks

-- Filters to remove unwanted characters from the new file name
on fixFileName(theName)
	-- Remove the special chars
	-- Note: "/" is forbidden in shell and ":" is forbidden in Finder.
	if "/" is in theName then set theName to my replaceString(theName, "/", "")
	if ":" is in theName then set theName to my replaceString(theName, ":", "")
	-- Remove all the symbols
	if my RemoveSymbols is true then
		repeat with char in items of my ForbiddenChars
			if char is in theName then
				set theName to my replaceString(theName, char, "")
			end if
		end repeat
	end if
	-- lstrip & rstrip the new name
	set theName to my stripString(theName, " ")
	return theName
end fixFileName

-- Change one string for another
on replaceString(theText, oldString, newString)
	set AppleScript's text item delimiters to oldString
	set tempList to every text item of theText
	set AppleScript's text item delimiters to newString
	set theText to the tempList as string
	set AppleScript's text item delimiters to ""
	return theText
end replaceString

-- Returns the integer index of a list item (zero if not found)
on getListItemIndex(theList, theItem)
	repeat with i from 1 to count of theList
		if item i of theList is theItem then return i
	end repeat
	return 0
end getListItemIndex

-- Trims the provided string from the text's beginning/ending
on stripString(theText, trimString)
	set x to count trimString
	try
		repeat while theText begins with the trimString
			set theText to characters (x + 1) thru -1 of theText as string
		end repeat
	on error
		set theText to ""
	end try
	try
		repeat while theText ends with the trimString
			set theText to characters 1 thru -(x + 1) of theText as string
		end repeat
	on error
		set theText to ""
	end try
	return theText
end stripString