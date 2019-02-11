#===============================================================================#
# TCRLUS: QUANTIZE IMAGES
#   Use magick package to compute zoning area shares
#
# Cecile Murray
# 2019-02-03
#===============================================================================#

library(here)
source("scripts/setup.R")

library(magick)
library(pdftools)
library(grDevices)

CITY <- "Simi_Valley"
CITY2 <- "Simi Valley"
CONVERT_PDF <- FALSE
NUM_COLORS <- 30
DROP_COLORS <- c("TRANSPARENT", "#FFFFFFFF")

raw_img_path <- paste0("raw/", CITY, "_raw.pdf")
png_out_path <- paste0("raw/", CITY, ".png")
edited_png_path <- paste0("raw/", CITY, "_edited.png")

#===============================================================================#
# IMAGE PRE-PROCESSING: CONVERT FROM PDF, IF NECESSARY
#===============================================================================#

# this will read in a PDF and spit out a png image for cropping, etc
if(CONVERT_PDF){
  pdf_image <- image_read_pdf(raw_img_path)
  image_write(pdf_image, path = png_out_path)
}

# read in the edited image - should have just the zoning area
map_png <- image_read(edited_png_path)

#===============================================================================#
# QUANTIZE AND COMPUTE COLOR SHARES
#===============================================================================#

# quantize the map image into the specified number of colors, return a df w/pixel
# counts for each color
quantize_map <- function(png, max_color){
  
  img_q <- image_quantize(map_png, max = max_color)
  img_r <- as.raster(img_q)
  img_tab <- table(img_r)
  img_df <- data.frame(Color = names(img_tab), Count = as.integer(img_tab)) 
  return(img_df)
}

# compute shares of pixels of each color, with and without specified colors
compute_color_shares <- function(df, excluded_colors = c("TRANSPARENT", "#FFFFFFFF")) {
  tot <- sum(df$Count)
  tot_excluded <- sum(df$Count[!toupper(df$Color) %in% excluded_colors])
  df %<>% mutate(Color = toupper(Color),
                 color_share = Count / tot,
                 color_share2 = Count / tot_excluded,
                 color_hex = str_remove(Color, "FF"))
  return(df)
}

img_df <- quantize_map(map_png, NUM_COLORS)
img_df %<>% compute_color_shares(excluded_colors = DROP_COLORS) 

#===============================================================================#
# MAKE PLOTS
#===============================================================================#

img_df_no_white <- filter(img_df, !Color %in% DROP_COLORS) %>% 
  arrange(color_share2)

color_df <- data.frame(t(col2rgb(img_df_no_white$Color))) %>% 
  mutate(rgb_color = paste0("R", red, "-", green, "-", blue)) %>% 
  bind_cols(select(img_df_no_white, Color))

img_df_no_white %<>% left_join(select(color_df, Color, rgb_color), by = "Color")

ggplot(img_df_no_white) +
  geom_col(aes(x = reorder(rgb_color, color_share2), y = color_share2),
           fill = img_df_no_white$color_hex) +
  scale_y_continuous(labels = scales::percent) + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.background = element_rect(fill = NA),
        panel.grid.major = element_line(color = "gray80", linetype = "dotted"),
        panel.grid.minor = element_line(color = "gray90", linetype = "dotted"),
        legend.position = "none",
        axis.ticks = element_blank()) +
  labs(title = paste0("Share of pixels of each color in ", CITY2, "\nexcluding white"),
       x = "Color", y = "Pixel Share") +
  annotate(geom = "text", x = 24, y = .22, label = "Residential moderate?",
           size = 3) +
  annotate(geom = "text", x = 23.5, y = .16, label = "Residential low?", size = 3) +
  annotate(geom = "text", x = 22.5, y = .07, label = "Residential estates", size = 3)
  
# ggsave(paste0("plots/", CITY, "_without_white_FINAL.png"))

# simi valley
# https://www.arcgis.com/apps/View/index.html?appid=9740fc270c8641f8b23f44b9c0601317

# http://carlsbad.maps.arcgis.com/apps/webappviewer/index.html?id=0de9b47631654fa490dd1abb829dac45
# annotate(geom = "text", x = 25.5, y = .22, label = "Planned community 1?",
#          size = 3) +
#   annotate(geom = "text", x = 27, y = .13, label = "Open space", size = 3) +
#   annotate(geom = "text", x = 24, y = .07, label = "Planned community 2?",
#            size = 3)+
#   annotate(geom = "text", x = 21, y = .06, label = "Single family residential", size = 3) 
