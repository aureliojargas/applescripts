(*

   Export Contacts to Yahoo CSV
	by Aurelio Marinho Jargas (http://aurelio.net)
	v1.0 - March 9, 2005
   
   Apple Script to export the Address Book contacts to the Yahoo! CSV format.
   Then it can be uploaded to the Yahoo Web-based Address Book.


Features:
   - Exports ALL fields that are used by Yahoo Address Book, including groups.
 
   - Handles correctly the quote escaping, international text and date formats.
	
   - The four Yahoo custom fields are filled with IM numbers:
     ICQ, MSN, AIM and Jabber
    
   - Some Yahoo fields are not available in Apple's Address Book, they are:
      Distribution Lists, Yahoo! Phone, Primary and Business Website   


Usage:
   Just run this script and it will dump the "Yahoo-AB.csv" file to your Desktop.


Note: It is my real first Apple Script. Improvements are VERY welcome.

*)


-- ##################################### USER CONFIG HERE

-- Set to TRUE if you don't have Scripting Adictions installed
-- (Error in "display dialog" command)
set Vanilla to false

-- The resulting CSV file location (default is Desktop:Yahoo-AB.csv)
set CsvFile to (((path to desktop folder) as text) & "Yahoo-AB.csv")

-- Default values for fields not available in Address Book
set YahooDistributionList to "Unfiled"
set YahooMainPhone to "home"

-- Maximum number of contacts to export
set MaxContacts to 1

-- List with all the Yahoo CSV fields
-- If your language is not listed here, check the first line of your Yahoo generated CSV file.

-- English fields. The default.
set YahooFields to {"First", "Middle", "Last", "Nickname", "Email", "Category", "Distribution Lists", "Yahoo! ID", "Home", "Work", "Pager", "Fax", "Mobile", "Other", "Yahoo! Phone", "Primary", "Alternate Email 1", "Alternate Email 2", "Personal Website", "Business Website", "Title", "Company", "Work Address", "Work City", "Work State", "Work ZIP", "Work Country", "Home Address", "Home City", "Home State", "Home ZIP", "Home Country", "Birthday", "Anniversary", "Custom 1", "Custom 2", "Custom 3", "Custom 4", "Comments"}

-- Portuguese fields. Uncomment this if your accont is from Yahoo! Brasil
--set YahooDistributionList to "Todos"
--set YahooFields to {"Nome", "&nbsp;", "Sobrenome", "Apelido", "E-mail", "Categoria", "Listas de distribui‹o", "ID Yahoo!", "Informa›es pessoais", "Trabalho", "Pager", "Fax", "Celular", "Outro", "Fone Yahoo!", "Principal", "E-mail alternativo 1", "E-mail alternativo 2", "Web site pessoal", "Website da empresa", "Cargo", "Empresa", "Endereo", "Cidade", "Estado", "CEP", "Pa’s", "Endereo residencial", "Cidade", "Estado", "CEP", "Pa’s", "Data de nascimento", "Anivers‡rio", "Complemento 1", "Complemento 2", "Complemento 3", "Complemento 4", "Coment‡rios"}

-- ##################################### END OF USER CONFIG

set ScriptName to "Export Contacts to Yahoo CSV"
set ContactCount to 0
set AllLines to {}

-- Join list items in a single string, quoted and comma separated
-- Example: "one","two","three"
on ListToCsvLine(theList)
	set AppleScript's text item delimiters to "\",\""
	set CsvLine to ("\"" & theList as text) & "\"" & return
	set AppleScript's text item delimiters to ""
	return CsvLine
end ListToCsvLine

-- Convert from date property to Yahoo "MM/DD/YYYY" format
on FormatDate(theDate)
	if theDate is missing value then
		return ""
	end if
	set d to day of theDate as text
	set y to year of theDate as text
	set m to month of theDate as integer
	set m to m as text -- no need to zeropad
	return m & "/" & d & "/" & y
end FormatDate

-- Find the group name of the given contact
on getGroup(Contact)
	tell application "Address Book"
		repeat with theGroup in groups
			if id of Contact is in id of every person of theGroup then
				return the name of theGroup
			end if
		end repeat
	end tell
	return "" -- not found
end getGroup

-- Parses and saves field data to the data folder
on AddMe(info)
	global full_line
	
	-- XXX: dirty hack, don't know how to check if a var is not defined
	try
		set FOO to info
	on error
		set info to ""
	end try
	
	-- Map missing to empty
	if info is missing value then
		set info to ""
	end if
	
	-- From here, we only know about text
	if class of info is not text then
		set info to info as text
	end if
	
	-- Every embedded " turns to "" on Yahoo CSV
	if info contains "\"" then
		set AppleScript's text item delimiters to "\""
		set tmp_list to every text item of info
		set AppleScript's text item delimiters to "\"\""
		set info to tmp_list as string
	end if
	
	copy info to the end of full_line
end AddMe

-- Copied from Apple docs
on write_to_file(this_data, target_file, append_data)
	try
		set the target_file to the target_file as text
		set the open_target_file to Â
			open for access file target_file with write permission
		if append_data is false then Â
			set eof of the open_target_file to 0
		write this_data as Unicode text to the open_target_file starting at eof
		close access the open_target_file
		return true
	on error
		try
			close access file target_file
		end try
		return false
	end try
end write_to_file

-- ###################################### Processing begins here

if not Vanilla then
	display dialog (ScriptName & return & return & "I will scan your Address Book and dump all information to the Yahoo CSV format. It will take just a few seconds.") buttons {"OK"}
end if

-- Add the field names at the first line
copy ListToCsvLine(YahooFields) to the end of AllLines

-- Here we go, extracting (in order) all the properties for every contact
tell application "Address Book"
	repeat with Contact in every person
		
		if ContactCount is MaxContacts then
			exit repeat
		end if
		
		set ContactCount to ContactCount + 1
		set full_line to {} -- reset the data holder
		set full_name to name as text
		
		tell Contact
			
			-- Add the full name & nick
			my AddMe(first name)
			my AddMe(middle name)
			my AddMe(last name)
			my AddMe(nickname)
			
			-- Home e-mail
			if (count emails of Contact) > 0 then
				my AddMe(value of first email of Contact where label is "home")
			else
				my AddMe("")
			end if
			
			-- Contact group
			my AddMe(my getGroup(Contact))
			
			-- Distribution lists (not used in AB)
			my AddMe(YahooDistributionList)
			
			-- IM: Yahoo
			if (count Yahoo handles of Contact) > 0 then
				my AddMe(value of first Yahoo handle of Contact)
			else
				my AddMe("")
			end if
			
			-- Phone numbers
			if (count phones of Contact) > 0 then
				my AddMe(value of first phone of Contact where label is "home")
				my AddMe(value of first phone of Contact where label is "work")
				my AddMe(value of first phone of Contact where label is "pager")
				my AddMe(value of first phone of Contact where label is "work fax")
				my AddMe(value of first phone of Contact where label is "mobile")
				my AddMe(value of first phone of Contact where label is "other")
			else
				repeat 6 times
					my AddMe("")
				end repeat
			end if
			
			-- Yahoo phone and Main phone (not used in AB)
			my AddMe("")
			my AddMe(YahooMainPhone)
			
			-- Alternative e-mails
			if (count emails of Contact) > 0 then
				my AddMe(value of first email of Contact where label is "work")
				my AddMe(value of first email of Contact where label is "other")
			else
				my AddMe("")
				my AddMe("")
			end if
			
			-- Personal homepage
			my AddMe(home page)
			
			-- Work homepage (not used in AB)
			my AddMe("")
			
			-- Job info
			my AddMe(job title)
			my AddMe(organization)
			
			-- Work and Home addresses (street, city, state, zip, country)
			if (count addresses of Contact) > 0 then
				my AddMe(street of first address of Contact where label is "work")
				my AddMe(city of first address of Contact where label is "work")
				my AddMe(state of first address of Contact where label is "work")
				my AddMe(zip of first address of Contact where label is "work")
				my AddMe(country of first address of Contact where label is "work")
				
				my AddMe(street of first address of Contact where label is "home")
				my AddMe(city of first address of Contact where label is "home")
				my AddMe(state of first address of Contact where label is "home")
				my AddMe(zip of first address of Contact where label is "home")
				my AddMe(country of first address of Contact where label is "home")
			else
				repeat 10 times
					my AddMe("")
				end repeat
			end if
			
			-- Birth date
			my AddMe(my FormatDate(birth date))
			
			-- Special date (not used in AB)
			my AddMe("")
			
			-- IM: ICQ
			if (count ICQ handles of Contact) > 0 then
				my AddMe(value of first ICQ handle of Contact)
			else
				my AddMe("")
			end if
			
			-- IM: MSN
			if (count MSN handles of Contact) > 0 then
				my AddMe(value of first MSN handle of Contact)
			else
				my AddMe("")
			end if
			
			-- IM: AIM
			if (count AIM handles of Contact) > 0 then
				my AddMe(value of first AIM Handle of Contact)
			else
				my AddMe("")
			end if
			
			-- IM: Jabber
			if (count Jabber handles of Contact) > 0 then
				my AddMe(value of first Jabber handle of Contact)
			else
				my AddMe("")
			end if
			
			-- Notes
			my AddMe(note)
			
		end tell
		
		-- Save line
		copy my ListToCsvLine(full_line) to the end of AllLines
		
	end repeat
end tell

-- Write the CSV file to the Desktop
write_to_file(AllLines as text, CsvFile, true)

-- XXX: how to avoid these chars from being inserted?
-- Remove strange chars (^@ ^M) that are inserted on the CSV file
set CsvUnixFile to POSIX path of CsvFile
set TmpFile to CsvUnixFile & ".tmp"
do shell script "cat " & CsvUnixFile & " | tr -d '\\000' | tr '\\015' '\\n' > " & TmpFile
do shell script "mv " & TmpFile & " " & CsvUnixFile

if not Vanilla then
	display dialog ((ScriptName & return & return & ContactCount as text) & " contacts were exported from your Address Book to the following file:" & return & return & tab & tab & CsvFile as text) buttons {"OK"}
end if