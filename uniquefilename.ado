// uniquefilename.ado

/*
	28AUG09: My laziness comes back to haunt me. I used recursion for this
	one and ended up with a system limit error because I have over 60 files
	open.
	
	Too many levels of recursion.
	I need to fix this now!!!

	I might have a problem with recursion in this one.
	It will essentially loop through all the numbers
	until it finds one that is free. There should be
	a shortcut.
	
	Basically, we want to search and find the filename
	with the highest number, then put that in -- instead
	of running the program for each increment.
*/
capture program drop uniquefilename
program uniquefilename, rclass
	version 10
	syntax using/ [, format(string)]
	if "`format'"=="" { 
		local format "%03.0f"
	} 
	
	display _newline as text "Running " as result "\$Id: uniquefilename.ado 1394 2010-01-27 14:50:32Z mesa $"
	
	display _newline as text "Testing " as result "`using'" as text " for uniqueness."
	
	capture confirm new file "`using'"
	if _rc { 
		local notnewfile = _rc
		/* 
			The filename isn't unique, so I now want to 
			check to see if there are any numbers at the end
			of the filename (but not the extension).
		*/
		display as result "`using'" as text " is not unique. " _continue
		local match = regexm( "`using'", "^(.*)\.([A-Za-z]*)$")
		if `match' { 
			local filename = regexs(1)
			local extension = regexs(2)
			display as text "Filename: " as result "`filename'" _continue
			display as text " Extension: " as result "`extension'" as text "."
			/*
				Now we check the filename for numbers at the end of it.
			*/
			local match2 = regexm( "`filename'", "^(.*[^0-9])([0-9]+)$")
			if `match2' { 
				local filewords = regexs(1)
				local filenumbers = regexs(2)
				display as text "Filename: " as result "`filewords'" _continue
				display as text "Numbers at end: " as result "`filenumbers'" as text "."
				/*
					We've found numbers at the end, now we need to increment the
					numbers.
					
					First, we need to convert the numbers in the filenumbers
					macro from a stirng to an integer.
				*/
				local tablenumber = int(real("`filenumbers'"))
				/*
					Now we want to increment that number.
				*/
				
				while `notnewfile'==602 { 
					local ++tablenumber
					local newstringnumber = string(`tablenumber',"`format'")
					display as text "Incremented number: " as result "`newstringnumber'" as text "."
					local finalfilename "`filewords'`newstringnumber'.`extension'"
					display as text "Final File Name: " as result "`finalfilename'" as text "."
					capture confirm new file "`finalfilename'"
					local notnewfile = _rc
				} 
				if `notnewfile'!=0 { 
					error `notnewfile'
				} 
			} 
			else { 
				/*
					In this case, we don't find numbers at the end, so
					we just add some.
				*/
				display as text "No existing numbers found at the end of the file."
				local newstringnumber = string(1, "`format'")
				local finalfilename "`filename'`newstringnumber'.`extension'"
				display as text "Final File Name: " as result "`finalfilename'" as text "."
			}
			uniquefilename using "`finalfilename'"
			local finalfilename "`r(filename)'"
		} 
		else { 
			/*
				We get here if we can't find an extension on the file
				name. Basically, we screwed up.
			*/
			display as error "Could not find file extension!"
			error 100
		} 
	} 
	else { 
		/*
			The filename is unique. No action necessary.
		*/
		local finalfilename "`using'"
	} 
	return local filename = "`finalfilename'"
end

