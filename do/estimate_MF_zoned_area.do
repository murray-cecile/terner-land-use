/*================================================================= *
* TERNER HOUSING SURVEY DATA: LAND AREA ZONED FOR MF 
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-02
* 	Modified: 2019-01-16
* ================================================================= */

clear all
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
cmdlog using "log/land_area_2019-01-15", append

* =========================== *
* CLEAN PLACE LAND AREA
* =========================== *

* first clean land area data from MABLE Geocorr
import delimited "xwalks/CA_places_land_area.csv", varnames(1) rowrange(3:)

gen stplfips = state + placefp
keep stplfips landsqmi

* sum area over places
destring landsqmi, replace
collapse (sum) landsqmi, by(stplfips)

save "temp/place_land_area.dta", replace

* =========================== *
* MERGE W/TCRLUS, PART I
* =========================== *

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

* snapshot 1
snapshot save

keep if _merge == 1
keep stplfips city
save "temp/19_unincorporated_counties.dta", replace

snapshot restore 1
keep if _merge != 2
drop _merge

* save temporary extract without unincorporated counties
save "temp/merged_place_land_area.dta", replace

* =========================== *
* UNINCORPORATED LAND AREA
* =========================== *

clear
import delimited "xwalks/county_to_place_geocorr14.csv", varnames(1) rowrange(3:) 

keep county placefp14 landsqmi  
destring landsqmi, replace

* keep only unincorporated portions
keep if placefp == "99999"

* change FIPS codes to match TCRLUS
gen stplfips = county14 + "999"
drop placefp14 county14

* include only the 19 that made it into TCRLUS
merge 1:1 stplfips using "temp/19_unincorporated_counties.dta", nogen keep(match)

* now merge back to the rest of the data 
drop city
merge 1:1 stplfips using "temp/merged_place_land_area.dta", nogen

* =========================== *
* NOW COMPUTE SHARES
* =========================== *

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

* snapshot 2
snapshot save

* compute total area by zoning type
collapse (sum) landsqmi lnd_lb lnd_ub, by(zone)

gen lb_share = lnd_lb / landsqmi
gen ub_share = lnd_ub / landsqmi

export excel using "output/zoning_area_estimates.xlsx", cell(A3) firstrow(var) replace

* ====================== *
* LAND AREA BY PLACE
* ====================== *

snapshot restore 2

gen lb_share = lnd_lb / landsqmi
gen ub_share = lnd_ub / landsqmi

hist lb_share
hist ub_share

save "temp/zoning_land_area_by_place.dta", replace

* ====================== *
* LAND AREA BY CBSA
* ====================== *

clear
import delimited "xwalks/CBSA_county_place.csv", varnames(1) rowrange(3:) 

* clean
gen stplfips = state + placefp14
destring landsqmi afact, replace
rename county14 stcofips
keep cbsa cbsaname stcofips stplfips afact landsqmi
rename cbsaname15 cbsaname

* replace unincorporated county FIPS codes
replace stplfips = stcofips + "999" if stplfips == "0699999"

* check for places in multiple metros
duplicates tag stplfips, gen(dup_place)
tab dup_place
* browse if dup_place > 0

* four problems split in two CBSAs: 06-02812 (Aromas CDP), 06-26000 (Fremont),
*	06-38604 (Kingvale CDP), and 06-85012 (Wheatland) 
* we can ignore Aromas, Kingvale, and Wheatland b/c they're tiny and not in TCRLUS
* we assign Fremont to San Francisco-Oakland-Hayward (41860) by land area 
drop if stplfips == "0626000" & cbsa == "41940"
drop if stplfips == "0602812" | stplfips == "0638604" | stplfips == "0685012"

* now we can drop other duplicates b/c they are just split across counties
drop stcofips dup_place afact landsqmi
duplicates drop stplfips cbsa, force

* save this crosswalk of places to CBSAs (places are unique)
save "xwalks/place_county_CBSA_xwalk.dta", replace

* ====================== *
* SHARES BY CBSA
* ====================== *

* merge back the TCRLUS data
merge 1:m stplfips using "temp/zoning_land_area_by_place.dta", nogen keep(match)

* snapshot 3
snapshot save

* export a place-level version with CBSA assignment
export excel using "output/zoning_area_estimates.xlsx", ///
sheet("Place shares") firstrow(var) sheetreplace

* collapse by CBSA
collapse (sum) lnd_* landsqmi, by(cbsa cbsaname zone)

gen lb_share = lnd_lb / landsqmi
gen ub_share = lnd_ub / landsqmi

sort lb_share ub_share cbsa

* export a CBSA-level version 
export excel using "output/zoning_area_estimates.xlsx", ///
sheet("CBSA shares") firstrow(var) sheetreplace

* ========================= *
* DEMOGRAPHICS & ANALYSIS
* ========================= *

* return to the place-level data
snapshot restore 3

* merge in more data
merge m:1 stplfips using "output/FINAL_merged_TCRLUS_census_buildperm.dta"

/* keep stplfips zone city lnd landsqmi lnd_min lnd_max lnd_lb lnd_ub lb_share ///
ub_share total baplus* medhhinc race* age* unit_share* has_demo _merge */

reg ub_share unit_sharerentocc if zone == "_mf"

reg ub_share unit_sharerentocc total if zone == "_mf"

reg ub_share unit_sharerentocc total age_shareover65 race_sharewhite_nh ///
medhhinc baplus_share if zone == "_mf"

reg ub_share unit_share*_3to4 unit_share*_5to9 unit_share*_10to19 ///
unit_share*_20to49 unit_share*50plus if zone == "_mf"

reg ub_share total age_shareover65 race_sharewhite_nh ///
medhhinc baplus_share if zone == "_mf"

* ========================= *
* COUNTS VS. PERMITS
* ========================= *

tab lrg_sf20to49 
