library(tidyverse)
library(dplyr)


# Preparation
path <- "C:/Users/witim/final-project-jieyi_hanzhe_jaeho"

df <- read_csv(file.path(path, "0.raw_data_zillow_zipcode.csv"))
names(df) <- tolower(names(df))



# Data Wrangling
df_house <- df %>% 
  filter(city == "Chicago") %>%    #[note] 56 observations (Chicago has more than 56 zip codes. Need to check!!!!)
  rename("zip_code" = regionname) %>%
  select(zip_code, "2000-01-31":"2021-12-31") %>%   #[note] 'zip' column is character
  pivot_longer(cols = "2000-01-31":"2021-12-31",
               names_to = "year",
               values_to = "house_price") %>%
  separate(year, 
           into = c("year", NA), 
           sep = (-6))   #[note] 



# Draw average prices for each year
df_house_avg <- df_house %>% 
  group_by(zip_code, year) %>%
  summarise(avg.house_price = mean(house_price, na.rm = TRUE), 
            .groups = "drop")

  

write.csv(df_house_avg, "02.zip_house_price.csv", row.names = FALSE)

# '[note]' is for group members. Remove those notes before submission. 