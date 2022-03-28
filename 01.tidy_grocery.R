library(tidyverse)
library(dplyr)


# Preparation
path <- "C:/Users/witim/final-project-jieyi_hanzhe_jaeho"

df_2020 <- read_csv(file.path(path, "0.raw_data_grocery_store_2020.csv"))
df_2013 <- read_csv(file.path(path, "0.raw_data_grocery_store_2013.csv"))
df_2011 <- read_csv(file.path(path, "0.raw_data_grocery_store_2011.csv"))

names(df_2020) <- tolower(names(df_2020))
names(df_2013) <- tolower(names(df_2013))
names(df_2011) <- tolower(names(df_2011))



# Data Wrangling
fn.zip_store <- function (df) {
  names(df) <- tolower(names(df))
  
  df %>%
    rename("zip_code" = contains("zip")) %>%
    select(zip_code) %>%
    separate(col = zip_code,
             into = c("zip_code", NA),
             sep = (5)) %>%
    count(zip_code)
}


df_grocery_2020 <- fn.zip_store(df_2020) 
df_grocery_2013 <- fn.zip_store(df_2013)
df_grocery_2011 <- fn.zip_store(df_2011)


df_grocery_list <- list(df_grocery_2020, df_grocery_2013, df_grocery_2011)
df_grocery <- df_grocery_list %>% 
  reduce(full_join, by = "zip_code")

colnames(df_grocery)[2:4] <- c("2020", "2013", "2011")


df_grocery <- df_grocery %>%
  pivot_longer(cols = 2:4,
               names_to = "year",
               values_to = "tot_grocery") %>%
  mutate(tot_grocery = coalesce(tot_grocery, 0))
  


write.csv(df_grocery, "02.zip_grocery.csv", row.names = FALSE)

# '[note]' is for group members. Remove those notes before submission. 

# [reference]: https://www.statology.org/merge-multiple-data-frames-in-r/