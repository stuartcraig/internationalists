/*----------------------------------------------------KB_riskdata_combinetclc.do
Brings legal categories data into Stata format and creates value labels
for the variables. 

Here, we also create preliminary conquest flags. These are somewhat incomplete
in that they do not incorporate the restriction that a conquest not be undoing
a prior non-recognized conquest!. For the update procedure see: 

KB_riskdata_conqflags.do	
	
Stuart Craig
Last updated: 20170226
*/
args dt

	// Prep the "coredata"
	insheet using ${rdKB}/cow/coredata/`dt'_legalcategories.csv, comma clear
	
	// Labeling the legal category vars
	#d ;
	label var q1 "Q1: Sorvereignty in dispute";
	label define q1
		0 "0: No"
		1 "1: Yes"
		9 "9: Unclear", replace;
	label val q1 q1;
	
	label var q2 "Q2: Reversion";
	label define q2 
		0 "0: No"
		1 "1: Yes"
		9 "9: Unclear", replace;
	label val q2 q2;
	
	label var q3 "Q3: Multinational assist";
	label define q3
		0 "0: No"
		1 "1: Yes"
		9 "9: Unclear", replace;
	label val q3 q3;
	
	label var q4 "Q4: International recognition";
	label define q4
		0 "0: No states"
		1 "1: 1 country other than those involved"
		2 "2: Less than a majority of countries"
		3 "3: Majority of countries"
		4 "4: Nearly all countries"
		9  "9: DK", replace;
	label val q4 q4;
	
	label var q5 "Q5: Declaration of war";
	label define q5
		0 "0: No"
		1 "1: Yes"
		9 "9: DK", replace;
	label val q5 q5;
	
	label var q6 "Q6: Independence";
	label define q6
		0 "0: No" 
		1 "1: Yes" 
		9 "9: DK",replace;
	label val q6 q6;
	
	label var q7 "Q7: Claim of sovereignty";
	label define q7
		0 "0: No"
		1 "1: Yes"
		2 "2: Occupied by mandate of intl org"
		9 "9: DK", replace;
	label val q7 q7;
	#d cr
	
	tempfile codedvars
	save `codedvars', replace

	
	// Load the TC data, restrict and merge in the coded variables
	use ${ddKB}/KB_cow_tc.dta, clear
	keep if tc_conflict==1|tc_procedur==1    // isolate the military conflicts and conquests
	
	cap drop _merge
	merge 1:1 tc_number_s using `codedvars'
	assert _merge==3 // the restrictions above should match those used to 
	drop _merge		 // decide for whom to generate legal categories
	
	/* 
	-----------------------------------------------------------------------
	Here we create PRELIMINARY CONQUEST FLAGS:
	Eventually we update these using reversions as a condition,
	but we also use these conquest flags to (indirectly) help us clean the
	reversion data so we produce them here.
	-----------------------------------------------------------------------
	*/
	
	cap drop conq_r_prelim
	qui gen conq_r_prelim = 	q3==0& /// no multinational assist
								q4>2 & /// majority recognize
								q6==0& /// not an independence
								q7==1  //  there is a claim of sovereignty
	cap drop conq_nr_prelim
	qui gen conq_nr_prelim = 	q3==0&	/// no multinational assist
								q4<=2& /// at least a majority recognize
								q6==0&	/// not an independence
								q7==1	/// claim of sov
	
	
	qui gen period = 1 if tc_year<=1928
	qui replace period = 2 if inrange(tc_year,1929,1948)
	qui replace period = 3 if tc_year>=1949
	#d ;
	label define period
		1 "1: 1818-1928"
		2 "2: 1929-1948"
		3 "3: post-1949", replace;
	label val period period;
	#d cr
	
	save ${tKB}/temp_tclc.dta, replace

exit
