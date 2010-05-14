// pad_file.ado

/*
	This program adds blank lines to a text file
*/
capture program drop pad_file
program pad_file
	syntax using [, lines(integer 1)]
	file open myfile `using', write append all
	forvalues i = 1/`lines' { 
		file write myfile _newline
	} 
	file close myfile
end 


