#===============================================================================#
# CREATE TCRLUS CHARTS
#
# Cecile Murray
#===============================================================================#

library(here)
source("scripts/setup.R")

# bring in final dataset
setwd(MAIN_DIR)
tcrlus <- haven::read_dta("output/FINAL_merged_TCRLUS_census_buildperm.dta")

#===============================================================================#
# THEMING /AESTHETICS
#===============================================================================#

# Terner colors
terner_blue <- "#4F758B" # c(79, 117, 139)
terner_gold <- "#F1A900" # c(241, 169, 0)

# define theme
chart_theme <- function(...) {
  theme(panel.background = element_blank(),
        panel.grid.major = element_line(color = "gray75",
                                        size = rel(0.75),
                                        linetype = "dotted"),
        text = element_text(family = "Lucida Grande"),
        legend.background = element_blank()) +
  theme(...)
}

#===============================================================================#
# BAR CHART: SHARE OF LAND ZONED FOR MF VS. SF
#===============================================================================#

# create frequency tables, filter out unwanted categories
land_share <- data.frame(sf = table(haven::as_factor(tcrlus$lnd_sf)),
                mf = table(haven::as_factor(tcrlus$lnd_mf)),
                nr = table(haven::as_factor(tcrlus$lnd_nr))) %>% 
  select(sf.Var1, contains("Freq")) %>% 
  dplyr::rename(land_share = sf.Var1,
                SF = sf.Freq,
                MF = mf.Freq,
                NR = nr.Freq) %>% 
  filter(!land_share %in% c("Missing", "Varies, inconsistent", "N/A, none")) %>% 
  gather(key = "zone", value = "ct", SF:NR) %>% 
  filter(zone != "NR")

# create plot
ggplot(land_share, aes(x = land_share, y = ct, group = zone, fill = zone)) +
  geom_col(position = "dodge") +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  scale_fill_discrete(labels = c("Multifamily", "Single-family")) +
  labs(title = "Most municipalities reserve most of their land for single-family units",
       subtitle = "Share of land zoned to allow multifamily vs. single-family construction",
       x = "Share of land zoned", y = "Number of municipalities",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(axis.ticks.x = element_blank(),
        legend.position = c(0.8, 0.85),
        legend.title = element_blank())
# ggsave("plots/fig2_land_share.png", width = 7, height = 5, units = c("in"))

#===============================================================================#
# BAR CHART: MAX BUILDING HEIGHT
#===============================================================================#

# rounding max heights to nearest 5, capping at 50
max_height <- tcrlus %>% select(contains("heightlimit")) %>% 
  dplyr::rename(SF = zon_sfheightlimit,
                MF = zon_mfheightlimit) %>% 
  gather(key = "zone", value = "height") %>% 
  mutate(limit = case_when(
    height < 0 ~ height,
    height < 50 ~ 5 * round(height / 5),
    height >= 50 ~ 50)) %>% 
  filter(limit > 0) %>% 
  group_by(zone, limit) %>%
  summarise(ct = n()) %>% 
  bind_rows(data.frame(zone = c("SF", "MF"),
                       limit = c(50, 15),
                       ct = c(0, 0)))

ggplot(max_height, aes(x = limit, y = ct, group = zone, fill = zone)) +
  geom_col(position = "dodge") +
  scale_x_continuous(breaks = seq(0, 50, 5)) +
  scale_fill_discrete(labels = c("Multifamily", "Single-family")) +
  labs(title = "Most respondents restrict building heights to four stories or fewer",
       subtitle = "Adjusted building height limits",
       x = "Height limit", y = "Number of municipalities",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(legend.title = element_blank(),
              legend.position = c(0.8, 0.9))
# ggsave("plots/fig3_bld_hgt.png", width = 7, height = 5, units = c("in"))

#===============================================================================#
# HISTOGRAM: DU / ACRE
#===============================================================================#

density <- tcrlus %>% select(contains("maxdensity")) %>% 
  dplyr::rename(SF = zon_sfmaxdensity,
                MF = zon_mfmaxdensity) %>% 
  gather(key = "zone", value = "max_density") %>% 
  filter(max_density > 0, zone == "MF")

ggplot(density, aes(x = max_density)) +
  geom_histogram(binwidth = 5, fill = terner_blue, color = "white") +
  scale_x_continuous(breaks = seq(0, 200, 25)) +
  labs(title = "Many municipalities restruct multifamily density",
       x = "Maximum dwelling units per acre", y = "Number of municipalities",
       subtitle = "Maximum multifamily dwelling units per acre",
       source = "Terner Center Land Use Survey") +
  chart_theme(legend.title = element_blank())
# ggsave("plots/max_du_acre_histogram.png", width = 7, height = 5, units = c("in"))

#===============================================================================#
# BAR CHART: APPROVAL TIMES
#===============================================================================#

approvals <- tcrlus %>% select(x5_units_units, apt_mfconsistent) %>% 
  mutate(permit_level = ifelse(x5_units_units >= 66, 
                               "Above median",
                               "Below median"),
         apt_mfconsistent = haven::as_factor(apt_mfconsistent)) %>% 
  select(-x5_units_units) %>% 
  group_by(apt_mfconsistent, permit_level) %>% 
  summarize(ct = n()) %>% 
  filter(!apt_mfconsistent %in% c("Missing", "Varies, inconsistent",
                                  "N/A, none", NA))

ggplot(approvals, aes(x = apt_mfconsistent, y = ct, group = permit_level,
                      fill = permit_level)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  scale_fill_discrete(name = "Permits issued") +
  geom_col(position = "dodge") +
  labs(title = "Municipalities that didn't permit many units reported \nshorter approval times",
       subtitle = "Approval time for multifamily projects consistent with general zoning",
       x = "Approval time", y = "Number of municipalities",
       source = "Terner Center Land Use Survey") +
  chart_theme(legend.position = c(0.8, 0.8))
ggsave("plots/fig4_approval_times.png", width = 7, height = 5, units = c("in"))

#===============================================================================#
# BAR CHART: APPLICATIONS
#===============================================================================#

apps <- tcrlus %>% select(x5_units_units, apl_mf5to19) %>% 
  mutate(permit_level = ifelse(x5_units_units >= 66, 
                               "Above median",
                               "Below median"),
         apl_mf5to19 = haven::as_factor(apl_mf5to19)) %>% 
  select(-x5_units_units) %>% 
  group_by(apl_mf5to19, permit_level) %>% 
  summarize(ct = n()) %>% 
  filter(!apl_mf5to19 %in% c("Missing"))

ggplot(apps, aes(x = apl_mf5to19, y = ct, group = permit_level,
                      fill = permit_level)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  scale_fill_discrete(name = "Permits issued") +
  geom_col(position = "dodge") +
  labs(title = "Municipalities that didn't permit many units reported \nless frequent applications",
       subtitle = "Frequency of approvals for multifamily projects between 5 and 19 units",
       x = "Application frequency", y = "Number of municipalities",
       source = "Terner Center Land Use Survey") +
  chart_theme(legend.position = c(0.8, 0.8))
ggsave("plots/fig8_applications.png", width = 7, height = 5, units = c("in"))


#===============================================================================#
# SMALL MULTIPLES/SCATTER: PREDICTED CONSTRUCTION IN CA
#===============================================================================#

# bring in data, filter out other metros 
setwd(MAIN_DIR)
scatter_data <- data.table::fread('plots/fig4data.txt') %>% 
  mutate(metro_name = ifelse(big6 == 1, cbsaname, "Other")) %>% 
  filter(metro_name != "Other") %>% 
  select(city, stplfips, metro_name, mf_new, rrent10) 

ggplot(scatter_data, aes(x = rrent10, y = mf_new, color = metro_name)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(facets = vars(metro_name)) +
  labs(title = 'Rents do not necessarily predict construction in California municipalities',
       subtitle = "New multifamily permits versus rents in California municipalities",
       x = "Median gross rent, 2008-2012", y = "New multifamily permits, 2013-2017",
       colour = "Metro Name") +
  theme(legend.position = "none",
        text = element_text(family='Lucida Grande'))
ggsave('plots/fig4_small_multiples_v2.png', width = 11, height = 8.5)


