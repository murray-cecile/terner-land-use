/*================================================================= *
* TERNER HOUSING SURVEY DATA: MORE APPROVALS
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-03-11
* ================================================================= */

clear all
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

use "output/FINAL_merged_TCRLUS_census_buildperm.dta", clear

capture log close
log using "temp/approvals-vs-permits_2019-03-11", append



egen permunits = rowtotal(x*_unit*_units)
summarize permunits, detail

egen mfunits = rowtotal(x*_units_units) // this excludes x1_unit_units, so I think no sf
summarize mfunits, detail

gen mfunits_pc = 1000 * mfunits / tot_unit_ct

capture drop dont_build
gen dont_build = 0
replace dont_build = 1 if mfunits < 75 // generous: this is just above the median!
browse city total apt_* if dont_build == 1

* snapshot 1
snapshot save


// APPROVAL TIMES

keep city apt_* permunits mfunits* dont_build
drop apt_time*
reshape long apt, i(city permunits mfunits mfunits_pc dont_build) j(app_time) string

tab apt app_time
bysort dont_build: tab apt app_time

// APPROVALS

snapshot restore 1

keep city permunits mfunits* dont_build apl_mf*
reshape long apl, i(city permunits mfunits mfunits_pc dont_build) j(mfsize) string

tab apl mfsize
bysort dont_build: tab apl mfsize
