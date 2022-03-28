library(tidyverse)
library(tidycensus)
library(ggplot2)
library(treemapify)
library(geomtextpath)
library(RColorBrewer)
library(psych)
library(sf)

setwd("/Users/chenjieyi/Documents/GitHub/final-project-jieyi_hanzhe_jaeho")

static_df <- read.csv("data/02.merged_data.csv")

# first ----

plot_fun_forother <- function(df, selectvar){
  df %>%
    filter(year %in% c(2011:2019)) %>%
    group_by(zipcode) %>%
    select(as.name(selectvar), year) %>% 
    rename(n = as.name(selectvar)) %>% 
    ggplot() +
    xlab("year") +
    ylab(selectvar)+
    geom_boxplot(aes(x = as.factor(year), y = n)) +
    ggtitle(paste0("11. Average ", selectvar, " in chicago by year"))
}

plot_fun_forother(static_df, "housing_price")

ggsave("11. Average housing price trend from 2011 to 2019.png")

plot_fun_forother(static_df, "income")

ggsave("11. Average Median income trend from 2011 to 2019.png")

# second ----

readshp <- function(x){
  st_read(file.path(path,x))
}

path <- "/Users/chenjieyi/Documents/GitHub/final-project-jieyi_hanzhe_jaeho"

zipcode <- readshp("data/zipcode_area.shp")
zipcode$zip <- as.numeric(zipcode$zip)

map_plot <- left_join(static_df, zipcode, by = c("zipcode" = "zip"))


map_plot_year <- function(df, y_num){
  avg_price_year <- df %>%
    filter(year == y_num)
  avg_price_year <- st_sf(avg_price_year)
  final_plot <- ggplot(avg_price_year) +
    geom_sf(data = zipcode) +
    geom_sf(data = avg_price_year, aes(fill = housing_price)) +
    scale_fill_gradientn(limits = c(40000, 750000),
                         colours = c("beige", "bisque", "darkred")) +
    ggtitle(paste0("11. Average housing price in ", y_num)) 
}

avg_2011 <- map_plot_year(map_plot, y_num = 2011)

ggsave("11. Average housing price in 2011 by zipcode.png")

avg_2019 <- map_plot_year(map_plot, y_num = 2019)

ggsave("11. Averagee housing price in 2019 by zipcode.png")


# third ----

plot_fun_for_race <- function(df, y_num) {
  plot1_st1 <- df %>%
    filter(year == y_num) %>%
    select(white_rate, black_rate, asian_rate)
  
  plot1_st2 <- plot1_st1 %>%
    pivot_longer(cols = white_rate:asian_rate,
                 names_to = "race",
                 values_to = "prop")
  
  plot1_st3 <- plot1_st2 %>%
    group_by(race) %>%
    mutate(avg_prop = mean(prop))
    
  plot1_st4 <- plot1_st3[1:3,] %>%
    select(-prop)
  
  plot1_st4$label <- paste0(plot1_st4$race, "\n",
                            round(plot1_st4$avg_prop, 3), "%")
  return(plot1_st4)
}

ggplot(plot_fun_for_race(static_df, y_num = 2011), 
       aes(fill = race, 
           area = avg_prop, 
           label = label)) +
  geom_treemap() + 
  geom_treemap_text(colour = "white", 
                    place = "centre") +
  labs(title = "11. Average race distribution in 2011 chicago") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.position = "none")

ggsave("11. Average race distribution in 2011 chicago.png")

ggplot(plot_fun_for_race(static_df, y_num = 2019),
       aes(fill = race, 
           area = avg_prop, 
           label = label)) +
  geom_treemap() + 
  geom_treemap_text(colour = "white", 
                    place = "centre") +
  labs(title = "11. Average race distribution in 2019 chicago") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.position = "none")

ggsave("11. Average race distribution in 2019 chicago.png")


# fourth ----

corr_plot_df <- static_df %>%
  filter(between(year, 2011, 2019)) %>% 
  select(-c(year, zipcode, grocery, bus_stop))

png(height=800, width=1000, file="11. Correlation plot between each variables.png", res = 96)

corPlot(corr_plot_df, main = "11. Correlation plot between each variables.png", 
        stars = TRUE, xlas = 2)


dev.off()






