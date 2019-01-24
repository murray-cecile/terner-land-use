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

* COMPARE 
