/*-------------------------------------------------------------------clookup.ado
Finds all available data given a country name string

Stuart Craig
20160912
*/

	cap prog drop clookup
	prog define clookup
		args c

		cap confirm file ${ddKB}/KB_ssdata.dta
		if _rc!=0 di in red "Stock data not yet prepared"
		else {
			di "======================================================="
			di "Stock data"
			di "======================================================="
			use ${ddKB}/KB_ssdata.dta, clear
			gsort cname -year
			list cname year area if strpos(cname,"`c'"), noobs
		}
		
		cap confirm file ${ddKB}/KB_wbarea.dta
		if _rc!=0 di in red "World Bank area data not yet prepared"
		else {
			di "======================================================="
			di "World Bank data"
			di "======================================================="
			use ${ddKB}/KB_wbarea.dta, clear
			list if strpos(cname,"`c'")>0&year==2014, noobs
		}
		
		cap confirm file ${rdKB}/cow/states/states2011.csv
		if _rc!=0 di in red "State system records not found in ${rdKB}/cow/states"
		else {
			di "======================================================="
			di "State system records"
			di "======================================================="
			qui insheet using ${rdKB}/cow/states/states2011.csv, comma clear
			list if strpos(statenme,"`c'")>0, noobs
		}
		
		cap confirm file ${rdKB}/cow/territorial/v5/entities.txt
		if _rc!=0 di in red "Entity list not found in ${rdKB}/cow/territorial/v5"
		else {
			di "======================================================="
			di "Entity list records"
			di "======================================================="
			qui insheet using ${rdKB}/cow/territorial/v5/entities.txt,  clear
			list if strpos(v1,"`c'")>0, noobs
		}
		
		cap confirm file ${ddKB}/KB_cow_tc.dta
		if _rc!=0 di in red "Territorial change data not yet prepared"
		else {
			di "======================================================="
			di "Territorial change data"
			di "======================================================="
			qui use ${ddKB}/KB_cow_tc.dta, clear
			qui {
			foreach v of varlist tc_gainer tc_loser tc_entity {
				cap drop _merge
				cap drop merge_id
				qui gen merge_id = `v'
				merge m:1 merge_id using ${ddKB}/KB_cow_entitylist.dta // states and entities
				drop if _m==2
				drop _merge
				rename entity_str `v'_s
			}
			sort tc_year
			}
			foreach v of varlist tc_gainer_s tc_loser_s tc_entity_s {
				di "`c' is `v'"
				list tc_year tc_gainer* tc_loser* tc_entity*s tc_area tc_number if strpos(`v',"`c'")>0, noobs
				di ""
				di ""
			}
		}
	end

exit
