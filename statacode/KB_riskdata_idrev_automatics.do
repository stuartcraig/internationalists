/*-----------------------------------------------KB_riskdata_idrev_automatics.do
Performs automatic assignments ('super-safe') where the name matches
perfectly and the land is within 10% or 10 sq km.

Stuart Craig
Last updated 20170226
*/


/*
----------------------------------------------------

1. Create the list of automatic reversions

----------------------------------------------------
*/

	preserve
		use ${tKB}/temp_matchmatrix.dta, clear
		
		
		keep if match_land==1&match_name==1 // &l_number_c!="" // only show matches where l_ conflict is in the coredata
		drop if l_number_c==""&r_number_c=="" // we don't care if there's nothing at stake
		//-----------------------------------------------1. Output a list of the matches

		log using KB_riskdata_idrev_automatics.txt, text replace
		/*
		-----------------------------------------
		This is a list of (near)perfect matches 
		where the 'reverted' conflict is in the 
		legal categories data
		-----------------------------------------
		*/
		
		list 	l_number* l_gainer_s l_loser_s l_year l_area l_conq* ///
				r_number* r_gainer_s r_loser_s r_year r_area r_q2 match* if match_land==1&match_name==1, sepby(l_number) noobs
		log close
		
		// Nothing can be used more than once
		cap drop tempNl_number
		cap drop tempNr_number
		bys l_number: gen tempNl_number = _N
		bys r_number: gen tempNr_number = _N
		foreach v of varlist l_number r_number {
			cap assert tempN`v'==1 
			if _rc!=0 {
				di "Cases where we're trying to revert something twice"
				sort `v'
				list 	l_number* l_gainer_s l_loser_s l_year l_area l_conq* ///
						r_number* r_gainer_s r_loser_s r_year r_area r_q2 match* if match_land==1&match_name==1&tempN`v'>1, sepby(`v')
				cap assert inlist(r_number,612,397) if match_land==1&match_name==1&tempN`v'>1
				if _rc!=0 {
					pause on
					pause
				}
			}
			drop if tempN`v'>1
		}
		
		
		//-----------------------------------------------2. Create a dataset and bring it back into the coredata
		tempfile automatics
		save `automatics', replace
	restore

/*
----------------------------------------------------

2. Identify them in the original dataset

----------------------------------------------------
*/
	cap drop _merge
	cap drop l_number
	cap drop r_number
	qui gen l_number = real(tc_number_s)
	merge 1:1 l_number using `automatics', keepusing(r_number)
	* assert _m!=2
	drop if _m==2
	assert (reverted_how==-9&reverted_yn==-9&reverted_by==-9)|inlist(reverted_how,10,11) if _m==3
	qui replace reverted_yn		= 1 		if _m==3&reverted_how==-9
	qui replace reverted_by		= r_number 	if _m==3&reverted_how==-9
	qui replace reverted_how 	= 20 		if _m==3&reverted_how==-9
	drop _merge l_number r_number

	cap drop _merge
	cap drop l_number
	cap drop r_number
	qui gen r_number = real(tc_number_s)
	merge 1:1 r_number using `automatics', keepusing(l_number)
	drop if _m==2 // some reverting events are not conflicts
	assert (reversion_how==-9&reversion_yn==-9&reversion_to==-9)|inlist(reversion_how,10,11) if _m==3
	qui replace reversion_yn	= 1 		if _m==3&reversion_how==-9
	qui replace reversion_to	= l_number 	if _m==3&reversion_how==-9 
	qui replace reversion_how	= 20 		if _m==3&reversion_how==-9
	drop _merge
	
	
exit
