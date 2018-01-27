/*----------------------------------------------------------------KB_riskdata.do
Prepare the territorial change and legal category data for calculating 
"risk" figures.

Stuart Craig
Last updated 20170226
*/

cap confirm file ${ddKB}/KB_riskdata.dta
if _rc!=0 {

/*
----------------------------------------------------

Combine territorial change and legal categories.
The argument is the date of the most recent revision
to the legal categories data. 

----------------------------------------------------
*/

	do ${scKB}/KB_riskdata_combinetclc.do 20151211 
		

/*
----------------------------------------------------

Identify reversions in the conquest data.

----------------------------------------------------
*/

	do ${scKB}/KB_riskdata_idrev.do

	
/*
----------------------------------------------------

Use legal categories and reversions to identify
our notions of conquest and recognition.

----------------------------------------------------
*/	
	
	qui do ${scKB}/KB_riskdata_conqflags.do

/*
----------------------------------------------------

Finally, create indicators for whether the gainer
or loser is in the state system at the time of
the transfer.

----------------------------------------------------
*/	

	qui do ${scKB}/KB_riskdata_instate.do

	
	save ${ddKB}/KB_riskdata.dta, replace

}

exit
