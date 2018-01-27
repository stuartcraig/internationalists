/*-----------------------------------------------------------KB_cleancow_wars.do
Clean the basic war files

Stuart Craig
Last updated: 20170226
*/


	cap confirm file ${ddKB}/KB_cow_nonstate.dta
	if _rc!=0 {
		insheet using ${rdKB}/cow/nonstate/Non-StateWarData_v4.0.csv, comma clear
		save ${ddKB}/KB_cow_nonstate.dta, replace
	}
	
	cap confirm file ${ddKB}/KB_cow_intrastate.dta
	if _rc!=0 {
		insheet using ${rdKB}/cow/intrastate/Intra-StateWarData_v4.1.csv, comma clear
		save ${ddKB}/KB_cow_intrastate.dta, replace
	}
	
	cap confirm file ${ddKB}/KB_cow_extrastate.dta
	if _rc!=0 {
		insheet using ${rdKB}/cow/extrastate/Extra-StateWarData_v4.0.csv, comma clear
		save ${ddKB}/KB_cow_extrastate.dta, replace
	}
	
	cap confirm file ${ddKB}/KB_cow_interstate.dta
	if _rc!=0 {
		insheet using ${rdKB}/cow/interstate/Inter-StateWarData_v4.0.csv, comma clear
		save ${ddKB}/KB_cow_interstate.dta, replace
	}

exit
