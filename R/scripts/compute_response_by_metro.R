#===============================================================================#
# COMPUTE RESPONSE RATES BY METRO
#
# Cecile Murray
#===============================================================================#

library(here)
source("scripts/setup.R")

setwd(MAIN_DIR)

# bring in final dataset
tcrlus <- haven::read_dta("output/FINAL_merged_TCRLUS_census_buildperm.dta")

#===============================================================================#
# CONSTRUCT CROSSWALK
#===============================================================================#

# names for metro crosswalk
msa_varnames <- read_csv("xwalks/CBSA_county_place.csv",
                         n_max = 0) %>% names()

# bring in metro crosswalk
msa_xwalk <- read_csv("xwalks/CBSA_county_place.csv",
                      skip = 2,
                      col_names = msa_varnames) %>% 
  mutate(stplfips = paste0(state, placefp14)) %>% 
  select(cbsa, cbsaname15, stplfips)

# now pull population by place in 2017
plpop17 <- get_acs("place",
                   "B01001_001",
                   year = 2017,
                   state = "06") %>% 
  dplyr::rename(stplfips = GEOID,
                pop = estimate) %>% 
  select(-NAME, -variable, -moe)

msa_xwalk %<>% left_join(plpop17,
                          by = "stplfips")

#===============================================================================#
# COMPUTE RESPONSE RATES
#===============================================================================#

# assign respondants to metros
respondants <- tcrlus  %>% 
  select(city,
         stplfips,
         county,
         total) %>% 
  left_join(msa_xwalk,
            by = "stplfips")

# count # in 6 big metros
big6 <- respondants %>% 
  filter(cbsa %in% c("31080", # LA
                     "41860", # SF
                     "40140", # Riverside
                     "40900", # Sacramento,
                     "41740", # San Diego
                     "41940" # San Jose
                     )) %>% 
  group_by(cbsa) %>% 
  summarize(num_responded = n(),
            pop_responded = sum(total))

# compute count of places in each metro
big6_ct <- msa_xwalk %>% 
  filter(cbsa %in% c("31080", # LA
                     "41860", # SF
                     "40140", # Riverside
                     "40900", # Sacramento,
                     "41740", # San Diego
                     "41940" # San Jose
  )) %>% 
  group_by(cbsa, cbsaname15) %>% 
  summarize(ct = n(),
            pop = sum(pop, na.rm=TRUE))

# compute share of places and share of pop responding
response_summary <- big6 %>% 
  left_join(big6_ct, by = "cbsa") %>% 
  mutate(response_rate = num_responded / ct,
         pop_response_rate = pop_responded / pop) %>% 
  select(cbsa, cbsaname15, everything())

write_excel_csv(response_summary,
                "output/response_rates.csv")
