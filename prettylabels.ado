// prettylabels.ado
capture program drop prettylabels
program prettylabels
	syntax [varlist] [, saving(string) replace numlabel(namelist)]
	// syntax [namelist(name=varlist)] [using] [, saving(string) replace numlabel(namelist)]
	version 10.1

	/*
		14MAY2010:

		Be careful with this file. It will rewrite your
		variable and value labels. It's an old file, and
		I haven't used it in a year or so.
	*/
	
	// Specifying a dataset is optional. If you specifiy nothing, it shouldn't load anything.
	// capture use `using', clear

	/*
		The easy part is fixing the variable labels.
		
		This is taken from a Stata Journal article by J. Weesie.
	*/
	foreach v of varlist `varlist' {
		local oldlabel : variable label `v'
		local newlabel = proper( `"`oldlabel'"' ) /* " */
		local newlabel = subinstr( `"`newlabel'"', "'S", "'s",.)
		local newlabel = subinstr( `"`newlabel'"', "'T", "'t",.)
		local newlabel = subinstr( `"`newlabel'"', "'M", "'m",.)
		local newlabel = subinstr( `"`newlabel'"', "(S)", "(s)",.)
		local newlabel = subinstr( `"`newlabel'"', "Pse", "PSE",.)
		local newlabel = subinstr( `"`newlabel'"', "Epi", "EPI",.)
		local newlabel = subinstr( `"`newlabel'"', "Hs", "HS",.)
		local newlabel = subinstr( `"`newlabel'"', "Cip ", "CIP ",.)
		label var `v' `"`newlabel'"' /* " */
	}
	
	/*
		We want to convert the varlist to a list of labels
	*/
	local labellist
	foreach i of varlist `varlist' { 
		local labelname : value label `i'
		local labellist "`labellist' `labelname'"
	}
	local labellist : list uniq labellist
	
	/* 
		Now to tackle the value labels.
	*/
	preserve				// Save the dataset for later.
	uselabel `labellist', clear	// Create a dataset of the value labels
	
	/*
		The commands to fix the labels go here.
	*/
	replace label = proper(label)
	replace label = subinstr(label, "'S", "'s",.)
	replace label = subinstr(label, "'T", "'t",.)
	replace label = subinstr(label, "'M", "'m",.)
	replace label = subinstr(label, "(S)", "(s)",.)
	replace label = subinstr(label, "Pse", "PSE",.)
	replace label = subinstr(label, "Epi", "EPI",.)
	replace label = subinstr(label, "Cip ", "CIP ",.)
	replace label = subinstr(label, "Hs", "HS",.)
	replace label = subinstr(label, "Ba", "BA",.)
	replace label = subinstr(label, "BAchelor", "Bachelor",.)
	replace label = subinstr(label, "BAptist", "Baptist",.)
	replace label = subinstr(label, "BAthurst", "Bathurst",.)
 	replace label = subinstr(label,`"""',`" "',.) /* " */
	
	/*
		Now we need to put those labels back in the dataset.
	*/
	generate command = "label define " + lname + " " + string(value) + `" ""' + label + `"", modify"'
	tempfile mytempfile
	outfile command using "`mytempfile'", noquote replace
	
	// Bring back our data
	restore
	quietly do "`mytempfile'"
	
	/*
		Ok -- the next step is to numlabel the appropirate variables
	*/
	if "`numlabel'"!="" {
		numlabel `numlabel', add mask( "(#) " ) 
	} 
	
	if "`saving'"!="" {
		save "`saving'", `replace'
	}
end
