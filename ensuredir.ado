// ensuredir.ado
capture program drop ensuredir
program ensuredir
	version 10
	args dirname
	
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
