/*----------------------------------------------------------------KB_intrafig.do
Creates figure of intrastate wars from 1816-2011

20170830
- Figure type update (no emf/wmf for compatibility)

Stuart Craig
Last updated 20170830
*/

timestamp, output
cap mkdir intrafig
cd intrafig

use ${ddKB}/KB_cow_stockwars_annual.dta, clear

cap drop intra_tot
qui egen intra_tot = rowtotal(intra_*)
drop if year>2007 // 2008 is a filler year

tw line intra_tot year, color(black) lw(medthick) ///
	xlab(1815(10)2005, angle(50)) ytitle("") xtitle("") ///
	title("Annual Number of Active Intra-State Wars, 1816-2007")
foreach t in png /* emf wmf */ {
	graph export KB_intrafig.`t', as(`t') replace
}
outsheet intra_tot year using KB_intrafig.csv, comma replace
	
exit
