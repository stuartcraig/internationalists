/*------------------------------------------------------------------KB_sfdata.do
Creates state failure data (count of state failures by year).

Stuart Craig
Last updated: 20170226
*/

cap confirm file ${ddKB}/KB_sfdata.dta
if _rc!=0 {
	insheet using ${rdKB}/sf/sfdata.csv, comma clear
	collapse (sum) sf, by(year) fast
	save ${ddKB}/KB_sfdata.dta, replace
}

exit
	
