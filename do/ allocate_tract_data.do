/*================================================================= *
* TERNER HOUSING SURVEY DATA: ALLOCATE TRACT DATA 
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-09
* ================================================================= */

set more off
clear all

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
log using "log/unincorporated_allocation-01-22", append

* convert csvs into Stata files

import delimited "R/temp/BA_plus_share_tracts.csv", clear
save "census/BA_plus_share_CA_tracts_2013-17.dta", replace

import delimited "R/temp/median_income_tracts.csv", clear
save "census/median_hh_income_CA_tracts_2013-17.dta", replace

import delimited "R/temp/race_ethnicity_tracts.csv", clear
save "census/race_ethnicity_CA_tracts_2013-17.dta", replace

import delimited "R/temp/age_composition_tracts.csv", clear
save "census/age_composition_CA_tracts_2013-17.dta", replace

import delimited "R/data_pulls/value_data_by_tract.csv", clear
save "census/housing_value_CA_tracts_2013-17.dta", replace


* now merge all files together and reshape wide
use "census/median_hh_income_CA_tracts_2013-17.dta", clear
merge 1:1 tract using "census/BA_plus_share_CA_tracts_2013-17.dta", nogen

merge 1:1 tract using "census/housing_value_CA_tracts_2013-17.dta", nogen

merge 1:m tract using "census/race_ethnicity_CA_tracts_2013-17.dta", nogen
reshape wide race_ct* race_share*, i(tract) j(race) string

merge 1:m tract using "census/age_composition_CA_tracts_2013-17.dta", nogen
reshape wide age_ct* age_share*, i(tract) j(agecat) string

* fix the FIPS codes
tostring tract, format(%011.0f) replace

save "census/all_tract_data.dta", replace

*===================================
* MERGE DATA WITH UNINCORPORATED
*===================================

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
merge m:1 tract using "census/all_tract_data.dta", nogen keep(match)

*===================================
* ALLOCATE
*===================================

* snapshot save

* reshape for convenience
reshape long age_, i(tract stplfips city) j(agevar) string
reshape long race_, i(tract stplfips city agevar) j(racevar) string

* multiply by the allocation factor
replace age_ = afact * age_
replace race_ = afact * race_

foreach v of varlist medhhinc* tot* baplus* agg_* {
	replace `v' = `v' * afact
}

* now collapse by place
collapse (sum) age_ race_ baplus* tot* agg*, by(stplfips city agevar racevar)

* actually going to drop all the se2s and previusly computed shares
drop baplus_share_se2 baplus_se2 total_se2
drop if substr(agevar, 1, 5) == "share"
drop if substr(agevar, 4, 3) == "se2"
drop if substr(racevar, 1, 5) == "share"
drop if substr(racevar, 4, 3) == "se2"

*===================================
* RESHAPE WIDE (horribly)
*===================================

* currently snapshot 2 (formerly 14!)
snapshot save

keep stplfips city baplus* total* agg*
duplicates drop stplfips, force

* fix the shares
replace baplus_share = baplus / total

* save this extract
save "temp/unincorporated_place_basic_wide.dta", replace

snapshot restore 2 

foreach v in age race {
	keep stplfips `v'_ `v'var total
	drop if substr(`v'var, 4, 3) == "se2"
	duplicates drop stplfips `v'var, force
	gen `v'_share = `v'_ / total
	keep stplfips `v'var `v'_share
	reshape wide `v'_share, i(stplfips) j(`v'var) string
	save "temp/unincorporated_place_`v'_data.dta", replace
	snapshot restore 2
}

use "temp/unincorporated_place_basic_wide.dta", clear

merge 1:1 stplfips using "temp/unincorporated_place_age_data.dta", nogen
merge 1:1 stplfips using "temp/unincorporated_place_race_data.dta", nogen

*===================================
* RENAME AND SAVE
*===================================

rename *ct* **
drop city baplus

save "census/unincorporated_place_acs_data_final.dta", replace
