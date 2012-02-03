// configure.do

/*
	This Stata do file will configure a new installation
	of the Stata-Utilities do files.
*/

capture program drop check_path_ignored
program check_path_ignored, rclass
	syntax anything using
	
	tempname gitignore_backup
	file open `gitignore_backup' `using', read text
	
	local anything = regexr(`"`anything'"',"[\/]$","")
	
	local duplicate = 0
	file read `gitignore_backup' line
	while r(eof)==0 { 
		if `"`line'"'==`"`anything'/*"' {
			local duplicate = 1
			exit
		}
		file read `gitignore_backup' line
	}
	
	file close `gitignore_backup'
	return local dupe = `duplicate'
end
	
	
capture program drop configure_paths
program configure_paths
	display _newline
	display as text "Welcome to the Stata do file configuration utility."
	display as text "We will setup a " as result " su_user_locals.do" as text "  file for you."
	display _newline _newline

	/*
		If there is an existing su_user_locals.do file, back it up.
		
		I'm also going to backup the .gitignore file. 
	*/
	capture confirm file su_user_locals.do
	if !_rc {
		copy su_user_locals.do su_user_locals_backup.do, replace
		rm su_user_locals.do
	}
	capture confirm file .gitignore
	if !_rc {
		copy .gitignore gitignore_backup.txt, replace
	}

	tempname myfile
	tempname gitignore
	// tempname gitignore_backup
	file open `myfile' using su_user_locals.do, write text replace
	file open `gitignore' using .gitignore, write text append
	// file open `gitignore_backup' using gitignore_backup.txt, read text

	file write `myfile' "// su_user_locals.do" _newline _newline

	display as text "*** Location Name ***"
	display as text "Please choose a name for this particularl installation of the do files."
	display _newline as text "Location name (home1):" _newline _request(locationname)
	if "${locationname}"=="" {
		global locationname "home1"
	}
	file write `myfile' `"local locationname "${locationname}""' _newline

	local currdir "`c(pwd)'"
	display _newline _newline
	display as text "*** Project Directory ***"
	display as text "Please enter the location where the project files are stored, or hit enter to put them in the current directory."
	display _newline as text "Project Directory (`currdir'`c(dirsep)'):" _newline _request(projectdirectory)
	if "${projectdirectory}"=="" {
		global projectdirectory "`currdir'`c(dirsep)'"
	}
	if substr( "${projectdirectory}",-1,1)!="/" & substr( "${projectdirectory}",-1,1)!="\" {
		global projectdirectory "${projectdirectory}`c(dirsep)'"
	}
	file write `myfile' `"local projectdirectory "${projectdirectory}""' _newline

	display _newline _newline
	display as text "*** Log Path ***"
	display as text "Directory for storing Stata logs."
	display _newline as text "Log paths (${projectdirectory}log`c(dirsep)'):" _newline _request(logdatapath)
	if "${logdatapath}"=="" {
		global logdatapath "${projectdirectory}log`c(dirsep)'"
	}
	file write `myfile' `"local logpath "${logdatapath}""' _newline
	local data_ignore = subinstr(`"${logdatapath}"',"${projectdirectory}","",1)
	check_path_ignored `data_ignore' using gitignore_backup.txt
	if "`r(dupe)'"=="0" { 
		file write `gitignore' "`data_ignore'" _newline
	} 

	display _newline _newline
	display as text "*** Manual Log Path ***"
	display as text "Directory for storing Stata manual logs."
	display _newline as text "Log paths (${projectdirectory}log`c(dirsep)'manual`c(dirsep)'):" _newline _request(manuallogpath)
	if "${manuallogpath}"=="" {
		global manuallogpath "${projectdirectory}log`c(dirsep)'manual`c(dirsep)'"
	}
	file write `myfile' `"local manuallogpath "${manuallogpath}""' _newline
	local data_ignore = subinstr(`"${manuallogpath}"',"${projectdirectory}","",1)
	check_path_ignored `data_ignore' using gitignore_backup.txt
	if "`r(dupe)'"=="0" { 
		file write `gitignore' "`data_ignore'" _newline
	} 

	display _newline _newline
	display as text "*** Output Path ***"
	display as text "Generated output will be created here."
	display _newline as text "Output directory (${projectdirectory}output`c(dirsep)'):" _newline _request(outputpath)
	if "${outputpath}"=="" {
		global outputpath "${projectdirectory}output`c(dirsep)'"
	}
	file write `myfile' `"local outputpath "${outputpath}""' _newline
	local data_ignore = subinstr(`"${outputpath}"',"${projectdirectory}","",1)
	check_path_ignored `data_ignore' using gitignore_backup.txt
	if "`r(dupe)'"=="0" { 
		file write `gitignore' "`data_ignore'" _newline
	} 
	file write `myfile' _newline _newline

	file close `myfile'
  file close `gitignore'

  display _newline as text "Thank you for setting up your configuration file."
  display _newline as text "The contents of your configuration file are listed below:" _newline
  display as text "*** su_user_locals.do BEGINS *****"
  file open `myfile' using "su_user_locals.do", read text
  file read `myfile' line
  while r(eof)==0 { 
    display `"`line'"'
    file read `myfile' line
  }
  file close `myfile'
  display as text "*** su_user_locals.do ENDS *****"

  display _newline
  display as text "Please ensure that your data directories are in the " as result ".gitignore" as text " file." _newline
  display as text "The file will be output below for reference:" _newline
  display as text "*** .gitignore BEGINS *****"
  file open `gitignore' using ".gitignore", read text
  file read `gitignore' line
  while r(eof)==0 { 
    display `"`line'"'
    file read `gitignore' line
  }
  file close `gitignore'
  display as text "*** .gitignore ENDS *****"
  display _newline  as text "Remember to commit these changes to the git repository."
  display as text "Have a nice day." _newline

end

configure_paths

