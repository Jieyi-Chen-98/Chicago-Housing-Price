# Jieyi: this R script is for getting demographics data ACS (American Community Survey)
rm(list = ls())
# basic setting ----
setwd("/Users/chenjieyi/Documents/GitHub/final-project-jieyi_hanzhe_jaeho")
library(tidyverse)
library(tidycensus) # acs data
library(rlist) # rbind list
zipcode <- read_csv("data/02.zip.csv")
CENSUS_KEY <-Sys.getenv("census_api_key")

# get ACS  variables ----
acs_vars_18 <- load_variables(2018, "acs5", cache = TRUE)
acs_vars_11 <- load_variables(2011, "acs5", cache = TRUE)
acs_vars_15 <- load_variables(2015, "acs5", cache = TRUE)

# get ASC demographics data we need from 2011 to 2019 ----
vt <- list()
for (i in 2011:2019) {
  vt[[i-2010]] <- get_acs(geography = "zcta",
                          year = i,
                          variables =  c(population = "B01003_001",
                                         med_age = "B01002_001",
                                         med_income = "B06011_001",
                                         bachelor_higher = "B23006_023",
                                         total_race = "B02001_001",
                                         white = "B02001_002", 
                                         black = "B02001_003",
                                         asian = "B02001_005"),
                          survey = "acs5")
}

# data manipulation ----
perc_twodigit <- function(c) {
  c <- round(c * 100, 2)
}

demo_list <- list()
for (i in 2011:2019) {
  demo_list[[i-2010]] <- vt[[i-2010]] %>% 
    select(-GEOID, -moe) %>% 
    mutate(zipcode = as.double(substr(NAME, 7, 12))) %>% 
    mutate(year = i) %>% 
    pivot_wider(names_from = variable,
                values_from = estimate) %>% 
    mutate(bachelor_hrate = perc_twodigit(bachelor_higher / population),
           white_rate = perc_twodigit(white / total_race),
           black_rate = perc_twodigit(black / total_race),
           asian_rate = perc_twodigit(asian / total_race)) %>% 
    select(-NAME, -population, -bachelor_higher, 
           -total_race, -white, -black, -asian) %>% 
    inner_join(zipcode, by = c("zipcode" = "zipcode"))
}

# rbind list to get 9 year panel data by zipcode----
demo_df <- list.rbind(demo_list) %>% 
  tibble()

# Fix NA function ----
## The logic is to substitute NA values using the average value of the year before and after
fixna <- function(df) {
  na_position <- apply(is.na(df[]), 2, which)
  for (i in 1:length(na_position)) {
    if (length(na_position[[i]]) == 0){
      next
    }
    na_position_column <- na_position[[i]]
    for (j in na_position_column) {
      zip <- as.double(df[j, 1])
      year_a <- as.double(df[j, 2]) + 1
      year_b <- as.double(df[j, 2]) - 1
      df[j, i] <- mean(as.double(df[df$zipcode == zip & df$year == year_a, i]),
                       as.double(df[df$zipcode == zip & df$year == year_b, i]))  
    }
  }
  return(df)
}

demo_complete <- fixna(demo_df)
any(sapply(demo_complete, function(x) sum(is.na(x))) > 0)
write.csv(demo_complete, "02.zip_demo.csv", row.names = FALSE)

