/*----------------------------------------------------------KB_riskdata_idrev.do
Control file for process by which we identify reverted conflicts

Stuart Craig
Last updated 20170226
*/

timestamp, output
cap mkdir idrev
cd idrev

// Creates matrix of potential reverted/reverting conflicts
	do ${scKB}/KB_riskdata_idrev_matchmatrix.do

// Use the match matrix to assign reversions
	use ${tKB}/temp_tclc.dta, clear // created in KB_riskdata_combinetclc.do
	
		do ${scKB}/KB_riskdata_idrev_setup.do

		do ${scKB}/KB_riskdata_idrev_manuals.do "20150925" // takes in the date of most recent "manuals" file

		do ${scKB}/KB_riskdata_idrev_automatics.do

		do ${scKB}/KB_riskdata_idrev_checks.do

		do ${scKB}/KB_riskdata_idrev_remainders.do
		
		// Some light clean up of the data
		foreach p in temp merge r_number l_number {
			pfixdrop `p'
		}
		
	// Overwrite the temp file with new version including reversions	
	save ${tKB}/temp_tclc.dta, replace	

exit
