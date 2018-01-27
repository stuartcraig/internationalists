/*-------------------------------------------------------------KB_cleancow_tc.do
Create a copy of the territorial transfer data that has our manual 
fixes incorporated. These fixes were made to resolve apparent discrepancies
discovered either while designating legal categories or by tracing
transfer histories from the World Bank data.

Stuart Craig
Last updated: 20170226
*/	
	

	cap confirm file ${ddKB}/KB_cow_tc.dta
	if _rc!=0 {
	
		// 670 Saudi Arabia
		// 640 is Turkey
		// 672 Asir
		// 671 Hejaz Sultanate
		// 673 Al Hasa
		
/*-----------------------------------First, input several transfers that were 
									 not recorded in the original TC data */
				
		clear 
		input number year  gainer loser area
			// Saudi Arabia
			9001 1920 670 672 104338
			9002 1921 670 640 554000
			9003 1926 670 671 259000
			9004 1932 670 -9  1161898
			// Kosovo from Serbia
			9005 2008 347 345 10887 // 10887 comes from WB
			// Danzig gets conquered with Poland in 1939
			9006 1939 255 291 2056 
			// Must account of dissolution of A-H
			9007 1919 305 300 79039 // how much? this is backed out from the stock data
			// Peru joins Bolivia in confederation in 1836
			9008 1836 145 135 1220057
			// Gran Colombia gets territory of Venezuela and Ecuador from Spain ~1820 but never releases them (in CoW)
			9009 1831 130 100 550685
			9010 1831 101 100 1082207
			// Yemen has to absorb BOTH PRY and YAR in 1990
			9012 1990 679 678 195181
			// Montenegro
			9013 1922 345 348 14913
			// Germany must gain West Germany in 1990
			9014 1990 255 260 250045
		end
		tempfile SAobs
		save `SAobs', replace
	
//----------------------------------- Bring in TC data and make some corrections

		insheet using ${rdKB}/cow/territorial/v5/tc2014.csv, clear
		
		// Missing area, filled by reverting area in 886
		assert area==. if number==882
		qui summ area if number==886, mean
		qui replace area = r(mean) if number==882
			
		// Apparent error in area for obs 466--filled with later reverting conflict (585)
		assert area==59984&entity==366 if number==466
		qui summ area if number==585, mean
		qui replace area = r(mean) if number==466
		
		// Peru over-recorded in territory--disputed boundaries in ind. from Spain
		assert area==1559891 if inlist(number,42,72)
		qui replace area = 1220057 if inlist(number,42,72)		
		
		// Colombia (non-Venezuela/Ecuador) backed out from remainder
		assert area == 660760 if number==37
		qui replace area=1092821 if number==37
		
		// Asir not a sovereign state when Turkey conquers in 1871
		assert loser ==672 if number==211
		qui replace loser=-9 if number==211
		
		// Austria is still Austria-Hungary in state system in 1918
		foreach n in 465 490 487 489 492 485 {
			assert loser==305 if number==`n'
			qui replace loser=300 if number==`n'
		}
		// Hungary got some territory that it giave up right away
		assert area == 91075 if number==487
		qui replace area = 329457 if number==487
		
		// 602 reverts 562, 564, and 572--562, and 564 were originally left out of the 602 transfer
		qui summ area if inlist(number,562,564,572)
		qui replace area = r(mean)*r(N) if number==602
		
		// We must split number 750 into to observations
		expand 2 if number==750
		qui gen number_s = string(number)
		bys number: replace number_s = number_s + "A" if _n==2&_N==2
		qui replace area = 5814.5 	if number_s=="750"
		qui replace area = 63.5 	if number_s=="750A"
		qui replace pop	 = 617500	if number_s=="750"
		qui replace pop	 = 66000	if number_s=="750A"
		
		// Germany actually colonizing FUTURE Tanzania in 1888
		assert loser==511 if number==312
		qui replace loser=-9 if number==312
		// Tanzania from Zanzibar is actually the differetnial it didn't get from the UK
		assert area==942003 if number==736
		qui replace area = 2642 if number==736
		// Zanzibar doesn't exist prior to this
		foreach n in 294 299 317 322 324 {
			assert loser==511 if number==`n'
			qui replace loser = -9 if number==`n'
		}
		
		// Decimal point error in Egypt takes Syria
		assert area==1187338 if number==683
		qui replace area = 187338 if number==683
		// Egypt was under British rule in 1884 so can't have lost to Ethiopia then (comes from UK)
		assert loser==651 if number==275
		qui replace loser=200 if number==275
		
		// Sudan has to move with Egypt when conquered by UK
		qui replace area = area + 2658063 if number==261
		
		// Area of Ethiopia also has to go to UK
		qui replace area = area + 468000 if number==261
				
		// Poland:
		// Decimal point problem
		qui replace area = area/10 if number==484
		
		// Newfoundland discrepancy
		qui replace area=404519 if number==497
		
		// Lithuania:
		qui replace area = 82626 if number==468 // much of original CoW figure unrealised
				
		// Yemen:
		// Doesn't exist as a state when Turkey takes in 1872
		assert loser==678 if number==214
		qui replace loser=-9 if number==214
		// Doesn't exist when UK takes 182 in 1915
		assert loser==678 if number==457
		qui replace loser=-9 if number==457
		// Backed out independence from UK #
		assert area==160300 if number==751 
		qui replace area = 329293 if number==751
		
		// Other corrections:
		qui replace year = 1871 if number==225
		qui replace year = 1829 if number==66
		qui replace month=10 if number==440
		
		// Canada and Australia do not get independence until 1931 
		// (after League of Nations admits them)
		qui replace year = 1931 if inlist(gainer,900,20)&year<1931
		
		// CoW Massively undercounts Mexico's initial independence territory
		qui replace area = 4401341 if number==40
		
		// Germany cannot be losing entity from 1946-1954
		qui replace loser=1 if inlist(number,636,637,635,634,613)
		
		// CZ/Hungary
		qui summ area if number==507, mean
		qui replace area = area - r(mean) if number==465

		// Sudetenland is roughly 18,000 sq km, COW has ~28,000
		qui replace area=18000 if number==574
		// Bohemia and Moravia is 49,363, COW has 98,909
		qui replace area = 49363 if number==577
		// "Reversion" of these two transfers is now too big! 
		qui replace area = 73515 if number==593
		// Under estimate Carpethian Ruthenia is actually about 12k
		qui replace area = 12097 if number==599
		
		append using `SAobs'
		qui replace number_s = string(number) if number_s==""
		
		qui ds
		foreach v in `r(varlist)' {
			rename `v' tc_`v'
		}

		save ${ddKB}/KB_cow_tc.dta, replace
	}
	
exit
