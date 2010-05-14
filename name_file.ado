// name_file.ado

/*
	This program adds a title to a text file
*/
capture program drop name_file
program name_file
	syntax using, [text(string) sampname(string) lines(integer 1) append replace]
	file open myfile `using', write `append' `replace' all
	if "`text'"!="" { 
		file write myfile `"`text'"' /* " */ _newline
	} 
	if "`sampname'"!="" { 
		file write myfile `"`sampname'"' /* " */ _newline
	}
	if `lines' > 0 { 
		forvalues i = 1/`lines' { 
			file write myfile _newline
		} 
	} 
	file close myfile
end 


