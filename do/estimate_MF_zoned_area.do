/*================================================================= *
* TERNER HOUSING SURVEY DATA: LAND AREA ZONED FOR MF 
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-02
* ================================================================= */

clear all
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
cmdlog using "log/land_area_2019-01-02"


* first clean land area data from MABLE Geocorr
import delimited "raw/CA_places_land_area.csv", varnames(1) rowrange(3:)

gen stplfips = state + placefp
keep stplfips landsqmi

* sum area over places
destring landsqmi, replace
collapse (sum) landsqmi, by(stplfips)

save "temp/place_land_area.dta", replace

* switch to the Terner dataset and prepare to merge
use "raw/TCRLUS_data13_2018-11-12.dta", clear

keep FIPS city lnd_*
rename FIPS stplfips

* check for duplicates - none
duplicates list stplfips

* merge on place FIPS code: 
* 	19 unincorporated counties don't merge from master
* 	1,272 places don't merge from Geocorr file 
merge 1:1 stplfips using "temp/place_land_area.dta"
keep if _merge == 3
drop _merge

* reshape to long
reshape long lnd, i(stplfips) j(zone) string

* extract minimum share from ranges (treat missing as 0)
gen lnd_min = 0
replace lnd_min = .06 if lnd == 2
replace lnd_min = .26 if lnd == 3
replace lnd_min = .51 if lnd == 4
replace lnd_min = .76 if lnd == 5
replace lnd_min = .96 if lnd == 6

* extract max share from ranges (ignore missing)
gen lnd_max = .
replace lnd_max = .05 if lnd == 1
replace lnd_max = .25 if lnd == 2
replace lnd_max = .50 if lnd == 3
replace lnd_max = .75 if lnd == 4
replace lnd_max = .95 if lnd == 5
replace lnd_max = 1 if lnd == 6

* compute lower and upper bound of land area for each city/zoning type
gen lnd_lb = landsqmi * lnd_min
gen lnd_ub = landsqmi * lnd_max

* snapshot 1
snapshot save

* compute total area by zoning type
collapse (sum) landsqmi lnd_lb lnd_ub, by(zone)

gen lb_share = lnd_lb / landsqmi
gen ub_share = lnd_ub / landsqmi

export excel using "output/zoning_area_estimates.xlsx", cell(A3) firstrow(var)
