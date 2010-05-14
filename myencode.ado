// myencode.ado

capture program drop myencode
program myencode
	syntax varlist(min=1 max=1) [, label(passthru)]
	tempvar B
	
	display _newline as text "Running " as result "\$Id: myencode.ado 658 2009-08-18 15:41:09Z mesa $"
	
	capture encode `varlist', generate( `B' ) `label'
	local rc = _rc
	if `rc'==107 {
		display as result "`varlist'" as text " already numeric. No action taken."
	} 
	else { 
		error `rc'
		/*
			Encode command successfully executed.
		*/
		quietly drop `varlist'
		quietly rename `B' `varlist'
	} 
end
