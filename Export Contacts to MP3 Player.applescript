(*
Export Contacts to MP3 Player
	by Aurelio Marinho Jargas, October 2005
	http://aurelio.net/bin/as
	License: MIT

Some cheap Asian MP3 players have a simple Telephone & E-mail browser,
whose contacts are managed by an external Windows program. With this
script you can copy your Apple's Address Book contacts directly to the player.

There are 6 fields on the player's browser. This is the list of Address Book
information used to fill them: 

	MP3 Player		Address Book
	---------------------------------------
	Name			Full Name
	Mobile			Mobile Phone
	Phone			Home Phone
	Email			Home Email
	QQ				Birthday
	Fax				Work Phone

Just run this script and copy the generated file to the player. It is a binary
file, so don't try to edit it. Then use the player's import feature to populate
the browser.
*)

set ScriptName to "Contacts on MP3 Player"
set ScriptName to "Export Contacts to MP3 Player"
set scriptVersion to "1.0"

set ContactCount to 0
set AllContacts to {}
set AllGroupsLabel to "- ALL -"

-- ###################################### Handy tools

-- Example: { "one","two","three" }  ->  [ 'one', 'two', 'three' ]
on AppleScriptListToPythonList(theList)
	set AppleScript's text item delimiters to "','"
	set theResult to "['" & (theList as text) & "']" & return
	set AppleScript's text item delimiters to ""
	return theResult
end AppleScriptListToPythonList

-- Convert from date property to a short readable format
on FormatDate(theDate)
	if theDate is missing value then return ""
	set d to day of theDate as text
	set m to (items 1 thru 3 of (month of theDate as text) as text)
	set y to year of theDate as text
	return d & " " & m & " " & y
end FormatDate

-- Normalize the value of a Contact's field
on FixIt(theValue)
	-- XXX: dirty hack, don't know how to check if a variable is not defined
	try
		set FOO to theValue
	on error
		set theValue to ""
	end try
	if theValue is missing value then set theValue to "" -- force empty
	if class of theValue is not text then set theValue to theValue as text -- force text
	return theValue
end FixIt

-- Replace all occurences of one string for another in a text
on replaceString(theText, oldString, newString)
	set AppleScript's text item delimiters to oldString
	set tempList to every text item of theText
	set AppleScript's text item delimiters to newString
	set theText to the tempList as string
	set AppleScript's text item delimiters to ""
	return theText
end replaceString

-- Remove all (Brazilian) accented characters
(*
	Note 1: The player understands iso-8859-1 accented chars, but Address Book
	returns the name as Unicode. I've tried "name as text", "name as string",
	"do shell script" with "tr", Python's string.replace() and some other tricks,
	but this function seemed to be the best.

	Note 2: You can add more chars to the translation table if necessary. They are
	simple search&replace pairs. The search field can have multiple chars.
*)
on unAccent(theText)
	set theTable to {{"ˆ‡‹‰", "a"}, {"Ž", "e"}, {"’", "i"}, {"—›™", "o"}, {"œŸ", "u"}, {"", "c"}, {"ËçÌå", "A"}, {"ƒæ", "E"}, {"ê", "I"}, {"îÍï", "O"}, {"ò†", "U"}, {"‚", "C"}}
	repeat with thisItem in theTable
		set {cFrom, cTo} to thisItem
		repeat with thisChar in cFrom
			set theText to my replaceString(theText, thisChar, cTo)
		end repeat
	end repeat
	return theText
end unAccent

-- Sorts a list (copied verbatim from Apple docs)
on ASCII_Sort(my_list)
	set the index_list to {}
	set the sorted_list to {}
	repeat (the number of items in my_list) times
		set the low_item to ""
		repeat with i from 1 to (number of items in my_list)
			if i is not in the index_list then
				set this_item to item i of my_list as text
				if the low_item is "" then
					set the low_item to this_item
					set the low_item_index to i
				else if this_item comes before the low_item then
					set the low_item to this_item
					set the low_item_index to i
				end if
			end if
		end repeat
		set the end of sorted_list to the low_item
		set the end of the index_list to the low_item_index
	end repeat
	return the sorted_list
end ASCII_Sort

-- ###################################### Processing begins here

display dialog (ScriptName & ", version " & (scriptVersion as text) & return & return & "First, check on your MP3 player which is your version (System > Firmware version):" & return & return & "OLD:  2005/03/23  V1.2_T100A1F" & return & "NEW:  2005/07/22  3.0.43.0001" & return & return & "The dates and numbers may vary. If you're not sure, try both.") buttons {"Cancel", "Old version", "New version"} default button 3 with icon 1
set FirmwareVersion to button returned of the result

-- The resulting file will be saved on the desktop
if FirmwareVersion is "Old version" then
	set FileName to "TEL_SAVE.BIN"
	set MaxContacts to 199
else
	set FileName to "TelBook.bin"
	set MaxContacts to 99
end if
set DiskFile to ((POSIX path of (path to desktop folder)) & FileName)

tell application "Address Book"
	-- The user will choose a specific group (or all)
	set allGroups to {AllGroupsLabel} & my ASCII_Sort(name of every group)
	set UserGroup to choose from list allGroups with prompt ScriptName & " - Choose one group:" OK button name "Generate File"
	if UserGroup is false then return -- User pressed Cancel button
	
	if (UserGroup as text) is AllGroupsLabel then
		set theContacts to a reference to every person
	else
		set theContacts to a reference to every person of group named UserGroup
	end if
	
	-- Here we go, extracting info of every contact and saving it in the right order
	repeat with thisContact in theContacts
		if ContactCount is MaxContacts then exit repeat
		set ContactCount to ContactCount + 1
		
		set ContactInfo to {}
		tell thisContact
			-- First prepare some data
			set theEmail to my FixIt(value of first email whose label is "home") -- home preferred
			if theEmail is "" then set theEmail to my FixIt(value of first email whose label is not "")
			-- Store the information
			set the end of ContactInfo to my FixIt(my unAccent(name))
			set the end of ContactInfo to my FixIt(value of first phone where label is "mobile")
			set the end of ContactInfo to my FixIt(value of first phone where label is "home")
			set the end of ContactInfo to theEmail
			set the end of ContactInfo to my FixIt(my FormatDate(birth date))
			set the end of ContactInfo to my FixIt(value of first phone where label is "work")
		end tell
		
		copy my AppleScriptListToPythonList(ContactInfo) to the end of AllContacts
	end repeat
end tell

-- Sort and join the Python lists into to a mother list
set AllContacts to ASCII_Sort(AllContacts)
set AppleScript's text item delimiters to ","
set contactsList to "[" & (AllContacts as text) & "]"
set AppleScript's text item delimiters to ""

-- The dirty binary tricks are made by a Python script
set thePythonScript to "

import re, binascii

field_names = ('name', 'mobile', 'phone', 'email', 'QQ', 'fax')
field_sizes = (  16  ,    16   ,    32  ,    32  ,  16 ,   16 )
firmware_version = '" & FirmwareVersion & "'
contacts = " & (contactsList as text) & "
data = []

def ascii2hex(text):
	return ' '.join([hex(ord(c))[2:] for c in text])
def int2hex(number):
	n = '0' + hex(number)[2:]
	return n[-2:]

### Compose headers

if firmware_version.lower()[:3] == 'new':
	data.append(ascii2hex('Radio technology'))
	data.append(' 03 00 00 00')
	data.append(' %s 00 00 00' % int2hex(len(contacts)))
	data.append(' 02 00 00 00')
	data.append(' af 39 40 00')  # 257 9 @ null

### Add every contact

for i in range(len(contacts)):
	for j in range(len(field_names)):
		max, val = field_sizes[j], contacts[i][j].strip()
		# XXX: Real strange gotcha: the e-mail of the 1st contact must be <= 27
		if i == 0 and j == 3: val = val[:27]
		val = val[:(max-1)]           # more: slice the excess if necessary
		pad = max - 1 - len(val)      # less: zero pad if necessary
		data.append(int2hex(len(val)) + ascii2hex(val) + '00'*pad)
		# Note: The 1st position of each field is the lenght of its contents

### Convert data to binary form

data = ''.join(data).replace(' ', '') # list2str, remove blanks
data = binascii.unhexlify(data)       # hex2bin

### Save results to disk

f = open('" & DiskFile & "', 'w')
f.write(data)
f.close()
"

-- Execute the Python script and show OK dialog
do shell script "echo \"" & thePythonScript & "\" | python -"

display dialog (ScriptName & return & return & (ContactCount as text) & " contacts were saved to the \"" & FileName & "\" file on your Desktop." & return & return & "Now just copy this file to the player and import it.") buttons {"OK"} default button 1 with icon 1


-- trash can: data = data + '0'*(25664 - len(data)) # file size must be 12K (wrong!)