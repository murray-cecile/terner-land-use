/*================================================================= *
* TERNER HOUSING SURVEY DATA: RESHAPE ACS TENURE DATA
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-10
* ================================================================= */

clear all 
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
log using "log/tenure_reshape_2019-01-13", append

*=======================
* PLACE DATA
*=======================

import delimited "R/data_pulls/CA_tenure_by_units_2013-17.csv", clear

* keep only unit shares and total count
keep stplfips varname share total
rename share unit_share

* reshape wide
reshape wide unit_share, i(stplfips) j(varname) string

* rename variables
rename total tot_unit_ct

* convert FIPS to string 
tostring stplfips, format(%07.0f) replace

* save 
save "temp/units_by_tenure.dta", replace

*=======================
* TRACT DATA
*=======================

import delimited "R/temp/tenure_all_CA_tracts.csv", clear

* keep only unit shares and total count
keep tract varname units total

* rename total variable
rename total tot_unit_ct

* convert FIPS to string 
tostring tract, format(%011.0f) replace

* save
save "temp/units_by_tenure_tracts.dta", replace

*=======================
* ALLOCATE TRACT DATA
*=======================

use "raw/TCRLUS_data13_2018-11-12.dta", clear

rename FIPS stplfips
merge 1:m stplfips using "temp/unincorporated_tract_xwalk.dta", nogen keep(match)

duplicates tag stplfips, gen(dup)
tab dup
drop dup

duplicates tag tract stplfips, gen(dup)
tab dup

keep tract stplfips city stcofips county afact

* keep only tracts in unincorporated places
merge m:m tract using "temp/units_by_tenure_tracts.dta", nogen keep(match)

* allocate - data are already long, helpfully
replace units = units * afact
replace tot_unit_ct = tot_unit_ct * afact

* collapse by place
collapse (sum) units tot_unit_ct, by(stplfips varname)

* compute share
gen unit_share = units / tot_unit_ct

* reshape the shares wide
drop units
reshape wide unit_share@, i(stplfips) j(varname) string

save "temp/unincorporated_county_tenure.dta", replace

*=======================
* COMBINE UNINCORPORATED
*=======================

append using "temp/units_by_tenure.dta"

save "census/units_by_tenure.dta", replace
