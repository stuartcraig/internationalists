/*----------------------------------------------------KB_riskdata_idrev_setup.do
Creates empty reversion/reverted vars

Stuart Craig
Last updated 20170226
*/

	foreach t in reverted reversion {
		cap drop `t'_how
		qui gen `t'_how=-9
		#d ;
		label define rev_how
			-9 "NYA"
			 0 "INAP"
			10 "Manual--land match"
			11 "Manual--logical checks"
			20 "Automatic--land/name match"
			30 "Remainders", replace;
		#d cr
		label val `t'_how rev_how
		label var `t'_how "Method by which reversion data was assigned"

		
		cap drop `t'_yn
		cap drop `t'_to
		cap drop `t'_by
		qui gen `t'_yn=-9
		qui gen `t'_to=-9
		qui gen `t'_by=-9
		#d ;
		label define rev_toby
			-9 "NYA"
			-8 "Not in COW"
			 0 "INAP", replace;
		label define rev_yn
			-9 "NYA" 
			 0 "0: No"
			 1 "1: Yes", replace;
		#d cr
		label val `t'_to rev_toby
		label val `t'_by rev_toby
		label val `t'_yn rev_yn
		
		
	}
	// These are nonsensical 
	drop reverted_to
	drop reversion_by 

	cap drop reversion_toplus
	qui gen reversion_toplus = ""

exit
