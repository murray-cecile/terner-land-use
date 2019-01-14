/*================================================================= *
* TERNER HOUSING SURVEY DATA: SINGLE- VS MULTI-FAMILY CROSSTABS
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2018-12-15
* ================================================================= */

clear all
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

use "raw/TCRLUS_data13_2018-11-12.dta", clear

capture log close
log using "temp/exploration_2018-12-17", append

* snapshot 1
snapshot save 

* look at land share and fees for SF vs MF
keep city lnd_* fee_* 
reshape long lnd fee, i(city) j(zone) string
tab lnd zone, missing
tab fee zone, missing
* tabout lnd fee zone if zone != "_nr" using "temp/land_fee.csv", replace
snapshot restore 1


* define list of parallel zoning variables
#delimit ;
local zonvars "minlotsize minlotwidth maxfar maxdensity mindensity minunitsize maxlotcover heightlimit frontsetback sidesetback backsetback";
#delimit cr

keep city zon_*

* calculate some summary stats for zoning 
foreach v of local zonvars {
	di "`v'"
	gen has_sf_`v' = 1 if zon_sf`v' > 0
	gen has_mf_`v' = 1 if zon_mf`v' > 0
	tab has_sf_`v' has_mf_`v', col missing
	tabstat zon_*`v' if zon_sf`v' > 0 & zon_mf`v' > 0, s(min mean median max)
}
 
 
snapshot restore 1

* parking
local parkvars "covered tandem" 
keep city prk*

foreach v of local parkvars {
	di "`v'"
	tab prk_sf`v' prk_mf`v', missing
}


snapshot restore 1

* variances
tab var_sfparking var_mfparking, missing
tab var_sfheight var_mfheight, missing
tab var_sfsetbacks var_mfsetbacks, missing

* approvals
foreach v in "auth" "plan" "permit" "occupy" {
	tab apr_sf`v' apr_mf`v', missing
}

* brd
foreach v in "limit" "maxunits" {
	tab brd_sf`v' brd_mf`v'
}

* approval time
local aprvars "consistent variance amend eir"
foreach v of local aprvars {
	tab apr*sf`v' apr*mf`v'
{

* CEQA
local ceqavars "lawsuit threat revision failure"
foreach v of loc ceqavars {
	tab ceq_*sf`v' ceq_*mf`v'
}


keep city apl*
drop apl_adu
reshape long apl_sf apl_mf, i(city) j(unitsize) string
tab apl_sf unitsize, missing
tab apl_mf unitsize, missing 
tab apl_mf unitsize, col

snapshot restore 1

keep city lrg*
drop lrg_all
reshape long lrg_sf lrg_mf, i(city) j(unitsize) string
tab lrg_sf unitsize, missing col
tab lrg_mf unitsize, missing col

