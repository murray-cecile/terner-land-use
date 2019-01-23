#===============================================================================#
# PULL CENSUS BUILDING PERMITS
#   Pull annual building permits by place for West region, 2016 and 2017
#
# Cecile Murray
# 2018-12-19
#===============================================================================#

library(here)
here()

source("scripts/setup.R")

YEAR <- 2013

#===============================================================================#
# PULL DATA FROM CENSUS WEBSITE
#===============================================================================#

url <- paste0("https://www2.census.gov/econ/bps/Place/West%20Region/we",
                YEAR, "a.txt")

# building permits colnames are terribly specified so this creates a names vector
get_colnames <- function(url){
  
  # grab the two rows containing names
  row1 <- read_csv(url, n_max = 1, col_names = FALSE) %>% as.character()
  row2 <- read_csv(url, skip = 1, n_max = 1, col_names = FALSE) %>% as.character()

  # shift everything over because 1-unit is in the wrong place
  row1[18:41] <- c(row1[19:40], NA, NA)

  names <- bind_cols(tibble(row1), tibble(row2)) %>% 
    fill(row1) %>% 
    mutate(names = paste0(row1, row2))

  rv <- c(names$row1[1:17], names$names[18:41])
  return(rv)
}

colnames <- get_colnames(url)

raw_permits <- fread(url, col.names = colnames) %>% clean_names()

write_excel_csv(raw_permits, paste0("data_pulls/building_permits_West_places_",
                                    YEAR, ".xlsx"))

#===============================================================================#
# FILTER TO CALIFORNIA, UNITS AND BUILDINGS
#===============================================================================#

permCA <- mutate(raw_permits, 
                 stfips = str_pad(as.character(state), 2, side = "left", pad = "0"),
                 cofips = str_pad(as.character(county), 3, side = "left", pad = "0"),
                 plfips = str_pad(as.character(fips_place), 5, side = "left", pad = "0"),
                 stcofips = paste0(stfips, cofips),
                 stplfips = paste0(stfips, plfips)) %>% 
  select(stfips, stcofips, stplfips, cofips, plfips, csa, cbsa, region, division, place,
         contains("units"), -contains("value")) %>% 
  filter(stfips == "06") 

setwd(CENSUS_DIR)
save.dta13(permCA, paste0("CA_places_building_permits_", YEAR, ".dta"))
setwd(here())
