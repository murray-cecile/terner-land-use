/*================================================================= *
* TERNER HOUSING SURVEY DATA: MERGE BULDING PERMIT DATA 
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

* add year indicators and drop extraneous geographic indicatorss
foreach y in "2013" "2014" "2015" "2016" "2017" {
	use "census/CA_places_building_permits_`y'.dta", clear
	capture gen year = `y'
	capture drop stfips cofips plfips region division csa cbsa
	save "census/CA_places_building_permits_`y'.dta", replace
}

use "census/CA_places_building_permits_2013.dta", clear

* merge all years together
append using "census/CA_places_building_permits_2014.dta"
append using "census/CA_places_building_permits_2015.dta"
append using "census/CA_places_building_permits_2016.dta"
append using "census/CA_places_building_permits_2017.dta"

sort place
order stcofips stplfips place year

* check for anomalies and correct Truckee
duplicates tag place, gen(dup)
* browse if dup < 4
replace place = "Truckee" if place == "Truckee town"
drop dup

* change unincorporated county FIPS to match TCRLUS: stcofips + 999
replace stplfips = stcofips + "999" if stplfips == "0699990"

* manually recode Alpine County: 0600000 -> 06003999
replace stplfips = "06003999" if stplfips == "0600000" & stcofips == "06003"

collapse (sum) x*, by(stplfips place)

* additionally check Alpine, Mariposa, Sierra, and Trinity Counties in 2013?
* only Alpine unincorporated is actually in the Terner data
duplicates tag stplfips, gen(dup)
drop if dup > 0
drop dup

save "census/merged_building_permits_2013-17.dta", replace

* save alternative version with no incorporated counties
duplicates tag stplfips, gen(dup)
drop if dup > 0
drop dup
save "census/merged_building_permits_nocounty_2013-17.dta", replace
