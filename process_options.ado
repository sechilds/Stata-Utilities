// process_options.ado

/*
	If you specifiy multiple instances of the same option into this program, 
	it will return the LAST one.
*/

capture program drop process_options
program process_options, rclass
	syntax, *
	
	display _newline as text "Running " as result "\$Id: process_options.ado 711 2009-08-21 14:12:48Z mesa $" as text "."
	
	// loop through all options submitted
	while `"`options'"' != `""' /* " */ { 
		display as text "Options Left: " as result `"`options'"' /* " */ as text "."
		tokenize `"`options'"'	/* " */
		local current_token `1'
		display as text "Processing " as result `"`current_token'"' /* " */ as text "."
		macro shift
		local options `*'
		// Does the option have a bracket -- i.e. did it pass a parameter?
		if regexm(`"`current_token'"' /* " */,"^([a-zA-Z0-9]+)\(") { 
			// Grab the name part only
			local option_name = regexs(1)
		} 
		else { 
			local option_name `current_token'
		} 
		display as text "Option Name: " as result `"`option_name'"' /* " */ as text "."
		return local `option_name' `"`current_token'"' /* " */
	} 
end


