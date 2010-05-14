// catbar2.ado

capture program drop catbar2
program catbar2
	syntax varname [if] [in] [aweight fweight pweight], relabel(string) [*]
	marksample touse, novarlist
	tempvar cats
	
	quietly tabulate `varlist', generate(`cats'_)
	unab catvars : `cats'_*
	quietly levelsof `varlist', local(levs)
	
	local counter = 1
	local myrelabel `""'
	
	graph bar (mean) `catvars' if `touse' [`weight'`exp'], ascategory yvaroptions(relabel(`relabel')) `options'
	drop `cats'_*
end

