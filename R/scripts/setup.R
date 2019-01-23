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
UTILS <- "/Users/cecilemurray/Documents/coding/R/utils"
CENSUS_DIR <- "/Users/cecilemurray/Documents/coding/Terner/census"
RAW_DIR <- "/Users/cecilemurray/Documents/coding/Terner/raw"

setwd(UTILS)
source("utils.R")
setwd(here())

source("scripts/statsig_functions.R")

