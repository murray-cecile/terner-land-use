/*================================================================= *
* TERNER HOUSING SURVEY DATA: EXPLORE DATA
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2019-01-23
* ================================================================= */

clear all 
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

capture log close
log using "log/analysis_2019-01-23", append

use "output/FINAL_merged_TCRLUS_census_buildperm.dta", clear

merge 1:1 stplfips using "xwalks/place_county_CBSA_xwalk.dta", nogen

* snapshot 2
snapshot save


* COMPARE SHARES OF UNITS AND BUILDINGS
snapshot restore 2
keep stplfips city cbsa* x*_units_bldgs* // x*_unit_unit* x*_units_unit*
reshape long x@, i(stplfips city cbsa cbsaname) j(unit_type) string

tabstat x, s(sum) by(cbsaname) 

snapshot restore 2
