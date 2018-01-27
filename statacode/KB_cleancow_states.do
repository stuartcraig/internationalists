/*---------------------------------------------------------KB_cleancow_states.do
Creates roster of states, stock data on state system, and an entity list 
to bring in string names for country codes (mostly for cleaning)

Stuart Craig
Last updated: 20170226
*/

	
/*
---------------------------------------------------------

Clean the country list and create a country count
file for the risk calculations

---------------------------------------------------------
*/	

	// Build stock data from the flow data
	cap confirm file ${ddKB}/KB_cow_countryroster.dta
	if _rc!=0 {
		qui insheet using ${rdKB}/cow/states/states2011.csv, comma clear
		
		/* the file contains a list of countries with start and end dates
		we will expand by the total years covered and fill in starting with 
		the styear--do this by a new index so that we don't confuse
		multiple country spells! (eg cuba) */
		
		// create a series ID that keeps track of country "spells"
		cap drop seriesid
		qui gen seriesid = _n
		// create the number of copies necessary to span the spell
		cap drop temp_nyears
		qui gen temp_nyears = endyear-styear+1
		expand temp_nyears
		cap drop year
		bys seriesid: gen year = _n+styear-1 // number them from styear to endyear
		
		rename statenme state
		
		keep ccode state year
		sort year
		
		// Add new obs for years after 2011
		expand 4 if year==2011
		bys ccode year: replace year = year[_n-1]+1 if _n>1
		
		save ${ddKB}/KB_cow_countryroster.dta, replace
	}

	// Create a count dataset and graph it
	cap confirm file ${ddKB}/KB_cow_countrycount.dta 
	if _rc!=0 {
		
		use ${ddKB}/KB_cow_countryroster.dta, clear
		
		// collapse to yearly counts
		cap drop count
		qui gen count = 1
		collapse (sum) count, by(year) fast
		
		save ${ddKB}/KB_cow_countrycount.dta, replace
	}
	
	
	
/*	
---------------------------------------------------------

Clean the entity list--combination of the country
codes and the entities from the territorial transfer
set

---------------------------------------------------------
*/	
	cap confirm file ${ddKB}/KB_cow_entitylist.dta
	if _rc!=0 {
		// First prep the country list
		use ${ddKB}/KB_cow_countryroster.dta, clear
		keep ccode state
		bys ccode state: keep if _n==1
		rename ccode merge_id
		rename state entity_str
		tempfile ckey
		save `ckey', replace
		
		/* Bring in a list of entities (text document is copied and 
		pasted from the pdf) */
		insheet using ${rdKB}/cow/territorial/v5/entities.txt, clear
		list in 1
		drop in 1
		
		pfixdrop temp
		cap drop id
		qui gen temp1 = substr(v1,1,strpos(v1," ")-1)
		qui gen temp2 = subinstr(v1,temp1+" ","",1)
		qui gen temp_c = strpos(temp2,"1")
		
		qui gen id = real(temp1)
		qui gen entity = substr(temp2,1,temp_c-2)
		qui replace entity = trim(entity)
		
		
		cap drop N*
		bys id: gen N1=_N
		bys entity: gen N2=_N
		sort id entity
		list id entity v1 N? if N1>N2,  noobs
		/* None of these are a big deal, so drop for now.
		The entity list is only used to attach names to 
		conflicts and transfers so this will not affect any
		of our calculated statistics. */
		drop if N1>N2 // names can have multiple IDs but not the other way around
		
		keep id entity
		bys id entity: keep if _n==1
		rename id merge_id
		rename entity entity_str
		
		append using `ckey'
		duplicates drop
		
		// Sometimes there is a lengthier name, e.g. (Republic of) Papau
		// we take the shorter one to minimize matching confusion
		bys merge_id: gen N=_N
		gen l = length(entity_str)
		bys merge_id (l): keep if _n==1
		drop l N
		
		save ${ddKB}/KB_cow_entitylist.dta, replace
	}
	
exit
