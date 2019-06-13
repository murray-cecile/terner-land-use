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
terner_gray <- "#5B6770"
terner_blue <- "#4E748B" 
terner_gold <- "#B7B09D" 
terner_navy <- "#011E41"
terner_red <- "#E74C39"


# define theme
chart_theme <- function(...) {
  theme(panel.background = element_blank(),
        panel.grid.major = element_line(color = "gray75",
                                        size = rel(0.75),
                                        linetype = "dotted"),
        text = element_text(family = "Minion Pro", size = 11),
        axis.text = element_text(size = 11),
        legend.text = element_text(size = 10),
        plot.title = element_text(size = 14),
        plot.subtitle = element_text(size = 12),
        axis.ticks.x = element_blank(),
        plot.caption = element_text(hjust = 0),
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
  scale_fill_manual(values = c("SF" = terner_gold, 'MF' = terner_blue),
                    labels = c(" Multifamily", " Single-family")) +
  labs(title = "Most municipalities reserve most of their land for single-family units",
       subtitle = "Share of land zoned to allow multifamily vs. single-family construction",
       x = "Share of land zoned", y = "Number of municipalities",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(axis.ticks.x = element_blank(),
        legend.position = c(0.8, 0.85),
        legend.title = element_blank())
# ggsave("final_plots/fig2_land_share.png", width = 7, height = 5, units = c("in"), dpi = 600)

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
  scale_fill_manual(labels = c(" Multifamily", " Single-family"),
                    values = c("SF" = terner_gold, 'MF' = terner_blue)) +
  labs(title = "Most respondents restrict building heights to four stories or fewer",
       subtitle = "Adjusted building height limits",
       x = "Height limit", y = "Number of municipalities",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(legend.title = element_blank(),
              legend.position = c(0.8, 0.9))
# ggsave("final_plots/fig3_bld_hgt.png",
#        width = 7, height = 5, units = c("in"), dpi= 600)

#===============================================================================#
# HISTOGRAM: DU / ACRE
#===============================================================================#

# correct for erroneous outlier in Concord and reshape for ggplot
density <- tcrlus %>% select(city, contains("maxdensity")) %>% 
  mutate(zon_mfmaxdensity = ifelse(city == "Concord",
                                   100,
                                   zon_mfmaxdensity)) %>% 
  select(-city) %>% 
  dplyr::rename(SF = zon_sfmaxdensity,
                MF = zon_mfmaxdensity) %>% 
  gather(key = "zone", value = "max_density") %>% 
  filter(max_density > 0, zone == "MF")

ggplot(density, aes(x = max_density)) +
  geom_histogram(binwidth = 5, fill = terner_blue, color = "white") +
  scale_x_continuous(breaks = seq(0, 200, 25)) +
  labs(title = "Many municipalities restrict multifamily density",
       x = "Maximum dwelling units per acre", y = "Number of municipalities",
       subtitle = "Maximum multifamily dwelling units per acre",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(legend.title = element_blank())
# ggsave("final_plots/appendixA_max_du_acre_histogram.png",
#        width = 7, height = 5, units = c("in"), dpi = 600)

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
  scale_fill_manual(name = "Permits issued",
                    values = c("Above median" = terner_blue,
                               'Below median' = terner_gold)) +
  geom_col(position = "dodge") +
  labs(title = "Reported approval times vary little by number of permits issued",
       subtitle = "Approval time for multifamily projects consistent with general zoning",
       x = "Approval time", y = "Number of municipalities",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(legend.position = c(0.8, 0.8))
# ggsave("final_plots/fig5_approval_times.png",
#        width = 7, height = 5, units = c("in"), dpi = 600)

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
  filter(!apl_mf5to19 %in% c("Missing")) %>% 
  bind_rows(data.frame(apl_mf5to19 = c("Most months"),
                             permit_level = c("Below median"),
                             ct = c(0))) %>% 
  mutate(order = case_when(
    apl_mf5to19 == "Never" ~ 0,
    apl_mf5to19 == "Once per year or less" ~ 1,
    apl_mf5to19 == "Several times per year" ~ 2,
    apl_mf5to19 == "Most months" ~ 3,
    apl_mf5to19 == "Most weeks" ~ 4,
  ))

ggplot(apps, aes(x = reorder(apl_mf5to19, order),
                 y = ct,
                 group = permit_level,
                 fill = permit_level)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) +
  scale_fill_manual(name = "Permits issued",
                    values = c("Above median" = terner_blue,
                               'Below median' = terner_gold)) +
  geom_col(position = "dodge") +
  labs(title = "Municipalities that didn't permit many units reported fewer permit applications",
       subtitle = "Frequency of permit approvals for multifamily projects (5-19 units per building)",
       x = "Application frequency", y = "Number of municipalities",
       caption = "Source: Terner Center Land Use Survey") +
  chart_theme(legend.position = c(0.8, 0.8))
# ggsave("final_plots/fig8_applications.png",
#        width = 7, height = 5, units = c("in"), dpi = 600)


#===============================================================================#
# SMALL MULTIPLES/SCATTER: PREDICTED CONSTRUCTION IN CA
#===============================================================================#

# bring in data, filter out other metros 
setwd(MAIN_DIR)
scatter_data <- data.table::fread('plots/fig4data.txt') %>% 
  mutate(metro_name = ifelse(big6 == 1, cbsaname, "Other")) %>% 
  filter(metro_name != "Other") %>% 
  select(city, stplfips, metro_name, mf_new, rrent10) %>% 
  mutate(metro_name = case_when(
    metro_name == "San Francisco-Oakland-Hayward, CA (Metro)" ~ "San Francisco (Metro)",
    metro_name == "San Jose-Sunnyvale-Santa Clara, CA (Metro)" ~ "San Jose (Metro)",
    metro_name == "Los Angeles-Long Beach-Anaheim, CA (Metro)" ~ "Los Angeles (Metro)",
    metro_name == "San Diego-Carlsbad, CA (Metro)" ~ "San Diego (Metro)",
    metro_name == "Riverside-San Bernardino-Ontario, CA (Metro)" ~ "Riverside (Metro)",
    metro_name == "Sacramento--Roseville--Arden-Arcade, CA (Metro)" ~ "Sacramento (Metro)",
  ))

ggplot(scatter_data, aes(x = rrent10, y = mf_new, color = metro_name)) +
  geom_point(color = terner_blue) +
  geom_smooth(method = "lm", se = FALSE, color = terner_blue) +
  facet_wrap(facets = vars(metro_name), 
             nrow = 3,
             ncol = 2,
             scales = "free_y") +
  labs(title = 'Rents do not consistently predict apartment development in California',
       subtitle = "New multifamily permits versus rents in California municipalities by metro area",
       x = "Median gross rent, 2008-2012", y = "New multifamily permits per existing housing units, 2013-2017",
       colour = "Metro Name",
       caption = "Source: Median rent and housing count from ACS 2008-2012, total multifamily permits 2013-2017 from Census Bureau’s Residential Construction series") +
  chart_theme(legend.position = "none",
        strip.text = element_text(size = 14),
        panel.background = element_blank(),
        panel.grid.major = element_line(linetype = 'dotted', color = 'gray60'),
        panel.grid.minor = element_line(linetype = 'dotted', color = 'gray60')
        )
# ggsave('final_plots/fig7_small_multiples_v5.png',
#        width = 8.5, height = 11, dpi = 600)

#===============================================================================#
# SCATTER: PERMITS VS RENTS
#===============================================================================#

perm_rent_data <- data.table::fread("R/temp/metro_graph.txt") %>% 
  mutate(in_CA = ifelse(ca == 1, "California metro", "Other large metro"))

ggplot(perm_rent_data,
       aes(x = medrent, y = pnewmf)) +
  geom_point(aes(color = in_CA)) +
  scale_color_manual( name = "",
                     values = c("California metro" = terner_red,
                                "Other large metro" = terner_blue)) +
  geom_smooth(method = "lm", color = terner_blue, se = FALSE) +
  labs(title = "California metros underbuild multifamily units",
       subtitle = "New multifamily housing and initial rent levels, 100 largest metropolitan areas",
       x = "Median rent ($)", y = "MF permits/old housing",
       caption = "Source: Median rent and housing count for 100 largest metros as of 2010 (Census 2010), total multifamily permits
as of 2013-2017 from Census Bureau’s Residential Construction series") +
  chart_theme(legend.position = c(0.8, 0.85),
              legend.text = element_text(size = 11),
              legend.key = element_rect(colour = "white", fill = NA))
# ggsave("final_plots/fig1_CA_metros_underbuild.png",
#        width = 7, height = 5, units = "in", dpi = 600)

#===============================================================================#
# SCATTER: MAX UNITS PER ACRE VS PERMITS
#===============================================================================#

zoning_permits <- data.table::fread("R/temp/city_dense_graph.txt") 

ggplot(zoning_permits, aes(x = mfdense, y = mf_new)) +
  geom_point(color = terner_blue) +
  geom_smooth(method = "lm", se = FALSE, color = terner_blue) +
  labs(title = "Less restrictive zoning predicts more multifamily permits",
       subtitle = "Maximum allowed multifamily units per acre vs. new multifamily permits in CA municipalities",
       x = "Maximum units per acre", y = "MF permits per 1,000 old housing units",
       caption = "Source: Vertical axis shows multifamily permits from 2013-2017 normalized by 2010 housing units.
Permit data from Census Bureau’s New Residential Construction Series, housing unit counts from 2008-2012 ACS.
Maximum units per acre from TCRLUS.") +
  chart_theme()
# ggsave("final_plots/fig9_restrictive_zoning_permits.png",
#        width = 7, height = 5, units = "in", dpi = 600)







