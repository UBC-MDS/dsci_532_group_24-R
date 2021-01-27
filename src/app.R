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
disease_list <- c("HIV",
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
  pivot_longer(cols = disease_list,
               names_to = "disease",
               values_to = "count")

## Define map data
country_iso <-
  read_csv(
    "https://raw.githubusercontent.com/plotly/datasets/master/2014_world_gdp_with_codes.csv"
  )
country_iso <- country_iso %>% select(COUNTRY, CODE)
colnames(country_iso) <- c("country", "iso_alpha")

## Add South Sudan and Seychelles
country_iso <-
  country_iso %>% add_row(country = "South Sudan", iso_alpha = "SSD") %>% add_row(country = "Seychelles", iso_alpha = "SYC")

## Rename the two Congos and Gambia
country_iso[country_iso$country == "Congo, Democratic Republic of the", "country"] <-
  "Congo, Dem. Rep."
country_iso[country_iso$country == "Congo, Republic of the", "country"] <-
  "Congo, Rep."
country_iso[country_iso$country == "Gambia, The", "country"] <-
  "Gambia"

disease_count_map_data <-
  disease_count_data %>% left_join(country_iso, by = "country")

# Define three controllers
year_controller = htmlDiv(list(
  "Year",
  dccSlider(
    id = "year_widget",
    min = 1990,
    max = 2015,
    marks = list(
      "1990" = "1990",
      "1995" = "1995",
      "2000" = "2000",
      "2005" = "2005",
      "2010" = "2010",
      "2015" = "2015"
    ),
    value = 2005,
    included = FALSE,
  )
))

country_controller = htmlDiv(list(
  "Country",
  dccDropdown(
    id = "country_widget",
    value = country_list,
    placeholder = "Select a country...",
    options = country_list %>%  purrr::map(function(country)
      list(label = country, value = country)),
    multi = TRUE,
    style = list("overflowY" = "scroll", "height" = "100px")
  )
))

disease_controller = htmlDiv(list(
  "Disease",
  dccDropdown(
    id = "disease_widget",
    value = disease_list,
    placeholder = "Select a disease...",
    options = disease_list %>% purrr::map(function(disease)
      list(label = disease, value = disease)),
    multi = TRUE,
    style = list("overflowY" = "scroll", "height" = "100px")
  )
))

# Define information tab
row1 <-
  htmlTr(list(
    htmlTd("The total number of children dying before age 5"),
    htmlTd(
      htmlA("World Health Organization", href = "https://www.who.int/data/maternal-newborn-child-adolescent-ageing/child-data")
    )
  ))
row2 <-
  htmlTr(list(
    htmlTd(
      "HIV, malaria, measles, meningitis and NCD (non-communicable disease) deaths in children 1-59 months"
    ),
    htmlTd(
      htmlA("World Health Organization", href = "https://www.who.int/data/maternal-newborn-child-adolescent-ageing/child-data")
    )
  ))
row3 <-
  htmlTr(list(htmlTd("Total Population by country"), htmlTd(
    htmlA(
      "The United Nations, 2019 Revision of World Population Prospects",
      href = "https://population.un.org/wpp/"
    )
  )))
table_body <- list(htmlTbody(list(row1, row2, row3)))

information_tab <- list(
  htmlP(
    "
    This app is developed as part of DSCI 532's coursework. We intend to provide information to staff and volunteers at an international charity whose work focuses on healthcare and medication to children in Africa.
    The underlying dataset of this app is obtained from Gapminder, an independent Swedish foundation, with a mission to fight misconceptions and promotes a fact-based worldview.
    The table below summarizes the key data sources used in the app.
    "
  ),
  dbcTable(
    children = list(htmlThead(htmlTr(
      list(htmlTh("Variable"), htmlTh("Source"))
    )), htmlTbody(list(row1, row2, row3))),
    bordered = TRUE
  )
)

# Define app
app <- Dash$new(external_stylesheets = dbcThemes$BOOTSTRAP)

app$layout(dbcContainer(list(dbcTabs(list(
  dbcTab(list(
    htmlH1("Causes of Child Mortality in Africa, 1990 - 2015"),
    htmlP("App Developed by Junghoo Kim, Mark Wang and Zhenrui (Eric) Yu"),
    dbcCol(list(dbcRow(
      list(
        dbcCol(country_controller),
        dbcCol(year_controller),
        dbcCol(disease_controller)
      )
    ),
    dbcRow(
      list(dbcCol(
        list("Top Countries (Default Five) by Number of Deaths",
            dccGraph(
               id = "country_chart",
               style = list(
                 "border-width" = "0",
                 "width" = "100%",
                 "height" = "50vh"
                 )
               )
            )
      ),
      dbcCol(list(
        dccGraph(
          id = "map",
          style = list(
            "border-width" = "0",
            "width" = "100%",
            "height" = "50vh"
          )
        )
      )),
      dbcCol(list(
        "Diseases by Number of Deaths",
        dccGraph(
          id = "disease_chart",
          style = list(
            "border-width" = "0",
            "width" = "100%",
            "height" = "50vh"
        )
      )
      )))
    )))
  ), label = "Visualization"),
  dbcTab(information_tab, label="Data Source and Explanation")
))), style = list('max-width' = '100%')))

app$callback(list(output("country_chart", "figure")),
             list(
               input("year_widget", "value"),
               input("country_widget", "value"),
               input("disease_widget", "value")
             ),
             function(year_selected, countries, diseases) {
               data_transformed <- disease_count_data %>%
                 filter((year == year_selected) &
                          (country %in% countries) &
                          (disease %in% diseases)) %>%
                 drop_na(count) %>%
                 group_by(country) %>%
                 summarise(total_deaths = sum(count)) %>%
                 top_n(5, total_deaths)
               
               fig <- ggplot(data_transformed) + 
                 aes(x = total_deaths, 
                     y = reorder(country, total_deaths), 
                     fill = country) +
                 geom_bar(stat='identity', show.legend=FALSE) +
                 labs(x = "Number of Deaths",
                      y = "Country")
               
               return(list(ggplotly(fig)))
             })

app$callback(list(output("disease_chart", "figure")),
             list(
               input("year_widget", "value"),
               input("country_widget", "value"),
               input("disease_widget", "value")
             ),
             function(year_selected, countries, diseases) {
               data_transformed <- disease_count_data %>%
                 filter((year == year_selected) &
                          (country %in% countries) &
                          (disease %in% diseases)) %>%
                 drop_na(count) %>%
                 group_by(disease) %>%
                 summarise(total_deaths = sum(count)) %>%
                 top_n(5, total_deaths)
               
               fig <- ggplot(data_transformed) + 
                 aes(x = total_deaths, 
                     y = reorder(disease, total_deaths), 
                     fill = disease) +
                 geom_bar(stat='identity', show.legend=FALSE) +
                 labs(x = "Number of Deaths",
                      y = "Disease")

               return(list(ggplotly(fig)))
             })


app$callback(list(output("map", "figure")),
             list(
               input("year_widget", "value"),
               input("country_widget", "value"),
               input("disease_widget", "value")
             ),
             function(year_selected, countries, diseases) {
               data_transformed <-
                 disease_count_map_data %>% filter((year == year_selected) &
                                                     (country %in% countries) &
                                                     (disease %in% diseases)) %>% group_by(country, iso_alpha) %>% summarise(total_deaths = sum(count))
               fig <- plot_ly(data_transformed)
               fig <- fig %>% add_trace(
                 type = 'choropleth',
                 z = data_transformed$total_deaths,
                 locations = data_transformed$iso_alpha,
                 color = data_transformed$total_deaths,
                 text = data_transformed$country,
                 colorscale = "RdBu"
               )
               fig <- fig %>% colorbar(title = "Total deaths",
                                       thickness=20,
                                       lenmode="pixels",
                                       len=300)
               fig <- fig %>% layout(geo = list(scope = 'africa'))
               return(list(fig))
             })

app$run_server(debug = T)