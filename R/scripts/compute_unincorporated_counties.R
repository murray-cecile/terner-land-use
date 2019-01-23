#===============================================================================#
# COLLAPSE CENSUS TRACT DATA TO UNINCORPORATED COUNTIES
#   Create crosswalk between tracts and unincorporated counties; assign data
#
# Cecile Murray
# 2019-01-08
#===============================================================================#

library(here)
source("scripts/setup.R")
 
#===============================================================================#
# CREATE TRACT-PLACE CROSSWALK
#===============================================================================#
 
setwd(RAW_DIR)
geocorr <- fread("geocorr2014.csv", header = TRUE)
geocorr <- geocorr[2:nrow(geocorr), ]
setwd(here())

xwalk <- geocorr %>% select(state, county, tract, hus10, afact) %>% 
  dplyr::rename(st = state, stcofips = county, fips = tract) %>% 
  mutate(tract = paste0(stcofips, as.numeric(fips) * 100),
         afact = as.numeric(afact),
         hus10 = as.numeric(hus10)) %>% 
  group_by(tract) %>% mutate(largest_afact = max(afact))  
  # select(stcofips, tract, hus10, afact, allocate)

qplot(xwalk$afact)
qplot(xwalk$afact, xwalk$hus10)

xwalk %<>% filter(allocate == 1)
