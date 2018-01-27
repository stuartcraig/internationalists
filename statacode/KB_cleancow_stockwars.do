/*------------------------------------------------------KB_cleancow_stockwars.do
This file creates datasets recording the total number of unique wars 
that are active in a given year. 

Stuart Craig
Last updated: 20170226
*/

// Check to make sure all revelant files exit
	loc switch=0
	cap confirm file ${ddKB}/KB_cow_stockwars_decade.dta
	if _rc!=0 loc switch=1
	cap confirm file ${ddKB}/KB_cow_stockwars_annual.dta
	if _rc!=0 loc switch=1

// If not, create them
	if `switch'==1 {
		cd ${ddKB}
		tempfile build
		loc ctr=0
		fs *state*
		foreach file in `r(files)' {
			loc ++ctr
			use `file', clear
			gen file = "`file'"
			keep file wartype startyear* endyear* 
			
			cap rename endyear endyear1
			cap rename startyear startyear1
			cap gen startyear2 = -8
			cap gen endyear2 = -8
			qui replace endyear1 = startyear1 if endyear1==. // 2 of these and they are brief incidents
			
			if `ctr'>1 append using `build'
			save `build', replace 
		}
		qui gen inter = wartype==1
		
		qui gen extra_colonial = wartype==2
		qui gen extra_imperial = wartype==3
		
		qui gen intra_civilcentral = wartype==4
		qui gen intra_civillocal = wartype==5
		qui gen intra_reginternal = wartype==6
		qui gen intra_intercommun = wartype==7
		
		qui gen nonstate_nsterr = wartype==8
		qui gen nonstate_crossborder = wartype==9
		
		/*
		preserve
			collapse (sum) inter extra* intra* nonstate*, by(startyear1) fast
			save ${ddKB}/KB_cow_summary_begin.dta, replace
		restore
		*/
		
		// Create a variable for each active conflict in that year
		cap drop temp
		qui gen temp = endyear1==startyear2
		qui replace startyear1=startyear2 if temp
		qui replace startyear2 = -8 if temp
		qui replace endyear2 = -8 if temp
		
		gen i=_n
		reshape long startyear endyear, i(i) j(part)
		drop if startyear==-8&endyear==-8
		qui replace endyear=2007 if endyear==-7 // still ongoing in 2007
		
		
		// Create stock data
		qui gen yeartot = endyear - startyear+1
		expand yeartot
		bys i part: gen n=_n
		qui gen year = n-1+startyear
		
		preserve
			collapse (sum) inter extra* intra* nonstate*, by(year) fast
			save ${ddKB}/KB_cow_stockwars_annual.dta, replace
		restore
		preserve
		
		qui gen dec = year - mod(year,10)
		bys dec i: keep if _n==1 // we only want to count a conflict once per decade
		collapse (sum) inter extra* intra* nonstate*, by(dec) fast
		save ${ddKB}/KB_cow_stockwars_decade.dta, replace
	}
	
	
	exit
