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
# aggregate home value - B25079
# median year built - B25035

# construct varlist
vars <- sapply(c("B25035", "B25064", "B25065", "B25077", "B25079"), 
               function(x) {paste0(x, "_001E")})

place_data <- getCensus("acs/acs5", vintage = 2017, key = censuskey,
                 vars = vars, region = "place", regionin = "state:06") %>% 
  clean_api_pull("place") %>% 
  dplyr::rename(med_age = B25035_001E, med_rent = B25064_001E,
                agg_rent = B25065_001E, med_homeval = B25077_001E,
                agg_homeval = B25079_001E)

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

tract_vars <- sapply(c( "B25065", "B25079"), function(x) {paste0(x, "_001E")})

# use tidycensus because it handles the missing and top-coded values better!
tract_data <- get_acs(geography = "tract", variables = tract_vars,
                      year = 2017, state = "CA", key = censuskey) %>% 
  dplyr::rename(tract = GEOID) %>% select(-NAME, -moe) %>% 
  spread(variable, estimate) %>% 
  dplyr::rename(agg_rent = B25065_001, agg_homeval = B25079_001)

write_excel_csv(tract_data, "data_pulls/value_data_by_tract.csv",
                na = ".")
