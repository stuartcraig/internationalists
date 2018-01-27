/*-----------------------------------------------------------------timestamp.ado
Program to set the date/time stamp global

NOTE: when transporting the file across projects, you must change the
output global on lines 38-39.

Stuart Craig
20160912
*/

	cap prog drop timestamp
	prog define timestamp, rclass
		syntax [anything] [, output]
		
		// Grab the basics
		loc year = substr("`c(current_date)'",-4,4)
		loc mon  = substr("`c(current_date)'",-8,3)
		loc day  = substr("`c(current_date)'",1,2)
		
		// Clean the month
		loc ctr=0
		foreach m in `c(Mons)' {
			loc ctr = `ctr'+1
			if "`mon'"=="`m'" {
				loc mon = `ctr'
				continue, break
			}
		}
		loc mon = subinstr("`mon'"," ","",.)
		loc day = subinstr("`day'"," ","",.)
		if length("`mon'")==1 loc mon = "0" + "`mon'" // add leading zeros to single digit days and months
		if length("`day'")==1 loc day = "0" + "`day'"
		
		// Build the date
		loc date = "`year'`mon'`day'"
		
		if "`output'"=="output" {
			cap mkdir ${oKB}/`date'
			cd ${oKB}/`date'
		}
		
		// Clean up the time
		loc time  = subinstr("`c(current_time)'"," ","_",.)
		loc time  = subinstr("`time'",":","_",.)
		
		loc dt = "`date'" + "_" + "`time'"
		
		return local stamp = "`dt'"
		return local date  = "`date'"
		
		
	end

exit
