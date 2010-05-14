capture program drop manual_close
program manual_close
	syntax [, NAMe(passthru)]
	
	display _newline as text "Running " as result "\$Id: manual_close.ado 658 2009-08-18 15:41:09Z mesa $"
	
	log close `name'
	cmdlog close
end
