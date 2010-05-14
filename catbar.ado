// catbar.ado

capture program drop catbar
program catbar
	syntax varname [if] [in] [aweight fweight pweight], [alternate *]
	marksample touse, novarlist
	tempvar cats
	
	quietly tabulate `varlist', generate(`cats'_)
	unab catvars : `cats'_*
	quietly levelsof `varlist', local(levs)
	
	local counter = 1
	local myrelabel `""'
	
	foreach i of local levs { 
		local catlabel : label (`varlist') `i'
		local myrelabel `"`myrelabel' `counter' "`catlabel'""'	/* " */
		local ++counter
	} 
	display `"`myrelabel'"'	/* " */
	
	graph bar (mean) `catvars' if `touse' [`weight'`exp'], ascategory yvaroptions(relabel(`myrelabel') label(labsize(small) `alternate')) `options'
	drop `cats'_*
end

