#===============================================================================#
# TERNER DATA PULLS: SETUP
#   import packages, set global vars, etc
#
# Cecile Murray
# 2018-12-19
#===============================================================================#

libs <- c("tidyverse", "magrittr", "stringr", "readr", "openxlsx", "janitor", "sp",
          "tigris", "tidycensus", "censusapi", "broom", "foreign", "readstata13",
          "data.table")
lapply(libs, library, character.only=TRUE)

MAIN_DIR <- "/Users/cecilemurray/Documents/coding/Terner"
UTILS <- "/Users/cecilemurray/Documents/coding/R/r_utils"
CENSUS_DIR <- "/Users/cecilemurray/Documents/coding/Terner/census"
RAW_DIR <- "/Users/cecilemurray/Documents/coding/Terner/raw"

setwd(UTILS)
source("utils.R")
setwd(here())

source("scripts/statsig_functions.R")

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


