#===============================================================================#
# PULL ACS MEDIAN & AGGREGATE RENTS, MEDIAN HOME VALUES AND MEDIAN YEAR BUILT
#   Tables B25064, B25065, B25077, and 25035
#
# Cecile Murray
# 2019-01-22
#===============================================================================#

library(here)
source("scripts/setup.R")

censuskey <- Sys.getenv("CENSUS_API_KEY")

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

place_data <- getCensus("acs/acs5", vintage = 2012, key = censuskey,
                 vars = vars, region = "place", regionin = "state:06") %>% 
  clean_api_pull("place") %>% 
  dplyr::rename(med_age = B25035_001E, med_rent = B25064_001E,
                agg_rent = B25065_001E, med_homeval = B25077_001E,
                agg_homeval = B25079_001E)

rent0812 <- place_data %>% select(stplfips, med_rent, agg_rent)

# check whether I need to fix NA's and top-code values
setwd(MAIN_DIR)
master <- read.dta13("output/FINAL_merged_TCRLUS_census_buildperm.dta")
setwd(here())

stplfips_list <- select(master, stplfips) %>%
  left_join(rent0812, by = "stplfips") %>% 
  mutate(uninc = ifelse(str_sub(stplfips, -3) == "999", 1, 0)) %>% 
  filter(!uninc)
map(stplfips_list, function(x) which(is.na(x)))
stplfips_list[26, ]
# one NA on aggregate rent in Bradbury CA... small place, probably okay

write_excel_csv(filter(place_data, stplfips %in% master$stplfips),
                "data_pulls/rent0812_data_by_place.csv",
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
  dplyr::rename(agg_rent = B25065_001, agg_homeval = B25079_001) %>% 
  select(-agg_homeval)

# grab unincorporated 

write_excel_csv(tract_data, "data_pulls/rent0812_data_by_tract.csv",
                na = ".")
