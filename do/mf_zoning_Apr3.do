/******************************************************************************
** This do file "mf_zoning_Apr3.do" creates tables/figures for CA zoning paper
** Author: Jenny Schuetz
** Written: Jan 17 2019
** Revised: Apr 3 2019
******************************************************************************/

capture log close
clear all
set more off

*******************************
** Some additional variables **
*******************************

cd "V:\Jenny\Terner land use\Data\"
use "Survey\zone_master.dta", clear

rename county countyfp
merge m:1 countyfp using "ca_land_cnty.dta"
drop if _merge==2
drop _merge

** 2010 rent data **
rename stplfips str_plfips
gen stplfips = real(str_plfips)
merge 1:1 stplfips using "Census\rent2010.dta"
drop _merge

** adjusting 2010 rent to 2016 $ **
gen rrent10 = medrent10*(240.007/218.179)

gen mf_new = mfunits/(hus10/1000)
replace pnewhsg = permtot/hus10

** From agg rent to avg rent **
gen rent_hsg = hsg*(1-ownocc)
gen own_hsg = hsg*ownocc
gen avgrent = agg_rent/rent_hsg
gen avgval = agg_homeval/own_hsg

gen hsgdens = hus10/landsqmi
gen ldense = ln(hsgdens + 1)
gen ldist = ln(distcbd + 1)
gen linc = ln(medhhinc + 1)
gen lpop = ln(pop + 1)
gen lmfnew = ln(mf_new + 1)

gen la = (cbsa==31080)
gen riversid= (cbsa==40140)
gen sac = (cbsa==40900)
gen sf = (cbsa==41860)
gen sandiego = (cbsa==41740)
gen sanjose = (cbsa==41940)
gen big6 = (la==1 | riversid==1 | sac==1 | sf==1 | sandiego==1 | sanjose==1 )

** Recoding MF ht limit (lots of bunching **
gen mfheight = 30 if (zon_mfheightlimit > 0 & zon_mfheightlimit<=30)
replace mfheight = 35 if (zon_mfheightlimit > 30 & zon_mfheightlimit<=35)
replace mfheight = 40 if (zon_mfheightlimit > 35 & zon_mfheightlimit<=40)
replace mfheight = 45 if (zon_mfheightlimit > 40 & zon_mfheightlimit<=45)
replace mfheight = 50 if (zon_mfheightlimit > 45 & zon_mfheightlimit~=.)

** recode units/acre (w/out missings) **
gen mfdense = zon_mfmaxdensity if zon_mfmaxdensity>0
replace mfdense = 100 if mfdense==200

STOP

/************
** Table 2 **
*************/

tab lnd_mf
tab lnd_sf
tab lnd_nr

tab lnd_mf if big6==1 & uninc==0
tab lnd_mf if pop>=100000

*************
** Table 3 **
*************

tab mfheight
tab mfheight if big6==1 & uninc==0
tab mfheight if pop>=100000

*************
** Table 4 **
*************

tabstat mfdense, stats(min p25 p50 p75 max mean sd n)
tabstat mfdense if big6==1 & uninc==0, stats(p50 mean sd n)
tabstat mfdense if pop>=100000, stats(p50 mean sd n)

*************
* Figure 4 **
*************

# delimit ;
graph twoway 
	(scatter mf_new rrent10 if big6==0, color(gray) ) 
	(scatter mf_new rrent10 if la==1, color(red) )
	(scatter mf_new rrent10 if riversid==1, color(orange) ) 
	(scatter mf_new rrent10 if sac==1, color(gold) ) 
	(scatter mf_new rrent10 if sandiego==1, color(green) ) 
	(scatter mf_new rrent10 if sanjose==1, color(blue) ) 
	(scatter mf_new rrent10 if sf==1, color(purple) ) 
	(lfit mf_new rrent10, lwidth(medthick) lcolor(black) )	,
title( "Highest rent CA cities build little MF")
subtitle( "New multifamily permits in CA cities/towns" ) 
ytitle( "MF permits/1000 old housing" ) 
xtitle( "Median rent (2010)" ) 
legend( rows(2) label(1 "Not Big 6") label(2 "LA") label(3 "R-SB") label(4 "SAC") label(5 "SD") label(6 "SJ") label(7 "SF") label(8 "Predicted MF" ) );

*************
** Table 5 **
*************

gsort -rrent10 city
browse city cbsaname rrent10 mf_new

/*************
** Figure 5 **
*************/ 

# delimit ;
twoway 
	(scatter mf_new mfdense) (lfit mf_new mfdense ),
title( "MF permits vs allowed density")
ytitle( "MF permits/1000 old housing" ) 
xtitle( "zoned units/acre" ) 
legend( rows(2) label(1 "Pop < 30k") label(2 "predicted MF") );

/***********
* Table 6 **
***********/

gen sample = (mfdense~=. & mfheight~=. & more_mf~=. & rrent10~=.)

cd "V:\Jenny\Terner land use\Analysis\Results\"

reg mf_new mfdense mfheight more_mf if sample==1, r
	outreg2 mfdense mfheight more_mf using "regs1.txt", nocons replace
tobit mf_new mfdense mfheight more_mf if sample==1, ll(0)
	outreg2 mfdense mfheight more_mf using "regs1.txt", nocons append
tobit mf_new mfdense mfheight more_mf rrent10 lpop ldens baplus black hisp asian if sample==1, ll(0)
	outreg2 mfdense mfheight more_mf rrent10 lpop ldens baplus black hisp asian using "regs1.txt", nocons append
tobit mf_new rrent10 if sample==1, ll(0)
	outreg2 rrent10 using "regs1.txt", nocons append
tobit mf_new rrent10 lpop ldens baplus black hisp asian if sample==1, ll(0)
	outreg2 rrent10 lpop ldens baplus black hisp asian using "regs1.txt", nocons append
