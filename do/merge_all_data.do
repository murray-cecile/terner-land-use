/*================================================================= *
* TERNER HOUSING SURVEY DATA: MERGE ALL DATA
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-07
* ================================================================= */

clear all 
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
log using "log/data_merges_2019-01-13", append

use "raw/TCRLUS_data13_2018-11-12.dta", clear

* MERGE IN ACS DEMOGRAPHIC DATA
rename FIPS stplfips
merge 1:1 stplfips using "census/all_census_data_CA_places.dta"
drop if _merge == 2
rename _merge has_demo

* MERGE IN ACS TENURE DATA
merge 1:1 stplfips using "census/units_by_tenure.dta"
tab _merge
rename _merge has_tenure
drop if has_tenure < 3

* MERGE IN PERMIT DATA
merge 1:1 stplfips using "census/merged_building_permits_2013-17.dta"
rename _merge has_buildperm

* snapshot 2
snapshot save

* save extract of the observations that won't merge (unincorporated + a few others)
keep if has_buildperm == 1
keep stplfips county has_buildperm 
save "temp/five_unmerged_places.dta", replace 
// Clayton, Fort Bragg, Farmersville, Moraga, Tehama???

snapshot restore 2

drop if has_buildperm < 3

save "output/FINAL_merged_TCRLUS_census_buildperm.dta", replace
