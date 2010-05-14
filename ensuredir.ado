// ensuredir.ado
capture program drop ensuredir
program ensuredir
	version 10
	args dirname
	
	display _newline as text "Running " as result "\$Id: ensuredir.ado 1394 2010-01-27 14:50:32Z mesa $"
	
	/*
		Check to see if the directory name passed to
		this program ends with a slash. If so, we
		will want to test the match on the name
		WITHOUT the slash.
		
		The cool thing about regular expressions, is that
		we can test the name for any ending character, by
		adding it to the [] in the expression -- that make
		it part of the character class we are testing for.
	*/
	local match = regexm( "`dirname'", "(.*)[\/]$")
	if `match' {
		local confirmname = regexs(1)
	}
	else {
		local confirmname "`dirname'"
	} 
	capture confirm new file `confirmname'
	if _rc==0 { 
		mkdir `dirname'
		display as text "Directory " as result "`dirname'" as text " created."
	}
	else {
		display as text "Directory " as result "`dirname'" as text " already exists."
	} 
end
