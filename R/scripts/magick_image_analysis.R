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

raw_img_path <- "raw/Simi_Valley_online.pdf"
CONVERT_PDF <- FALSE
png_out_path <- "raw/Simi_Valley_online.png"
edited_png_path <- "raw/Simi_Valley_edited.png"

NUM_COLORS <- 30
DROP_COLORS <- c("transparent", "#FFFFFF")

#===============================================================================#
# IMAGE PRE-PROCESSING: CONVERT FROM PDF, IF NECESSARY
#===============================================================================#

# this will read in a PDF and spit out a png image for cropping, etc
if(CONVERT_PDF){
  pdf_image <- image_read_pdf(raw_img_path)
  image_write(simi_valley, path = png_out_path)
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
compute_color_shares <- function(df, excluded_colors = c("transparent", "#FFFFFF")) {
  tot <- sum(df$Count)
  tot_excluded <- sum(df$Count[!df$Color %in% excluded_colors])
  df %<>% mutate(color_share = Count / tot,
                   color_share2 = Count / tot_excluded,
                   color_hex = str_remove(Color, "ff"))
  return(df)
}

img_df <- quantize_map(map_png, NUM_COLORS)
img_df %<>% compute_color_shares(excluded_colors = DROP_COLORS)

#===============================================================================#
# MAKE PLOTS
#===============================================================================#

img_df_no_white <- filter(img_df, !Color %in% c("transparent", "#FFFFFF")) %>% 
  arrange(color_share2)

ggplot(img_df_no_white) +
  geom_col(aes(x = reorder(Color, color_share2), y = color_share2),
           fill = img_df_no_white$color_hex) +
  scale_y_continuous(labels = scales::percent) + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        panel.background = element_rect(fill = NA),
        panel.grid.major = element_line(color = "gray80", linetype = "dotted"),
        panel.grid.minor = element_line(color = "gray90", linetype = "dotted"),
        legend.position = "none",
        axis.ticks.x = element_blank()) +
  labs(title = "Share of pixels of each color in Simi Valley, excluding white",
       x = "Color", y = "Pixel Share") 

ggsave("plots/Simi_Valley_without_white_REVISED.png")


