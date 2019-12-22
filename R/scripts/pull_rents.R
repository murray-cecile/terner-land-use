#===============================================================================#
# PULL CENSUS 2000 MEDIAN RENTS
#
# Cecile Murray
# 2019-12-22
#===============================================================================#

library(here)
source("scripts/setup.R")

censuskey <- Sys.getenv("CENSUS_API_KEY")

#===============================================================================#
# PULL DATA
# pull data for all places within CA
#===============================================================================#


# 2013-17 median rents: table B25064
rents_1317 <- get_acs(geography = "place",
                       state = "CA",
                       table = "B25064",
                       year = 2017,
                       key = censuskey,
                       cache = TRUE) %>% 
  dplyr::rename(stplfips = GEOID) %>% 
  mutate(year = "13-17")

# 2008-2012 median rents: table B25064
rents_0812 <- get_acs(geography = "place",
                      state = "CA",
                      table = "B25064",
                      year = 2012,
                      key = censuskey,
                      cache = TRUE) %>% 
  dplyr::rename(stplfips = GEOID) %>% 
  mutate(year = "08-12")

rents_2000 <- get_decennial("place",
                       variables = "H063001",
                       year = 2000,
                       sumfile = "sf3",
                       state = "CA") %>% 
  dplyr::rename(stplfips = GEOID, 
                estimate = value) %>% 
  mutate(year = "00")

rents <- bind_rows(rents_1317,
                   rents_0812) %>%
  bind_rows(rents_2000) %>% 
  select(-moe)

#===============================================================================#
# INCLUDE ONLY THOSE IN TERNER SURVEY
#===============================================================================#

# get master dataset
setwd(MAIN_DIR)
master <- read.dta13("output/FINAL_merged_TCRLUS_census_buildperm.dta")
setwd(here())

# responding places
responding <- master %>%
  select(stplfips, city)
rm(master)

# merge with rents
rents %<>% right_join(responding,
                      by = "stplfips")

# count totals of non-NA estimates per year
counts <- rents %>% 
  group_by(city, stplfips) %>% 
  summarize(ct = sum(!is.na(estimate))) 

# only the unincorporated places don't match at all, as expected,
# plus Menifee is missing 2000

#===============================================================================#
# EXPORT
#===============================================================================#

write_excel_csv(rents, 
                "data_pulls/rents_all_years.csv",
                na = ".")
