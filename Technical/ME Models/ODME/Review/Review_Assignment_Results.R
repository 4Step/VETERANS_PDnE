# Script to extract assignment volumes and plot the differences
# EPSG:2236 for State plane Florida East (feet)

path <- "C:\\projects\\Veterans_ExpressWay\\ODME\\Review"
netShape <- "shapeFiles\\Subarea_Hwy.shp"
loaded_network_2020 <- "odme_loaded\\2020_ODME_loaded.dbf"
loaded_network_2040 <- "odme_loaded\\2040_ODME_loaded.dbf"

#========================================================================
#========================================================================

# load libraries
library(foreign)
library(dplyr)
library(tidyr)
library(leaflet)
library(rgdal)
library(maptools)
library(ggplot2)
library(plotly)

setwd(path)

# TODO: Fix the shape file with Lat/Lons to plot
# function to get filename without extension
# getLayerName <- function(filename_with_ext){
#   parts = strsplit(filename_with_ext, "\\\\")
#   filename = parts[[1]][length(parts[[1]])]
#   return (unlist(strsplit(filename, "\\."))[1])
# }
#
# Read shape file
# layerName <- getLayerName(netShape)
# network <- readOGR(netShape,layerName)
# only selected fields
# network@data <- network@data %>%
#                  select(A, B, NUM_LANES, SPEED, CAPACITY, 
#                 FTYPE, LOC, CNT_2020, CNT_2040, V_1) 
#
#
# Set projection (if exist overwrite it)
# proj4string(network) <- CRS("+init=epsg:2236") 
# network <- spTransform(network, CRS("+proj=longlat +datum=WGS84 +no_defs"))
#
# map <- leaflet() %>% 
#        addTiles() %>% 
#        setView(lng = -82.5381, lat = 28.0679, zoom = 11) %>%
#        addPolylines(data = network, color = "black", weight = 2)
# 
# writeOGR(obj=count_links, dsn = "count_links.shp", layer="count_links", driver="ESRI Shapefile")

loaded_2020 <- read.dbf(loaded_network_2020)
loaded_2040 <- read.dbf(loaded_network_2040)


# ToDO rename V_1 as estimated volume for corresponding year
count_links_2020 <- loaded_2020 %>% filter(CNT_2020 > 0 ) %>% 
               select(A, B, NUM_LANES, SPEED, CAPACITY, 
                       FTYPE, LOC, CNT_2020,  V_1) 

count_links_2040 <- loaded_2040 %>% filter(CNT_2040 > 0 ) %>% 
  select(A, B, NUM_LANES, SPEED, CAPACITY, 
         FTYPE, LOC, CNT_2040,  V_1) 

#========================================================================
#========================================================================
# Plot ODME Stats
for(f in 1:2){
  
  ifelse(f==1, count_links <- count_links_2020, count_links <- count_links_2040)
  
  # fix FTYPE code on one of the main line
  count_links$FTYPE[count_links$FTYPE == 0] <- 71
  count_links$FTYPE <- as.factor(count_links$FTYPE)
  
  
  # Function to plot
  p <- qplot(CNT_2020, V_1, data = count_links, colour = FTYPE)
  p <- ggplotly(p)
  
  q <- ggplot(data = count_links, aes(x = CNT_2020, y = V_1)) +
    geom_point(aes(text = paste("Location:", LOC)), size = .5) +
    geom_smooth(aes(colour = FTYPE, fill = FTYPE)) + facet_wrap(~ FTYPE)
  q <- ggplotly(q)
  
  # Compute R-Squared and %RMSE
  Compute_PRMSE_RSq <- function(x,y){
    reg = lm(y ~ x)
    R2 = summary(reg)$r.squared
    rmse = sqrt(mean(reg$residuals^2))
    prmse = rmse * (100 * length(x) / sum(x))
    return(list("R2" = R2, fitted = reg$fitted.values, "prmse" = prmse))  
  }
  
  # Add R-Squared
  x = count_links$CNT_2020
  y = count_links$V_1
  stats <- Compute_PRMSE_RSq(x,y)
  y2 = stats$fitted
  
  r <- p %>%
    add_trace(x = x , y = stats$fitted, 
              type = "scatter", mode = "lines", 
              line = list(dash = "dashed")) %>%
    layout (title = "Counts to Volume", 
            xaxis = list(title = "Counts - 2020"), 
            yaxis = list(title = "Est. Volume"),
            annotations = list(x = max(x), y = max(y), showarrow = F,
                               text = paste0("R-Squared = ",round(stats$R2,4), "\n",
                                             "%RMSE = ", round(stats$prmse,2))))
  r
  
  
}

#========================================================================
#========================================================================
# write count links
count_links_2040 <- count_links_2040 %>%
                    select(LOC, CNT_2040, ODME_2040 = V_1)
count_links_2020 <- count_links_2020 %>% 
                    select(LOC, CNT_2020, ODME_2020 = V_1)

ODME_links <- count_links_2020 %>% 
              left_join(count_links_2040, by = "LOC") 
              
write.csv(ODME_links, "ODME_Link_Vols.csv")




     