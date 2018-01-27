/*------------------------------------------------------KB_riskdata_conqflags.do
This file creates conquest flags that account for whether the prior
transfer (in a reversion chain) was recognized in the first place. 
		
Stuart Craig
Last updated: 20170519
*/


/*
----------------------------------------

First, create a flag for whether the 
conflict is reverting a non-recognized 
transfer

----------------------------------------
*/

	preserve
		qui gen l1_recognized=q4>2
		keep l1_recognized tc_number_s
		rename tc_number_s merge_num
		tempfile sovs
		save `sovs', replace
	restore

	cap drop _merge
	qui gen merge_num = string(reversion_to)
	merge m:1 merge_num using `sovs'
	drop if _m==2
	drop _merge merge_num
	label var l1_recognized "Reversion of prior transfer that was recognized"

/*
----------------------------------------

Now, create conquest flags from the
lag recognition flag and q#s

l1_recognized!=0 excludes from the 
conquest category any transfers which
revert a previously unrecognized 
conquest

The INCLUDES categories are: 
inlist(l1_recognized,1,.)

----------------------------------------
*/

	pfixdrop conq
	qui gen conq_r = 	q3==0	& ///
						q4>2	& ///
						q6==0	& ///
						q7==1	& ///
						l1_recognized!=0 
						
	qui gen conq_nr = 	q3==0	& ///
						q4<=2	& ///
						q6==0	& ///
						q7==1	& ///
						l1_recognized!=0

	label var conq_r  "Recognized Conquest"
	label var conq_nr "Non-recognized Conquest"
	
			
					
exit					
