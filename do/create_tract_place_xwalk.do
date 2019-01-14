/*================================================================= *
* TERNER HOUSING SURVEY DATA: CREATE TRACT-PLACE CROSSWALK
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-08
* ================================================================= */

set more off
clear all

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
log using "log/unincorporated_xwalk_2019-01-08", append

* bring in crosswalk from MABLE-Geocorr
clear
import delimited "raw/geocorr2014.csv", varnames(1) rowrange(3:)

* adjust FIPS codes
destring tract, gen(fips)
replace fips = fips * 100
gen tract2 = string(fips, "%06.0f")
drop tract
rename tract2 tract

replace tract = county + tract
gen stplfips = state + placefp14 
rename county stcofips
rename placefp14 plfips

* replace numerics stored as string
destring hus10, replace
destring afact, replace

* fix census tract 06037930401 (geographic change, 2012)
replace tract = "06037137000" if tract == "06037930401"

* keep only relevant vars and save temp file
keep tract stcofips stplfips plfips placenm14 hus10 afact
save "temp/tract_place_xwalk_raw.dta", replace 

* flag unincorporated places
gen uninc = 1 if plfips == "99999"
replace stplfips = stcofips + "999" if uninc==1

* keep only unincorporated places, save temp file
keep if uninc==1

duplicates tag tract stplfips, gen(dup)
browse if dup > 0
drop dup

save "temp/unincorporated_tract_xwalk.dta", replace

