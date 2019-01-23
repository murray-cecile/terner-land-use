#===============================================================================#
# PULL ACS TENURE AND UNIT DATA 
#   Table B25032
#
# Cecile Murray
# 2018-12-20
#===============================================================================#

library(here)

source("scripts/setup.R")
censuskey <- Sys.getenv("CENSUSAPI_KEY")

#===============================================================================#
# PULL OCCUPANCY AND TENURE
#===============================================================================#

# pull data for all CA places, rename GEOID variable, convert MOE to SE2
tenure_type <- get_acs(geography = "place", state = "CA", table = "B25032",
                       year = 2017, key = censuskey, cache = TRUE) %>% 
  dplyr::rename(stplfips = GEOID) %>% 
  mutate(se2 = (moe/1.645)^2)

# create list of variables and create data frame aligning them
tenure_varnames <- c("total", "ownocc", "own_1det", "own_1att", "own_2", "own_3to4",
                 "own_5to9", "own_10to19", "own_20to49", "own_50plus", "own_mobile",
                 "own_boatrv", "rentocc", "rent_1det", "rent_1att", "rent_2", "rent_3to4",
                 "rent_5to9", "rent_10to19", "rent_20to49", "rent_50plus", "rent_mobile",
                 "rent_boatrv")
tenure_vars <- data.frame(variable = unique(tenure_type$variable),
                          varname = tenure_varnames)

# merge descriptive names into tenure data
tenure <- left_join(tenure_type, tenure_vars, by = "variable") %>% 
  mutate(total = ifelse(varname == "total", estimate, NA),
         total_se2 = ifelse(varname == "total", se2, NA)) %>% 
  fill(total, total_se2) %>% filter(varname != "total") %>% 
  select(-moe, -variable) %>% select(stplfips, NAME, varname, everything()) %>% 
  dplyr::rename(place = NAME, units = estimate, units_se2 = se2) %>% 
  mutate(share = units / total,
         share_se2 = derive_se2(units, total, units_se2, total_se2, "prop")) 

# export to Stata .dta file
write_excel_csv(tenure, "data_pulls/CA_tenure_by_units_2013-17.csv", na=".")

#===============================================================================#
# GET TRACT-LEVEL DATA
#===============================================================================#

# tenure
tenure_tract_data <- get_acs(geography = "tract", state = "CA", table = "B25032",
                       year = 2017, key = censuskey, cache = TRUE) %>% 
  dplyr::rename(tract = GEOID) %>% 
  mutate(se2 = (moe/1.645)^2)

# merge descriptive names into tenure data
tenure_tracts <- left_join(tenure_tract_data, tenure_vars, by = "variable") %>% 
  mutate(total = ifelse(varname == "total", estimate, NA),
         total_se2 = ifelse(varname == "total", se2, NA)) %>% 
  fill(total, total_se2) %>% filter(varname != "total") %>% 
  select(-moe, -variable, -NAME) %>% select(tract, varname, everything()) %>% 
  dplyr::rename(units = estimate, units_se2 = se2) %>% 
  mutate(share = units / total,
         share_se2 = derive_se2(units, total, units_se2, total_se2, "prop")) 

write_excel_csv(tenure_tracts, "temp/tenure_all_CA_tracts.csv", na=".")
