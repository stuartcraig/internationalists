/*------------------------------------------------------------------KB_wbarea.do
Prepares world bank data on state territories.

Stuart Craig
Last updated: 20170226
*/

cap confirm file ${ddKB}/KB_wbarea.dta
if _rc!=0 {
	import excel using ${rdKB}/worldbank/ag.lnd.totl.k2_Indicator_en_excel_v2.xls, clear
	rename A cname
	rename B ccode
	rename C ind
	rename D icode
	foreach v of varlist E-BG {
		rename `v' area`=`v'[4]'
	}
	drop in 1/4
	drop ind icode ccode
	
	reshape long area, i(cname) j(year)
	
	cap drop temp
	rename area temp
	qui gen area = real(temp)
	drop temp
	save ${ddKB}/KB_wbarea.dta, replace
}

exit
