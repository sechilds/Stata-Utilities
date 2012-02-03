// manual_log.ado

capture program drop manual_log
program manual_log
	syntax using/ [, APPend REPlace NAMe(string) path(string)]

	quietly findfile su_user_locals.do
	include `r(fn)'

	if missing("`name'") {
		local name "manual"
	}

	if !missing(`"`path'"') {
		local fileprefix `"`path'"'	
	}
	else {
		local fileprefix "`manuallogpath'`locationname'/"
	}
	ensuredir "`fileprefix'"
	local datestringp "$S_DATE"
	tokenize `datestringp'
	local day = string(`1',"%02.0f") // leading zero
	local month `2'
	local year `3'
	local timestring "$S_TIME"
	local ml_timestring : subinstr local timestring ":" "_", all
	local logfilename "`fileprefix'`year'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`month'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`day'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`ml_timestring'/"
	ensuredir "`logfilename'"
	local logfilename "`logfilename'`using'"
	capture log close `name'
	capture cmdlog close
	log using "`logfilename'", `append' `replace' text name(`name')
	cmdlog using "`logfilename' cmd", `append' `replace'
end

// manual_log.ado

