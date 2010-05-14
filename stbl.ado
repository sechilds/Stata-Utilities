// stbl.ado (was super_table.do)

/*
	This program is designed to generate Excel tables of various data.
	It is basically used for descriptive statistics. The stbl command, which
	is implemented below, calls super_table with a correctly formatted request.
	
	The problem with it is, it's a bit murky what it actually DOES. It needs some
	updating.
	
	Types of statistics offered: mean, proportion, count, obs, total, mean, change.
	
	Each type of stat does something slightly different. Plus, there's a flip option which rotates 
	the table. Various stats actually do slightly different things in a flipped table. 
	It's a little bit of a mess, actually.
	
	13AUG09: I think I've figured out a way to actually allow for options within the list of stats,
	formats and variables. Basically you could specifiy options within stats: (mean, standarderror), 
	would be an example. I think you could nest the parenthesis to allow for sets if you wanted.
	(proportion mean, standarderror) would have the standarderror option apply to both stats, while
	(proportion (mean, standarderror)) would have it only apply to mean.
	
	Basically, options specified in this way would actually overwrite other options. The stbl program
	could actually parse that text, and then pass it along to super_table in a simlar way to what I do
	for variables stats and formats. You additionally send a list of "options" for each variable.
	When the program loops through those variables, you would check to see if there were any options
	specified, and if so, they override the other options specified at the end of the command.
	
	I think that you could double nest options as well. I had an example of that in my brain, but I
	can't think of it now.
	
	Actually, this syntax will make the "round" statistic useless. Basically, round will apply to all
	the results if you specify it at the end. Instead of round, you would type (mean, round(10)).
	
	I wonder if I could set up something where you could make all instances of mean in the command
	be rouned by specifying one option command. Something like: (mean, round(10) persist) -- so
	subsequent (mean)'s will be automatically rounded. I'd want to implement this syntax before making
	the move.
	
	Also, is it the best setup to actually use Stata to parse this text. Perhaps I want to look at
	another language for it.
	
	18AUG09: I fixed my problems with the generation of the individual tables, but I think that I
	may have caused a problem. Currently, each individual table is named after the variable that
	it is using: some are over variables, and some are varlist variables. But, it will make sense
	to include the same variable more than once in the list... after all you might use different
	stats for the table -- or you could use the same stat with different options (I'm thinking
	ahead here.)
	
	Anyway, to solve this I will do two things. Add in the stats for the varlist variables, since
	that will make it easier to find the table that you want. Also, I could write some code to
	pick a filename if it already exists. Actually, I should write that up as an ado file.
*/

/*
	Program name: stbl
	Function: This program is the text parser. It takes the values passed to the "anything" macro and
	turns them into lists of variable names, statistic names and formats. It then passes those lists
	to super_table, which actually generates tables based on them.
*/
capture program drop stbl
program stbl
	syntax anything using [if] [in] [pweight], [over(varlist) SUBGRoup(varlist) ALLSGroup]  [FORMat(string)] [ROUND(passthru) STANDARDERRor STDERRBRacket STDERRPOSition(passthru) APPend REPLace FLIP noHEADer MISSing  ALLCol noALLRow] [REGEX(passthru) RXREPLACEment(passthru)] [VERBose] [notes(string)] [title(string)] [rowtitle(passthru)] [SHOWTOTal] [ATOMize] [XOVER(passthru) XOVERAll] [OPENFile] [BACKup INDIVidualfiles]
	marksample touse, novarlist
	tempvar all
	
	// global optdelimit " >>> "
	global optdelimit ">"
	
	display _newline as text "Running " as result "\$Id: stbl.ado 1399 2010-01-28 14:24:21Z mesa $"
	
	generate `all' = 1
	label define all 1 "All", modify
	label values `all' all
	
	/*
		Backup and replace the file.
	*/
	
	grabfilename `using'
	local filepath = r(filepath)
	local dirpath = r(dirpath)
	local backupfile = `"`dirpath'.bak"'	/* " */
	uniquefilename using "`backupfile'"
	local backupfile = r(filename)
	if "`replace'"=="replace" { 
		capture copy `filepath' `backupfile'
		capture erase `filepath'
	}
	
	/*
		Do the recursive atomize function for flipped tables.
	*/
	if "`atomize'"=="atomize" & "`flip'"=="flip" { 
		/*
			Basically, the first table that we generate will follow the rules specified
			in the overall command. Subsequent commands should be replaced. My strategy
			for doing this is to define a local macro of my own which will contain the
			contents of both append and replace macros that have been passed to the
			original stbl command. After it is run once, I will change it to append
			for the rest of the loop.
			
			I'm not sure what to do about headers in this case. I could pass noheaders to
			subsequent tables, but I don't think I will.
		*/
		if "`verbose'"=="verbose" { 
			display as text "Flipped atomized table. Running stbl recursively."
		} 
		createdir `using'
		local subtabledir "`r(dirname)'"
		local originalfile "`r(filename)'"
		local atomized_filelist ""
		// local myappend_replace "`append' `replace'"
		local myappend_replace "replace"	// replace for each separate file.
		foreach over_i of local over { 
			uniquefilename using "`subtabledir'O`over_i'.txt"
			local tableoutputfilename "`r(filename)'"
			stbl `anything' using "`tableoutputfilename'" /* " */`if' `in' [`weight'`exp'], over(`over_i') subgroup(`subgroup') `allsgroup' format(`format') `round' `standarderror' `stderrbracket' `stderrposition' `myappend_replace' `flip' `noheader' `missing' `allcol' `noallrow' `regex' `rxreplacement' `verbose' notes(`notes') title(`title') `showtotal'
			local atomized_filelist `"`atomized_filelist' "`tableoutputfilename'""'	/* " */
			// local myappend_replace "append"
		} 
		
		/*
			Now we merge all the files together. We use the append and replace macros to
			determine what files to include.
		*/
		local replacex "`replace'"
		if "`append'"=="append" { 
			capture confirm file `originalfile'
			if !_rc { 
				local firstfile "`originalfile'"
				local replacex "replace" // We will need to replace the original file.
			} 
		} 
		else { 
			local firstfile ""
		} 
		inccat `firstfile' `atomized_filelist', to(`originalfile') replace
		uniquefilename using "`subtabledir'filelist.txt"
		local filelistfilename "`r(filename)'"
		file open myfile using "`filelistfilename'", write all replace
		foreach l of local atomized_filelist { 
			file write myfile `"`l'"' /* " */ _newline
		} 
		file close myfile
	} 
	else { 
		if "`verbose'"=="verbose" { 
			display _newline as text "Original List: " as result `"`anything'"' /* " */ as text "."
		} 
		
		local myvarlist ""
		local mystatlist ""
		local myformatlist ""
		local myoptionlist ""
		local nextstat ""
		local nextformat ""
		local statgroup ""
		local formatgroup ""
		local open_para = 0
		local option_flag = 0
		local STAT_SET = 0
		local stderrleft ""
		local stderrright ""
		
		if "`stderrbracket'"=="stderrbracket" { 
			local stderrleft "[ "
			local stderrright " ]"
		} 
		
		if "`format'" == "" { 
			local format "%12.1f"
		} 
		
		local cur_stat "mean"
		local cur_format "`format'"
		// local option_list "default"
		// Level 1 - while loop open
		while `"`anything'"' != `""' /* " */ { 
			tokenize `"`anything'"' /* " */
			local cur_var `1'
			macro shift
			local anything `"`*'"'	/* " */
			display _newline as text "Processing " as result `"`cur_var'"' /* " */ as text "."
			display as text "Remaining tokens: " as result `"`anything'"' /* " */ as text "."
			display as text "open_para = " as result "`open_para'" as text "   option_flag = " as result "`option_flag'" as text "."
			display _newline as text "Stat Group: " as result "`statgroup'" as text "."
			display as text "Format Group: " as result "`formatgroup'" as text "."
			display as text "Individual Option List: " as result `"`option_list'"' /* " */ as text "."
			display _newline as text "Varlist (so far): " as result "`myvarlist'" as text "."
			display as text "Statlist (so far): " as result "`mystatlist'" as text "."
			display as text "Formatlist (so far): " as result "`myformatlist'" as text "."
			display as text "Optionlist (so far): " as result `"`myoptionlist'"' /* " */ as text "."
			/*
				Single Stat Commands
				First is with options, the second is without options.
			*/
			// Level 2 - if statement, stat with option
			if regexm(`"`cur_var'"' /* " */,"\([ ]*([a-z]+[0-9]*)[ ]*,[ ]*([a-z]+.*)[ ]*\)$") { 
				// Options were provided
				display as text "Single Stat with Options"
				local cur_stat = regexs(1)
				local option_list = regexs(2)
				local option_list = `"`"`option_list'"'"'
				local STAT_SET = 1
				// Level 2 closing
			} 
			// Level 2 - else if statment, not stat with options
			else { 
				// Level 3 - if statement, stat without options
				if regexm(`"`cur_var'"' /* " */,"\([ ]*([a-z]+[0-9]*)[ ]*\)$") { // single stat command
					display as text "Single Stat without options"
					local cur_stat = regexs(1)
					local option_list "default"
					local STAT_SET = 1
					// Level 3 closing
				} 
				// Level 3 - else if statement, not stat without opiton
				else { 
					// Not a stat command, don't process the set thingy.
					local STAT_SET = 0
					// Level 3 closing
				}
				// Level 2 closing
			} 
			// Dealing with the "set" stat (which is a predefined block of stats
			// Level 2 - if statement -- stat was set this iteration
			if `STAT_SET' == 1 { 
				// Level 3 -- is verbose on?
				if "`verbose'"=="verbose" { 
					display as text "The current stat is " as result "`cur_stat'" as text "."
					display as text "The current option list is " as result "`option_list'" as text "."
					// Level 3 closing
				} 
				// Level 3 -- if statement - was the cur_stat equal to set?
				if "`cur_stat'"=="set" { 
					display as text "Set of stats invoked."
					local statgroup "count mean min max pctile25 pctile50 pctile75 iqr"
					local formatgroup = regexr("`cur_format'","[.][0-9]+",".0")
					// Level 4 -- forvalues loop over the different stats
					forvalues fcounter = 2/8 {
						// local myvarlist "`myvarlist' `cur_var'"
						// local myformatlist "`myformatlist' `cur_format'"
						local formatgroup "`formatgroup' `cur_format'"
						// Level 4 closing
					} 
					// local mystatlist "`mystatlist' count mean min max pctile25 pctile50 pctile75 iqr"
					// Level 3 Closing
				}
				// Level 3 -- else if statement, stat is not equal to 'set'
				else {
					// Single stat variable -- set groups to empty
					local statgroup ""
					local formatgroup ""
					// Level 3 closing
				}
				// Level 2 closing
			} 
			// Level 2 - else statement -- stat not set this iteration
			else { 
				// Level 3 - if statement -- this is a format command
				if regexm(`"`cur_var'"' /* " */,"^(%.+)") { // format command
					display as text "Formatting Command"
					local cur_format = regexs(1) 
					// Level 3 closing
				} 
				// Level 3 - else statement -- not a formatting command
				else { 
					// Level 4 - if statement -- item matches the opening for a group of stats
					if regexm(`"`cur_var'"' /* " */,"\([ ]*([a-z%][a-z0-9.,]*)") { // opening para for set of stats
						display "Opening Parenthesis (set of stats)"
						local cur_var = regexs(1) // strip the parenthesis
						// Level 5 -- check if paragraph already open
						if `open_para'==1 { 
							// para already open
							error 198
							// level 5 closing
						}
						// level 5 -- paragraph not already open
						else { 
							local open_para = 1 // indicate open parentheses
							/*
								Clear options!
							*/
							local option_list `""'
							// level 6 -- if statement -- formatting command
							if regexm(`"`cur_var'"' /* " */,"(%.+)") { 
								display as text "Formating within set of stats"
								// the next time we get a stat -- use this as the format
								local cur_format "`cur_var'"
								// level 6 closing
							} 
							// level 5 -- not a formatting command -- else statement
							else { 
								display "Stat in the middle of a group of stats!"
								// check for commas, which will set the option flag.
								// level 6 -- if statement - includes a comma
								if regexm(`"`cur_var'"' /* " */, "(.*),") { 
									display as text "stat with comma. Setting option flag."
									// local option_list `"`option_list' ""' // Opening Quote Mark
									/*
										This section should deal properly with the
										case where there is just a comma on its own.
										It just drops an empty string into cur_var,
										and sets the option flag.
									*/
									local cur_var = regexs(1) // strip the comma
									local option_flag = 1
									// level 6 closing
								} 
								// add the stat to the statgroup macro
								local statgroup "`cur_var'"
								local formatgroup "`cur_format'"
								// display _newline as text "Statgroup: " as result "`statgroup'"
								// display as text "Format Group: " as result "`formatgroup'"
								// level 5 closing
							} 
							// level 4 closing
						}
						// level 3 closing
					}
					// level 4 -- else statement -- item does not match para opening
					else {
						// level 5 -- if statement -- option flag is set
						if `option_flag'==1 { 
							display "Option flag on, adding options to group of stats"
							/* 
								If the option flag is on, we are now adding 
								options to the option list.
								
								If the options contain (, then we have to make sure
								we don't close the thingy.
							*/
							// level 6 -- if statement -- contains option argument in ()?
							if regexm(`"`cur_var'"' /* " */, "(.+\(.*\))") { 
								display as text "Option with argument detected."
								local temp_cur_var = regexs(1)
								/* 
									Was there a closing parenthsis at the end
								*/
								// level 7 - if statement -- two closing paras detected
								if regexm(`"`cur_var'"' /* " */, "\)[ ]*\)") { 
									display as text "Two closing parenthsis detected because of option"
									local open_para = 0
									local option_flag = 0
									// level 8 - if statement - trimming an extra )
									if regexm(`"`cur_var'"' /* " */, "(.+\(*.\))\)") { 
										local temp_cur_var = regexs(1)
										// level 8 closing
									} 
									// level 7 closing
								} 
								local cur_var `"`temp_cur_var'"'	/* " */
								// level 6 closing
							} 
							// level 6 -- else statement -- does not contaion option argument
							else { 
								// level 7 -- if statement -- closing para found
								if regexm(`"`cur_var'"' /* " */, "(.+)[ ]*\)$") { 
									display as text "Closing parenthsis found with option"
									/*
										If there is a closing parenthsis, we
										are done.
									*/
									local cur_var = regexs(1)
									// level 8 -- para not open
									if `open_para'==0 { 
										// no para open
										error 198
										// level 8 closing
									} 
									// level 8 -- para is open
									else { 
										local open_para = 0
										local option_flag = 0
										// local option_list `"`option_list'""' // Closing Quote Mark
										// level 8 closing
									} 
									// level 7 closing
								}
								// level 6 closing
							} 
							local option_list `"`option_list' `cur_var'"'	/* " */
							// level 5 closing
						} 
						// level 5 -- else statement -- option flag not set 
						else { 
							// level 6 -- if statement -- matches closing para
							if regexm(`"`cur_var'"' /* " */,"([a-z][a-z0-9]*)[ ]*\)$") { // closing para for set of stats
								display "Closing parenthsis for group of stats with no options"
								local cur_var = regexs(1) // strip the para
								// level 7 -- if statement -- no para open
								if `open_para'==0 { 
									// no para open
									error 198
									// closing level 7
								}
								// level 7 -- else statement -- para is open
								else { 
									local open_para = 0 // close the para
									local option_flag = 0 // no more options either
									local statgroup "`statgroup' `cur_var'"
									local formatgroup "`formatgroup' `cur_format'"
									// level 7 closing
								} 
								// level 6 closing
							} 
							// level 6 -- else statement -- doesn't match closing para
							else { 
								// level 7 -- if statement -- para is open
								if `open_para'==1 { // Open paraenthesis -- not a formatting code
									display "Open parenthesis, not adding options (yet)"
									/*
										If there is an open parenthesis, we have to check to
										see if there are options involved
									*/
									// check for commas, which will set the option flag.
									// level 8 -- if statement -- comma check
									if regexm(`"`cur_var'"' /* " */, "(.*),") { 
										display as text "Comma found at the end. Setting option flag"
										// local option_list `"`option_list' ""' // Opening Quote Mark
										/*
											This section should deal properly with the
											case where there is just a comma on its own.
											It just drops an empty string into cur_var,
											and sets the option flag.
										*/
										local cur_var = regexs(1) // strip the comma
										local option_flag = 1
										// level 8 closing
									} 
									// level 8 -- else statement -- no comma
									else { 
										display as text "No comma found at the end"
										/*
											If the comma is at the beginning of the
											thingy, we basically have an option
											in cur_var
										*/
										// level 9 -- if statement -- comma at beginning
										if regexm(`"`cur_var'"' /* " */, ",(.*)") { 
											display as text "Comma found at the beginning"
											local option_flag = 1
											// local option_list `"`option_list' ""' // Opening Quote Mark
											local cur_var = ""
											local option_list = regex(1)
											// level 9 closing
										} 
										// level 8 closing
									} 
									/* 
										If we just have a comma on it's on, all we
										want it to do is set the option flag, and
										not add anything to the statgroup or
										formatgroup macros.
									*/
									// level 8 -- if statement -- cur var not empty
									if `"`cur_var'"' /* " */ !=`""' { 
										local statgroup "`statgroup' `cur_var'"
										local formatgroup "`formatgroup' `cur_format'"
										// level 8 closing
									} 
									// level 8 -- if statement -- is verbose on?
									if "`verbose'"=="verbose" { 
										display _newline as text "Statgroup: " as result "`statgroup'"
										display as text "Format Group: " as result "`formatgroup'"
										// level 8 closing
									} 
									// level 7 closing
								} 
								// level 7 -- else statement -- para is not open
								else { // if it's a variable
									display "Variable or list of variables"
									/* 
										Check to see if it's actually a varlist.
									*/
									unab expandlist : `cur_var'
									// level 8 -- foreach statement -- loop through varlist
									foreach indiv_var of varlist `expandlist' { 
										// level 9 -- if statement -- group not defined
										if "`statgroup'" == "" { // no group/set of stats defined
											local myvarlist "`myvarlist' `indiv_var'"
											local mystatlist "`mystatlist' `cur_stat'"
											local myformatlist "`myformatlist' `cur_format'"
											local myoptionlist `"`myoptionlist' `"`option_list'${optdelimit}"'"' /* " */
											// level 9 closing
										} 
										// level 9 -- else statement -- group defined
										else { 
											// level 10 - foreach statement -- loop through statgroup
											foreach i of local statgroup { 
												local myvarlist "`myvarlist' `indiv_var'"
												local myoptionlist `"`myoptionlist' `"`option_list'${optdelimit}"'"' /* " */
												// level 10 closing
											} 
											local mystatlist "`mystatlist' `statgroup'"
											local myformatlist "`myformatlist' `formatgroup'"
											// level 9 closing
										} 
										// level 8 closing
									} 
									// level 7 closing
								} 
								// level 6 closing
							}
							// level 5 closing
						} 
						// level 4 closing
					}
					// level 3 closing
				}
				// level 2 closing
			}
			// level 1 closing
		}
		
		if "`verbose'"=="verbose" { 
			display _newline as text "Submiting to super_table program:" _newline _newline
			display as text "Variables: " as result "`myvarlist'" as text "."
			display as text "Stats: " as result "`mystatlist'" as text "."
			display as text "Formats: " as result "`myformatlist'" as text "."
			display as text "Options: " as result `"`myoptionlist'"' /* " */ as text "."
		} 
		
		// file open myfile `using', write all `append' `replace'
		// if "`title'"!="" { 
		//	file write myfile "`title'" _newline _newline
		// } 
		// file close myfile
		
		/*
			if "`flip'"=="flip" { 
				// the xover command is not used with flipped tables
				local xover ""
			}
		*/
		super_table `myvarlist' `using' if `touse' [`weight'`exp'], statlist( `mystatlist' ) formatlist( `myformatlist' ) optionlist( `"`myoptionlist'"' /* " */ )  over( `over' ) subgroup( `subgroup' ) `allsgroup' append `flip' `header' `missing' `allcol' `allrow' title("`title'") notes("`notes'") `atomize' `xover' `xoverall' `rowtitle' stderrleft("`stderrleft'") stderrright("`stderrright'") `stderrposition' `showtotal'
	} 
	
	if "`backup'"=="" { 
		capture erase `backupfile'
	} 
	
	macshellout `using', `openfile'
end

/*
	Program Name: super_table
	Function: This was the original program, and I added stbl as an interface to this program.
	
	Note: If we do end up passing a list of options to this program, to allow for custom options
	per variable, we need to actually have the options be surrounded by double quotes. Several
	of our options take strings.
*/
capture program drop super_table
program super_table
	syntax varlist using [if] [in] [pweight], STATlist(string) FORMatlist(string) [OPTIONLIST(string)] [over(varlist) SUBGRoup(varlist) ALLSGroup] [ROUND(passthru) STANDARDERRor STDERRPOSition(string) APPend REPLace FLIP noHEADer MISSing ALLCol noALLRow] [REGEX(passthru) RXREPLACEment(passthru)] [title(string) rowtitle(string) notes(string)] [SHOWTOTal] [ATOMize] [XOVER(passthru) XOVERAll] [STDERRLEFT(passthru) STDERRRIGHT(passthru)]
	marksample touse, novarlist
	tempvar all
	generate `all' = 1
	label define all 1 "All", modify
	label values `all' all
	
	local num_varlist : word count `varlist'
	local num_statlist : word count `statlist'
	local num_formatlist : word count `formatlist'
	// local num_optionlist : word count `optionlist'
	
	local match `optionlist'
	local num_optionlist = 0
	while regexm(`"`match'"' /* " */, "(.*)${optdelimit}") { 
		local ++num_optionlist
		local match = regexs(1)
	} 
	
	if `num_varlist' != `num_statlist' { 
		display as error "Variables and Statistics Requested Don't Match!!"
		exit
	} 
	if `num_varlist' != `num_formatlist' { 
		display as error "Variables and Formats Don't match!!"
		exit
	} 
	
	display as text "`num_varlist' variables: " as result "`varlist'" as text "."
	display as text "`num_statlist' stats: " as result "`statlist'" as text "."
	display as text "`num_formatlist' formats: " as result "`formatlist'" as text "."
	display as text "`num_optionlist' options: " as result `"`optionlist'"' /* " */ as text "."
	
	if "`flip'"=="flip" { 
		if "`stderrposition'" == "" { 
			local stderrposition "below"
		} 
		if "`over'" == "" { 
			local over "`all'"
		} 
		else { 
			if "`allcol'"=="allcol" { 
				local over "`all' `over'"
			} 
		} 
		local headerstats ""
		foreach i of local over { 
			local headerstats "`headerstats' proportion"
		} 
		createdir `using'
		local subtabledir "`r(dirname)'"
		local originalfile "`r(filename)'"
		local flipped_filelist ""
		if "`header'"=="" { 
			// We never pass showtotal to big_header when the table is flipped.
			// big_header `over' `using' if `touse' [`weight'`exp'], statlist(`headerstats') `standarderror' `append' `replace' subgroup(`subgroup') `allsgroup'
			// local myst "showtotal"
			// local fixed_optionlist : list optionlist - myst
			// local fixed_optionlist = regexr(`"`optionlist'"' /* " */, "showtotal", "")
			uniquefilename using "`subtabledir'V_HEADER.txt"
			local tableoutputfilename "`r(filename)'"
			if "`title'" != "" { 
				file open myfile using "`tableoutputfilename'", write all replace
				file write myfile "`title'" _newline
				file close myfile
			} 
			big_header `over' using "`tableoutputfilename'" if `touse' [`weight'`exp'], statlist(`headerstats') `standarderror' stderrposition("`stderrposition'") append subgroup(`subgroup') `allsgroup' optionlist( `"`optionlist'"' /* " */) `xover' `xoverall'
			local flipped_filelist `"`flipped_filelist' "`tableoutputfilename'""'	/* " */
		} 
		else { 
			if "`title'" != "" { 
				uniquefilename using "`subtabledir'V_TITLE.txt"
				local tableoutputfilename "`r(filename)'"
				file open myfile using "`tableoutputfilename'", write all append
				file write myfile "`title'" _newline
				file close myfile
				local flipped_filelist `"`flipped_filelist' "`tableoutputfilename'""'	/* " */
			} 
		} 
		
		/*
			For flipped tables, this is the central loop that the program goes through. It will
			actualy generate all the different tables that were originally submitted to stbl.
			
			For the purposes of breaking this up into separate files -- each loop through this
			could be considered it's own table.
		*/
		tokenize `"`optionlist'"' /* " */, parse("${optdelimit}")
		forvalues i = 1/`num_varlist' { 
			local myvar : word `i' of `varlist'
			local mystat : word `i' of `statlist'
			local myformat : word `i' of `formatlist'
			// local myoptionlist : word `i' of `optionlist'
			// If default is specified, pass a blank myoptionlist
			// if `"`myoptionlist'"' /* " */ == `"default"' { 
			//	local myoptionlist ""
			// } 
			local myoptionlist ``i''
			local catlbl : variable label `myvar'
			/*
				Ensure we have a unique filename for the table.
			*/
			uniquefilename using "`subtabledir'V`myvar'_`mystat'.txt"
			local tableoutputfilename "`r(filename)'"
			// file open myfile `using', write text append all
			file open myfile using "`tableoutputfilename'", write text replace all
			file write myfile _newline "`catlbl' (`myvar')"
			if "`mystat'"=="proportion" | "`mystat'"=="obs" { 
				file write myfile " `mystat'" _newline
			}
			file close myfile
			
			// big_row `myvar' `using' if `touse' [`weight'`exp'], statlist(`mystat') formatlist(`myformat') name("`catlbl'") `round' `standarderror' over(`over') subgroup(`subgroup') `allsgroup' `missing' `regex' `rxreplacement' flip `showtotal'
			if "`rowtitle'"=="" { 
				big_row `myvar' using "`tableoutputfilename'" if `touse' [`weight'`exp'], statlist(`mystat') formatlist(`myformat') name("`catlbl'") `round' `standarderror' over(`over') subgroup(`subgroup') `allsgroup' `missing' `regex' `rxreplacement' flip append `showtotal' optionlist( `"`myoptionlist'"' /* " */ ) stderrposition("`stderrposition'") `stderrleft' `stderrright' `xover' `xoverall'
			} 
			else { 
				big_row `myvar' using "`tableoutputfilename'" if `touse' [`weight'`exp'], statlist(`mystat') formatlist(`myformat') name(`rowtitle') name2("`catlbl'") `round' `standarderror' over(`over') subgroup(`subgroup') `allsgroup' `missing' `regex' `rxreplacement' flip append `showtotal' optionlist( `"`myoptionlist'"' /* " */ ) stderrposition("`stderrposition'") `stderrleft' `stderrright' `xover' `xoverall'
			} 
			local flipped_filelist `"`flipped_filelist' "`tableoutputfilename'""'	/* " */
		} 
		local firstfile ""
		capture confirm file `originalfile'
		if _rc==0 & "`append'"=="append" { 
			local firstfile "`originalfile'"
		} 
		inccat `firstfile' `flipped_filelist', to(`originalfile') replace
		uniquefilename using "`subtabledir'filelist.txt"
		local filelistfilename "`r(filename)'"
		file open myfile using "`filelistfilename'", write all replace
		foreach l of local flipped_filelist { 
			file write myfile `"`l'"' /* " */ _newline
		} 
		file close myfile
	}
	else { 
		/*
			Non Flipped tables -- to generate separate tables, we can't really use the stbl
			command recursively. Instead, we probably have to run this command recursively.
		*/
		if "`stderrposition'"=="" { 
			local stderrposition "right"
		} 
		if "`atomize'"=="atomize" { 
			// Atomized non flipped table -- loop through the varlist, statlist and formatlist.
			createdir `using'
			local subtabledir "`r(dirname)'"
			local originalfile "`r(filename)'"
			local nonflipped_atom_filelist ""
			// local myappend_replace "`append' `replace'"
			tokenize `"`optionlist'"' /* " */, parse("${optdelimit}")
			forvalues ai = 1/`num_varlist' { 
				local a_myvar : word `ai' of `varlist'
				local a_mystat : word `ai' of `statlist'
				local a_myformat : word `ai' of `formatlist'
				// local a_myoption : word `ai' of `optionlist'
				local a_myoption ``ai''
				uniquefilename using "`subtabledir'V`a_myvar'_`a_mystat'.txt"
				local tableoutputfilename "`r(filename)'"
				// super_table `a_myvar' `using' `if' `in' [`weight'`exp'], over(`over') subgroup(`subgroup') `allsgroup' statlist(`a_mystat') formatlist(`a_myformat') `round' `standarderror' `myappend_replace' `noheader' `missing' `allcol' `noallrow' `regex' `rxreplacement' notes(`notes') `showtotal'
				super_table `a_myvar' using "`tableoutputfilename'" `if' `in' [`weight'`exp'], over(`over') subgroup(`subgroup') `allsgroup' statlist(`a_mystat') formatlist(`a_myformat') optionlist( `"`a_myoption'"' /* " */ ) replace `noheader' `missing' `allcol' `noallrow' rowtitle(`rowtitle') notes(`notes') `xover' `xoverall' `stderrleft' `stderrright' stderrposition("`stderrposition'")
				// local myappend_replace "append"
				local nonflipped_atom_filelist `"`nonflipped_atom_filelist' "`tableoutputfilename'""'	/* " */
			} 
			local firstfile ""
			capture confirm file `originalfile'
			if _rc==0 & "`append'"=="append" { 
				local firstfile "`originalfile'"
			}
			inccat `firstfile' `nonflipped_atom_filelist', to(`originalfile') replace
		} 
		else { 
			// Not atomized
			/*	
				To split up these tables into their individual components, we basically need to create
				one file per over and subgroup variable.
			*/
			createdir `using'
			local subtabledir "`r(dirname)'"
			local originalfile "`r(filename)'"
			local nonflipped_nonatomized_filelist ""
			if "`header'"=="" { 
				/*
					We pass the showtotal option to the header when creating non-flipped tables.
					The header changes for those, but not for others.
				*/
				// big_header `varlist' `using' if `touse' [`weight'`exp'], statlist(`statlist') `standarderror' `append' `replace' `showtotal'
				uniquefilename using "`subtabledir'O_HEADER.txt"
				local tableoutputfilename "`r(filename)'"
				if "`title'" != "" { 
					file open myfile using "`tableoutputfilename'", write all replace
					file write myfile "`title'" _newline /* _newline */
					file close myfile
				} 
				big_header `varlist' using "`tableoutputfilename'" if `touse' [`weight'`exp'], statlist(`statlist') append `xover' `xoverall' optionlist( `"`optionlist'"' /* " */) stderrposition("`stderrposition'")
				local nonflipped_nonatomized_filelist `"`nonflipped_nonatomized_filelist' "`tableoutputfilename'""'	/* " */
			} 
			else { 
				if "`title'" != "" { 
					uniquefilename using "`subtabledir'O_TITLE.txt"
					local tableoutputfilename "`r(filename)'"
					file open myfile using "`tableoutputfilename'", write all append
					file write myfile "`title'" _newline /* _newline */
					file close myfile
					local nonflipped_nonatomized_filelist `"`nonflipped_nonatomized_filelist' "`tableoutputfilename'""'	/* " */
				} 
			} 
			if "`allrow'"=="" { 
				// big_row `varlist' `using' if `touse' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("All") `round' `standarderror' `missing' `regex' `rxreplacement' append `showtotal'
				uniquefilename using "`subtabledir'O_ALLROW.txt"
				local tableoutputfilename "`r(filename)'"
				if "`rowtitle'"=="" { 
					big_row `varlist' using "`tableoutputfilename'"  if `touse' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("All") `missing' `regex' replace `xover' `xoverall' optionlist( `"`optionlist'"' /* " */ ) `stderrleft' `stderrright' stderrposition("`stderrposition'")
				} 
				else { 
					big_row `varlist' using "`tableoutputfilename'"  if `touse' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`rowtitle'") name2("All") `missing' `regex' replace `xover' `xoverall' optionlist( `"`optionlist'"' /* " */ ) `stderrleft' `stderrright' stderrposition("`stderrposition'")
				} 
				local nonflipped_nonatomized_filelist `"`nonflipped_nonatomized_filelist' "`tableoutputfilename'""'	/* " */
			} 
			if "`over'" != "" { 
				if "`subgroup'" == "" { 
					foreach i of varlist `over' { 
						local catlbl : variable label `i'
						// file open myfile `using', write text append all
						uniquefilename using "`subtabledir'O_`i'.txt"
						local tableoutputfilename "`r(filename)'"
						file open myfile using "`tableoutputfilename'", write text replace all
						file write myfile _newline "`catlbl' (`i')" _newline
						file close myfile
						quietly levelsof `i' if `touse', local(mycats)
						local realformat : format `i'
						// display _n as text "Variable: " as result "`i'" as text " Format: " as result "`realformat'"
						foreach j of local mycats { 
							local mycatlbl : label (`i') `j'
							if substr("`realformat'",1,2) == "%t" { 
								local mycatlbl : display `realformat' `j'
							} 
							// big_row `varlist' `using' if `touse' & `i'==`j' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'") `round' `standarderror' `regex' `rxreplacement' append `showtotal'
							if "`rowtitle'"=="" { 
								big_row `varlist' using "`tableoutputfilename'" if `touse' & `i'==`j' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'")  append `xover' `xoverall' optionlist( `"`optionlist'"' /* " */) `stderrleft' `stderrright' stderrposition("`stderrposition'")
							} 
							else { 
								big_row `varlist' using "`tableoutputfilename'" if `touse' & `i'==`j' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`rowtitle'") name2("`mycatlbl'")  append `xover' `xoverall' optionlist( `"`optionlist'"' /* " */) `stderrleft' `stderrright' stderrposition("`stderrposition'")
							} 
						}
						local nonflipped_nonatomized_filelist `"`nonflipped_nonatomized_filelist' "`tableoutputfilename'""'	/* " */
					}
				}
				else { 
					foreach i of varlist `over' { 
						local catlbl : variable label `i'
						// file open myfile `using', write text append all
						uniquefilename using "`subtabledir'O_`i'.txt"
						local tableoutputfilename "`r(filename)'"
						file open myfile using "`tableoutputfilename'", write text replace all
						file write myfile _newline "`catlbl' (`i')" _newline
						file close myfile
						quietly levelsof `i' if `touse', local(mycats)
						local realformat : format `i'
						// display _n as text "Variable: " as result "`i'" as text " Format: " as result "`realformat'"
						foreach j of local mycats { 
							local mycatlbl : label (`i') `j'
							if substr("`realformat'",1,2) == "%t" { 
								local mycatlbl : display `realformat' `j'
							} 
							if "`allsgroup'"=="allsgroup" { 
								// big_row `varlist' `using' if `touse' & `i'==`j' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'") name2("All") `round' `standarderror' `regex' `rxreplacement' append `showtotal'
								big_row `varlist' using "`tableoutputfilename'" if `touse' & `i'==`j' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'") name2("All") append `xover' `xoverall' optionlist( `"`optionlist'"' /* " */) `stderrleft' `stderrright' stderrposition("`stderrposition'")
							} 
							foreach k of varlist `subgroup' { 
								if "`k'" != "`i'" {		// As long as they are different variables, we can subgroup!!
									quietly levelsof `k' if `touse', local(mysubcats)
									foreach l of local mysubcats { 
										local mysubcatlbl : label (`k') `l'
										// big_row `varlist' `using' if `touse' & `i'==`j' & `k'==`l' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'") name2("`mysubcatlbl'") `round' `regex' `rxreplacement' append `standarderror' `showtotal'
										big_row `varlist' using "`tableoutputfilename'" if `touse' & `i'==`j' & `k'==`l' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'") name2("`mysubcatlbl'") append `xover' `xoverall' optionlist( `"`optionlist'"' /* " */) `stderrleft' `stderrright' stderrposition("`stderrposition'")
									} 
								} 
								else { 
									if "`allsgroup'"=="" {
										// big_row `varlist' `using' if `touse' & `i'==`j' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'") `round' `regex' `rxreplacement' append `standarderror' `showtotal'
										big_row `varlist' using "`tableoutputfilename'" if `touse' & `i'==`j' [`weight'`exp'], statlist(`statlist') formatlist(`formatlist') name("`mycatlbl'") append `xover' `xoverall' optionlist( `"`optionlist'"' /* " */) `stderrleft' `stderrright' stderrposition("`stderrposition'")
									} 
								}
							} 	
						}
						local nonflipped_nonatomized_filelist `"`nonflipped_nonatomized_filelist' "`tableoutputfilename'""'	/* " */
					}
				}
			} 
			local firstfile ""
			capture confirm file `originalfile'
			if _rc==0 & "`append'"=="append" { 
				local firstfile "`originalfile'"
			} 
			inccat `firstfile' `nonflipped_nonatomized_filelist', to(`originalfile') replace
			uniquefilename using "`subtabledir'filelist.txt"
			local filelistfilename "`r(filename)'"
			file open myfile using "`filelistfilename'", write all replace
			foreach l of local nonflipped_nonatomized_filelist { 
				file write myfile `"`l'"' /* " */ _newline
			} 
			file close myfile
		} 
	}
	if "`atomize'"=="" { 
		// file open myfile `using', write text append all
		if `"`notes'"'!=`""'	/* " */ { 
			file open myfile `using', write text append all
			file write myfile /* _newline */ `"`notes'"'	/* " */ _newline
			file close myfile
		} 
		// file write myfile _newline _newline
		// file close myfile
	} 
end


capture program drop big_header
program big_header, rclass
	syntax varlist using [if] [in] [pweight], STATlist(namelist) OPTIONList(string) [APPend REPLace] [allover SUBGRoup(varlist) allsgroup] [STANDARDERRor STDERRPOSition(passthru)] [SHOWTOTal] [XOVER(varlist) XOVERAll noNAMEROW noWRITETOfile] [MISSing] [*]
	marksample touse, novarlist
	tempvar all
	generate `all' = 1
	label define all 1 "All", modify
	label values `all' all
	
	display _newline as text "Header Program"
	display as text "Variables: " as result "`varlist'"
	display as text "Stats: " as result "`statlist'"
	display as text "Options: " as result `"`optionlist'"' /* " */
	
	local minlines = 1
	local maxlines = 4
	if "`xover'"!="" { 
		/* 
			X-over command used, which will recurse the header over the variables in the varlist.
		*/
		local minlines = 0
		local hline0 `""Xover" _tab _tab"'
		local hline1 `""Variable" _tab _tab"'
		local hline2 `""Label" _tab _tab"'
		local hline3 `""Catagories Statistics" _tab _tab"'
		local hline4 `""Subgroups" _tab _tab"'
		/*
			loop through the variables, then the categories of those variables.
		*/
		foreach xover_i of varlist `xover' { 
			local hline0 `"`hline0' "`xover_i': ""'	/* " */
			quietly levelsof `xover_i' if `touse', local(myxovercats)
			local realformat : format `xover_i'
// 			if "`xoverall'"=="xoverall" { 
// 				local hline0 `"`hline0' "All""'	/* " */
// 				big_header `varlist' `using' if `touse' [`weight'`exp'], statlist(`statlist') optionlist( `"`optionlist'"' /* " */) `append' `replace' `allover' subgroup(`subgroup') `allsgroup' `standarderror' `stderrposition' `showtotal' `missing' nonamerow nowritetofile
// 				forvalues xover_k = 0/4 { 
// 					local hline`xover_k' `"`hline`xover_k'' `r(l`xover_k')'"'	/* " */
// 				} 
// 			} 
			foreach xover_j of local myxovercats { 
				local mycatlbl : label (`xover_i') `xover_j'
				if substr("`realformat'",1,2) == "%t" { 
					local mycatlbl : display `realformat' `j'
				} 
				local hline0 `"`hline0' "`mycatlbl'""'	/* " */
				big_header `varlist' `using' if `touse' & `xover_i'==`xover_j' [`weight'`exp'], statlist(`statlist') optionlist( `"`optionlist'"' /* " */) `append' `replace' `allover' subgroup(`subgroup') `allsgroup' `standarderror' `stderrposition' `showtotal' `missing' nonamerow nowritetofile
				forvalues xover_k = 0/4 { 
					local hline`xover_k' `"`hline`xover_k'' `r(l`xover_k')'"'	/* " */
				} 
			} 
		} 
	} 
	else { 
		if "`subgroup'"=="" { 
			local subgroup "`all'"
			local maxlines = 3
		}
		else { 
			local maxlines = 4
		} 
		
		local rate 0 
		// local hline1 "_char(9) _char(9)"
		// local hline2 "_char(9) _char(9)"
		// local hline3 "_char(9) _char(9)"
		// local hline4 "_tab _tab"
		if "`namerow'"!="nonamerow" { 
			local hline0 `"_tab _tab"'
			local hline1 `""Variable" _tab _tab"'
			local hline2 `""Label" _tab _tab"'
			local hline3 `""Catagories Statistics" _tab _tab"'
			local hline4 `""Subgroups" _tab _tab"'
		} 
		
		local option_word_count = 1
		while "`varlist'" != "" { 
			tokenize `varlist'
			local cur_var `1'
			macro shift
			local varlist `*'
			tokenize `statlist'
			local cur_stat `1'
			macro shift
			local statlist `*'
			// local optionlist : list clean optionlist
			display _newline as text "Cleaned Option List: " as result `"`optionlist'"'	/* " */
			tokenize `"`optionlist'"'	/* " */, parse("${optdelimit}")
			// local cur_option : word `option_word_count' of `optionlist'
			local cur_option ``option_word_count''
			display as text "Word " as result "`option_word_count'" as text " of the optionlist is " as result `"`cur_option'"' /* " */ as text "."
			// local optionlist `"`*'"'	/* " */
			// local optionlist `*'
			local ++option_word_count
			
			local cur_varl : variable label `cur_var'
			
			display _newline _newline as text "Variable: " as result "`cur_var'"
			display as text "Variable Label: " as result "`cur_varl'"
			display as text "Stat: " as result "`cur_stat'"
			display as text "Options: " as result `"`cur_option'"' /* " */
			
			if "`cur_stat'"=="percent" { 
				local cur_stat "mean"
				local percent "percent"
			} 
			else {
				local percent ""
			} 
			if "`cur_stat'"=="round" { 
				local cur_stat "mean"
			} 
			
			if "`cur_stat'"=="change" { 
				local cur_stat "mean"
			} 
			
			// The obs stat uses the proportion header to display all the categories.
			if "`cur_stat'"=="obs" {
				local cur_stat "proportion"
			}
			
			// Percentile
			local pctile_num ""
			if substr("`cur_stat'",1,6)=="pctile" { 
				local pctile_num = substr("`cur_stat'",7,.)
				local pctile_num = real("`pctile_num'")
				local pctile_num = "pctile_num(`pctile_num')"
				local cur_stat "pctile"
			} 
			
			display _newline as text "Variable Name: " as result "`cur_var'"
			display as text "Variable Label: " as result "`cur_varl'"
			display as text "Statistic to Generate: " as result "`cur_stat'"
			display as text "Options Applied: " as result `"`cur_option'"' /* " */
			
			`cur_stat'_header `cur_var' if `touse', `percent' rate(`rate') `allover' subgroup(`subgroup') `allsgroup' `pctile_num' `cur_option' `stderrposition' `missing'
			local rate `r(rate)' 
			forvalues i = 0/4 { 
				local hline`i' `"`hline`i'' `r(l`i')'"' /* " */
			} 
		} 
	} 
	
	if "`writetofile'"!="nowritetofile" { 
		capture file close myfile
		file open myfile `using', write text `append' `replace' all
		forvalues i = `minlines'/`maxlines' { 
			file write myfile `hline`i'' /* " */ _newline
		} 
		file write myfile _newline
		file close myfile
	} 
	else { 
		forvalues i = 0/4 { 
			return local l`i' `"`hline`i''"'	/* " */
		} 
	} 
end 

capture program drop big_row
program big_row, rclass
	syntax varlist using [if] [in] [pweight], STATlist(namelist) OPTIONList(string) name(string) [NAME2(string)] FORMatlist(string) [ROUND(passthru) STANDARDERRor STDERRPOSition(string) OVER(passthru)] [SUBGRoup(passthru) allsgroup] [MISSing] [REGEX(passthru) RXREPLACEment(passthru)] [FLIP] [APPend REPLace] [SHOWTOTal] [XOVER(varlist) XOVERAll noNAMEROW noWRITETOfile] [STDERRLEFT(passthru) STDERRRIGHT(passthru)] [*]
	marksample touse, novarlist
// 	tempvar all
// 	generate `all' = 1
// 	
// 	if "`over'"=="" { 
// 		local over "`all'"
// 	} 

	// local showstderrors "standarderror"
	// local showstderrors : list showstderrors in optionlist
	display _newline as text "Checking for " as result "standarderror" as text "option in the option list."
	display as text "Option List: " as result `"`optionlist'"'	/* " */
	
	local showstderrors = regexm(`"`optionlist'"'	/* " */, "standarderror")

	display _newline as text "Row Program"
	display as text "Variables: " as result "`varlist'"
	display as text "Stats: " as result "`statlist'"
	display as text "Formats: " as result "`formatlist'"
	display as text "Options: " as result `"`optionlist'"' /* " */
	display as text "Display Standard Errors: " as result "`showstderrors'" as text "."
	display as text "Show Total Option: " as result "`showtotal'" as text "."
	

	if "`xover'"!="" { 
		/* 
			X-over command used, which will recurse the header over the variables in the varlist.
			loop through the variables, then the categories of those variables.
		*/
		local mynonamerow ""
		foreach xover_i of varlist `xover' { 
			quietly levelsof `xover_i' if `touse', local(myxovercats)
			local realformat : format `xover_i'
			// local mynonamerow ""
// 			if "`xoverall'"=="xoverall" { 
// 				big_row `varlist' `using' if `touse' [`weight'`exp'], statlist(`statlist') name("`name'") name2("`name2'") formatlist(`formatlist') optionlist( `"`optionlist'"' /* " */) stderrposition("`stderrposition'") `over' `subgroup' `allsgroup' `missing' `regex' `rxreplacement' `append' `replace' `mynonamerow' nowritetofile `stderrleft' `stderrright' `showtotal'
// 				local lines `r(lines)'
// 				forvalues xover_k = 0/`lines' { 
// 					local rowline`xover_k' `"`rowline`xover_k'' `r(l`xover_k')'"'	/* " */
// 				} 
// 				local mynonamerow "nonamerow"
// 			} 
			foreach xover_j of local myxovercats { 
				big_row `varlist' `using' if `touse' & `xover_i'==`xover_j' [`weight'`exp'], statlist(`statlist') name("`name'") name2("`name2'") formatlist(`formatlist') optionlist( `"`optionlist'"' /* " */) stderrposition("`stderrposition'") `over' `subgroup' `allsgroup' `missing' `regex' `rxreplacement' `append' `replace' `mynonamerow' nowritetofile `stderrleft' `stderrright' `showtotal'
				local lines `r(lines)'
				forvalues xover_k = 0/`lines' { 
					local rowline`xover_k' `"`rowline`xover_k'' `r(l`xover_k')'"'	/* " */
				} 
				local mynonamerow "nonamerow"
			} 
		} 
		// Add in any Standard Errors
		// if "`stderrposition'"=="below" & "`showstderrors'"=="1" { 
		// 	forvalues i = 2(2)`lines' { 
		// 		local rowline`i' `""Standard Errors" _tab _tab `rowline`i''"'	/* " */
		// 	} 
		// } 
	} 
	else { 
		local rate 0
		local previous 0
		local PRINT_STANDARDERR_TITLE = 0
		if "`namerow'"!="nonamerow" { 
			if "`name'"!="" { 
				local rowline1 `""`name'" _tab "`name2'" _tab"'
				if "`stderrposition'"=="below" & "`showstderrors'"=="1" { 
					local PRINT_STANDARDERR_TITLE = 1
				} 
			} 
			else { 
				local rowline1 `""'
				
			} 
		} 
		
		local option_word_count = 1
		while "`varlist'" != "" { 
			tokenize `varlist'
			local cur_var `1'
			macro shift
			local varlist `*'
			tokenize `statlist'
			local cur_stat `1'
			macro shift
			local statlist `*'
			tokenize `formatlist'
			local cur_format `1'
			macro shift
			local formatlist `*'
			// local optionlist : list clean optionlist
			display _newline as text "Cleaned Option List: " as result `"`optionlist'"'	/* " */
			tokenize `"`optionlist'"'	/* " */, parse("${optdelimit}")
			// local cur_option : word `option_word_count' of `optionlist'
			local cur_option ``option_word_count''
			display as text "Word " as result "`option_word_count'" as text " of the optionlist is " as result `"`cur_option'"' /* " */ as text "."
			// local cur_option : list clean cur_option
			// macro shift
			// local optionlist `"`*'"'	/* " */
			local ++option_word_count
			
			local cur_varl : variable label `cur_var'
			
			display _newline _newline as text "Variable: " as result "`cur_var'"
			display as text "Variable Label: " as result "`cur_varl'"
			display as text "Stat: " as result "`cur_stat'"
			display as text "Format: " as result "`cur_format'"
			display as text "Options: " as result `"`cur_option'"' /* " */
			
			if "`cur_stat'"=="percent" { 
				local cur_stat "mean"
				local percent "percent"
			} 
			else {
				local percent ""
			} 
			/*
				Round will only affect round and mean for now.
			*/
			// if "`cur_stat'"=="round" | "`cur_stat'"=="mean" { 
			// 	local cur_stat "mean"
			// 	local roundopt `round'
			// } 
			// else { 
			//	/*
			//		All I need to do to setup the new rounding is to
			//		actually pass the rounding option at all times.
			//		
			//		If I want to round other things, just put in
			//		local roundopt "`round'"
			//	*/
			//	local roundopt ""
			// }
			// if "`cur_stat'"=="mean" { 
			// 	local standarderroropt "`standarderror'"
			// } 
			// else { 
			//	local standarderroropt ""
			// } 
			if "`over'"!="" {
				if "`cur_stat'"!="proportion" & "`cur_stat'"!="obs" { 
					local rowline1 `"_tab _tab"'
				} 
				else { 
					local rowline1 `""'
				} 
			} 
			
			// Percentile
			local pctile_num ""
			if substr("`cur_stat'",1,6)=="pctile" { 
				local pctile_num = substr("`cur_stat'",7,.)
				local pctile_num = real("`pctile_num'")
				local pctile_num = "pctile_num(`pctile_num')"
				local cur_stat "pctile"
			} 
			
			if "`rate'"=="" { 
				local rate 0 
				local previous 0
			} 
			`cur_stat'_row `cur_var' if `touse' [`weight'`exp'], format("`cur_format'") `percent' rate(`rate') previous(`previous') stderrposition("`stderrposition'") `over' `subgroup' `allsgroup' `missing' `pctile_num' `flip' `cur_option' `stderrleft' `stderrright' `showtotal'
			local rate `r(rate)'
			local previous `r(previous)'
			local lines `r(lines)'
			
			/* 
				If the standard errors are below the stat, then the last line will be
				standard errors. Label it. BUT ONLY IF WE ARE DOING A NAMEROW????
				nonamerow = no row name needs to be generated.
			*/
			if `PRINT_STANDARDERR_TITLE'==1  { 
				/*
					If standard errors are being generated, we want to
					put the title on EVERY SECOND LINE!
				*/
				forvalues i = 2(2)`lines' { 
					local rowline`i' `""Standard Errors" _tab _tab"'
				} 
				local PRINT_STANDARDERR_TITLE = 0
			} 
				
			forvalues i = 0/`lines' { 
				local rowline`i' `"`rowline`i'' `r(l`i')'"' /* " */
			} 
		}
	} 
	if "`writetofile'"!="nowritetofile" { 
		capture file close myfile
		file open myfile `using', write text `append' `replace' all
		forvalues i = 1/`lines' { 
			file write myfile `rowline`i'' /* " */ _newline
		}
		file close myfile
	} 
		else { 
		return local lines `lines'
		forvalues i = 1/`lines' { 
			return local l`i' `"`rowline`i''"'	/* " */
		} 
	} 
		
end

capture program drop mean_header
program mean_header, rclass
	syntax varname [if] [in] [pweight], [PERCent] [RATe(integer 0)] [SUBGRoup(varlist)] [STANDARDERRor] STDERRPOSition(string) [SHOWTOTal] [COLUMNVAr(string) COLUMNLABel(string)] [*]
	marksample touse, novarlist
	
	local varlbl : variable label `varlist'
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
		return local l0 `"_tab _tab"'
		return local l1 `""`varlist'" _char(9) _tab"'
		return local l2 `""`varlbl'" _char(9) _tab"'
		if "`percent'"=="percent" { 
			return local l3 `""Percent" _char(9) "Error" _tab"'
		} 
		else { 
			return local l3 `""Mean" _char(9) "Error" _tab"'
		} 
		return local rate 0
	}
	else { 
		return local l0 `"_tab"'
		return local l1 `""`varlist'" _char(9)"'
		return local l2 `""`varlbl'" _char(9)"'
		if "`percent'"=="percent" { 
			return local l3 `""Percent" _char(9)"'
		} 
		else { 
			return local l3 `""Mean" _char(9)"'
		} 
		return local rate 0
	} 
end

capture program drop min_header
program min_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [allover SUBGRoup(varlist) allsgroup] [STANDARDERRor] [COLUMNVAr(string) COLUMNLABel(string)] [*]
	marksample touse, novarlist
	
	local varlbl : variable label `varlist'
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	return local l0 `"_tab"'
	return local l1 `""`varlist'" _char(9)"'
	return local l2 `""`varlbl'" _char(9)"'
	return local l3 `""Min" _char(9)"'
	return local rate 0
end

capture program drop max_header
program max_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [allover SUBGRoup(varlist) allsgroup] [STANDARDERRor] [COLUMNVAr(string) COLUMNLABel(string)] [SHOWTOTal] [*]
	marksample touse, novarlist
	
	local varlbl : variable label `varlist'
	
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	return local l0 `"_tab"'
	return local l1 `""`varlist'" _char(9)"'
	return local l2 `""`varlbl'" _char(9)"'
	return local l3 `""Max" _char(9)"'
	return local rate 0
end

capture program drop iqr_header
program iqr_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [allover SUBGRoup(varlist) allsgroup] [STANDARDERRor] [COLUMNVAr(string) COLUMNLABel(string)] [SHOWTOTal] [*]
	marksample touse, novarlist
	
	local varlbl : variable label `varlist'
	
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	return local l0 `"_tab"'
	return local l1 `""`varlist'" _char(9)"'
	return local l2 `""`varlbl'" _char(9)"'
	return local l3 `""IQR" _char(9)"'
	return local rate 0
end

capture program drop pctile_header
program pctile_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [allover SUBGRoup(varlist) allsgroup pctile_num(integer 50)] [STANDARDERRor] [COLUMNVAr(string) COLUMNLABel(string)] [SHOWTOTal] [*]
	marksample touse, novarlist
	
	local varlbl : variable label `varlist'
	
		local varlbl : variable label `varlist'
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	return local l0 `"_tab"'
	return local l1 `""`varlist'" _char(9)"'
	return local l2 `""`varlbl'" _char(9)"'
	return local l3 `""Percentile `pctile_num'" _char(9)"'
	return local rate 0
end

capture program drop proportion_header
program proportion_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [allover SUBGRoup(varlist) allsgroup] [STANDARDERRor] STDERRPOSition(string) [COLUMNVAr(string) COLUMNLABel(string)] [SHOWTOTal] [MISSing] [*]
	marksample touse, novarlist
	tempvar all
	generate `all' = 1
	label variable `all' "All"
	label define all 1 "All", modify
	label values `all' all
	
	local myvarlist `varlist'
	local varlbl : variable label `varlist'
	local myvarlbl `varlbl'
	
	quietly levelsof `varlist', `missing' local(varcats)
	local line0 `""'
	if regex( "`varlist'", "^[_]+") { // Variable name begins with dashes -- tempvar
	
	if "`columnvar'"!="" { 
		local myvarlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local myvarlbl "`columnlabel'"
	} 
	
		local line1 `""All""'
	} 
	else { 
		local line1 `""`myvarlist'""'  /* " */
	} 
	local line2 `""`myvarlbl'""'  /* " */
	local line3 `""'
	local line4 `""'
	// leave room for standard errors.
	// if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
	// 	forvalues i = 0/4 { 
	// 		local line`i' `"`line`i'' _tab"'	/* " */
	// 	} 
	// } 
	if "`allover'"=="allover" { // Add all category first!
		local line3 `"`line3' "All""' /* " */ 
		forvalues i = 0/4 {
			local line`i' `"`line`i'' _tab"'	/* " */
			if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
				local line`i' `"`line`i'' _tab"'	/* " */
			} 
		} 
	} 
	if "`allsgroup'"=="allsgroup" { 
			local subgroup "`all' `subgroup'"
	} 
	foreach j of local varcats { 
		local varcatlbl : label (`varlist') `j'
		forvalues i = 0/2 { 
			local line`i' "`line`i''"  /* " */
		} 
		local line3 `"`line3' "`varcatlbl'""' /* " */
		foreach k of varlist `subgroup' { 
			if "`k'"=="`varlist'" { 
				if "`allsgroup'"=="" { 
					forvalues m = 0/4 {
						local line`m' "`line`m'' _tab"
						if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
							local line`m' `"`line`m'' _tab"'	/* " */
						} 
					} 
				} 
			} 
			else {
				quietly levelsof `k', local(subcats)
				foreach l of local subcats { 
					local subcatlbl : label (`k') `l'
					forvalues m = 0/3 { 
						local line`m' "`line`m'' _tab"
						if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
							local line`m' `"`line`m'' _tab"'	/* " */
						} 
					} 
					local line4 `"`line4' "`subcatlbl'" _tab"'  /* " */
					if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
						local line4 `"`line4' _tab"'	/* " */
					} 
				} 
			} 
		} 
	} 
	/* 
		This section is triggered if we are showing the totals to the left of the catagories (non-flipped table).
	*/
	if "`showtotal'"=="showtotal" { 
		forvalues m = 0/2 { 
			local line`m' "`line`m'' _tab"
		} 
		local line3 `"`line3' "Total" _tab"' /* " */
		local line4 `"`line4' _tab"' /* " */
	} 
	
	forvalues i = 0/4 { 
		return local l`i' "`line`i''"  /* " */
	} 
	return local rate 0
end

capture program drop count_header
program count_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [SUBGRoup(varlist)] [STANDARDERRor] [SHOWTOTal]  [COLUMNVAr(string) COLUMNLABel(string)] [*]
	marksample touse /*, novarlist */
	
	local varlbl : variable label `varlist'
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	return local l0 `"_tab"'
	return local l1 `""`varlist'" _char(9)"'
	return local l2 `""`varlbl'" _char(9)"'
	return local l3 `""Count" _char(9)"'
	return local rate 0
end

capture program drop obs_header
program obs_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [SUBGRoup(varlist)] [STANDARDERRor] [SHOWTOTal]  [COLUMNVAr(string) COLUMNLABel(string)] [MISSing] [*]
	marksample touse /*, novarlist */
	
	local varlbl : variable label `varlist'
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	return local l0 `"_tab"'
	return local l1 `""`varlist'" _char(9)"'
	return local l2 `""`varlbl'" _char(9)"'
	return local l3 `""Observations" _char(9)"'
	return local rate 0
end


capture program drop total_header
program total_header, rclass
	syntax varname [if] [in] [pweight], [RATe(integer 0)] [SUBGRoup(varlist)] [STANDARDERRor] [SHOWTOTal]  [COLUMNVAr(string) COLUMNLABel(string)] [*]
	marksample touse /*, novarlist */
	
	local varlbl : variable label `varlist'
	if "`columnvar'"!="" { 
		local varlist "`columnvar'"
	} 
	if "`columnlabel'"!="" { 
		local varlbl "`columnlabel'"
	} 
	
	if `rate' == 1 {
		return local l0 `"_tab _tab"'
		return local l1 `""`varlist'" _char(9) _char(9)"'
		return local l2 `""`varlbl'" _char(9) _char(9)"'
		return local l3 `""Total" _char(9) "Rate" _tab"'
		return local rate 0
	} 
	else { 
		return local l0 `"_tab"'
		return local l1 `""`varlist'" _char(9)"'
		return local l2 `""`varlbl'" _char(9)"'
		return local l3 `""Total" _char(9)"'
		local ++rate
		return local rate `rate'
	}
end

capture program drop mean_row
program mean_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) PERCent ROUND(integer 0) STANDARDERRor STDERRFORMat(string) STDERRLEFT(string) STDERRRIGHT(string)] STDERRPOSition(string) [RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname B
	tempvar all
	generate `all' = 1
	
	/* 
		if "`stderrposition'"=="" { 
			if "`flip'"=="" { 
				local stderrposition "right"
			} 
			else { 
				local stderrposition "below"
			} 
		} 
	*/ 
	
	local line1 `""'
	local line2 `""'
	// local line2 `""Standard Error" _tab _tab"'
	local mylines = 1
	
	if "`over'"=="" { 
		local over "`all'"
	} 
	if "`subgroup'"=="" { 
		local subgroup "`all'"
	}  
	if "`allsgroup'"=="allsgroup"  { 
		local subgroup "`all' `subgroup'"
	} 
	
	foreach i of local over { 
		quietly levelsof `i', local(overcats)
		foreach j of local overcats { 
			foreach l of local subgroup { 
				quietly levelsof `l', local(subcats)
				foreach m of local subcats { 
					quietly count if `touse' & !missing(`varlist') & `i'==`j' & `l'==`m'
					if r(N) > 0 {
						quietly mean `varlist' if `touse' & `i'==`j' & `l'==`m' [`weight'`exp']
						// matrix `B' = e(b)
						// local cell_contents = `B'[1,1]
						local cell_contents = _b[`varlist']
						local std_error = _se[`varlist']
						if `cell_contents' == 0 { 
							local line1 "`line1' _tab"
							if "`standarderror'"=="standarderror" { 
								if "`stderrposition'"=="right" { // Non flipped table
									local line1 "`line1' _tab"
								} 
								else { 
									if "`stderrposition'"=="below" { 
										local mylines = 2
										local line2 "`line2' _tab"
									} 
								} 
							} 
						} 
						else { 
							if "`percent'"=="percent" { 
								local cell_contents = `cell_contents' * 100
								local std_error = `std_error' * 100
							} 
							if `round'!= 0 { 
								local cell_contents = round(`cell_contents',`round')
							} 
							local line1 "`line1' `format' (`cell_contents') _tab"
						} 
						if "`standarderror'"=="standarderror" { 
							if "`stderrposition'"=="right" { // Non flipped table
								local line1 `"`line1' "`stderrleft'" `stderrformat' (`std_error') "`stderrright'" _tab"'	/* " */
							} 
							else { 
								if "`stderrposition'"=="below" { 
									local mylines = 2
									local line2 `"`line2' "`stderrleft'" `stderrformat' (`std_error') "`stderrright'" _tab"'	/* " */
								} 
							} 
						} 
					} 
					else { 
						local line1 "`line1' _tab"
						if "`standarderror'"=="standarderror" { 
							if "`stderrposition'"=="right" { // Non flipped table
								local line1 "`line1' _tab"
							} 
							else { 
								if "`stderrposition'"=="below" { 
									local mylines = 2
									local line2 "`line2' _tab"
								} 
							} 
						} 
					}
				}
			}
		} 
	} 
		
	return local l1 `"`line1'"'		/* " */
	return local l2 `"`line2'"'		/* " */
	return local lines `mylines'
	return local rate 0
	return local previous 0
end

capture program drop change_row
program change_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) PERCent ROUND(integer 0) STANDARDERRor] [RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname B C
	tempvar all
	generate `all' = 1
	
	// Figure out the old variable (the y1 variable in the default case)
	if "`regex'"=="" { 
		local regex = "_y2$"
	} 
	if "`rxreplacement'"=="" { 
		local rxreplacement = "_y1"
	}
	// local y1varname = regexr("`varlist'","_y2$","_y1")
	local y1varname = regexr("`varlist'","`regex'","`rxreplacement'")
	
	
	local line1 ""
	
	if "`over'"=="" { 
		local over "`all'"
	} 
	if "`subgroup'"=="" { 
		local subgroup "`all'"
	} 
	if "`allsgroup'"=="allsgroup"  { 
		local subgroup "`all' `subgroup'"
	} 
	
	foreach i of local over { 
		quietly levelsof `i', local(overcats)
		foreach j of local overcats { 
			foreach l of local subgroup { 
				quietly levelsof `l', local(subcats)
				foreach m of local subcats { 
					quietly count if `touse' & !missing(`varlist') & `i'==`j' & `l'==`m'
					if r(N) > 0 {
						quietly mean `varlist' if `touse' & `i'==`j' & `l'==`m' [`weight'`exp']
						matrix `B' = e(b)
						local cell_contents = `B'[1,1]
						quietly mean `y1varname' if `touse' & `i'==`j' & `l'==`m' [`weight'`exp']
						matrix `C' = e(b)
						local cell_change = `cell_contents' - `C'[1,1]
						if `cell_contents' == 0 & `cell_change' == 0 { 
							local line1 "`line1' _tab"
						} 
						else { 
							if "`percent'"=="percent" { 
								local cell_contents = `cell_contents' * 100
								local cell_change = `cell_change' * 100
							} 
							if `round'!= 0 { 
								local cell_contents = round(`cell_contents',`round')
								local cell_change = round(`cell_change',`round')
							} 
							if "`varlist'" != "`y1varname'" { 
								local line1 `"`line1' `format' (`cell_contents') " (" `format' (`cell_change') ")" _tab"'  /* " */
							} 
							else { 
								local line1 `"`line1' `format' (`cell_contents') _tab"' /* " */
							} 
						} 
					} 
					else {
						local line1 "`line1' _tab" /* " */
					}
				}
			}
		} 
	} 
		
	return local l1 `line1'
	return local lines 1
	return local rate 0
	return local previous 0
end

capture program drop proportion_row
program proportion_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0) STANDARDERRor STDERRFORMat(string) STDERRLEFT(string) STDERRRIGHT(string) STDERRPOSition(string)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname B
	tempvar all
	generate `all' = 1
	
	local line1 `""'
	local line2 `""'
	local mylines = 1
	
	quietly levelsof `varlist' /* if `touse'*/ , `missing' local(varcats)
	local realformat : format `varlist'
	// display _n as text "Variable: " as result "`varlist'" as text " Format: " as result "`realformat'"
	local numcats : word count `varcats'
	if "`over'"=="" { // Non-flipped table
		quietly count if `touse' & !missing(`varlist')
		if r(N) > 0 {
			quietly proportion `varlist' if `touse' [`weight'`exp'], `missing'
			// matrix `B' = e(b)
			local column_labels `"`e(label1)'"' /* " */
			local column_names = e(namelist)
			// display as result `"`column_labels'"' /* " */
			// display as result `"`column_names'"' /* " */
			
			local rowtotal = 0 // Reset the total
			foreach j of local varcats { 
				local thiscatlbl : label (`varlist') `j'
				local thiscatlbl = substr("`thiscatlbl'",1,32)
				local thiscatlbl = rtrim("`thiscatlbl'")
				local cell_name : list posof `"`thiscatlbl'"' /* " */ in column_labels
				// display _newline as text "Catagory Label: " as result "`thiscatlbl'"
				// display as text "Position: " as result "`cell_name'"
				if `cell_name' == 0 { 
					local line1 "`line1' _tab"
				} 
				else { 
					local cell_name : word `cell_name' of `column_names'
					// local cell_contents = `B'[1,colnumb(`B',"`cell_name'")]
					local cell_contents = _b[`cell_name']
					local std_error = _se[`cell_name']
					// display as text "Cell Name: " as result "`cell_name'"
					// display as text "Cell Contents: " as result "`cell_contents'"
					if `cell_contents' == 0 | `cell_contents' == . { 
						local line1 "`line1' _tab"
						if "`standarderror'"=="standarderror" { 
							if "`stderrposition'"=="right" { // Non flipped table
								local line1 "`line1' _tab"
							} 
							else { 
								if "`stderrposition'"=="below" { 
									local mylines = 2
									local line2 "`line2' _tab"
								} 
							} 
						} 
					} 
					else { 
						local cell_contents = `cell_contents' * 100
						local std_error = `std_error' * 100
						local rowtotal = `rowtotal' + `cell_contents' // Keep a running total
						local line1 "`line1' `format' (`cell_contents') _tab"
						if "`standarderror'"=="standarderror" { 
							if "`stderrposition'"=="right" { 
								local line1 `"`line1' "`stderrleft'" `stderrformat' (`std_error') "`stderrright'" _tab"'	/* " */
							} 
							else { 
								if "`stderrposition'"=="below" { 
									local mylines = 2
									local line2 `"`line2' "`stderrleft'" `stderrformat' (`std_error') "`stderrright'" _tab"'	/* " */
								} 
							} 
						} 
					} 
				} 
			} 
			// Add the total column to this row
			if "`showtotal'"=="showtotal" { 
				local line1 "`line1' `format' (`rowtotal') _tab"
				if "`standarderror'"=="standarderror" & "`stderrposition'"=="below" { 
					local line2 "`line2' _tab"
				} 
			} 
		} 
		else { 
			foreach j of local varcats { 
				local line1 "`line1' _tab"
				if "`standarderror'"=="standarderror" { 
					if "`stderrposition'"=="right" { // Non flipped table
						local line1 "`line1' _tab"
					} 
					else { 
						if "`stderrposition'"=="below" { 
							local mylines = 2
							local line2 "`line2' _tab"
						} 
					} 
				} 
			}
			if "`showtotal'"=="showtotal" { 
				// Add in an extra column if we are showing totals
				local line1 "`line1' _tab"
				if "`standarderror'"=="standarderror" & "`stderrposition'"=="below" { 
					local line2 "`line2' _tab"
				} 
			} 
		} 
		local numcats = `mylines'
	}
	else { // Flipped Table
		/*
			If we're going to have standard errors below, then we need to do the following.
		*/
		if "`standarderror'"=="standarderror" & "`stderrposition'"=="below" { 
			local numcats = `numcats' + `numcats'
		} 
		// local ++numcats // Add an extra row to the table -- for the zero row ???
		if "`showtotal'"=="showtotal" { 
			/*
				For a flipped table, showing the total means showing an extra line.
			*/
			local ++numcats
		} 
		if "`subgroup'"=="" { 
			local subgroup "`all'"
		} 
		if "`allsgroup'"=="allsgroup" { 
			local subgroup "`all' `subgroup'"
		} 
		local catcounter2 1
		foreach i of local varcats { 
			local catname : label (`varlist') `i'
			if substr("`realformat'",1,2) == "%t" { 
				local catname : display `realformat' `i'
				local catname "`catname' (`i')"
			} 
			local line`catcounter2' `""`catname'" _tab _tab"'
			local ++catcounter2
			if "`standarderror'"=="standarderror" & "`stderrposition'"=="below" {
				local ++catcounter2
			} 
		} 
		// Set up the Total Row
		local line`catcounter2' `""Total" _tab _tab"'
		
		foreach i of local over { 
			quietly levelsof `i', local(overcats)
			foreach k of local overcats { 
				foreach l of local subgroup { 
					if "`l'"=="`i'" { 
						local subcatvar "`all'"
						if "`allsgroup'"=="" { 
							local subcats = 1
						} 
						else { 
							local subcats ""
						} 
					} 
					else { 
						local subcatvar "`l'"
						quietly levelsof `l', local(subcats)
					} 
					foreach m of local subcats { 
						quietly count if `touse' & !missing(`varlist') & `i'==`k' & `subcatvar'==`m'
						if r(N) > 0 { 
							quietly proportion `varlist' if `touse' & `i'==`k' & `subcatvar'==`m' [`weight'`exp']
							// matrix `B' = e(b)
							local column_labels `"`e(label1)'"' /* " */
							local column_names = e(namelist)
							
							local catcounter 1
							local columntotal = 0 // Reset the total
							foreach j of local varcats { 
								local thiscatlbl : label(`varlist') `j'
								local thiscatlbl = substr("`thiscatlbl'",1,32)
								local thiscatlbl = rtrim("`thiscatlbl'")
								local cell_name : list posof `"`thiscatlbl'"' /* " */ in column_labels
								if `cell_name' == 0 { 
									local line`catcounter' "`line`catcounter'' _tab"
									if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
										local line`catcounter' "`line`catcounter'' _tab"
									} 
									else { 
										// if we don't put anything to the right, we might put somethign
										// on the next line
										local std_error = 0
									} 
								} 
								else { 
									local cell_name : word `cell_name' of `column_names'
									// local cell_contents = `B'[1,colnumb(`B',"`cell_name'")]
									local cell_contents = _b[`cell_name']
									local std_error = _se[`cell_name']
									if `cell_contents' == 0 | `cell_contents' == . { 
										local line`catcounter' "`line`catcounter'' _tab"
									} 
									else { 
										local cell_contents = `cell_contents' * 100
										local std_error = `std_error' * 100
										local columntotal = `columntotal' + `cell_contents'
										local line`catcounter' "`line`catcounter'' `format' (`cell_contents') _tab"
										if "`standarderror'"=="standarderror" & "`stderrposition'"=="right" { 
											local line`catcounter' "`line`catcounter'' "`stderrleft'" `stderrformat' (`std_error') "`stderrright'" _tab"'	/* " */
										} 
									} 
								} 
								local ++catcounter
								if "`standarderror'"=="standarderror" & "`stderrposition'"=="below" {
									local line`catcounter' `"`line`catcounter'' "`stderrleft'" `stderrformat' (`std_error') "`stderrright'" _tab"'	/* " */
									local ++catcounter
								} 
							} 
							// Add the total to the total row (at the bottom of the table)
							local line`catcounter' "`line`catcounter'' `format' (`columntotal') _tab"
						} 
						else { 
							forvalues j = 1/`numcats' { 
								local k = `j' + 1
								local line`k' "`line`k'' _tab" /* " */
							} 
						} 
					} 
				}
			}
		} 
	}
	forvalues j = 1/`numcats' { 
		return local l`j' `"`line`j''"'  /* " */
	} 
	return local lines `numcats'
	return local rate 0
	return local previous 0
end

capture program drop count_row
program count_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [STANDARDERRor] [FLIP] [SHOWTOTal] [*]
	marksample touse /*, novarlist */
	tempvar all
	generate `all' = 1
	
	local line1 ""
	
	if "`over'" == "" { 
		local over "`all'"
	} 
	if "`subgroup'"=="" { 
		local subgroup "`all'"
	}
	if "`allsgroup'"=="allsgroup"  { 
		local subgroup "`all' `subgroup'"
	} 
	
	foreach i of local over { 
		quietly levelsof `i', local(overcats)
		foreach j of local overcats { 
			foreach l of local subgroup { 
				quietly levelsof `l', local(subcats)
				foreach m of local subcats { 
					quietly count if `touse' & `i'==`j' & `l'==`m'
					local cell_contents = r(N)
					if `cell_contents' == 0 { 
						local line1 "`line1' _tab"
					} 
					else { 
						local line1 "`line1' `format' (`cell_contents') _tab"
					} 
				}
			}
		}
	}
	
	return local l1 `line1'
	return local lines 1
	return local rate 0
	return local previous 0
end 

capture program drop obs_row
program obs_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [STANDARDERRor] [FLIP] [SHOWTOTal] [*]
	marksample touse , novarlist
	tempvar all
	generate `all' = 1
	
	local line1 ""
	
	// Set up the proper levels of the variable.
	quietly levelsof `varlist', `missing' local(varlistcats)
	local numcats : word count `varlistcats'
	local realformat : format `varlist'
	
	// If over is empty, we are dealing with the non-flipped version
	// We simply need to print out one line containing all the observations
	// for each category in the variable.
	if "`over'" == "" { 
		local rowtotal = 0 // Reset the total
		foreach j of local varlistcats { 
			quietly count if `touse' & `varlist'==`j'
			local cell_contents = r(N)
			local rowtotal = `rowtotal' + `cell_contents'
			local line1 "`line1' `format' (`cell_contents') _tab"
		} 
		if "`showtotal'"=="showtotal" { 
			local line1 "`line1' `format' (`rowtotal') _tab"
		} 
		return local l1 `line1'
		return local lines 1
		return local rate 0
		return local previous 0
	}
	else {	// Flipped Table
		local numcats = `numcats' + 1 // Increment numcats so the tables display correctly.
	
		/*
			For the flipped table, you don't actually need to total things up.
			Rather, just run a line the same way -- but count the total
		*/
	
		if "`subgroup'"=="" { 
			local subgroup "`all'"
		}
		if "`allsgroup'"=="allsgroup"  { 
			local subgroup "`all' `subgroup'"
		} 
		local catcount 2
		foreach k of local varlistcats {
			local catname : label (`varlist') `k'
			if substr("`realformat'",1,2) == "%t" { 
				local catname : display `realformat' `k'
				local catname "`catname' (`k')"
			} 
			local line`catcount' `""`catname'" _tab _tab"'
			foreach i of local over { 
				quietly levelsof `i', local(overcats)
				foreach j of local overcats { 
					foreach l of local subgroup { 
						quietly levelsof `l', local(subcats)
						foreach m of local subcats { 
							quietly count if `touse' & `i'==`j' & `l'==`m' & `varlist'==`k'
							local cell_contents = r(N)
							local line`catcount' "`line`catcount'' `format' (`cell_contents') _tab" 
						}
					}
				}
			}
			local ++catcount
		} 
		// Create the total line if set up
		if "`showtotal'"=="showtotal" { 
			local line`catcount' `""Total" _tab _tab"'
			foreach i of local over { 
				quietly levelsof `i', local(overcats)
				foreach j of local overcats { 
					foreach l of local subgroup { 
						quietly levelsof `l', local(subcats)
						foreach m of local subcats { 
							if "`missing'"=="missing" { 
								quietly count if `touse' & `i'==`j' & `l'==`m'
							} 
							else { 
								quietly count if `touse' & `i'==`j' & `l'==`m' & !missing(`varlist')
							} 
							local cell_contents = r(N)
							local line`catcount' "`line`catcount'' `format' (`cell_contents') _tab" 
						}
					}
				}
			}
			local ++numcats // Add an extra line
		}
		local numlines = `numcats' + 1
		forvalues j = 2/`numlines' { 
			return local l`j' `"`line`j''"'  /* " */
		} 
		return local lines `numlines'
		return local rate 0
		return local previous 0
	}
end 

capture program drop total_row
program total_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [STANDARDERRor] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname A
	tempvar all
	generate `all' = 1
	
	if "`over'"=="" { 
		local line1 ""
		
		capture quietly total `varlist' if `touse'
		if _rc == 2000 { 
			local cell_contents = 0
		} 
		else { 
			matrix `A' = e(b)
			local cell_contents = `A'[1,1]
		} 
		if `rate'==1 { 
			if `cell_contents' == 0 { 
				return local lines 1
				return local l1 "_char(9) _char(9) "
			} 
			else { 
				local rate_contents = `cell_contents' / `previous' * 100
				return local lines 1
				return local l1 "`format' (`cell_contents') _tab %12.1f (`rate_contents') _tab"
				return local rate 0
				return local previous 0
			} 
		} 
		else { 
			if `cell_contents' == 0 { 
				return local lines 1
				return local l1 "_char(9)"
			} 
			else { 
				local ++rate
				return local lines 1
				return local l1 "`format' (`cell_contents') _tab"
				return local previous `cell_contents'
				return local rate `rate'
			} 
		}
	} 
	else { 
		foreach i of local over { 
			quietly levelsof `i', local(overcats)
			foreach j of local overcats { 
				capture quietly total `varlist' if `touse' & `i'==`j'
				if _rc == 2000 { 
					local cell_contents = 0
				} 
				else { 
					matrix `A' = e(b)
					local cell_contents = `A'[1,1]
				} 
				if `cell_contents' == 0 { 
					local line1 "`line1' _tab"
				} 
				else { 
					local line1 "`line1' `format' (`cell_contents') _tab"
				} 
			} 
		} 
		return local lines 1
		return local l1 "`line1'"
		return local rate 0
	} 
end 

capture program drop min_row
program min_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [STANDARDERRor] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname A
	tempvar all
	generate `all' = 1
	
	if "`over'"=="" { 
		local line1 ""
		
		/*
			summarize doesn't cause an error if there
			are no observations.
		*/
		/* capture */ quietly summarize `varlist' if `touse'
		/* if _rc == 2000 { */
		if r(N) == 0 { // Zero Observations -- leave a space
			local cell_contents = 0
			return local lines 1
			return local l1 "_char(9)"
			return local rate 0 
			return local previous 0
		} 
		else { 
			local cell_contents = r(min)
			return local lines 1
			return local l1 "`format' (`cell_contents') _tab"
			return local rate 0 
			return local previous 0
		}
	} 
	else { 
		foreach i of local over { 
			quietly levelsof `i', local(overcats)
			foreach j of local overcats { 
				capture quietly summarize `varlist' if `touse' & `i'==`j'
				if _rc == 2000 { 
					local cell_contents = 0
					local line1 "`line1' _tab"
				} 
				else { 
					local cell_contents = r(min)
					local line1 "`line1' `format' (`cell_contents') _tab"
				} 
			} 
		} 
		return local lines 1
		return local l1 "`line1'"
		return local rate 0
		return local previous 0
	} 
end 

capture program drop max_row
program max_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [STANDARDERRor] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname A
	tempvar all
	generate `all' = 1
	
	if "`over'"=="" { 
		local line1 ""
		
		/* capture */ quietly summarize `varlist' if `touse'
		/* if _rc == 2000 { */
		if r(N) == 0 { // Zero Observations -- leave a space
			local cell_contents = 0
			return local lines 1
			return local l1 "_char(9)"
			return local rate 0 
			return local previous 0
		} 
		else { 
			local cell_contents = r(max)
			return local lines 1
			return local l1 "`format' (`cell_contents') _tab"
			return local rate 0 
			return local previous 0
		} 
	} 
	else { 
		foreach i of local over { 
			quietly levelsof `i', local(overcats)
			foreach j of local overcats { 
				capture quietly summarize `varlist' if `touse' & `i'==`j'
				if _rc == 2000 { 
					local cell_contents = 0
					local line1 "`line1' _tab"
				} 
				else { 
					local cell_contents = r(max)
					local line1 "`line1' `format' (`cell_contents') _tab"
				} 
			} 
		} 
		return local lines 1
		return local l1 "`line1'"
		return local rate 0
		return local previous 0
	} 
end 

capture program drop pctile_row
program pctile_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [pctile_num(integer 50)] [REGEX(string) RXREPLACEment(string)] [STANDARDERRor] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname A
	tempvar all
	generate `all' = 1
	
	if "`over'"=="" { 
		local line1 ""
		
		quietly count if !missing(`varlist')
		if r(N) == 0 { 
			local cell_contents = 0
			return local lines 1
			return local l1 "_char(9)"
			return local rate 0 
			return local previous 0
		} 
		else { 
			capture quietly _pctile `varlist' if `touse' [`weight'`exp'], percentiles(`pctile_num')
			local cell_contents = r(r1)
			return local lines 1
			return local l1 "`format' (`cell_contents') _tab"
			return local rate 0 
			return local previous 0
		} 
	} 
	else { 
		foreach i of local over { 
			quietly levelsof `i', local(overcats)
			foreach j of local overcats { 
				quietly count if !missing(`varlist')
				if r(N) == 0 { 
					local cell_contents = 0
					local line1 "`line1' _tab"
				} 
				else { 
					capture quietly _pctile `varlist' if `touse' & `i'==`j' [`weight'`exp'], percentiles(`pctile_num')
					local cell_contents = r(r1)
					local line1 "`line1' `format' (`cell_contents') _tab"
				} 
			} 
		} 
		return local lines 1
		return local l1 "`line1'"
		return local rate 0
		return local previous 0
	} 
end 

capture program drop iqr_row
program iqr_row, rclass
	syntax varname [if] [in] [pweight], FORMat(string) [OVER(varlist) RATe(integer 0) PREVious(real 0)] [SUBGRoup(varlist) allsgroup] [MISSing] [REGEX(string) RXREPLACEment(string)] [STANDARDERRor] [FLIP] [SHOWTOTal] [*]
	marksample touse, novarlist
	tempname A
	tempvar all
	generate `all' = 1
	
	if "`over'"=="" { 
		local line1 ""
		
		quietly count if !missing(`varlist')
		if r(N) == 0 { 
			local cell_contents = 0
			return local lines 1
			return local l1 "_char(9)"
			return local rate 0 
			return local previous 0
		} 
		else { 
			capture quietly _pctile `varlist' if `touse' [`weight'`exp'], percentiles(25 75)
			local cell_contents = r(r2) - r(r1)
			return local lines 1
			return local l1 "`format' (`cell_contents') _tab"
			return local rate 0 
			return local previous 0
		} 
	} 
	else { 
		foreach i of local over { 
			quietly levelsof `i', local(overcats)
			foreach j of local overcats { 
				quietly count if !missing(`varlist')
				if r(N)==0 { 
					local cell_contents = 0
					local line1 "`line1' _tab"
				} 
				else { 
					capture quietly _pctile `varlist' if `touse' & `i'==`j' [`weight'`exp'], percentiles(25 75)
					local cell_contents = r(r2) - r(r1)
					local line1 "`line1' `format' (`cell_contents') _tab"
				} 
			} 
		} 
		return local lines 1
		return local l1 "`line1'"
		return local rate 0
		return local previous 0
	} 
end 



