// tab_miss.ado

capture program drop tab_miss
program tab_miss
	syntax varname [if] [in]
	marksample touse, novarlist
	
	tabulate `varlist' if missing(`varlist') & `touse', missing
end

