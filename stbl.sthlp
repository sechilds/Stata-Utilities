{smcl}
{* *! version 0.1.0 09jul2009}{...}
{cmd:help stbl} {* *! right:dialog:  {bf:{dialog stbl}}}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:stbl} {hline 2}}Generate Tables of Descriptive Statistics (Super Tables){p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 16 2}
{cmd:stbl} {it:statlist} using {it:filename} {ifin} {weight}, [{cmd:,} {it:options}]

{phang}
where {it:statlist} is a list composed of the following:

{synoptset 20 tabbed}{...}
{synopthdr: statlist}
{synoptline}
{synopt :({it:statname})}Changes the type of statistic generated for subsequent variables in the {it:statlist}; default is (mean).{p_end}
{synopt :{cmd:%}{it:fmt}}Changes the format of the output to any valid Stata format. The default is {cmd:%}12.0f{p_end}
{synopt :{varlist}}Generate statistics for these variables.{p_end}
{synoptline}

{phang}
and {it:statname} is one of the following:

{synoptset 20 tabbed}{...}
{synopthdr: statname}
{synoptline}
{synopt :{cmd:mean}}The mean of the variable.{p_end}
{synopt :{cmd:round}}The mean of the variable rounded (as specified in the round option).{p_end}
{synopt :{cmd:percent}}The mean multiplied by 100, useful for displaying dummy variables.{p_end} 
{synopt :{cmd:min}}The minimum value of the variable.{p_end}
{synopt :{cmd:max}}The maximum value of the variable.{p_end}
{synopt :{cmd:iqr}}Interquartile range.{p_end}
{synopt :{cmd:pctile}[{it:##}]}Percentile. The default is the 50th percentile, but any number can be specified. (e.g. pctile25).{p_end}
{synopt :{cmd:proportion}}For a numeric catagorical variable, presents the percentage of observations in each catagory.{p_end}
{synopt :{cmd:obs}}Displays the unweighted numbers of observations in each catagory.{p_end}
{synopt :{cmd:count}}The number of non-missing observations for the variable.{p_end}
{synopt :{cmd:change}}The change in the mean of the variable from the previous cycle. (See options).{p_end}
{synopt :{cmd:total}}Total estimation. (Respects weights.) If two total estimations are specified, the rate will be calculated as well.{p_end}
{synopt :{cmd:set}}A standard set of statistics: count mean min max pctile25 pctile50 pctile75 iqr.{p_end}
{synoptline}

{title:Options}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Catagorical Variables}
{synopt :{opth over(varlist)}}Generates statistics over the catagorical variables specified.{p_end}
{synopt :{opth subgr:oup(varlist)}}When combined with {opth over(varlist)}, this allows the table to multiply the number of catagories by creating subgroups with in each of the catagories specified by {opth over(varlist)}.{p_end}
{synopt :{cmdab:allsg:roup}}When {opth subgroup(varlist)} is specified, an all catagory will be included.{p_end}
{syntab:Output Options}
{synopt :{cmd:round(x)}}Specifies the number to round to (as in the round() function).{p_end}
{synopt :{cmdab:miss:ing}}Includes missing values in the proportions and obs calculations.{p_end}
{synopt :{cmd:flip}}Changes the orientation of the table. (See below.){p_end}
{synopt :{cmdab:nohead:er}}Supresses the header.{p_end}
{synopt :{cmdab:allc:ol}}Adds an all column to the flipped table.{p_end}
{synopt :{cmdab:noallr:ow}}Supresses the all row in the default table.{p_end}
{syntab:File Operations}
{synopt :{cmdab:app:end}}Append output to existing file.{p_end}
{synopt :{cmdab:repl:ace}}Replace existing file.{p_end}
{syntab:Change}
{synopt :{opth regex(string)}}Takes a regular expression that matches the year indicator in the variable name.{p_end}
{synopt :{opth rxreplace:ment(string)}}What to replace the year indicator with.{p_end}
{syntab:Compatibility}
{synopt :{opth form:at(string)}}Sets the format.{p_end}
{synoptline}

