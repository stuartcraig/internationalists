/*--------------------------------------------------------------KB_statecount.do
Creates figure of state counts from 1816-2011.

20170830
- Figure type update (no emf/wmf for compatibility)

Stuart Craig
Last updated 20170830
*/

timestamp, output
cap mkdir statecount
cd statecount

	use ${ddKB}/KB_cow_countrycount.dta, clear

	tw area count year, color(gs7) ///
		ylab(0(50)250) ytitle("") ///
		xlab(1815(10)2015, angle(50)) xtitle("") ///
		title("Number of States in the World")
	foreach t in png /* emf wmf */ {
		graph export KB_statecount.`t', as(`t') replace
	}
	// Underlying data only go through 2011, 
	// we extended the series: see KB_cleancow_states.do
	outsheet using KB_statecount.csv, comma replace
	
	
exit
