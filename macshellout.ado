// macshellout.ado

capture program drop macshellout
capture program drop macshellout_myshell
program define macshellout
	syntax [anything] [using] [,cd] [openfile]
	
	display as text "Running " as result "\$Id: macshellout.ado 1243 2009-12-04 13:16:34Z mesa $" as text "."
	
	if "`openfile'"=="openfile" { 
		/*
			Are we on a Mac?
		*/
		if "`c(os)'"=="MacOSX" | substr("$S_MACH",1,3)=="Mac" { 
			macshellout_myshell `using'
		} 
		else { 
			shellout `anything' `using', `cd'
		} 
	}
end

program macshellout_myshell
	syntax using/
	shell open -g "`using'"
end

