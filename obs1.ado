// obs1.ado

capture program drop obs1
program obs1, rclass
	syntax varlist(min=1 max=1) [if] [in] [, missing]
	marksample touse, novarlist
	tempname A a
	
	display _newline as text "Running " as result "\$Id: obs1.ado 658 2009-08-18 15:41:09Z mesa $"
	
	quietly levelsof `varlist', local(x) `missing'
	foreach i of local x {
		quietly count if `varlist'==`i' & `touse'
		scalar `a' = r(N)
		if `a' > 0 {
			matrix `A' = (nullmat( `A' ) \ r(N) )
		}
		else {
			matrix `A' = (nullmat( `A' ) \ . )
		}
	} 
	quietly proportion `varlist', `missing'
	local catnames "`e(label1)'"
	matrix rownames `A' = `catnames'
	matrix roweq `A' = `varlist'
	return matrix X `A'
end

