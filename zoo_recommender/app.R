#
# This is a Shiny web application. BUILD APP
# 4.	Predict
#   a.	How to input data?
#   b.	Transform inputted data to binary rating matrix
#   c.	Filter for only currently ACTIVE projects
#   d.	Add a random novel/new project
# 5.	Present predictions
#   a.	Names, URL
#       i.	Slug prefix: https://www.zooniverse.org/projects/
#   b.	Image from homepage thumbnail?
#

library(shiny)
#library(here)
library(tidyverse)
library(recommenderlab)

#***********************************************
# Load Data, filter data, build IBCF model

# binary preference matrix
preference_matrix <- readRDS("binary_preference_matrix.rds")
#preference_matrix <- readRDS("zoo_recommender/binary_preference_matrix.rds")

# project details dataset
project_details <- readRDS("project_details.rds")
#project_details <- readRDS("zoo_recommender/project_details.rds")
project_list <- project_details$name

# Build the IBCF model
scheme <- preference_matrix_filtered %>%
    evaluationScheme(method = "cross", k = 4, train  = 0.8, given  = -1)

recomm <- Recommender(getData(scheme, 'train'), method = "IBCF",
                      param = list(k = 5))


#***********************************************
# Define UI for application
ui <- fluidPage(

    # App title ----
    headerPanel("Zooniverse Project Recommender"),

    fluidRow(

        # Input selection
        column(4,
               # INPUT
               h3("Which projects have you already enjoyed working on?"),
               wellPanel(
                   selectInput("input_item1", "Project #1", choices = c("", project_list)),
                   selectInput("input_item2", "Project #2", choices = c("", project_list)),
                   selectInput("input_item3", "Project #3", choices = c("", project_list)),
                   selectInput("input_item4", "Project #4", choices = c("", project_list)),
                   selectInput("input_item5", "Project #5", choices = c("", project_list)),
                   actionButton("submit", "Enter Your Choices")
               )
        ),

        # Output table
        column(8,
               h3("Here are some other projects we think you might like:"),
               tableOutput("item_recom")
        )
    )
)


# Define server logic required to draw a histogram
server <- function(input,output) {

    # output$item_recom <- renderTable({
    #     # react to submit button
    #     input$submit
    #     # gather input in string
    #     user_choices <-
    #         isolate(
    #
    #             unique(c(input$input_item1, input$input_item2, input$input_item3,
    #                      input$input_item4, input$input_item5))
    #         )
    #
    #
    #     # put in a matrix format
    #     newdat <- project_details %>%
    #         #Add a value column with 1's for the user choices
    #         mutate(value = as.numeric(name %in% user_choices)) %>%
    #         # Spread into sparse matrix format
    #         pivot_wider(names_from = project_id, values_from = value, values_fill = 0) %>%
    #         # Change to a matrix
    #         as.matrix() %>%
    #         # Convert to recommenderlab class 'binaryRatingsMatrix'
    #         as("binaryRatingMatrix")
    #

}

# Run the application
shinyApp(ui = ui, server = server)
