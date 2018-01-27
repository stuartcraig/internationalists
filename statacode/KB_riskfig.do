/*-----------------------------------------------------------------KB_riskfig.do
Creates figures describing rate of conquest by year and state-year.

20170830
- Figure type update (no emf/wmf for compatibility)

Stuart Craig
Last updated: 20170830
*/


timestamp, output
cap mkdir riskfig
cd riskfig

loc N=2014-1816+1
tempfile years
clear
set obs `N'
gen tc_year = _n+1815
save `years', replace

/*
----------------------------------------------------

First, we clean the list of events that feed 
into the risk calculation (or not)

----------------------------------------------------
*/

use ${ddKB}/KB_riskdata.dta, clear

// Bring in names--want to be able to create outputs that have names attached
	foreach v of varlist tc_gainer tc_loser tc_entity {
		cap drop _merge
		cap drop merge_id
		qui gen merge_id = `v'
		merge m:1 merge_id using ${ddKB}/KB_cow_entitylist.dta
		drop if _m==2
		loc stub = subinstr("`v'","tc_","",.)
		rename entity_str `stub'_string
		drop _merge
		
		// In this case, missings should be flagged
		qui replace `stub'_string = "NONMATCH" if missing(`stub'_string)
		
	}


	// Typology of transfers in the KB/core data
	cap drop type
	qui gen type = .
	qui replace type = 1 if conq_r&reverted_yn==0
	qui replace type = 2 if conq_r&reverted_yn==1	
	qui replace type = 3 if conq_nr&reverted_yn==0
	qui replace type = 4 if conq_nr&reverted_yn==1
	qui replace type = 5 if q6==1&type==.
	qui replace type = 6 if q7!=1&type==.
	qui replace type = 7 if q3==1&type==.
	
	#d ;
	label define type
		1 "1: Recognized, not reverted"
		2 "2: Recognized, reverted"
		3 "3: Non-recognized, not reverted"
		4 "4: Non-recognized, reverted"
		5 "5: Independence"
		6 "6: No claim of sov"
		7 "7: Multi-nat. assist", replace;
	label val type type;
	#d cr

	// Output list of (1) all conquests (2) all transfers
	sort period type
	outsheet period type tc_year tc_number_s gainer_s loser_s tc_area q* reverted* *instate   ///
		if q3==0&q6==0&q7==1 ///
		using KB_riskfig_transferlist_conq.csv, comma replace
		
	sort period type
	outsheet period type tc_year tc_number_s gainer_s loser_s tc_area q* reverted* *instate   ///
		using KB_riskfig_transferlist_all.csv, comma replace
		
		
		
/*
----------------------------------------------------

Next, create risk numbers in our very coarse
time bands

----------------------------------------------------
*/	
	
	// Here, we only care about "conquests"
	cap drop type
	pfixdrop conqtype
	qui gen type = .
	qui replace type = 1 if conq_r&reverted_yn==0
	qui replace type = 2 if conq_r&reverted_yn==1
	qui replace type = 3 if conq_nr&reverted_yn==0
	qui replace type = 4 if conq_nr&reverted_yn==1
	tab type, generate(conqtype)

	// Create area measures for each of these conquest types
	foreach v of varlist conqtype* {
		loc t = subinstr("`v'","type","area",.)
		cap drop `t'
		qui gen double `t' = tc_area if `v'==1
	}

	
	preserve	
		// Collapse to a yearly number and fill in empty years
		collapse (sum) conqtype* conqarea* q6 (first) period, by(tc_year) fast
		
		/*
		tsset tc_year
		tsfill
		*/
		cap drop _merge
		merge 1:1 tc_year using `years'
		drop _merge
		
		foreach v of varlist conq* q6 {
			qui replace `v'=0 if `v'==.
		}

		// We did a collapse and fillin so remake the period flag
		cap drop period
		recode tc_year (1816/1928=1) (1929/1948=2) (1949/2014=3) (*=.), generate(period)
		#d ;
		label define period
			1 "1: 1816-1928"
			2 "2: 1929-1948"
			3 "3: post-1949", replace;
		label val period period;
		#d cr
		
		// How many countries
		cap drop _merge
		cap drop year
		qui gen year = tc_year
		merge 1:1 year using ${ddKB}/KB_cow_countrycount.dta
		drop if _m==2

		rename count stateyears
		collapse (sum) conq* q6  (count) year (sum) stateyears, by(period) fast

		// Per year
		pfixdrop rate_
		foreach v of varlist conq* q6 {
			qui gen rate_`v'=`v'/year
		}
	
		/*
		graph bar (asis) rate_conqtype?, over(period) stack ///
			bar(1, color("${red}") fi(inten80)) ///
			bar(2, color("${red}") fi(inten20)) ///
			bar(3, color("${blu}") fi(inten80)) ///
			bar(4, color("${blu}") fi(inten20)) ///
			legend(label(1 "True Conquest") label(2 "True Conquest/Reverted") label(3 "Non-recognized") label(4 "Non-recognized/Reverted") ) ///
			title("Conquests per year, 1816-2014")  ///
			ytitle("Number of conquests per year") blabel(bar, size(medsmall)) ///
			note("`note'")
		graph export KB_riskfig_coarse_1conqperyear.png, as(png) replace

		graph bar (asis) rate_conqarea?, over(period) stack ///
			bar(1, color("${red}") fi(inten80)) ///
			bar(2, color("${red}") fi(inten20)) ///
			bar(3, color("${blu}") fi(inten80)) ///
			bar(4, color("${blu}") fi(inten20)) ///
			legend(label(1 "True Conquest") label(2 "True Conquest/Reverted") label(3 "Non-recognized") label(4 "Non-recognized/Reverted") ) ///
			title("Territory conquered per year, 1816-2014") ///
			ytitle("Sq. Km. conquered per year") blabel(bar, size(medsmall)) ///
			note("`note'")
		graph export KB_riskfig_coarse_2terrperyear.png, as(png) replace	
		*/

		// Recognized/Not Recognized, all not reverted (Chapter 14, figure 2)
		graph bar (asis) rate_conqarea1 rate_conqarea3, over(period) ///
			bar(1, color(gs0) fcolor(gs0) fintensity(inten100)) ///
			bar(2, color(gs5)) ylab(,format(%10.0fc)) ///
			legend(order(1 "Recognized" 2 "Not Recognized") region(lw(0)))
		foreach t in png /* emf wmf */ {
			graph export KB_riskfig_nonrev.`t', as(`t') replace
		}
		gen recognized		= rate_conqarea1
		gen notrecognized	= rate_conqarea3
		outsheet recognized notrecognized period using KB_riskfig_nonrev.csv, comma replace
		
		outsheet using KB_riskfig_coarse_stats_1peryear.csv, comma replace
	restore
	
	
	// Per state-year	
	preserve
		// To make a statement about a state's risk of being conquered, 
		// we have to exclude any conquests where the loser is a non-state
		// entity!
		drop if loser_instate==0
		
		// Collapse to a yearly number and fill in empty years
		collapse (sum) conqtype* conqarea* q6 (first) period, by(tc_year) fast
		
		/*
		tsset tc_year
		tsfill
		*/
		cap drop _merge
		merge 1:1 tc_year using `years'
		drop _merge
		
		foreach v of varlist conq* q6 {
			qui replace `v'=0 if `v'==.
		}

		// We did a collapse and fillin so remake the period flag
		cap drop period
		recode tc_year (1816/1928=1) (1929/1948=2) (1949/2014=3) (*=.), generate(period)
		#d ;
		label define period
			1 "1: 1816-1928"
			2 "2: 1929-1948"
			3 "3: post-1949", replace;
		label val period period;
		#d cr
		
		// How many countries
		cap drop _merge
		cap drop year
		qui gen year = tc_year
		merge 1:1 year using ${ddKB}/KB_cow_countrycount.dta
		drop if _m==2

		rename count stateyears
		collapse (sum) conq* q6  (count) year (sum) stateyears, by(period) fast
		
		// Per state/year
		pfixdrop rate_
		foreach v of varlist conq* {
			qui gen rate_`v'=`v'/stateyears
		}

		graph bar (asis) rate_conqtype?, over(period) stack ///
			bar(1, color("${red}") fi(inten80)) ///
			bar(2, color("${red}") fi(inten20)) ///
			bar(3, color("${blu}") fi(inten80)) ///
			bar(4, color("${blu}") fi(inten20)) ///
			legend(label(1 "True Conquest") label(2 "True Conquest/Reverted") label(3 "Non-recognized") label(4 "Non-recognized/Reverted") ) ///
			title("Conquests per state-year, 1816-2014")  ///
			ytitle("Number of conquests per state-year") blabel(bar, size(medsmall)) ///
			note("`note'")
		graph export KB_riskfig_coarse_3conqperstateyear.png, as(png) replace

		graph bar (asis) rate_conqarea?, over(period) stack ///
			bar(1, color("${red}") fi(inten80)) ///
			bar(2, color("${red}") fi(inten20)) ///
			bar(3, color("${blu}") fi(inten80)) ///
			bar(4, color("${blu}") fi(inten20)) ///
			legend(label(1 "True Conquest") label(2 "True Conquest/Reverted") label(3 "Non-recognized") label(4 "Non-recognized/Reverted") ) ///
			title("Territory conquered per state-year, 1816-2014") ///
			ytitle("Sq. Km. conquered per state-year") blabel(bar, size(medsmall)) ///
			note("`note'")
			
		graph export KB_riskfig_coarse_4terrperstateyear.png, as(png) replace

		outsheet  using KB_riskfig_coarse_stats_2perstateyear.csv, comma replace
		
	restore		
	*/	
		
		
/*
----------------------------------------------------

Next, create risk numbers BY 10-YEAR BINS

----------------------------------------------------
*/		

	
	collapse (sum) conqtype* conqarea* q6, by(tc_year)
	tsset tc_year
	tsfill
	foreach v of varlist conqtype* conqarea* {
		qui replace `v' = 0 if `v'==.
	}
	
	/* we don't do the stateyear calc here */
	
	cap drop dec
	qui gen dec = tc_year - mod(tc_year,10)
	qui gen decc = dec // just to center the decade at the right spot!
	collapse (sum) conqtype* conqarea* (count) tc_year, by(dec decc) fast
	
	// Create cumulative totals of conquest type
	pfixdrop conqnum
	qui gen conqnum1 = conqtype1
	qui gen conqnum2 = conqnum1 + conqtype2
	qui gen conqnum3 = conqnum2 + conqtype3
	qui gen conqnum4 = conqnum3 + conqtype4
	tw 	bar  conqnum1 decc, color("${red}") barw(8) fi(inten80) || ///
		rbar  conqnum2 conqnum1 decc, color("${red}") barw(8) fi(inten20) || ///
		rbar  conqnum3 conqnum2 decc, color("${blu}") barw(8) fi(inten80) || ///
		rbar  conqnum4 conqnum3 decc, color("${blu}") barw(8) fi(inten20) ///
		title("Number of conquests per decade, 1816-2014") xtitle("") ///
		xline(1928, lc(black) lw(medthick)) ///
		xline(1945, lc(black) lw(medthick)) ///
		xlab(/* 1800 1850 1900 1928 1945 2000*/ 1810(10)2010, tick angle(50)) ///
		legend(	label(1 "True Conquest") ///
				label(2 "True Conquest/Reverted") ///
				label(3 "Non-recognized")  ///
				label(4 "Non-recognized/Reverted") ) 
	foreach t in png /* wmf emf */ {
		graph export KB_riskfig_dec_counts.`t', as(`t') replace
	}
	
	qui gen conqa1 = conqarea1
	qui gen conqa2 = conqa1 + conqarea2
	qui gen conqa3 = conqa2 + conqarea3
	qui gen conqa4 = conqa3 + conqarea4
	foreach v of varlist conqa* {
		replace `v'=`v'/1000000
	}
	tw 	bar  conqa1 decc, color("${red}") barw(8) fi(inten80) || ///
		rbar  conqa2 conqa1 decc, color("${red}") barw(8) fi(inten20) || ///
		rbar  conqa3 conqa2 decc, color("${blu}") barw(8) fi(inten80) || ///
		rbar  conqa4 conqa3 decc, color("${blu}") barw(8) fi(inten20) ///
		title("Area conquered per decade, 1816-2014", pos(12)) xtitle("") ///
		ytitle("Territory conquered (millions sq. km)") ///
		xline(1928, lc(black) lw(medthick)) ///
		xline(1945, lc(black) lw(medthick)) ///
		xlab(/* 1800 1850 1900 1928 1945 2000*/ 1810(10)2010, tick angle(50)) ///
		legend(	label(1 "Recognized")  ///
				label(2 "Recognized and Later Reverted") /// 
				label(3 "Not Recognized") ///
				label(4 "Not Recognized and Later Reverted") ) 		
	foreach t in png /* wmf emf */ {
		graph export KB_riskfig_dec_area.`t', as(`t') replace
	}

	rename conqarea1 area_rec_notrev		
	rename conqarea2 area_rec_rev			
	rename conqarea3 area_nonrec_notrev
	rename conqarea4 area_nonrec_rev		
	
	rename conqtype1 cq_rec_notrev	
	rename conqtype2 cq_rec_rev		
	rename conqtype3 cq_nonrec_notrev
	rename conqtype4 cq_nonrec_rev	
			  
	outsheet dec area_* cq_* using KB_riskfig_dec_stats.csv, comma replace
	
exit
	
		
