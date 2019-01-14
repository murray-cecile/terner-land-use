/*================================================================= *
* TERNER HOUSING SURVEY DATA
*	
*	Cecile Murray
*	Stata 13.1 on Mac
*	Created: 2018-11-23
* ================================================================= */

clear all
set more off

capture cd "/Users/cecilemurray/Documents/coding/Terner"

use "raw/TCRLUS_data13_2018-11-12.dta", clear

hist rez_year if rez_year > 100

scatter zon_sfminlotsize zon_mfminlotsize if zon_sfminlotsize > 0 & zon_mfminlotsize > 0

tab apt_sfvariance apt_mfvariance, chi2
tab apt_sfeir apt_mfeir, chi2 row

tab apr_sfplan apr_mfplan, row

tab type
