/*----------------------------------------------------------------KB_indcount.do
Creates figure of independence events

20170830
- Figure type update (no emf/wmf for compatibility)

Stuart Craig
Last updated 20170830
*/


timestamp, output
cap mkdir indcount
cd indcount


// Bring in TC data and add our 
	use ${ddKB}/KB_cow_tc.dta, clear
	cap drop _merge
	merge 1:1 tc_number_s using ${ddKB}/KB_riskdata.dta, keepusing(q6)

	gen indep = tc_indep
	qui replace indep = q6 if q6<.

// Produce a list of all independences
	preserve
		foreach v in gainer loser {
			cap drop _merge
			cap drop merge_id
			qui gen merge_id = tc_`v'
			merge m:1 merge_id using ${ddKB}/KB_cow_entitylist.dta
			drop if _m==2
			drop _merge
			rename entity_str `v'
		}
		order gainer loser
		keep if indep==1
		sort tc_year
		outsheet using KB_indcount_list.csv, comma replace
	restore

// Create yearly figure and underlying data
	collapse (sum) indep, by(tc_year) fast
	tsset tc_year
	tsfill
	preserve
		replace indep = 0 if indep==.
		qui gen count=1
		collapse (sum) count indep, by(tc_year) fast
		tw bar indep tc_year, color(gs7)  ///
			title("Number of Independences per Year, 1816-2015") ///
			xtitle("") ytitle("")  ///
			/* xlab(1800 1850 1900 1928 1945 2000) */ xlab(1810(10)2010, angle(50))
		foreach t in png /* emf wmf */ {
			graph export KB_indcount_annual.`t', as(`t') replace
		}
		outsheet tc_year indep using KB_indcount_annual.csv, comma replace
	restore

// Create decade figure and underlying data
	qui gen dec = tc_year - mod(tc_year,10)
	qui gen decc = tc_year - mod(tc_year,10)

	qui gen count=1
	collapse (sum) count indep, by(dec decc) fast
	qui replace indep = indep*(10/count)

	tw bar indep decc, barw(8) color(gs7)  ///
		title("Number of Independences per Decade, 1816-2015") ///
		xtitle("") ytitle("")  ///
		/* xlab(1800 1850 1900 1928 1945 2000) */ xlab(1810(10)2010, angle(50))
	foreach t in png /* emf wmf */ {
		graph export KB_indcount_decade.`t', as(`t') replace
	}
	outsheet dec indep using KB_indcount_decade.csv, comma replace


exit
