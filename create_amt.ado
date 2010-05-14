// create_amt.ado

capture program drop create_amt
program create_amt
	syntax varname, INCIDence(name) AMOunt(name) [EXIStingincidence(varname) recode]
	confirm new variable `incidence'
	confirm new variable `amount'
	
	/*
		First we deal with variables that do not have an existing
		incidence variable.
	*/
	if "`existingincidence'"=="" { 
		quietly clonevar `amount' = `varlist'
		quietly generate `incidence' = .
		quietly replace `incidence' = 0 if `amount' == 0 | `amount' == .v
		quietly replace `incidence' = 1 if `amount' > 0 & `amount' < .
		quietly replace `incidence' = `amount' if missing(`amount') & `amount' != .v
		quietly replace `amount' = .v if `amount' == 0
		label values `incidence' yesno0
	} 
	else { 
		quietly clonevar `incidence' = `existingincidence'
		if "`recode'"=="recode" { 
			quietly recode `incidence' (1 = 1) (2 = 0)
		} 
		quietly clonevar `amount' = `varlist'
		quietly replace `amount' = .v if `amount' == 0
		quietly replace `amount' = .s if `incidence' == 0
		quietly replace `amount' = `incidence' if missing(`incidence')
		label values `incidence' yesno0
	} 
end


