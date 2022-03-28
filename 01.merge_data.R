library(tidyverse)
library(tidycensus)
library(sf)
library(rnaturalearth)
library(sp)
library(data.table)

rm(list = ls())
readshp <- function(x){
  st_read(file.path(path,x))
}
r_csv <- function(x){
  read_csv(file.path(path,x))
}

path <- "C:/Users/witim/final-project-jieyi_hanzhe_jaeho/data"

demo <- r_csv("02.zip_demo.csv")
housing_price <- r_csv("02.zip_house_price.csv")
crime <- r_csv("02.zip_crime.csv")
grocery <- r_csv("02.zip_grocery.csv")

colnames(housing_price)[1] <- "zipcode"
colnames(crime)[1] <- "zipcode"
colnames(grocery)[1] <- "zipcode"

# deal with crime missing value
zipcode <- unique(housing_price$zipcode)
year <- seq(2000, 2021)
combination_1 <- CJ(zipcode, year)
crime <- left_join(combination_1, crime, by = c("zipcode", "year")) %>% 
  as.data.frame()
crime[is.na(crime[, 3]), 3] <- 0

# deal with grocery missing value
year <- c(2011, 2013, 2020)
combination_2 <- CJ(zipcode, year)
grocery <- left_join(combination_2, grocery, by = c("zipcode", "year")) %>% 
  as.data.frame()
grocery[is.na(grocery[, 3]), 3] <- 0

merged2 <- housing_price %>%
  left_join(crime, by = c("year", "zipcode")) %>% 
  left_join(grocery, by = c("year", "zipcode")) %>% 
  left_join(demo, by = c("year", "zipcode"))


# spatial merge ----
busstop <- readshp("geo_export_99ecc1b5-aeac-4e03-88df-09249f9bb2eb.shp")
zipcode <- readshp("zipcode_area.shp")

sp_df <- st_join(zipcode, busstop)
colnames(sp_df)[4] <- "zipcode"

sp_df <- sp_df %>%
  group_by(zipcode) %>%
  mutate(busstop = n())

sp_list <- sp_df %>%
  as.data.frame() %>%
  select(zipcode, busstop)

sp_list$zipcode <- as.numeric(sp_list$zipcode)
sp_list2 <- unique(sp_list)
merged3 <- left_join(merged2, sp_list2, by = "zipcode")

merged3 <- rename(merged3,
                  age = med_age,
                  income = med_income,
                  bachelor_rate = bachelor_hrate,
                  housing_price = avg.house_price,
                  crime = tot_crime,
                  grocery = tot_grocery,
                  bus_stop = busstop)

# permutate for missing years in grocery number
zipcode <- unique(merged3$zipcode)

for (z in zipcode) {
  
  grocery_2011 <- merged3$grocery[(merged3$year == 2011)&(merged3$zipcode == z)]
  grocery_2013 <- merged3$grocery[(merged3$year == 2013)&(merged3$zipcode == z)]
  grocery_2020 <- merged3$grocery[(merged3$year == 2020)&(merged3$zipcode == z)]
  
  for (i in 2000:2010) {
    merged3$grocery[(merged3$year == i)&(merged3$zipcode == z)] <- grocery_2011
  }
  
  merged3$grocery[(merged3$year == 2012)&(merged3$zipcode == z)] <- grocery_2013
  
  for (i in 2014:2021) {
    merged3$grocery[(merged3$year == i)&(merged3$zipcode == z)] <- grocery_2020
  }
  
}

merged3 <- merged3 %>% 
  select(zipcode, year, housing_price, crime, grocery, bus_stop, everything())

# this merged3 dataframe is the data from 2011 to 2019 which we have the most common year between all independent variable

write.csv(merged3, row.names = FALSE, "02.merged_data.csv") 


# reference for panel creation
# https://stackoverflow.com/questions/21007913/create-a-panel-data-frame

