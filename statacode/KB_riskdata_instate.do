/*--------------------------------------------------------KB_riskdata_instate.do
Create a flag for whether the gainer/loser was in/out of the state system in
the year of conquest

Stuart Craig
Last updated: 20170226
*/

	cap drop _merge
	foreach v of varlist tc_gainer tc_loser {
		loc t = subinstr("`v'","tc_","",.)
		cap drop ccode
		qui gen ccode = `v'
		cap drop year
		qui gen year = tc_year
		merge m:1 ccode year using ${ddKB}/KB_cow_countryroster.dta, keepusing(ccode year)
		drop if _m==2
		cap drop `t'_instate
		qui gen `t'_instate = _m==3
		drop _merge ccode year
	}


exit
