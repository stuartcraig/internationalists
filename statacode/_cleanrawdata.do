/*--------------------------------------------------------------_cleanrawdata.do
This file prepares the anonymized legal categories data. In the original
spreadsheet, we track the names of the coders who recorded the legal categories
for the conquest data. This code cleans that data for use in Stata, and
creates an invertible coder key. 

This file is not for use with the public codebase. Rather it is left here
as a record of how we pre-processed the legal categories for use in the rest 
of the data preparation process. 

Stuart Craig
Last updated: 20170226
*/

import excel using ${rdKB}/cow/coredata/20151015_graphsandworkbook.xlsx, sheet("master_coding") clear
	
rename B o_n
rename C tc_number_s // we will use this to merge to tc data later
rename D o_coder1
rename E o_coder2

rename G q1
rename H q2
rename I q3
rename J q4
rename K q5
rename L q6
rename M q7

rename O o_gain
rename P o_lose

rename U kb_point
rename V kb_ever

drop if inlist(A,"(Poss. remove from dataset)","removed from dataset")
keep o_* tc_number q? kb_*
drop in 1/3
drop if tc_number_s==""

foreach v of varlist q? {
	cap drop temp
	rename `v' temp
	qui gen `v' = real(temp)
}
drop temp

// Anonymize the coders
preserve
	keep o_coder1 o_coder2
	gen i=_n
	reshape long o_coder, i(i) j(j)
	keep o_coder
	bys o_coder: keep if _n==1
	drop if missing(o_coder)
	sort o_coder
	gen codernum=_n
	rename o_coder merge_coder
	tempfile coderkey
	save ${ddKB}/KB_coderkey.dta, replace
restore

foreach v of varlist o_coder* {
	cap drop _merge
	cap drop merge_coder
	rename `v' merge_coder 
	merge m:1 merge_coder using ${ddKB}/KB_coderkey.dta
	drop if _m==2
	rename codernum `v'
}
drop merge_coder _merge
drop o_gain o_lose kb_*

outsheet using ${rdKB}/cow/coredata/20151211_legalcategories.csv, comma replace


