#===============================================================================#
# PULL TRACT LEVEL DEMOGRAPHIC DATA
#   Description
#
# Cecile Murray
# 2019-01-08
#===============================================================================#

library(here)
source("scripts/setup.R")
censuskey <- Sys.getenv("CENSUSAPI_KEY")

#===============================================================================#
# PULL DATA
#===============================================================================#

# pull educational attainment for 25+ population
edu_data <- get_acs(geography = "tract", state = "CA", table = "B15003",
                    year = 2017, key = censuskey, cache = TRUE) %>% 
  dplyr::rename(tract = GEOID) %>% 
  mutate(se2 = (moe / 1.645)^2)

# filter down to BA+, collapse categories, compute share 
ba_plus <- edu_data %>% mutate(num = as.numeric(str_sub(variable, -2, -1))) %>% 
  filter(num == 1 | num %in% seq(22, 25)) %>% 
  mutate(total = ifelse(num == 1, 1, 0)) %>% 
  select(-num, -moe, -variable, -NAME) %>% 
  group_by(tract, total) %>% summarize_all(sum, na.rm=TRUE) %>% 
  gather(type, value, -tract, -total) %>% 
  mutate(label = paste0(type, "_", total)) %>% 
  select(-total, -type) %>% 
  spread(label, value) %>% 
  dplyr::rename(baplus = estimate_0, baplus_se2 = se2_0,
                total = estimate_1, total_se2 = se2_1) %>% 
  mutate(baplus_share = baplus / total,
         baplus_share_se2 = derive_se2(baplus, total, baplus_se2, total_se2, "prop")) 

#===============================================================================#
# PULL MEDIAN HOUSEHOLD INCOME
#===============================================================================#

inc_data <- get_acs("tract", state = "CA", table = "B19013", year = 2017,
                    cache_table = TRUE, key = censuskey) %>% 
  dplyr::rename(tract = GEOID) %>% 
  mutate(se2 = (moe / 1.645)^2)

inc <- inc_data %>% dplyr::rename(medhhinc = estimate, medhhinc_se2 = se2) %>% 
  select(-NAME, -moe, -variable)

#===============================================================================#
# RACE
#===============================================================================#

race_data <- get_acs("tract", state = "CA", table = "B03002", year = 2017,
                     cache_table = TRUE, key = censuskey) %>% 
  dplyr::rename(tract = GEOID) %>% 
  mutate(se2 = (moe / 1.645)^2)

r <- c("white", "black", "ai_an", "asian", "nh_pi", "other", "twomore", 
       "twomore_other", "two_or_three")
race_names <- c("total", "nonhisp", sapply(r, function(x){paste0(x, "_nh")}),
                "hisp", sapply(r, function(x){paste0(x, "_hisp")}))
race_vars <- data.frame(variable = unique(race_data$variable),
                        name = race_names)

race <- left_join(race_data, race_vars, by = "variable") %>% 
  filter(name %in% c("total", "white_nh", "black_nh", "asian_nh", "hisp")) %>% 
  dplyr::rename(race = name) %>% select(-moe) %>% 
  mutate(total = ifelse(race == "total", estimate, NA),
         total_se2 = ifelse(race == "total", se2, NA)) %>% 
  fill(total, total_se2) %>% filter(race != "total") %>% 
  mutate(race_share = estimate / total,
         race_share_se2 = derive_se2(estimate, total, se2, total_se2, "prop")) %>% 
  select(tract, total, total_se2, race, estimate, se2, contains("share")) %>% 
  dplyr::rename(race_ct = estimate, race_ct_se2 = se2)

#===============================================================================#
# AGE
#===============================================================================#

#  families w/kids < 18, % of pop 65+ - S0101
demo_data <- getCensus(name = "acs/acs5/subject", vintage = 2017, key = censuskey,
                       vars = c("S0101_C01_001E", "S0101_C01_022E", "S0101_C01_030E",
                                "S0101_C01_001M", "S0101_C01_022M", "S0101_C01_030M"),
                       region = "tract", regionin = "state:06") %>% 
  clean_api_pull("tract") %>% 
  gather(contains("S0101"), estimate, -tract) %>% clean_names() %>% 
  mutate(variable = substr(contains_s0101, 1, 13),
         type = substr(contains_s0101, 14, 14)) %>% 
  select(-contains_s0101) %>% spread(type, estimate) %>% 
  dplyr::rename(estimate = E, moe = M) %>% 
  mutate(se2 = (moe / 1.645) ^ 2)

age_vars <- data.frame(variable = unique(demo_data$variable),
                       name = c("total", "under18", "over65"))

demo <- left_join(demo_data, age_vars, by = "variable") %>% 
  select(tract, name, estimate, moe, se2) %>% 
  mutate(total = ifelse(name == "total", estimate, NA),
         total_se2 = ifelse(name == "total", se2, NA)) %>% 
  fill(total, total_se2) %>% filter(name != "total") %>% 
  mutate(age_share = estimate / total,
         age_share_se2 = derive_se2(estimate, total, se2, total_se2, "prop")) %>% 
  select(tract, name, contains("total"), estimate, se2, contains("share")) %>% 
  dplyr::rename(agecat = name, age_ct = estimate, age_ct_se2 = se2)

#===============================================================================#
# SAVE TO TEMP FILES
#===============================================================================#

write_excel_csv(ba_plus, "temp/ba_plus_share_tracts.csv", na = ".")
write_excel_csv(inc, "temp/median_income_tracts.csv", na = ".")
write_excel_csv(race, "temp/race_ethnicity_tracts.csv", na = ".")
write_excel_csv(demo, "temp/age_composition_tracts.csv", na = ".")
