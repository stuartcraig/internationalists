/*--------------------------------------------------KB_riskdata_idrev_manuals.do
Performs manual assignments of various kinds. These are motivated by the
'remainders' file which tells us about transfers that are close but
not safe enough to assign automatically. 

Stuart Craig
Last updated 20170226
*/
args dt


/*
----------------------------------------------

First, pull the manual assignments from
the dataset of pared down cases where 
the land area was a close match

----------------------------------------------
*/	
	
	preserve
		insheet using ${rdKB}/cow/coredata/reversions/KB_riskdata_idrev_landonly_manuals`dt'.csv, comma clear
		keep if rev_mark==1
		tempfile manuals
		save `manuals', replace
	restore

	cap drop _merge
	cap drop l_number
	cap drop r_number
	qui gen l_number = real(tc_number_s)
	merge 1:1 l_number using `manuals', keepusing(r_number)
	* assert _m!=2
	drop if _m==2 // some reverted events were not in the original data
	assert reverted_how==-9&reverted_yn==-9&reverted_by==-9 if _m==3
	qui replace reverted_how 	= 10 if _m==3
	qui replace reverted_yn		= 1 if _m==3
	qui replace reverted_by		= r_number if _m==3
	drop _merge l_number r_number

	cap drop _merge
	cap drop l_number
	cap drop r_number
	qui gen r_number = real(tc_number_s)
	merge 1:1 r_number using `manuals', keepusing(l_number)
	drop if _m==2 // some reverting events are not conflicts
	assert reversion_how==-9&reversion_yn==-9&reversion_to==-9 if _m==3
	qui replace reversion_how	= 10 if _m==3
	qui replace reversion_yn	= 1 if _m==3
	qui replace reversion_to	= l_number if _m==3
	drop _merge
	
	
/*
----------------------------------------------

Manual assignments based on logical checks 
in the data

----------------------------------------------
*/

	cap prog drop rev_manuals
	prog define rev_manuals
		args c1 c2
		
		cap assert `c2'>`c1'|`c1'==-8|`c2'==-8
		if _rc!=0 {
			di in red "`c2' does not occur after `c1'"
			error 12
		}
		// If neither is negative 8, then c2 reverts c1
		if `c2'!=-8 {
			cap assert 	 reversion_yn==-9&reversion_to==-9&reversion_how==-9 if number==`c2'
			if _rc!=0 {
				di in red "`c2' already assigned a reversion transfer"
				di in red "it must be a mistake"
				list number tc_year reversion* if number==`c2', ab(30) noobs
				error 12
			}
		}
		if `c1'!=-8 {
			cap assert reverted_yn==-9&reverted_by==-9&reverted_how==-9 if number==`c1' 
			if _rc!=0 {
				di in red "`c1' already assigned a reverting transfer"
				di in red "it must be a mistake"
				list number tc_year reversion* if number==`c1', ab(30) noobs
				error 12
			}
		}
			qui replace reversion_yn = 1	if number==`c2'
			qui replace reversion_to = `c1'	if number==`c2'
			qui replace reversion_how= 11	if number==`c2'
			qui replace reverted_yn	 = 1 	if number==`c1'
			qui replace reverted_by	 = `c2' if number==`c1'
			qui replace reverted_how = 11	if number==`c1'
		
		
	end
	
	cap drop number
	qui gen number = real(tc_number_s)
	
	// Transvaal/UK transfers didn't go through because there were multiples
	rev_manuals 252 397
	
	// These are reversions that cannot be found in the COW data
	foreach n of numlist 72 225 619 766 {
		rev_manuals -8 `n'
	}
	
	// These are reversions that are of 2 sequential prior events--undone at once
	rev_manuals 579 594
	qui replace reversion_toplus = "576" if number==594 
	rev_manuals 577 593
	qui replace reversion_toplus = "574" if number==593
	rev_manuals 415 600
	qui replace reversion_toplus = "226" if number==600
	
	// 3 prior sequential events (Japan/China)
	rev_manuals 572 602
	qui replace reverted_by = 602 if inlist(number,562,564)
	qui replace reverted_yn = 1	if inlist(number,562,564)
	qui replace reverted_how = 11 if inlist(number,562,564)
	
	
	drop number
	
exit
