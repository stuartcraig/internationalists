/*--------------------------------------------------------------------KB_main.do
Main control file for Oona/Scott's KB project.
		
Stuart Craig
Last updated: 20170830
*/
args nodata

version 12


/*
-------------------------------------------- 

Setup code
- Directory macros
- User written programs

-------------------------------------------- 
*/

	loc set public

	// Enter your base directory here:
	cap cd [enter your path]/public_zip
	
	global rootdir = "`c(pwd)'"
	global rdKB "${rootdir}/rawdata"
	global ddKB "${rootdir}/deriveddata"
	global scKB "${rootdir}/statacode"
	global  oKB "${rootdir}/output"
	global 	tKB "${rootdir}/temp"
		
	// Define programs and set some key variables
	adopath ++ ${scKB}/ado
	set scheme kbcolor, perm
	qui do ${scKB}/KB_infsetup.do
	
	// stop here if we just want to define the environment variables
	if "`nodata'"=="nodata" exit 

	
/*
-------------------------------------------- 

Create underlying data for analysis

-------------------------------------------- 
*/

	// Build the World Bank area data
	do ${scKB}/KB_wbarea.do
	
	// State failure data
	do ${scKB}/KB_sfdata.do
		
	// Create Stata versions of the raw data from CoW
	do ${scKB}/KB_cleancow.do

	// Combine territorial change data with our legal categories
	do ${scKB}/KB_riskdata.do
	
	// Prepare the data on state size
	do ${scKB}/KB_ssdata.do
	
	
/*
-------------------------------------------- 

Analysis code

-------------------------------------------- 
*/
	
	// State count figure
	do ${scKB}/KB_statecount.do
	
	// Independence count figure
	do ${scKB}/KB_indcount.do
	
	// State failure figure
	do ${scKB}/KB_sffig.do	
	
	// Intrastate war figure
	do ${scKB}/KB_intrafig.do
	
	// Risk figure(s)
 	do ${scKB}/KB_riskfig.do

	// State size figure
	do ${scKB}/KB_ssfig.do
	
	
exit	








