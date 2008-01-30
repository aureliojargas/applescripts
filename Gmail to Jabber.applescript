(*
	Made by Aurelio Jargas
	http://aurelio.net/soft

	This script automates the copy of the Gmail email to the Jabber IM field in Apple's Address Book.

Install:
	Save this file on your "Library/Scripts/Applications/Address Book/" folder.

	For detailed information on installation, read
	http://aurelio.net/soft/applescript-install.html

License:
	Open Source, "as is", no warranty.

Get more scripts for free:
	http://aurelio.net/soft

*)



-------------------- USER CONFIG

-- Set here the default label to be used for the added Jabber contacts.
-- Leave empty for the default "other", or fill it with "home" or "work".
--
set defaultLabel to ""

-------------------- End of USER CONFIG



property runCount : 0
set myVersion to "1"
set myname to "Gmail to Jabber"

set myUrl to "http://aurelio.net/soft/"
set donateUrl to "http://aurelio.net/soft/donate.html"

set buttonAll to "All Contacts Once"
set buttonConfirm to "Confirm One by One"
set introMessage to "This script will set the Jabber field of all your Address Book contacts who have a Gmail e-mail." & return & return & "Do you want to do it in one shot or decide one by one which will be set?"

if runCount is 0 then
	display dialog "Thank you for downloading my " & myname & " script!" & return & return & "You can visit my website and get more free AppleScripts to use with iTunes, iPhoto and Address Book!" buttons {"Later", "OK"} default button 2 with icon 1
	if button returned of result as text is "OK" then open location myUrl
end if
set runCount to runCount + 1

-- Goodbye screen
on byebye(changedContacts)
	global myname
	global donateUrl

	set doneMessage to ""
	if changedContacts is greater than 0 then
		set doneMessage to "Work done!" & return & "We've set the Jabber of " & changedContacts & " contacts." & return & return
	end if

	display dialog myname & return & return & doneMessage & "Thank you for using my script. How about giving me a little hand to improve it?" & return & return & "Donate 3 or 5 dollars to make an independent programmer very happy today!" buttons {"Later", "Donate"} default button 2 with icon 1
	if button returned of result as text is "Donate" then open location donateUrl

end byebye

tell application "Contacts"

	-- Main screen
	display dialog myname & return & return & introMessage with icon 1 buttons {"Quit", buttonAll, buttonConfirm} default button 3
	set opMode to button returned of result
	if opMode is "Quit" then return

	-- Preparing...
	set setCount to 0
	set ContactCount to 0
	set totalCount to count every person

	repeat with thisContact in every person

		tell thisContact
			set ContactCount to ContactCount + 1

			set gmails to (value of every email whose value contains "@GMAIL.COM")

			if gmails is not {} then

				set jabbers to (value of every Jabber handle whose value contains "@GMAIL.COM")

				repeat with gmail in gmails
					if gmail is not in jabbers then

						set doIt to true

						if opMode is buttonConfirm then

							-- Show confirmation screen for this contact
							display dialog myname & " (contact " & ContactCount & " of " & totalCount & ")" & return & return & "Confirmation to set the Jabber for the following contact:" & return & return & "Name:" & tab & name & return & "Jabber:" & tab & gmail with icon 1 buttons {"Quit", "Skip", "Set Jabber"} default button 3

							-- Maybe we should skip or give up
							if button returned of result is "Quit" then
								if setCount is greater than 0 then my byebye(setCount)
								return
							else if button returned of result is "Skip" then
								set doIt to false
							end if


							-- Well, just do it [tm]
							if doIt then
								make new Jabber handle at end of Jabber handles with properties {label:defaultLabel, value:gmail}
								set setCount to setCount + 1

							end if
						end if
					end if
				end repeat
			end if
		end tell
	end repeat

	if setCount is greater than 0 then
		my byebye(setCount)
	else
		display dialog myname & return & return & "No Jabber to set!" & return & "All your fields are already filled." buttons {"Great!"} default button 1 with icon 1
	end if

end tell
