library(tidyverse)
library(dplyr)


# Preparation
path <- "C:/Users/witim/final-project-jieyi_hanzhe_jaeho"

df <- read_csv(file.path(path, "raw_data_crime.csv"))  #[note] use truncated data coming from the original
names(df) <- tolower(names(df))

unique(df$incident_primary)  #[note] we assume that each category of crime has the same level of insecurity regarng people's feeling.
                             # As follows, we will gather all categories into 'crime'.

# Data Wrangling
df_crime <- df %>%
  select(zip_code, date, incident_primary) %>%
  separate(col = date, 
           into = c("date", NA),
           sep =  " ") %>%
  separate(col = date,
           into = c(NA, "year"),
           sep = (-4)) %>%
  group_by(zip_code, year) %>%
  summarize(tot_crime = length(incident_primary), 
            .groups = "drop")



write.csv(df_crime, "02.zip_crime.csv", row.names = FALSE)


# '[note]' is for group members. Remove those notes before submission. 