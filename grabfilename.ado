// grabfilename.ado
capture program drop grabfilename
program grabfilename, rclass
	version 10
	syntax using/
	
	display _newline as text "Running " as result "grabfilename.ado"
	display as text "\$Id: createdir.ado 650 2009-08-18 12:58:33Z mesa $"
	
	// display _newline as text "Original File Path: " as result "`using'" as text "."
	
	local detectfilename = regexm(`"`using'"' /* " */, ".*\\([A-Za-z0.9.]+$)")
	if `detectfilename' { 
		local filename = regexs(1)
	} 
	
	// Remove extension
	local noextension = regexr(`"`using'"' /* " */, "\.[A-Za-z]*", "")
	local noextension2 = regexr(`"`filename'"' /* " */, "\.[A-Za-z]*", "")
	
	return local dirpath = "`noextension'"
	return local filepath = "`using'"
	return local dirname = "`noextension2'"
	return local filename - "`filename'"
end


