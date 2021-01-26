library(dash)
library(dashCoreComponents)
library(dashHtmlComponents)
library(dashBootstrapComponents)
library(plotly)
library(tidyverse)
library(purrr)

# Import data
clean_data <- read_csv("data/clean_data.csv")
clean_data <- clean_data %>% select(-X1)
country_list <- clean_data$country %>% unique()
disease_list = c("HIV",
                 "Malaria",
                 "Measles",
                 "Meningitis",
                 "NCD")

## Define new dataset to present disease
disease_count_data <- clean_data %>% select(
  country,
  year,
  sub_region,
  hiv_deaths_in_children_1_59_months_total_deaths,
  malaria_deaths_in_children_1_59_months_total_deaths,
  measles_deaths_in_children_1_59_months_total_deaths,
  meningitis_deaths_in_children_1_59_months_total_deaths,
  ncd_deaths_in_children_1_59_months_total_deaths
)
colnames(disease_count_data) <- c("country",
                                  "year",
                                  "sub_region",
                                  "HIV",
                                  "Malaria",
                                  "Measles",
                                  "Meningitis",
                                  "NCD")
disease_count_data <- disease_count_data %>%
  pivot_longer(cols = disease_list, names_to = "disease", values_to = "count")

## Define map data
country_iso <- read_csv("https://raw.githubusercontent.com/plotly/datasets/master/2014_world_gdp_with_codes.csv")
country_iso <- country_iso %>% select(COUNTRY, CODE)
colnames(country_iso) <- c("country", "iso_alpha")

## Add South Sudan and Seychelles
country_iso <- country_iso %>% add_row(country = "South Sudan", iso_alpha = "SSD") %>% add_row(country = "Seychelles", iso_alpha = "SYC") 

## Rename the two Congos and Gambia
country_iso[country_iso$country == "Congo, Democratic Republic of the", "country"] <- "Congo, Dem. Rep."
country_iso[country_iso$country == "Congo, Republic of the", "country"] <- "Congo, Rep."
country_iso[country_iso$country == "Gambia, The", "country"] <- "Gambia"


disease_count_map_data <- disease_count_data %>% left_join(country_iso, by = "country")
  
app <- Dash$new(external_stylesheets = dbcThemes$BOOTSTRAP)

year_controller = htmlDiv(
  list(
    "Year",
    dccSlider(
      id="year_widget",
      min = 1990,
      max = 2015,
      marks= list(
        "1990" = "1990",
        "1995" = "1995",
        "2000" = "2000",
        "2005" = "2005",
        "2010" = "2010",
        "2015" = "2015"
      ),
      value = 2005,
      included=FALSE,
    )
  )
)

country_controller = htmlDiv(
  list(
    "Country",
    dccDropdown(
      id="country_widget",
      value=country_list,
      placeholder="Select a country...",
      options = country_list %>%  purrr::map(function(country) list(label = country, value = country)),
      multi=TRUE,
      style=list("overflowY"="scroll", "height"="100px")
    )
  )
)

disease_controller = htmlDiv(
  list(
    "Disease",
    dccDropdown(
      id="disease_widget",
      value=disease_list,
      placeholder="Select a disease...",
      options= disease_list %>% purrr::map(function(disease) list(label = disease, value = disease)),
      multi=TRUE,
      style=list("overflowY"="scroll", "height"="100px")
    )
  )
)

app$layout(
  dbcContainer(
    list(
      dbcRow(
        list(
          dbcCol(country_controller),
          dbcCol(year_controller),
          dbcCol(disease_controller)
        )
      )
    ), style = list('max-width' = '100%')
  )
)  

app$run_server(debug = T)

# 
# fig <- plot_ly(clean_data, type='choropleth', locations=df$CODE, z=df$GDP..BILLIONS., text=df$COUNTRY, colorscale="Blues")
# 
# #fig
