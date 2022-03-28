# Jieyi: this R script is for getting all the zipcodes in Chicago 

# basic setting ----
setwd("/Users/chenjieyi/Documents/GitHub/final-project-jieyi_hanzhe_jaeho")
library(sf)
library(tidyverse)
library(scales)
# datasource: https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Chicago-Zip-Code-and-Neighborhood-Map/mapn-ahfc
# read shapefile ----
zipcode_shp <- st_read("zipcode_area.shp")

# get unique zipcodes in Chicago ----
zipcode_chicago <- zipcode_shp$zip %>% 
  unique() %>% 
  as.tibble() %>% 
  rename(zipcode = value)

write.csv(zipcode_chicago, "02.zip.csv", row.names = FALSE)
