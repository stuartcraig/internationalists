/*---------------------------------------------------KB_riskdata_idrev_checks.do
Performs consistency checks--what are the diasgreements (if any) between
the coder's reversions and those identified by the matching process?

Stuart Craig
Last updated 20170226
*/


	/*
	At this point the non-reversions in the 
	matching process are coded as -9: NYA
	*/
	cap drop temp_rev
	qui gen temp_rev = reversion_yn==1
	cap assert temp_rev==q2
	if _rc!=0 {

		cap log close
		log using KB_riskdata_idrev_checks.txt, text replace
		
			tab q2 reversion_yn
			
			/*
			-----------------------------------------
			A. Coders say it's not a reversion, but
			our method produces a disagreement
			-----------------------------------------
			*/
			
			list o_n tc_number_s o_gain o_lose tc_year conq_r conq_nr q2 ///
				reversion_yn reversion_to reversion_how tc_area ///
				if q2==0&reversion_yn>0, ab(30) noobs
				
			/*
			-----------------------------------------
			B. Coders say it's a reversion but we 
			didn't find a reverted conflict!
			--NOT NECESSARILY A MISTAKE--
			
			-----------------------------------------
			*/
			
			list o_n tc_number_s o_gain o_lose tc_year conq_r conq_nr q2 ///
				reversion_yn reversion_to reversion_how tc_area ///
				if q2>0&reversion_yn==-9, ab(30) noobs

		log close
	}
	
	
/*
--------------------------------
As of 20150830 (and actually 
slightly earlier) this produeces 
no "conflicts"!
--------------------------------
*/

exit
