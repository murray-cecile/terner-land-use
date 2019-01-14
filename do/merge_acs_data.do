/*================================================================= *
* TERNER HOUSING SURVEY DATA: MERGE ACS DATA
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-07
* ================================================================= */

clear all 
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
log using "log/data_merges_2019-01-10", append

*===============================
* convert csvs into Stata files - only needs to be run once

import delimited "R/data_pulls/BA_plus_share_CA_places_2013-17.csv", clear
save "census/BA_plus_share_CA_places_2013-17.dta", replace

import delimited "R/data_pulls/median_hh_income_CA_places_2013-17.csv", clear
save "census/median_hh_income_CA_places_2013-17.dta", replace

import delimited "R/data_pulls/race_ethnicity_CA_places_2013-17.csv", clear
save "census/race_ethnicity_CA_places_2013-17.dta", replace

import delimited "R/data_pulls/age_composition_CA_places_2013-17.csv", clear
save "census/age_composition_CA_places_2013-17.dta", replace

*===============================

* now merge all files together and reshape wide
use "census/median_hh_income_CA_places_2013-17.dta", clear
merge 1:1 stplfips using "census/BA_plus_share_CA_places_2013-17.dta", nogen

* drop extraneous vars
keep stplfips total baplus_share medhhinc

merge 1:m stplfips using "census/race_ethnicity_CA_places_2013-17.dta", nogen
drop race_ct* race_share_se2 total_se2
reshape wide race_share*, i(stplfips) j(race) string

merge 1:m stplfips using "census/age_composition_CA_places_2013-17.dta", nogen
drop age_ct* age_share_se2 total_se2
reshape wide  age_share*, i(stplfips) j(agecat) string

* fix the FIPS codes
tostring stplfips, format(%07.0f) replace

*===============================
* deal with unincorporated place data
append using "census/unincorporated_place_acs_data_final.dta"

* save final merged dataset
save "census/all_census_data_CA_places", replace
