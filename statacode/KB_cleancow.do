/*----------------------------------------------------------------KB_cleancow.do
Cleans the raw COW data

Stuart Craig
Last updated: 20170226
*/

// Clean the basic war files--intra-, extra-state, etc...

	do ${scKB}/KB_cleancow_wars.do

// Clean the country roster and entity lists
	
	do ${scKB}/KB_cleancow_states.do

// Clean the territorial change dataset

	do ${scKB}/KB_cleancow_tc.do
	
// Stock data of ongoing wars

	do ${scKB}/KB_cleancow_stockwars.do
	
exit
