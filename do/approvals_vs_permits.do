/*================================================================= *
* TERNER HOUSING SURVEY DATA: EXPLORE APPROVAL TIMES VS. PERMITS
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-03-06
* ================================================================= */

clear all
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

use "output/FINAL_merged_TCRLUS_census_buildperm.dta", clear

capture log close
log using "temp/approvals-vs-permits_2019-03-06", append


tabstat x5_units_units, by(lrg_mf20to49) s(sum mean median count)

egen permunits = rowtotal(x*_unit*_units)
summarize permunits, detail

egen mfunits = rowtotal(x*_units_units) // this excludes x1_unit_units, so I think no sf
summarize mfunits, detail

gen mfunits_pc = 1000 * mfunits / tot_unit_ct

drop dont_build
gen dont_build = 0
replace dont_build = 1 if mfunits < 75 // generous: this is just above the median!
browse city total apt_* if dont_build == 1

tabstat perm_units, by(apt_mfconsistent) s(min p25 p50 mean p75 max)

local aptvars = "consistent variance amend eir"
foreach v of loc aptvars {
	gen apt_mf`v'_rec = .
	replace apt_mf`v'_rec = 0 if apt_mf`v' == -97
	replace apt_mf`v'_rec = 1 if apt_mf`v' == 1
	replace apt_mf`v'_rec = 4 if apt_mf`v' == 2
	replace apt_mf`v'_rec = 8 if apt_mf`v' == 3
	replace apt_mf`v'_rec = 12 if apt_mf`v' == 4
}

reg mfunits apt_mfconsistent_rec 

scatter mfunits_pc apt_mfconsistent_rec if dont_build
scatter mfunits_pc apt_mfconsistent if dont_build & apt_mfconsistent >= 0
corr mfunits_pc apt_mfconsistent if dont_build & apt_mfconsistent >= 0

* WHAT ABOUT EASE OF APPROVALS?

egen apl_mftot = rowtotal(apl_mf*)

* revise dont_build
drop dont_build
gen dont_build = 0
replace dont_build = 1 if mfunits < 35 // half the median, idk


foreach v of varlist apl_mf2to4 apl_mf5to19 apl_mf20to49  apl_mf50plus {
	tab `v' dont_build
}
