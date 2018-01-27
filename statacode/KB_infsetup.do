/*----------------------------------------------------------------KB_infsetup.do
Sets up a infracture for the KB project

Stuart Craig
Last updated 20170226
*/

/* 
------------------------------------------

Make sure all of the directories exist. 
The statacode and rawdata files must 
already exist, and the raw data file 
should be be populated!

------------------------------------------
*/

	cap mkdir ${rdKB}
	cap mkdir ${ddKB}
	cap mkdir ${scKB}
	cap mkdir ${oKB}
	cap mkdir ${tKB}
/* 
------------------------------------------

Publicly available user written commands

------------------------------------------
*/
	cap fs
	if _rc!=0 ssc install fs

/* 
------------------------------------------

Color globals for the figures 

------------------------------------------
*/

	global red "178 24 43"
	global blu "33 102 172"



exit
