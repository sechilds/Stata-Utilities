// latex_codebook.ado
capture program drop latex_codebook
program latex_codebook
	syntax varlist using [if] [in], subtitle(passthru) [caption(passthru)]
	marksample touse, novarlist
	
	display _newline as text "Running " as result "\$Id: latex_codebook.ado 862 2009-09-16 19:20:18Z mesa $"
	
	local match = regexm( `"`using'"', `".*\"(.*[\/]).*\""')  /* " */
	local dirname = regexs(1)	
	uniquefilename using "`dirname'lcodebook.tex"
	local lcodebook_filename "`r(filename)'"
	
	latex_header `using', `subtitle'
	lcodebook2 `varlist' using "`lcodebook_filename'" if `touse', `caption'
	file open myfile `using', write append all
	file write myfile "\LTXtable{\textwidth}{`lcodebook_filename'}" _n
	file close myfile
	mycodebook `varlist' `using' if `touse', `caption'
	/*
		I need to figure out the folder that
		the file is in.
	*/
	
	
	latex_footer `using', folder(`dirname')
end 

capture program drop mycodebook
program mycodebook
	syntax varlist using [if] [in] [, caption(string) label(string)]
	marksample touse, novarlist
	// tempvar mysample mysample2 mysample3 notvalidskip noskpsamp
	tempvar mysample notvalidskip noskpsamp
	quietly generate byte `mysample' = .
	// generate byte `mysample2' = .
	// generate byte `mysample3' = .
	quietly generate byte `notvalidskip' = .
	quietly generate byte `noskpsamp' = . 
	// replace `mysample2' = 0
	// replace `mysample2' = 1 if x_year2 == 1
	// replace `mysample2' = `mysample2' & `touse'
	// replace `mysample3' = 0
	// replace `mysample3' = 1 if y3 == 3
	// replace `mysample3' = `mysample3' & `touse'
	
	capture file close myfile
	file open myfile `using', write append
	
// 	file write myfile "\begin{table}[htdp]"  _n
// 	file write myfile "\caption{`caption'}"  _n
// 	file write myfile "\label{`label'}"  _n
// 	file write myfile "\begin{center}"  _n
	
	foreach j of varlist `varlist' { 
		/* Handle Y2 variables */
		// replace `mysample2' = 0
		// replace `mysample2' = 1 if x_year2 > 1
		// replace `mysample2' = `mysample2' & `touse'
		quietly replace `mysample' = `touse'
		// replace `mysample' = `mysample2' if substr("`j'",-3,.)=="_y2"
		// replace `mysample' = `mysample3' if substr("`j'",-3,.)=="_y3"
		quietly replace `notvalidskip' = 1
		quietly capture replace `notvalidskip' = 0 if `j'==.s
		quietly capture replace `notvalidskip' = 0 if `j'=="Valid Skip"
		quietly replace `noskpsamp' = ( `mysample' & `notvalidskip' )
		// tab2 `noskpsamp' `mysample', missing
		// tab2 `noskpsamp' `notvalidskip', missing
		local inskiplist : list j in global(nofreqtbl)
		
		local mytype : type `j'
		latexclean ,clean( "`mytype'" )
		local mytype "`r(x)'"
		local myformat : format `j'
		latexclean ,clean( "`myformat'" )
		local myformat "`r(x)'"
		local myvariablelabel : variable label `j'
		if "`myvariablelabel'"=="" {
			local myvariablelabel "(Unlabeled)"
		} 
		latexclean ,clean( "`myvariablelabel'" )
		local myvariablelabel "`r(x)'"
		local myvariablename "`j'"
		latexclean ,clean( "`myvariablename'" )
		local myvariablename "`r(x)'"
		local latexlabelname "`j'"
		nospecials ,clean( "`latexlabelname'" )
		local latexlabelname "`r(x)'"
		local myvaluelabel : value label `j'
		if "`myvaluelabel'"=="" {
			local myvaluelabel "(None)"
		} 
		latexclean ,clean( "`myvaluelabel'" )
		local myvaluelabel "`r(x)'"
		quietly count if `mysample'
		local myobservations = r(N)
		quietly unique `j' if `mysample'
		local myunique = r(sum)
		quietly tabmiss `j' if `noskpsamp'
		local mymissing = r(sum)
		local mymissingpercent = r(mean)*100
		local mymissingpercent : display %9.0f `mymissingpercent'
		quietly levelsof `j', local(mylevelsof) /* missing */
		quietly levelsof `j' if missing(`j'), local(mymissinglevelsof) missing
		getgroup `j'
		local mygrouplabel `r(X)'
		// display _newline as text "Variable: " as result "`j'" as text " of group " _continue
		// display as result "`mygrouplabel'"
		// display as text "Sample: " 
		// tabulate `mysample'
		// display as text "Valid Skips: "
		// tabulate `notvalidskip'
		
		
		#delimit ;
		
		file write myfile "\markright{\texttt{`myvariablename'}}" _newline;
		file write myfile "\begin{table}[H]"  _n;
		file write myfile "\caption[]{`myvariablelabel' (`myvariablename')}"  _n;
		file write myfile "\label{`latexlabelname'}"  _n;
		file write myfile "\begin{center}"  _n;
		file write myfile "\begin{tabular*}{1\textwidth}{@{\extracolsep{\fill}} l r}"  _n;
		file write myfile "\hline"  _n;
		file write myfile "\texttt{`myvariablename'} & `myvariablelabel' \\"  _n;
		file write myfile "\hline"  _n;
		file write myfile "\end{tabular*}"  _n;
		file write myfile "\begin{tabular*}{0.75\textwidth}{@{\extracolsep{\fill}} l r c l r}"  _n;
		file write myfile "\\"  _n;
		file write myfile "Type: & `mytype' & & Format: & `myformat' \\"  _n;
		file write myfile "Label: & `myvaluelabel' & & Obs.: & `myobservations' \\" _n;
		file write myfile "Unique: & `myunique' & & Missing: & `mymissing' (`mymissingpercent'\%)" _n;
		file write myfile "\end{tabular*}"  _n;
		local mynumlevels : list sizeof mylevelsof;
		// if `mynumlevels' > $tabmax { ;
			// 
				/*
					Deal with String Variables with lots of
					different results.
				*/
			// } ;
			// else { ;
				quietly summarize `j';
				local realformat : subinstr local myformat "\%" "%", all;
				if substr("`realformat'",1,2) == "%t" {;
					local mymean : display `realformat' r(mean);
					local mymin : display `realformat' r(min);
					local mymax : display `realformat' r(max);
					local mysd : display %9.1f r(sd);
				} ;
				else { ;
					local mymean : display %9.1f r(mean);
					local mymin : display %9.1f r(min);
					local mymax : display %9.1f r(max);
					local mysd : display %9.1f r(sd);
				} ;
				if substr("`mytype'",1,3) != "str" { ; 
					file write myfile "\begin{tabular*}{0.75\textwidth}{@{\extracolsep{\fill}} l r c l r}"  _n;
					file write myfile "\\"  _n;
					file write myfile "Mean: & `mymean' & & Std. Dev.: & `mysd' \\"  _n;
					file write myfile "Min.: & `mymin' & & Max.: & `mymax'" _n;
					file write myfile "\end{tabular*}"  _n;
				} ;
			// } ;
		// } ;
		// else { ;
		if `inskiplist'==0 { ; 
			if substr("`mytype'",1,3) == "str" { ; 
				file write myfile "\begin{tabular*}{0.70\textwidth}{@{\extracolsep{\fill}} r p{.50\textwidth}}" _n;
				file write myfile "\\"  _n;
				file write myfile "\textit{Freq.} & \textit{Value} \\"  _n;
				file write myfile "\hline" _n;
				local rowcounter 1;
				foreach i of local mylevelsof { ;
					quietly count if `touse' & `j'==`"`i'"' /* " */ ;
					local myfreq = r(N);
					if `"`i'"'!=`""' /* " */ {  ; 
						latexclean ,clean( "`i'" );
						local myvalue "`r(x)'";
						local myvalue "\verb#`myvalue'#" ;
					} ;
					else { ;
						local myvalue "";
					} ;
					if `rowcounter' <= $tabmax { ;
						file write myfile "`myfreq' & `myvalue' \\"  _n ;
					} ;
					else { ;
						if `rowcounter' == $tabmax + 1 { ;
							file write myfile " & (more\ldots ) \\"  _n;
							quietly count if `j'=="Valid Skip";
							local myfreq = r(N);
							if `myfreq' > 0 { ;
								file write myfile "`myfreq' & Valid Skip \\" _n ;
							} ;
						} ;
					} ;
					local ++rowcounter;
				} ;
				file write myfile "\end{tabular*}"  _n;
			} ;
			else { ;
				file write myfile "\begin{tabular*}{0.70\textwidth}{@{\extracolsep{\fill}} r r p{.50\textwidth}}" _n;
				file write myfile "\\"  _n;
				file write myfile "\textit{Freq.} & \textit{Numeric} & \textit{Label} \\"  _n;
				file write myfile "\hline" _n;
				local rowcounter 1;
				foreach i of local mylevelsof { ;
					quietly count if `touse' & `j'==`i' ;
					local myfreq = r(N);
					if substr("`realformat'",1,2) == "%t" {;
						local myvlabelx : display `realformat' `i' ;
					} ;
					else { ;
						local myvlabelx : label (`j') `i' ;
					} ;
					latexclean ,clean( "`myvlabelx'" );
					local myvlabelx "`r(x)'";
					if `rowcounter' <= $tabmax { ;
						file write myfile "`myfreq' & `i' & `myvlabelx' \\"  _n;
					} ;
					else { ;
						if `rowcounter' == $tabmax + 1 { ;
							file write myfile " & & (more\ldots ) \\"  _n;
						} ;
					} ;
					local ++rowcounter;
				} ;
				foreach i of local mymissinglevelsof { ;
					quietly count if `touse' & `j'==`i' ;
					local myfreq = r(N);
					local myvlabelx : label (`j') `i' ;
					latexclean ,clean( "`myvlabelx'" );
					local myvlabelx "`r(x)'";
					file write myfile "`myfreq' & `i' & `myvlabelx' \\"  _n;
				} ;
				file write myfile "\end{tabular*}"  _n;
			} ;
		} ;
		else { ;
			if substr("`mytype'",1,3) == "str" { ; 
				/*
					file write myfile "\begin{tabular*}{0.70\textwidth}{@{\extracolsep{\fill}} r p{.50\textwidth}}" _n;
					file write myfile "\\"  _n;
					file write myfile "\textit{Freq.} & \textit{Value} \\"  _n;
					file write myfile "\hline" _n;
					local rowcounter 1;
					foreach i of local mylevelsof { ;
						quietly count if `touse' & `j'==`"`i'"' ; 
						local myfreq = r(N);
						if `"`i'"'!=`""' { ; 
							latexclean ,clean( "`i'" );
							local myvalue "`r(x)'";
							local myvalue "\verb#`myvalue'#" ;
						} ;
						else { ;
							local myvalue "";
						} ;
						if `rowcounter' <= $tabmax { ;
							file write myfile "`myfreq' & `myvalue' \\"  _n ;
						} ;
						else { ;
							if `rowcounter' == $tabmax + 1 { ;
								file write myfile " & (more\ldots ) \\"  _n;
							} ;
						} ;
						local ++rowcounter;
					} ;
					file write myfile "\end{tabular*}"  _n;
				*/ 
			} ;
			else { ;
				file write myfile "\begin{tabular*}{0.70\textwidth}{@{\extracolsep{\fill}} r r p{.50\textwidth}}" _n;
				file write myfile "\\"  _n;
				file write myfile "\textit{Freq.} & \textit{Numeric} & \textit{Label} \\"  _n;
				file write myfile "\hline" _n;
				quietly count if `touse' & !missing(`j');
				local myfreq = r(N);
				file write myfile "`myfreq' & `mymin' : `mymax' & Non Missing \\" _n;
				local rowcounter 1;
				foreach i of local mymissinglevelsof { ;
					quietly count if `touse' & `j'==`i' ;
					local myfreq = r(N);
					local myvlabelx : label (`j') `i' ;
					latexclean ,clean( "`myvlabelx'" );
					local myvlabelx "`r(x)'";
					file write myfile "`myfreq' & `i' & `myvlabelx' \\"  _n;
				} ;
				file write myfile "\end{tabular*}"  _n;
			} ;
		} ;
		/*
			file write myfile "\begin{tabular*}{0.85\textwidth}{@{\extracolsep{\fill}} p{.85\textwidth}}"  _n;
			file write myfile "\\"  _n;
			file write myfile "Notes go in here."  _n;
			file write myfile "\end{tabular*}"  _n;
		*/
		file write myfile "\begin{tabular*}{1\textwidth}{@{\extracolsep{\fill}} l r r}"  _n;
		file write myfile "\\ \hline"  _n;
		file write myfile "& \hyperref[`mygrouplabel']{\textsc{Group}} & \hyperref[top]{\textsc{Top}} \\"  _n;
		file write myfile "\end{tabular*}"  _n;
		file write myfile "\end{center}"  _n;
		file write myfile "\end{table}"  _n;
		// file write myfile "\begin{verbatim}"  _n;
		// file write myfile "Variable Notes:"  _n;
		// file close myfile;
		// capture log close notelog;
		// quietly log `using', text append name(notelog);
		// notes list `j';
		// quietly log close notelog;
		// file open myfile `using', write append;
		// file write myfile "\end{verbatim}"  _n _n;
		// file write myfile "\markright{\texttt{`myvariablename'}}" _n;
		// file write myfile "%\afterpage{\clearpage}"  _n;
		// file write myfile " \\"  _n;
		
		#delimit cr
	}
	
	// file write myfile "\end{center}"  _n
	// file write myfile "\end{table}"  _n
	file close myfile
end

# delimit ;
capture program drop latexclean;
program latexclean, rclass;
	syntax ,clean(string);
	local the_string = subinstr("`clean'","_","\_",.);
	local the_string = subinstr("`the_string'","#","\#",.);
	local the_string = subinstr("`the_string'","$","\$",.);
	local the_string = subinstr("`the_string'","%","\%",.);
	local the_string = subinstr("`the_string'","&","\&",.);
	local the_string = subinstr("`the_string'","^","\^",.);
	local the_string = subinstr("`the_string'","{","\{",.);
	local the_string = subinstr("`the_string'","}","\}",.);
	local the_string = subinstr("`the_string'",`"""'," ",.);
	return local x "`the_string'";
end;

capture program drop nospecials;
program nospecials, rclass;
	syntax ,clean(string);
	local the_string = subinstr("`clean'","_","",.);
	local the_string = subinstr("`the_string'","#","",.);
	local the_string = subinstr("`the_string'","$","",.);
	local the_string = subinstr("`the_string'","%","",.);
	local the_string = subinstr("`the_string'","&","",.);
	local the_string = subinstr("`the_string'","^","",.);
	local the_string = subinstr("`the_string'","{","",.);
	local the_string = subinstr("`the_string'","}","",.);
	return local x "`the_string'";
end;

capture program drop getgroup;
program getgroup, rclass;
	syntax varname;
	tempname mygroup mytest;
	scalar `mygroup' = "";
	display "`varlist'";
	scalar `mytest' = regexm("`varlist'","[a-z_]*");
	if `mytest' { ;
		scalar `mygroup' = regexs(0);
		scalar list `mygroup';
	} ;
	else { ;
		scalar `mygroup' = "x";
	} ;
	scalar list `mygroup';
	local returngroup `mygroup';
	return local X = `returngroup';
end;

# delimit cr

capture program drop latex_header
program latex_header
	syntax using, SUBTItle(string)
	
	capture file close mainfile
	file open mainfile `using', write replace

	file write mainfile "\documentclass[11pt]{scrartcl}" _newline
	file write mainfile "\usepackage[T1]{fontenc}" _newline
	file write mainfile "\usepackage{unicode}" _newline
	file write mainfile "\usepackage{ucs}" _newline
	file write mainfile "\usepackage[latin1]{inputenc}" _newline
	file write mainfile _newline "\usepackage[center,bf]{caption}" _newline
	file write mainfile "\usepackage{booktabs}" _newline
	file write mainfile "\usepackage{ltxtable}" _newline
	file write mainfile _newline "\usepackage[letterpaper,left=1.0in,right=1.0in,top=1.0in,bottom=1.0in]{geometry}" _newline
	file write mainfile _newline "\usepackage{lscape}" _newline
	file write mainfile "\usepackage{float}" _newline
	file write mainfile "\usepackage{afterpage}" _newline
	file write mainfile "\usepackage{hyperref}" _newline
	file write mainfile "\usepackage{array}" _newline
	file write mainfile "\usepackage{tabularx}" _newline
	file write mainfile "\usepackage{lastpage}" _newline
	file write mainfile "\usepackage{ifthen}" _newline
	file write mainfile "\usepackage{fancyhdr}" _newline
	file write mainfile "\usepackage{longtable}" _newline
	file write mainfile "\pagestyle{fancy}" _newline
	file write mainfile "\renewcommand{\sectionmark}[1]{}" _newline
	file write mainfile "\renewcommand{\subsectionmark}[1]{}" _newline
	file write mainfile "\fancyhead{}" _newline
	file write mainfile "\fancyfoot{}" _newline
	file write mainfile "\newcommand{\mymarks}{" _newline
	file write mainfile _tab "\ifthenelse{\equal{\leftmark}{\rightmark}}" _newline
	file write mainfile _tab _tab "{\rightmark} % if equal" _newline
	file write mainfile _tab _tab "{\leftmark -- \rightmark}} % if not equal" _newline
	file write mainfile "\fancyhead[LE,RO]{\rightmark}" _newline
	file write mainfile "\fancyhead[LO,RE]{}" _newline
	file write mainfile "\fancyhead[R]{\slshape \leftmark}" _newline
	file write mainfile "\fancyfoot[L]{\href{http://www.mesa-project.org}{MESA} LSLIS}" _newline
	file write mainfile "\fancyfoot[R]{Page \thepage}" _newline
	file write mainfile "\renewcommand{\footrulewidth}{0.4pt}" _newline
	// file write mainfile "\footrulewidth 0.4pt" _newline
	file write mainfile "\newcolumntype{Y}{>{\raggedright\arraybackslash}X}" _newline
	file write mainfile "\newcolumntype{W}{>{\raggedleft\arraybackslash}X}" _newline
	// file write mainfile "\usepackage{filecontents}" _newline
	file write mainfile _newline "\begin{document}" _newline
	file write mainfile _newline "\title{MESA Longitudinal Survey of Low Income Students (LSLIS)}" _newline
	file write mainfile "\subtitle{`subtitle'}" _newline
	file write mainfile "\author{\href{http://www.mesa-project.org}{Measuring the Effectiveness of Student Aid (MESA) Project}}" _newline
	file write mainfile "\date{${datestringp} ${timestringp}}" _newline
	file write mainfile _newline "\maketitle" _newline
	file write mainfile "\label{top}" _newline
	file write mainfile "\markboth{Contents}{Contents}" _newline
	file write mainfile "\tableofcontents" _newline
	file write mainfile "\section{Listing of Variables by Group}" _newline
	file write mainfile "\markboth{Variable Group List}{Variable Group List}" _newline
	file write mainfile "\renewcommand\listtablename{List of Variable Groups}" _newline
	file write mainfile "\listoftables" _newline
	file write mainfile _newline
	file close mainfile
end
	
capture program drop latex_footer
program latex_footer
	syntax using/, FOLDer(string)
	capture file close mainfile
	file open mainfile using "`using'", write append
	
	file write mainfile "\end{document}" _n
	file close mainfile
	cd "`folder'"
	shell /usr/texbin/pdflatex `using'
	shell /usr/texbin/pdflatex `using'
	cd "${projectdirectory}"
end
	