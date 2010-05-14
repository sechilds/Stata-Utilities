// createdir.ado
capture program drop createdir
program createdir, rclass
	version 10
	syntax using/
	
	display _newline as text "Running " as result "createdir.ado"
	display as text "\$Id: createdir.ado 1394 2010-01-27 14:50:32Z mesa $"
	
	// display _newline as text "Original File Path: " as result "`using'" as text "."
	
	// Remove extension
	local noextension = regexr(`"`using'"' /* " */, "\.[A-Za-z]*", "")
	// local match = regexm( `"`using'"' /* " */, "(.*)\.[.]*$")
	// if `match' { 
		// local noextension = regexs(1)
	// } 
	// else { 
		// local noextension = "`using'"
	// } 
	// display _newline as text "File Extension Removed: " as result "`noextension'" as text "."
	
	// Add directory slash
	local finaldirname "`noextension'/"
	// display _newline as text "Final Directory Name: " as result "`finaldirname'" as text "."
	
	ensuredir "`finaldirname'"
	return local dirname = "`finaldirname'"
	return local filename = "`using'"
end
