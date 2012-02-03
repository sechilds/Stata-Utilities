capture program drop manual_close
program manual_close
	syntax [, NAMe(passthru)]

	if missing("`name'") {
		local name "manual"
	}
	
	log close `name'
	cmdlog close
end
