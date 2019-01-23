#===============================================================================#
# PULL ACS MEDIAN & AGGREGATE RENTS, MEDIAN HOME VALUES AND MEDIAN YEAR BUILT
#   Tables B25064, B25065, B25077, and 25035
#
# Cecile Murray
# 2019-01-22
#===============================================================================#

library(here)
source("scripts/setup.R")

censuskey <- Sys.getenv("CENSUSAPI_KEY")

#===============================================================================#
# PULL PLACE DATA
#===============================================================================#

# median gross rent - table B25064
# aggregate gross rent - table B25065
# median home value - B25077
# median year built - B25035

# construct varlist
vars <- sapply(c("B25035", "B25064", "B25065", "B25077"), 
               function(x) {paste0(x, "_001E")})

place_data <- getCensus("acs/acs5", vintage = 2017, key = censuskey,
                 vars = vars, region = "place", regionin = "state:06") %>% 
  clean_api_pull("place") %>% 
  dplyr::rename(med_age = B25035_001E, med_rent = B25064_001E,
                agg_rent = B25065_001E, med_homeval = B25077_001E)

# check whether I need to fix NA's and top-code values
setwd(MAIN_DIR)
master <- read.dta13("output/FINAL_merged_TCRLUS_census_buildperm.dta")
setwd(here())

stplfips_list <- select(master, stplfips) %>%
  left_join(place_data, by = "stplfips") %>% 
  mutate(uninc = ifelse(str_sub(stplfips, -3) == "999", 1, 0)) %>% 
  filter(!uninc)
which(is.na(stplfips_list))
# No NA's besides the unincorporated places so we should be good

write_excel_csv(place_data, "data_pulls/value_data_by_place.csv",
                na = ".")

#===============================================================================#
# PULL TRACT DATA
#===============================================================================#

tract_data <- getCensus("acs/acs5", vintage = 2017, key = censuskey,
                        vars = vars, region = "tract", regionin = "state:06") %>% 
  clean_api_pull("tract") %>% 
  dplyr::rename(med_age = B25035_001E, med_rent = B25064_001E,
                agg_rent = B25065_001E, med_homeval = B25077_001E)

write_excel_csv(tract_data, "data_pulls/value_data_by_tract.csv",
                na = ".")
