/*-------------------------------------------------------------------KB_ssfig.do
This file takes the data from KB_ssdata.do and creates a visualization of
the state size dynamics from 1816-2014. 

Stuart Craig
Last updated: 20170226
*/

timestamp, output
cap mkdir ssfig
cd ssfig

	use ${ddKB}/KB_ssdata.dta, clear

	
/*
-------------------------------------------------------

Identify the largest states in 1816

-------------------------------------------------------
*/

	preserve
		drop if cname=="" // -9s have a lot of area but they aren't states
		keep if year==1816
		keep cname area
		gsort -area
		list in 1/20, noobs clean 
	restore

	/*
	20160308: 1816 largest states

				  cname       area  
		 United Kingdom   2.14e+07  
				 Russia   1.98e+07  
				  Spain   1.53e+07  
				  China   1.15e+07  
			   Portugal    9543644  
					USA    4708147  
				 Turkey    4666581  
				Belgium    2350759  
				 France    2224872  
			Netherlands    1669838  
				   Iran    1658348  
				Germany    1553788  
			   Ethiopia    1314213  
				  Italy     846827  
			Afghanistan     783840  
				 Sweden     732679  
				Myanmar     720172  
		   Turkmenistan     709830  
				Morocco     690335  
		Austria-Hungary     684967  

	 */

/*
-------------------------------------------------------

Create bins for the countries in our visualization

-------------------------------------------------------
*/

	cap drop ccat
	qui gen ccat=.
	loc ctr=0
	loc legend ""
	// Note: the order in this loop determines the order in the figure (bottom to top)
	foreach c in "USA"  "China" "Russia"  "Belgium" "Netherlands" "France" "Turkey" "United Kingdom" "Portugal"   "Spain" {
		loc ++ctr
		qui replace ccat=`ctr' if cname=="`c'" 	// building the aggreagation variable
		if "`c'"=="Turkey" loc legend `"`legend' `ctr' "Turkey/Ottoman Empire""'
		else loc legend `"`legend' `ctr' "`c'""'		// building the legend label
	}
	// Accomodate Independence/Other
	loc ind = `ctr'+1
	loc oth = `ctr'+2
	loc legend `"`legend' `ind' "Independences" `oth' "Other""'

	// Country eventually gains independence if it has no area in 1816
	cap drop temp
	qui gen temp = area if year==1816
	bys cname (temp): replace temp = temp[1] if temp==.
	qui replace ccat=`ind' if temp==0&ccat==.
	// Remainders go to "other"
	qui replace ccat=`oth' if ccat==.

/*
-------------------------------------------------------

Create a list of the states in independence/other 
categories

-------------------------------------------------------
*/

	preserve
		keep if ccat==`oth'&cname!=""
		bys cname: keep if _n==1
		outsheet cname using KB_ssfig_other.csv, comma replace
		restore
		preserve
		keep if ccat==`ind'&cname!=""
		bys cname: keep if _n==1
		outsheet cname using KB_ssfig_independences.csv, comma replace
	restore

	sort ccat merge_num year
	qui replace cname="Not in State System" if merge_num==0
	format area %12.0f
	outsheet using KB_ssfig_allstock.csv, comma replace
	
/*
-------------------------------------------------------

Collapse stock data down to yearly totals for 
the relevant bins

-------------------------------------------------------
*/

	qui replace cname="Independences" if ccat==`ind'
	collapse (sum) area (first) cname, by(year ccat) fast
	format area %12.0f
	outsheet using KB_ssfig_catstock.csv, comma replace
	drop cname
	reshape wide area, i(year) j(ccat)

	// Create cumulative totals for the area graph
	forvalues c=2/`oth' {
		loc cm1=`c'-1
		qui replace area`c' = area`c'+area`cm1'
	}
	// Scale by 1m
	foreach v of varlist area* {
		qui replace `v'=`v'/1000000
	}
	
	
/*
-------------------------------------------------------

Create the figure

-------------------------------------------------------
*/	


	// Build the area graph statement (flexibly allow for +/- 10 states)
	loc rareas ""
	forval i=2/`oth' {
		loc im1=`i'-1
		loc rareas "`rareas' || rarea area`i' area`im1' year"
	}
	sort year
	tw area area1 year `rareas', ///
		legend(order("`legend'") col(4)) ///
		ytitle("Sq. Km. (millions)") ylab(0(30)120) xtitle("Year")
	foreach t in png /* wmf emf */ {
		graph export KB_ssfig_area.`t', as(`t') replace		
	}
e
