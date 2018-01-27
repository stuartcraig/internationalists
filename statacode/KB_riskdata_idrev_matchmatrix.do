 /*---------------------------------------------KB_riskdata_idrev_matchmatrix.do
Creates full match matrix from which we derive our reversions

Stuart Craig
Last updated 20170226
*/


/*
------------------------------------------------------

Bring in the Correlates of war transfer data and 
create string identifiers--we just want to be able
to see who's who in the data

------------------------------------------------------
*/
	use ${ddKB}/KB_cow_tc.dta, clear
	
	foreach v of varlist tc* {
		loc vn=subinstr("`v'","tc_","",.)
		rename `v' `vn'
	}

	loc ctr=0
	foreach v of varlist gainer loser entity {
		
		cap drop merge_id
		cap drop _merge
		qui gen merge_id = `v'
		merge m:1 merge_id using ${ddKB}/KB_cow_entitylist.dta
		drop if _m==2
		cap assert inlist(`v',0,1,-9,.) if _m==1 
		if _rc!=0 {
			loc ++ctr
		
			cap log close
			if `ctr'==1 log using KB_riskdata_idrev_entitynonmatches.txt, text replace
			else log using KB_riskdata_idrev_entitynonmatches.txt, text append
			di "+--------------------------------------------------------------"
			di "+ Problem finding a name for `v' for the following cases"
			di "+ in the entity list"
			di "+--------------------------------------------------------------"
			list if _m==1&!inlist(`v',0,1,-9,.)
			log close
		}
		qui gen `v'_s = entity_str
		drop entity_str
		
	}

/*
------------------------------------------------------

Create right/left files and join them to create
a matrix of all possible reversions

------------------------------------------------------
*/

	keep year gainer loser entity area pop gainer_s loser_s number
	ds
	foreach v in `r(varlist)' {
		rename `v' r_`v'
	}
	qui gen temp_match = r_loser
	tempfile right
	save `right', replace

	drop temp_match
	rename r_* l_*
	qui gen temp_match = l_gainer
	joinby temp_match using `right'
	drop if l_number==r_number
	drop if r_year<l_year // only allow possible date matches
	drop if missing(temp_match)

	// Create markers that the land is within 10/10 and 
	// the country name matches--10% is inclusive i.e. can go either direction
	qui gen match_land = 	(abs((r_area-l_area)/l_area)<.1)| ///
							(abs((l_area-r_area)/r_area)<.1)| ///
							(abs(r_area - l_area)<10) //within 10pct or less than 10 sq km
	qui gen match_name = l_loser==r_gainer

	
/*
------------------------------------------------------

Merge on the INTERMEDIATE riskdata to include
preliminary conquest and reversion markers

------------------------------------------------------
*/	

	foreach v of varlist *number {
		loc stub = substr("`v'",1,2)
		
		cap drop tc_number_s
		qui gen tc_number_s = string(`v')
		cap drop _merge
		merge m:1 tc_number_s using ${tKB}/temp_tclc.dta, keepusing(o_n q2 conq_r_prelim conq_nr_prelim)
		drop if _m==2
		rename o_n `v'_c
		rename q2 `stub'q2
		rename conq_r_prelim `stub'conq_r_prelim
		rename conq_nr_prelim `stub'conq_nr_prelim
	}

	foreach v of varlist *_s {
		qui replace `v' = substr(`v',1,12)
	}

// Save for use identifying exact matches and outputting the remainder file
	sort l_year l_gainer temp_match l_number r_loser
	save ${tKB}/temp_matchmatrix.dta, replace 

	
exit
