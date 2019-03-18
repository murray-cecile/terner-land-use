#===============================================================================#
# MAKE MAP OF PERMITS
#
# Cecile Murray
#===============================================================================#

libs <- c("here", "tidyverse", "magrittr", "tigris", "sf", "viridis")
lapply(libs, library, character.only = TRUE)

censuskey <- Sys.getenv("CENSUS_API_KEY")

#===============================================================================#
# GET DATA
#===============================================================================#

permits <- haven::read_dta("/Users/cecilemurray/Documents/coding/Terner/output/FINAL_merged_TCRLUS_census_buildperm.dta")
permits %<>% select(city, stplfips, tot_unit_ct, x5_units_units)

# CApl <- places(state = "CA")
#  this is not working so I just run the following in the command line
#  wget https://www2.census.gov/geo/tiger/GENZ2017/shp/cb_2017_06_place_500k.zip
#  cd R/raw
#  unzip cb_2017_06_place_500k.zip
CApl <- st_read("raw/cb_2017_06_place_500k.shp")
CAst <- get_acs('state', table = "B01001", geometry = TRUE, state = "06")

mapdata <- CApl %>% mutate(stplfips = paste0("06", PLACEFP)) %>% 
  right_join(permits, by="stplfips") 

ggplot() +
  geom_sf(data = mapdata, aes(fill = x5_units_units), lwd = 0.1) +
  geom_sf(data = CAst, fill = NA, color="gray50", lwd = 0.5) +
  scale_fill_viridis() +
  coord_sf() +
  theme(panel.background = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = c(0.8, 0.8)) +
  labs(title = "Multifamily permit counts in surveyed municipalities", 
       caption = "Source: Census building permits")
# ggsave("plots/MF_permits_map.png", width = 8, height = 11, units = "in")

ggplot() +
  geom_sf(data = mapdata, aes(fill = x5_units_units/tot_unit_ct), lwd = 0.1) +
  geom_sf(data = CAst, fill = NA, color="gray50", lwd = 0.5) +
  scale_fill_viridis() +
  coord_sf() +
  theme(panel.background = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = c(0.85, 0.8)) +
  labs(title = "Multifamily permits per 1,000 housing units in surveyed municipalities",
       caption = "Source: Census building permits")
# ggsave("plots/MF_permits_percap_map.png", width = 8, height = 11, units = "in")
