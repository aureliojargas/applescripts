(*
Export Contacts to MP3 Player
	by Aurelio Marinho Jargas, November 2005
	http://aurelio.net/bin/as
	License: BSD

This script will export your Address Book contacts to the binary format
used by cheap Asian MP3 players (known as S1 players) that comes
with a simple contacts browser. Just run this script and copy the
generated file to the player. Then use the player's import feature to
populate its browser.

	MP3 Player		Address Book
	---------------------------------------
	Name			Full Name
	Mobile			Mobile Phone
	Phone			Home Phone
	Email			Home Email
	QQ				Birthday
	Fax				Work Phone

History:
	Version 1.0, 29 Oct 2005
		Supports TELBOOK.EXE versions 1.1 and 2.0, unAccent, ASCII order, choose group
	Version 1.1, 09 Nov 2005
		Updated Python script, TELBOOK.EXE version 1.0 also supported, unAccent optional	

		
This script is useful for you? Consider making a PayPal donation to verde@aurelio.net.

		
*)

set ScriptName to "Export Contacts to MP3 Player"
set scriptVersion to "1.1"
set RemoveAccents to false -- Change to true if you don't want accented letters

set AllContacts to {}
set AllGroupsLabel to "- ALL -"
set OutputFolder to (path to desktop folder as text)


-- ###################################### Handy tools

(*
	Note 1: The MP3 player understands iso-8859-1 accented chars. Just use this if
	your player is having problems with them.
	Note 2: You can add more chars to the translation table if necessary. They are
	simple search&replace pairs. The search field can have multiple chars.
*)
-- Remove all (Brazilian) accented characters
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

-- Join list items in a single string, quoted and comma separated
-- Example: "one","two","three"
on ListToCsvLine(theList)
	set AppleScript's text item delimiters to "\",\""
	set CsvLine to ("\"" & theList as text) & "\"" & return
	set AppleScript's text item delimiters to ""
	return CsvLine
end ListToCsvLine

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
	if theValue contains "\"" then replaceString(theValue, "\"", "") -- del quotes
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

-- Write the CSV file on the disk
on WriteFile(FileData, FilePath)
	try
		set fd to open for access file (FilePath as text) with write permission
		write FileData to the fd as Unicode text
		close access the fd
		-- Remove strange chars (^@ ^M) that are inserted on the Unicode file
		set UnixTmpFile to quoted form of ("/tmp/" & my ScriptName)
		set UnixFilePath to quoted form of (POSIX path of FilePath)
		do shell script "cat " & UnixFilePath & " | tr -d '\\000' | tr '\\015' '\\n' > " & UnixTmpFile
		do shell script "mv " & UnixTmpFile & space & UnixFilePath
		return true
	on error
		try
			close access file FilePath
		end try
		return false
	end try
end WriteFile

-- ###################################### Processing begins here

-- Get TELBOOK.EXE version
display dialog (ScriptName & "

First, you must choose the right version of your player's TELBOOK.EXE program.

Version 1.0:
    Year 2003, size of 40KB
    Saves the TELBOOK.BIN file

Version 1.1:
    Year 2004, size of 40KB
    Saves the TEL_SAVE.BIN file

Version 2.0:
    Year 2004, size of 457KB
    Saves the TELBOOK.BIN file

") buttons {"v1.0", "v1.1", "v2.0"} default button 3 with icon 1
set TelbookVersion to characters -3 thru -1 of button returned of the result as text

-- The resulting file
if TelbookVersion is "1.1" then
	set FileName to "TEL_SAVE.BIN"
else
	set FileName to "TELBOOK.BIN"
end if
set DiskFile to OutputFolder & FileName

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
		set ContactInfo to {}
		tell thisContact
			-- First prepare some data
			set theEmail to my FixIt(value of first email whose label is "home") -- home preferred
			if theEmail is "" then set theEmail to my FixIt(value of first email whose label is not "")
			set theName to name
			if RemoveAccents then set theName to my unAccent(theName)
			-- Store the information (change here if you want to export different fields)
			set the end of ContactInfo to my FixIt(theName)
			set the end of ContactInfo to my FixIt(value of first phone where label is "mobile")
			set the end of ContactInfo to my FixIt(value of first phone where label is "home")
			set the end of ContactInfo to theEmail
			set the end of ContactInfo to my FixIt(my FormatDate(birth date))
			set the end of ContactInfo to my FixIt(value of first phone where label is "work")
		end tell
		copy my ListToCsvLine(ContactInfo) to the end of AllContacts
	end repeat
end tell

-- Sort the contacts by the first field (full name)
set AllContacts to ASCII_Sort(AllContacts)

-- Add the CSV headers
copy ListToCsvLine({"name", "mobile", "home", "email", "birthday", "work"}) to the beginning of AllContacts

-- Write the temporary CSV file
set CsvFile to DiskFile & ".csv"
set SaveOk to WriteFile(AllContacts as text, CsvFile)
if not SaveOk then
	display dialog (ScriptName & return & return & "ERROR when trying to save the temporary CSV file:" & return & return & CsvFile) buttons {"OK"} with icon 2
	return
end if

-- The dirty binary tricks are made by a Python script
-- Note: The stand-alone version of this script (that reads any CSV file) is at http://aurelio.net/bin/python
set thePythonScript to "

import sys, getopt, csv, binascii

### Initialization

mp3_field_names = ('name', 'mobile', 'phone', 'email', 'QQ', 'fax')
mp3_field_sizes = (  16  ,    16   ,    32  ,    32  ,  16 ,   16 )
max_fields = len(mp3_field_sizes)

mp3_software_version = None
csv_field_offset = None
contacts = []
data = []

msg_invalid_offset = 'Error on the CSV offset (review -o value)'
help_message = 'help removed'

# Spec: Six CSV fields specified by positional number, starting by 1 
# Tip : To join two or more fields in one, put them inside (parenthesis)
# Data: Full name, mobile phone, home phone, email, birthday date, work phone
default_offsets = {
  'yahoo'   : [ (1, 2, 3), 13,  9,  5, 33, 10 ],
  'outlook' : [ (2, 3, 4), 41, 38, 56, 53, 32 ],
  'kontact' : [         1, 23, 21, 29,  8, 22 ], # thanks boto!
}

### Handy tools

def ascii2hex(text):
	return ' '.join([hex(ord(c))[2:] for c in text])
def int2hex(number):
	n = '0' + hex(number)[2:]
	return n[-2:]
def die(msg):
	print msg
	sys.exit(1)

### Parse command line

try:
	opts, args = getopt.getopt(sys.argv[1:], 'hv:o:', [])
except getopt.error, errmsg:
	die('%s (try -h)' % errmsg)
if len(args) == 0: die(help_message) # no CSV file

csv_file = args[0]
for name,value in opts:
	if name == '-h':
		die(help_message)
	elif name == '-v':
		mp3_software_version = value
	elif name == '-o':
		try:
			csv_field_offset = default_offsets.get(value)
			if not csv_field_offset:  # user defined
				csv_field_offset = [int(x) for x in value.split(',')]
			foo = csv_field_offset[5] # at least 6 fields
		except:
			die(msg_invalid_offset)
if not mp3_software_version or not csv_field_offset:
	die(help_message)

### Version gotchas

# use_field_lenght: The field's 1st byte is the lenght of its contents
#
if mp3_software_version == '2.0':
	outfile = 'TELBOOK.BIN'
	max_contacts = 99
	use_field_lenght = True
elif mp3_software_version == '1.1':
	outfile = 'TEL_SAVE.BIN'
	max_contacts = 199
	use_field_lenght = False
elif mp3_software_version == '1.0':
	outfile = 'TELBOOK.BIN'
	max_contacts = 99
	use_field_lenght = False
else:
	die('Invalid TELBOOK.EXE version. Check -v contents.')

### Extract contacts from CSV

try:
	if csv_file == '-':
		fd = sys.stdin
	else:
		fd = open(csv_file)
except:
	die('Cannot open CSV file: %s' % csv_file)
rows = csv.reader(fd)
rows.next()                     # skip first line (headers)
while 1:
	try: row = rows.next()  # read one record
	except: break
	new_contact = []
	for offset in csv_field_offset:
		try:
			if type(offset) == type(()):  # join multi-value
				val = ' '.join([row[x-1] for x in offset])
			elif type(offset) == type(9):
				val = row[offset-1]
			else:
				die('Invalid offset: %s' % repr(offset))
		except:
			die(msg_invalid_offset)
		val = ' '.join(val.split())  # squeeze spaces
		new_contact.append(val)
	contacts.append(new_contact[:max_fields])
	print 'Added: %s' % (', '.join(contacts[-1]))
	if len(contacts) == max_contacts: break

### Compose headers

# Note 1: The header's last 4 bytes vary when contacts are added on
# the TELBOOK.EXE program. But they aren't necessary for the import.
# 
# Note 2: Version 1.1 has some special bytes at the end (footer),
# but they aren't necessary for the import.
#
if mp3_software_version == '2.0':
	data.append(ascii2hex('Radio technology'))
	data.append('0300 0000 %s00 0000 0200 0000 af39 4000 ' %
		int2hex(len(contacts)))
elif mp3_software_version == '1.0':
	data.append('55aa 33cc ffee ddcc 0102 0304 0506 0708 ')
	data.append('0032 0000 %s00 0000 0000 0000 a62c e45a ' %
		int2hex(len(contacts)))

### Add every contact

for i in range(len(contacts)):
	for j in range(len(mp3_field_names)):
		max, val = mp3_field_sizes[j], contacts[i][j].strip()
		if use_field_lenght is True: max = max - 1
		# Gotcha 1.x: names cannot be empty
		if j == 0 and not val: val = ' '
		# Gotcha 2.0: email of the 1st contact must be < 28
		if i == 0 and j == 3: val = val[:27]
		val = val[:max]           # more: slice the excess
		pad = max - len(val)      # less: zero pad
		hex_val = ascii2hex(val) + '00'*pad
		if use_field_lenght is True:
			hex_val = int2hex(len(val)) + hex_val
		data.append(hex_val)

### Convert data to binary form

data = ''.join(data).replace(' ', '')  # list2str, remove blanks
data = binascii.unhexlify(data)        # hex2bin

### Save results to disk

f = open(outfile, 'w')
f.write(data)
f.close()

print
print '%s saved with %s contacts (for version %s)' % (
	outfile, len(contacts), mp3_software_version)
"

-- Execute the Python script
set UnixOutputFolder to quoted form of (POSIX path of OutputFolder)
set UnixCsvFile to quoted form of (POSIX path of CsvFile)
set ContactCount to do shell script "
	cd " & UnixOutputFolder & "
	echo \"" & thePythonScript & "\" |
		python - -o 1,2,3,4,5,6 -v " & TelbookVersion & space & UnixCsvFile & " |
		sed -n 's/.* saved with \\([0-9]*\\).*/\\1/p'
	rm -f " & UnixCsvFile

-- We're done, show report
display dialog (ScriptName & return & return & "Done! The contacts file was saved to your Desktop:" & return & return & "  " & FileName & " (" & ContactCount & " contacts, v" & TelbookVersion & ")" & return & return & "Now just copy this file to the player and import it.") buttons {"OK"} default button 1 with icon 1
