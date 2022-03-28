# Jieyi: This file is to build shiny app
# link here: https://jieyi-chen-98.shinyapps.io/final-project-jieyi_hanzhe_jaeho/

library(shiny) # app
library(rsconnect) # upload app
library(sf) # map
library(scales) # map color
library(tidyverse)
library(ggplot2)
library(plotly)
library(shinydashboard)

rm(list = ls())
# setwd("/Users/chenjieyi/Documents/GitHub/final-project-jieyi_hanzhe_jaeho")
options(scipen = 999) # disable scientific notation

df_all <- read.csv("data/02.merged_data.csv")
zipcode_area <- st_read("data/zipcode_area.shp")
zipcode_area$zip <- as.integer(zipcode_area$zip)
zipcode_area <- rename(zipcode_area, zipcode = zip)

ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Housing dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Distribution", tabName = "distribution", icon = icon("dashboard")),
      menuItem("Time Trend", tabName = "trend", icon = icon("dashboard"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "distribution",
        h2("Chicago Housing Data Distribution"),
        fluidRow(
          box(
            width = 6,
            selectInput(
              "year",
              "Select one year to check distribution :)",
              unique(df_all$year)
            )
          ),
          box(
            width = 6,
            selectInput(
              "variable",
              "Select one variable to compare with :p",
              colnames(df_all)[4:12]
            )
          )
        ),
        fluidRow(
          box(
            width = 6,
            plotlyOutput("map1")
          ),
          box(
            width = 6,
            plotlyOutput("map2")
          )
        ),
      fluidRow(
      box(
        title = "Note", width = 12,
        "Age, income, white rate, black rate, asian rate, bachelor or higher 
        rate data is only available from 2011-2019."
      )
      )
      )
      ,
      tabItem(
        tabName = "trend",
        h2("Chicago Housing Data Time Trend"),
        fluidRow(
          box(
            width = 6,
            height = "100px",
            sliderInput("range",
              "Select range of year to check the time trend :)",
              min = 2000, max = 2021,
              value = c(2011, 2019),
              sep = "",
              step = 1
            )
          ),
          box(
            width = 6,
            height = "100px",
            selectInput(
              "zipcode",
              "Select one zipcode :p",
              unique(df_all$zipcode)
            )
          )
        ),
        fluidRow(
          box(
            width = 6,
            plotOutput("plot1",
              width = "500px",
              height = "300px"
            )
          ),
          box(
            width = 6,
            plotOutput("plot2",
              width = "500px",
              height = "300px"
            )
          )
        ),
        fluidRow(
          box(
            width = 6,
            plotOutput("plot3",
              width = "500px",
              height = "300px"
            )
          ),
          box(
            width = 6,
            plotOutput("plot4",
              width = "500px",
              height = "300px"
            )
          )
        ),
        fluidRow(
          box(
            width = 6,
            plotOutput("plot5",
              width = "500px",
              height = "300px"
            )
          ),
          box(
            width = 6,
            plotOutput("plot6",
              width = "500px",
              height = "300px"
            )
          )
        ),
        fluidRow(
          box(
            width = 6,
            plotOutput("plot7",
              width = "500px",
              height = "300px"
            )
          ),
          box(
            width = 6,
            plotOutput("plot8",
              width = "500px",
              height = "300px"
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # draw maps ----
  # create reactive data for each map
  df_map1 <- reactive({
    df_all %>% 
      rename(n = housing_pice) %>% 
      filter(year == input$year) %>%
      left_join(zipcode_area, by = "zipcode")
  })
  
  df_map2 <- reactive({
    df_all %>% 
      rename(n = as.name(input$variable)) %>% 
      filter(year == input$year) %>% 
      left_join(zipcode_area, by = "zipcode")
  })
  
  # create draw_map function
  draw_map <- function(df, t, header = "Housing Price"){
    ggplot() +
      geom_sf(data = st_sf(df), aes(fill = n, text = zipcode), lwd = 0.2) +
      scale_fill_continuous(low = "thistle2", high = "darkred",
                            guide = "colorbar", na.value = "white") +
      labs(title = paste0("Distribution of ", 
                          header, 
                          " in Chicago ",
                          t),
           fill = element_blank()) +
      theme_void()
  }
  
  output$map1 <- renderPlotly({
    map1 <- draw_map(df = df_map1(), t = input$year)
    ggplotly(map1)
  })   
  
  output$map2 <- renderPlotly({
    map2 <- draw_map(df = df_map2(), t = input$year, header = input$variable)
    ggplotly(map2)
  })
  
  
  # draw plots ----
  # get reactive data
  df_plot <- reactive({
    df_all %>%
      filter(between(year, input$range[1], input$range[2])) %>%
      filter(zipcode == input$zipcode)
  })
  
  # get data source for time trend
  data_source <- c(
    rep(NA, 2),
    "Zillow",
    rep("Chicago Data Portal", 3),
    rep("American Community Survey", 6)
  )
  
  # create draw plot function
  draw_plot <- function(df, t) {
    ggplot(data = df, aes(x = year, y = df[, t])) +
      geom_point() + 
      geom_line(color = "midnightblue") +
      xlim(2000, 2021) +
      labs(x = "Year", y = colnames(df_all)[t],
           title = paste0("Time Trend of ", colnames(df_all)[t]),
           caption = paste0("Source: ", data_source[t])) +
      theme_classic()
  }
  
  output$plot1 <- renderPlot({draw_plot(df = df_plot(), t = 3)},
                             res = 96)
  output$plot2 <- renderPlot({draw_plot(df = df_plot(), t = 4)},
                             res = 96)
  output$plot3 <- renderPlot({draw_plot(df = df_plot(), t = 7)},
                             res = 96)
  output$plot4 <- renderPlot({draw_plot(df = df_plot(), t = 8)},
                             res = 96)
  output$plot5 <- renderPlot({draw_plot(df = df_plot(), t = 9)},
                             res = 96)
  output$plot6 <- renderPlot({draw_plot(df = df_plot(), t = 10)},
                             res = 96)
  output$plot7 <- renderPlot({draw_plot(df = df_plot(), t = 11)},
                             res = 96)
  output$plot8 <- renderPlot({draw_plot(df = df_plot(), t = 12)},
                             res = 96)
}

shinyApp(ui = ui, server = server)

# reference for deleting thousandth:
# https://stackoverflow.com/questions/26636335/formatting-number-output-of-sliderinput-in-shiny


