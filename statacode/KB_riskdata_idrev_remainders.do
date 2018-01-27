/*-----------------------------------------------KB_riskdata_idrev_remainders.do
Two things happen in this file:

1. We produce a list of remainder cases--places where the land is close in 
the match matrix but they are not labeled a reversion because the name doesn't
match. The resulting file becomes the input for the landonly manual assignments.

2. We take the NYA observations and code them as non reversions/reverted. 

Stuart Craig
Last updated 20170226
*/


// Create a dated folder in output for the land-only remainders
timestamp, output
cap mkdir idrev
cd idrev



/*
-----------------------------------------------

Produce a list of remainder cases (land only).

-----------------------------------------------
*/


	// If we found a reversion for you, then we 
	// exclude you from the LHS of the matrix
	preserve
		keep if reverted_how>-9
		keep reverted_by tc_number
		rename tc_number merge_num
		tempfile reverted
		save `reverted', replace
	restore

			
	// If we found a reverted for you, then we 
	// exclude you from the RHS of the matrix
	preserve
		keep if reversion_how>-9
		keep reversion_to tc_number
		rename tc_number merge_num
		tempfile reversions
		save `reversions', replace
	restore

	// Grab the matrix and produce a potential
	// match list using the narrowed matrix
	preserve
		use ${tKB}/temp_matchmatrix.dta, clear
		
		cap drop merge_num
		cap drop _merge
		qui gen merge_num=l_number
		merge m:1 merge_num using `reverted'
		// we don't care about any of these vectors
		drop if _m==3
		
		cap drop merge_num
		cap drop _merge
		qui gen merge_num=r_number
		merge m:1 merge_num using `reversions'
		// we don't care about any of these elements
		drop if _m>1 // sometimes _m==2 because of the first round of deletions
		
		tab *land* *name*
		* keep if match_name|match_land
		// If the name matches, but land doesn't, it isn't a reversion
		keep if match_land
		keep if l_number_c!=""|r_number_c!=""
		gsort -match_name -match_land
		outsheet  l_number* l_gainer_s l_loser_s l_year l_area l_conq* ///
			r_number* r_gainer_s r_loser_s r_year r_area r_q2 match*  ///
			using KB_riskdata_idrev_landonly.csv, comma replace // this file becomes the source file for the landclose manuals
	restore

	
/*
-----------------------------------------------

Assign what's left over.

-----------------------------------------------
*/	
	
	qui replace reverted_by=0 		if reverted_by==-9
	qui replace reverted_yn=0 		if reverted_yn==-9
	qui replace reverted_how=30 	if reverted_how==-9
	qui replace reversion_to=0 		if reversion_to==-9
	qui replace reversion_yn=0 		if reversion_yn==-9
	qui replace reversion_how=30 	if reversion_how==-9
	
exit
