capture program drop manual_log
program manual_log
	syntax using/ [, APPend REPlace NAMe(passthru)]
	
	local fileprefix "${manuallogpath}${locationname}/"
	ensuredir "`fileprefix'"
	if "${datestringp}"=="" {
		global datestringp "$S_DATE"
	} 
	// global datestring : subinstr global datestring " " "", all
	tokenize $datestringp
	local day = string(`1',"%02.0f") // leading zero
	local month `2'
	local year `3'
	if "${timestring}"=="" { 
		global timestring "$S_TIME"
	} 
	local ml_timestring : subinstr global timestring ":" "_", all
	local logfilename "`fileprefix'`year'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`month'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`day'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`ml_timestring'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`using'"
	log using "`logfilename'", `append' `replace' text `name'
	cmdlog using "`logfilename' cmd", `append' `replace'
end
