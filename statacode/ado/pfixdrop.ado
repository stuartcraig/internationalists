/*------------------------------------------------------------------pfixdrop.ado
This program quickly drops variables with a common prefix taken in as an arg

Stuart Craig
20160912
*/

	cap program drop pfixdrop
	prog define pfixdrop
		args p
		
		cap d `p'*
		if _rc==0 drop `p'*
		
	end

	
exit
