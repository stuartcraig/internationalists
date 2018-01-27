/*-------------------------------------------------------------------KB_sffig.do
Creates state failure figure and corresponding csv

20170830
- Figure type update (no emf/wmf for compatibility)

Stuart Craig
Last updated: 20170830
*/

timestamp, output
cap mkdir sffig
cd sffig

use ${ddKB}/KB_sfdata.dta, clear

collapse (sum) sf, by(year) fast
tsset year
tsfill
qui replace sf=0 if sf==.

tw area sf year, color(gs7) ///
	title("Number of failed states per year, 1816-2014") ///
	xlab(1815(10)2015,angle(50)) ///
	ylab(0(1)9) ytitle("") xtitle("")
foreach t in png /* emf wmf */ {
	graph export KB_sffig.`t', as(`t') replace
}

outsheet using KB_sffig.csv, comma replace

exit
