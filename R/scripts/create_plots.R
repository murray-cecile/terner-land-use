#===============================================================================#
# CREATE TRCLUS CHARTS
#
# Cecile Murray
#===============================================================================#
library(here)
source("scripts/setup.R")

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
