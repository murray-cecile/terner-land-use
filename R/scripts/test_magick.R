#===============================================================================#
# TCRLUS: TEST OUT MAGICK PACKAGE
#   Test whether the magick package offers a good way to analyze zoning maps
#
# Cecile Murray
# 2019-01-17
#===============================================================================#

library(here)
source("scripts/setup.R")

# install.packages("magick")
# install.packages("pdftools")
library(magick)
library(pdftools)

# see what formats are supported
magick::magick_config()

# try bringing in the PNG Carlsbad map
carlsbad <- image_read_pdf("raw/CarlsbadZoning11x17.pdf")
simi_valley <- image_read_pdf("raw/Simi_Valley_ZN.pdf")

q = image_quantize(simi_valley, max = 30)
r <- as.raster(q)
rtab <- table(r)
rtab <- data.frame(Color = names(rtab), Count = as.integer(rtab)) 

# compute color shares
tot <- sum(rtab$Count)
tot_no_white <- sum(rtab$Count[rtab$Color != "#ffffffff"])
rtab %<>% mutate(color_share = Count / tot,
                 color_share2 = Count / tot_no_white)

ggplot(rtab, aes(x = reorder(Color, color_share), y = color_share)) +
  geom_col(fill = rtab$Color) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.background = element_rect(fill = "gray80"),
        panel.grid.major = element_line(color = "gray50"),
        panel.grid.minor = element_line(color = "gray50")) +
  theme_dark() +
  labs(title = "Share of pixels of each color in Simi Valley, including white",
       x = "Color", y = "Pixel Share")
ggsave("plots/Simi_Valley_with_white.png")
  
ggplot(filter(rtab, Color != "#ffffffff"),
       aes(x = reorder(Color, color_share2), y = color_share2)) +
  geom_col(fill = rtab$Color[rtab$Color != "#ffffffff"]) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.background = element_rect(fill = "gray80"),
        panel.grid.major = element_line(color = "gray50"),
        panel.grid.minor = element_line(color = "gray50")) +
  labs(title = "Share of pixels of each color in Simi Valley, excluding white",
       x = "Color", y = "Pixel Share")
ggsave("plots/Simi_Valley_without_white.png")

