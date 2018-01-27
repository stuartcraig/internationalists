/*------------------------------------------------------------------KB_ssdata.do
The purpose of this file is to use world bank totals and the flow data from 
COW to create stock data to measure change in state/empire size over time

First, we match COW country codes to the World Bank data on state size in 2014. 
We then use the TC data to trace all transfers backward, creating stock data
for every year.  

Stuart Craig
Last updated: 20170226
*/


cap confirm file ${ddKB}/KB_ssdata.dta
if _rc!=0 {

/*
-------------------------------------------------------

Create a key matching WB territories to COW entities

-------------------------------------------------------
*/


// Bring in the World Bank data, make some manual corrections to facilitate the match
	use ${ddKB}/KB_wbarea.dta, clear
	keep if year==2014
	
	qui replace cname = "Bosnia-Herzegovina" if cname=="Bosnia and Herzegovina"
	qui replace cname = "Brunei" 		if cname=="Brunei Darussalam"
	qui replace cname = "Cape Verde" 	if cname=="Cabo Verde"
	qui replace cname = "Egypt" 		if cname=="Egypt, Arab Rep."
	qui replace cname = "Ivory Coast" 	if cname=="Cote d'Ivoire"
	qui replace cname = "Iran" 			if cname=="Iran, Islamic Rep."
	qui replace cname = "Kyrgyzstan"	if cname=="Kyrgyz Republic"
	qui replace cname = "Laos"			if cname=="Lao PDR"
	qui replace cname = "Macedonia" 	if cname=="Macedonia, FYR"
	qui replace cname = "Micronesia" 	if cname=="Micronesia, Fed. Sts."
	qui replace cname = "Russia" 		if cname=="Russian Federation"
	qui replace cname = "Sao Tome-Principe" if cname=="Sao Tome and Principe"
	qui replace cname = "St. Kitts-Nevis" if cname=="St. Kitts and Nevis"
	qui replace cname = "Slovakia" 		if cname=="Slovak Republic"
	qui replace cname = "Syria" 		if cname=="Syrian Arab Republic"
	qui replace cname = "Taiwan" 		if cname=="Taiwan, China"
	qui replace cname = "East Timor"	if cname=="Timor-Leste"
	qui replace cname = "USA" 			if cname=="United States"
	qui replace cname = "Venezuela" 	if cname=="Venezuela, RB"
	qui replace cname = "Yemen" 		if cname=="Yemen, Rep."
	qui replace cname = subinstr(cname,", The","",.) // gambia, bahamas
	
	qui replace cname = "North Korea"	if cname=="Korea, Dem. Rep."
	qui replace cname = "South Korea"	if cname=="Korea, Rep."
	
	qui replace cname="Yugoslavia"		if cname=="Serbia"
	
	// Dropping non-state entries
	drop if inlist(cname,"Arab World","Caribbean small states", ///
		"Central Europe and the Baltics","Euro area","European Union","South Asia", ///
		"North America", "Not classified","World")
	drop if strpos(cname,"East Asia & Pacific")>0
	drop if strpos(cname,"Europe & Central Asia")>0
	drop if strpos(cname,"Fragile and conflict")>0
	drop if strpos(cname,"Heavily indebted")>0
	drop if strpos(cname,"income")>0
	drop if strpos(cname,"Least developed")>0
	drop if strpos(cname,"Latin America")>0
	drop if strpos(cname,"states")>0
	drop if strpos(cname,"Africa")>0&!inlist(cname,"Central African Republic","South Africa")
	drop if strpos(cname,"OECD")>0
	
	// Correction:
	qui replace area = 13812 if cname=="Montenegro"
	qui replace area = 83869 if cname=="Austria" // CoW counts water
	qui replace area = 65301 if cname=="Lithuania" // CoW counts water
	
	// Create some missings
		set obs `=_N+1'
		qui replace cname = "Nauru" if _n==_N
		qui replace area  = 21 if _n==_N
		qui replace year=2014 if year==.
		
		set obs `=_N+1'
		qui replace cname = "Vatican City" if _n==_N
		qui replace area = 1 if _n==_N
		qui replace year=2014 if year==.

		qui replace area=619745 if cname=="South Sudan" // it's here but no area
		*qui replace area = area - 619745 if cname=="Sudan"
		qui replace area = 1879000 if cname=="Sudan"
		qui replace area=36193  if cname=="Taiwan"
	
	// Some World Bank territories never appear in the 
	// COW because they are actually part of larger states
	// Here we fold them in
	qui replace cname = "Samoa" if cname=="American Samoa"
	qui replace cname = "Denmark" if cname=="Faeroe Islands"
	qui replace cname = "Denmark" if cname=="Greenland"
	qui replace cname = "Netherlands" if cname=="Curacao"
	qui replace cname = "Netherlands" if cname=="Aruba"
	qui replace cname = "Netherlands" if cname=="Sint Maarten (Dutch part)"
	qui replace cname = "France" if cname=="French Polynesia"
	qui replace cname = "France" if cname=="New Caledonia"
	qui replace cname = "France" if cname=="St. Martin (French part)"
	qui replace cname = "USA" if cname=="Guam"
	qui replace cname = "USA" if cname=="Northern Mariana Islands"
	qui replace cname = "USA" if cname=="Puerto Rico"
	qui replace cname = "USA" if cname=="Virgin Islands (U.S.)"
	qui replace cname = "China" if cname == "Hong Kong SAR, China"
	qui replace cname = "China" if cname == "Macao SAR, China"
	qui replace cname = "United Kingdom" if cname=="Isle of Man"
	qui replace cname = "United Kingdom" if cname=="Bermuda"
	qui replace cname = "United Kingdom" if cname=="Cayman Islands"
	qui replace cname = "United Kingdom" if cname=="Channel Islands"
	qui replace cname = "United Kingdom" if cname=="Turks and Caicos Islands"
	qui replace cname = "Israel" if cname=="West Bank and Gaza"
	
	collapse (sum) area (first) year, by(cname) fast 
	
	tempfile wbc
	save `wbc', replace

// Prepare the COW data	
	use ${ddKB}/KB_cow_tc.dta, clear
	
	// Bring in the string names
	foreach v of varlist tc_gainer tc_loser {
		loc vn = subinstr("`v'","tc_","",.)
		cap drop _merge
		cap drop merge_id
		qui gen merge_id = `v'
		merge m:1 merge_id using ${ddKB}/KB_cow_entitylist.dta
		rename entity_str `vn'
		drop if _m==2
	}

	// now keep a list of all gainers and losers
	bys gainer loser: keep if _n==1
	keep *gainer *loser
	rename gainer c1
	rename loser c2
	rename tc_gainer n1
	rename tc_loser n2
	qui gen i=_n
	reshape long c n, i(i) j(side)
	keep c n
	drop if c==""
	bys c: keep if _n==1
	
	// MANUAL FIXES:
	qui replace c = "Luxembourg" if c=="Luxemburg"
	qui replace c = "Marshall Islands" if c=="Marshall Is."
	qui replace c = "Suriname" if c=="Surinam"
	qui replace c = "USA" if c=="United States of America"
	qui replace c = "Micronesia" if c=="Federated States of Micronesia"
	* qui replace c = "Germany" if c=="German Federal Republic" // GDR/east germany is gone by 2014
	qui replace c = "Romania" if c=="Rumania"
	
	* qui replace c = "Czech Republic" if c=="Czechoslovakia"  // Czechoslovakia (315) is a dead state
	qui replace c = subinstr(c,"&","and",.) // this takes out a few cases
	qui replace c = "Congo, Rep." if c=="Congo" // for some reason these are mixed up in COW
	qui replace c = "Congo, Dem. Rep." if c=="Zaire (Kinshasa) (Belgian Congo)"|c=="Democratic Republic of the Congo"
	* qui replace c = "Serbia" if c=="Yugoslavia" // rather than code a transfer to Serbia, 
												// COW seems to continue it as the Yugoslavia
	qui replace c = "Vietnam" if n==816
	
	qui gen cname = c
	qui gen year=2014
	merge 1:1 cname year using `wbc'
	
	
	// Identify dead states:
	qui gen dead = 0
	qui replace dead=1 if inlist(cname,"Aden","Al Hasa","Anhalt Dessau","Asir","Austria-Hungary")
	qui replace dead=1 if inlist(cname,"Baden","Bavaria","Bremen","Brunswick","Cracow") 
	qui replace dead=1 if inlist(cname,"Danzig","Frankfurt","Hamburg","Hanover","Hawaii")
	qui replace dead=1 if inlist(cname,"Hejaz Sultanate","Hesse Electoral","Hesse Grand Ducal","Hohenzollern Hechingen")
	qui replace dead=1 if inlist(cname,"Kashmir","Korea","Lippe","Lucca","Mecklenburg Schwerin")
	qui replace dead=1 if inlist(cname,"Mecklenburg Strelitz","Modena","Nassau","Natal","Newfoundland")
	qui replace dead=1 if inlist(cname,"Oldenburg","Orange Free State (Orange River Colony)")
	qui replace dead=1 if inlist(cname,"Papal States","Parma","Republic of Vietnam","Saxe Weimar","Saxony")
	qui replace dead=1 if inlist(cname,"Schwartzburg Rodolstadt","Schwartzburg Sonderhausen","Sikkim")
	qui replace dead=1 if inlist(cname,"Sind", "Texas", "Transvaal","Tuscany","Two Sicilies")
	qui replace dead=1 if inlist(cname,"Wuerttemburg","Yemen Arab Republic","Yemen People's Republic")
	qui replace dead=1 if inlist(cname,"Zanzibar","Czechoslovakia","Federated Malay States")
	qui replace dead=1 if inlist(cname,"German Democratic Republic","German Federal Republic")
	qui replace area=0 if dead
	// Identify passive states:
	cap prog drop pass_assign
	prog define pass_assign
		args c n
		
		qui replace pass=1 if cname=="`c'"
		qui replace n=`n' if cname=="`c'"
		
	end
	qui gen pass=0
	pass_assign "Haiti"			41
	pass_assign "Andorra"		232
	pass_assign "Guatemala"		90
	pass_assign "Switzerland"	225
	pass_assign "San Marino"	331
	pass_assign "Liechtenstein"	223

	preserve
		// Winnow the list down to things we should expect to match
		qui drop if dead|pass
		qui count if _m<3
		if r(N)>0 {
			timestamp, output
			cap mkdir ssdata
			cd ssdata
			
			// Creating a list of the problematic cases
			cap log close
			log using KB_ssdata_unmatched.txt, text replace
				/* THESE COUNTRIES ARE IN THE COW DATA ONLY */
				list cname n if _m==1, noobs
				/* THESE COUNTRIES ARE IN THE WORLD BANK DATA ONLY */
				list cname n if _m==2, noobs
			log close
		}
	restore
	
	* keep if _m==3
	rename _merge type
	#d ;
	label define type
		1 "COW only"
		2 "WB only"
		3 "Matched", replace;
	#d cr
	label val type type
	qui replace n = _n+10000 if n==. // create out of range mergenum placeholders
		
	keep n cname area type
	rename area area2014
	rename n merge_num
	
	tempfile cow_wb_key
	save `cow_wb_key', replace
	

/*
-------------------------------------------------------

Next, let's use this key to trace the transfers 
backwards

-------------------------------------------------------
*/

	use ${ddKB}/KB_cow_tc.dta, clear
	
	// Each transfer counts for the gainer and the loser
	expand 2
	qui gen merge_num = .
	sort tc_number_s
	by tc_number_s: replace merge_num = tc_gainer if _n==1
	by tc_number_s: replace merge_num = tc_loser if _n==2
	qui gen flow = .
	by tc_number_s: replace flow = -tc_area if _n==1
	by tc_number_s: replace flow = tc_area if _n==2

	cap drop _merge
	merge m:1 merge_num using `cow_wb_key' // here's where the key comes in, attaching 2014 areas to the countries in the TC data
	qui replace type = 1 if _merge==1
	qui replace area2014=0 if type==1
	qui replace tc_year=2014 if type==2

	keep tc_year merge_num flow cname area2014
	rename tc_year year 

	collapse (sum) flow (first) cname area2014, by(year merge_num) fast

	// Create a country/year file, and fill in the missing stuff for new obs
	tsset merge_num year
	tsfill, full
	bys merge_num (area2014): replace area2014=area2014[1] if area2014==.
	bys merge_num (cname) : replace cname = cname[_N] if cname==""
	qui replace flow = 0 if flow==. // nothing happened if we didn't already have a flow val for that year

	// Trace the transfers backwards
	gsort merge_num -year
	bys merge_num: gen flowtot = sum(flow)
	qui gen area = area2014 + flowtot 

	// Run a check for negative values
	pfixdrop temp
	qui gen temp1 = area<0
	qui egen temp2 = max(temp1), by(cname)

	// How often is this a simple size difference?
		// Count the unique negative values
		qui gen temp3=area if area<0
		bys cname temp3: gen temp4 = _n==1 if temp3<.
		qui egen temp5 = total(temp4), by(cname) // temp5 is count of unique negatives
		// Is this unique negative value (for singulars) within 10% of all positives?
		qui gen temp6 = area if area>=0
		qui egen temp7 = min(temp6), by(cname)
		qui egen temp8 = mean(temp3), by(cname)
		qui gen temp9 = temp8/temp7<.1	
		qui replace temp2=0 if temp9==1&temp5==1
		qui replace area=max(area,0) if temp9==1&temp5==1 // bottom code this type

	// Australia should have no size before 1931--this is a small discrepancy between WB/CoW
		qui replace area=0 if cname=="Australia"&year<1931
	// Albania has 2 unique values but they are very close
		qui replace area=max(area,0) if cname=="Albania"	
	// Japan has negatives for postwar period--there are two values, but they're close enough
		qui replace area=max(area,0) if cname=="Japan"
	// Sudan loses independence from 1900-1956
		qui replace area=0 if cname=="Sudan"&inrange(year,1900,1956)
	// Small discrepancies where independence hasn't happened yet!
		qui replace area=0 if inlist(cname,"Ecuador","Venezuela")&year<1832
	// Small discrepancy in areas for East Germany
		qui replace area=0 if cname=="German Democratic Republic"&year<1955
	
	// CZ doesn't exist in interward period or before 1918
		qui replace area=0 if cname=="Czechoslovakia"&(year<1919|inrange(year,1940,1945))

	// Produce a list of remaining negatives: 
	cap drop temp_neg
	cap drop temp_mn
	qui gen temp_neg = area<0
	qui egen temp_mn = max(temp_neg), by(cname)
	cap assert temp_mn==0 if cname!="" // by the time we're done, this should produce nothing
	if _rc!=0 {
		timestamp, output
		cap mkdir ssdata
		cd ssdata
		
		gsort cname -year	
		cap log close
		log using KB_ssdata_negarea.txt, text replace
		/* THESE ARE COUNTIRES WHERE THE AREA IS EVER NEGATIVE! */
		qui levelsof cname if temp_mn, local(cs)
		foreach c of local cs {
			di "+------------------------------------------+"
			di "+ `c'"
			di "+------------------------------------------+"
			list cname year area if cname=="`c'", noobs
		}
		log close
	}
	drop temp*


	// Combine league and UN and no political entity
	qui replace merge_num = 0 if inlist(merge_num,-9,0,1)
	collapse (mean) area, by(merge_num cname year) fast
	qui replace area = max(area,0) if merge_num==0
	
	// Need to balance the areas (rounding issues)
	cap drop temp_total1
	cap drop temp_total2
	cap drop temp_adj
	qui egen temp_total1 = total(area), by(year)
	qui egen temp_total2 = max(temp_total1)
	qui gen temp_adj = temp_total2 - temp_total1
	qui replace area = area + temp_adj if merge_num==0
	drop temp*

	save ${ddKB}/KB_ssdata.dta, replace

}
exit
