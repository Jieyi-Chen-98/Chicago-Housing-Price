library(tidyverse)
library(dplyr)
library(stargazer)
library(estimatr)

rm(list = ls())

# Preparation
path <- "C:/Users/witim/final-project-jieyi_hanzhe_jaeho/data"

df <- read_csv(file.path(path, "02.merged_data.csv")) %>%
  filter(year >= 2011 & year <= 2019)


# Running the Regression


predictors <- c("age", "income", "bachelor_rate", "white_rate", "black_rate", "asian_rate")
predictors_x <- paste(predictors, collapse= "+")


# The Pooled Model
reg_pooled <- lm(paste("housing_price ~", predictors_x), 
             data = df)

# The Time (Year) Fixed Model
reg_fx <- lm(paste("housing_price ~", predictors_x, "+ as.factor(year)"),
             data = df)


summary_pooled <- summary(reg_pooled)
summary_fx <- summary(reg_fx)


stargazer(reg_pooled, reg_fx,  
          se = starprep(reg_pooled, reg_fx),
          column.labels = c("Pooled", "Fixed (Time) Effects"),
          dep.var.labels.include = FALSE,
          dep.var.caption = "",
          model.names= FALSE,
          omit = c("year", "zipcode"),
          type="html", out = "31.regression.html")


