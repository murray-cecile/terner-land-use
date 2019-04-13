#===============================================================================#
# CREATE TRCLUS CHARTS
#
# Cecile Murray
#===============================================================================#

library(here)
source("scripts/setup.R")

setwd(MAIN_DIR)
tcrlus <- readstata13::read.dta13("output/FINAL_merged_TCRLUS_census_buildperm.dta")
setwd(here())

chart_theme <- function(...) {
  theme(panel.background = element_blank(),
        panel.grid.major = element_line(color = "gray75",
                                        size = rel(0.75),
                                        linetype = "dotted"),
        text = element_text(family = "Lucida Grande")) +
  theme(...)
}

#===============================================================================#
# BAR CHART: SHARE OF LAND ZONED FOR MF VS. SF
#===============================================================================#

land_share <- data.frame(sf = table(tcrlus$lnd_sf),
                mf = table(tcrlus$lnd_mf),
                nr = table(tcrlus$lnd_nr)) %>% 
  select(sf.Var1, contains("Freq")) %>% 
  dplyr::rename(land_share = sf.Var1,
                SF = sf.Freq,
                MF = mf.Freq,
                NR = nr.Freq) %>% 
  filter(!land_share %in% c("Missing", "Varies, inconsistent")) %>% 
  gather(key = "zone", value = "ct", SF:NR) %>% 
  filter(zone != "NR")

ggplot(land_share, aes(x = land_share, y = ct, group = zone, fill = zone)) +
  geom_col(position = "dodge") +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  labs(title = "Most municipalities reserve most of their land for single-family units",
       subtitle = "Share of land zoned to allow multifamily vs. single-family construction",
       x = "Share of land zoned", y = "Number of municipalities",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(axis.ticks.x = element_blank(),
        legend.position = c(0.8, 0.85),
        legend.title = element_blank())


#===============================================================================#
# SMALL MULTIPLES/SCATTER: PREDICTED CONSTRUCTION IN CA
#===============================================================================#

setwd(MAIN_DIR)
scatter_data <- data.table::fread('plots/fig4data.txt') %>% 
  mutate(metro_name = ifelse(big6 == 1, cbsaname, "Other")) %>% 
  select(city, stplfips, metro_name, mf_new, rrent10)

ggplot(scatter_data, aes(x = rrent10, y = mf_new, color = metro_name)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(facets = vars(metro_name)) +
  labs(title = 'Rents do not necessarily predict construction in California municipalities',
       subtitle = "New multifamily permits versus rents in California municipalities",
       x = "Median gross rent, 2008-2012", y = "New multifamily permits, 2013-2017",
       colour = "Metro Name") +
  theme(legend.position = c(0.8, 0.15),
        text = element_text(family='Lucida Grande'))
ggsave('plots/fig4_small_multiples.png', width = 11, height = 8.5)


