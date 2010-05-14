// checkvars.ado

capture program drop checkvars
program checkvars
	syntax varlist [if] [in]
	marksample touse, novarlist
	
	display _newline as text "Running " as result "\$Id: checkvars.ado 658 2009-08-18 15:41:09Z mesa $"
	
	foreach i of varlist `varlist' {
		/* quietly */ unique `i' if !mi( `i') & `touse'
		display r(sum)
		local uniques = r(sum)
		display "`uniques'"
		if `uniques' < 2 { 
			global blacklist "`i' ${blacklist}"
			display "${blacklist}"
		} 
	} 
end

