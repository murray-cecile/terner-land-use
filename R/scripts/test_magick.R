#===============================================================================#
# TCRLUS: TEST OUT MAGICK PACKAGE
#   Test whether the magick package offers a good way to analyze zoning maps
#
# Cecile Murray
# 2019-01-17
#===============================================================================#

library(here)
source("scripts/setup.R")

install.packages("magick")
install.packages("pdftools")
library(magick)
library(pdftools)

# see what formats are supported
magick::magick_config()

# try bringing in the PNG Carlsbad map
carlsbad <- image_read_pdf("raw/CarlsbadZoning11x17.pdf")

q = image_quantize(carlsbad)
r <- as.raster(carlsbad)
rtab <- table(r)
rtab <- data.frame(Color = names(rtab), Count = as.integer(rtab))

