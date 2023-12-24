setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
print(paste("wd of app.R is ", getwd()))
source("./frontend/tabs.R")
source("./backend/serverFunctions.R")


# Define the Shiny UI
ui <- navbarPage(
  title = "HDBWise",
  fluid = TRUE,
  
  #Tab Panel 1 - Home
  homeTab,
  
  #Tab Panel 2- Nearby Amenities
  nearbyAmenitiesTab,
  
  #Tab Panel 3 - Price appreciation map
  priceAppreciationTab,
  
  #Tab Panel 4 - Block Comparison
  comparisonTab,
  
  #Tab Panel 5 - Loan Type & Downpayment
  downpaymentTab,
  
  #Tab Panel 6: Neighbourhood search
  neighbourhoodSearchTab
)

# Define the Shiny server
server <- function(input, output, session) {
  
  ##----------------------------------------------------------------------------
  ##Nearby Amenities
  output$map <- nearbyMap
  
  observeEvent(input$submit, nearbyHandler(input, output, session))
  
  #-------------------------------------------------------------------------
  #Price appreciation
  #React to the button click
  observeEvent(input$submitBtn, priceAppreciationHandler(input, output, session))
  
  #----------------------------------------------------------------------
  #Comparison Function
  observeEvent(input$compareBtn, comparisonHandler(input, output, session))
  
  #------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  #Loan & Downpayment
  # Reactive value for the filtered data
  recommendations <- eventReactive(input$search, downpaymentFunction(input, output, session))
  
  # Render the table in the UI
  output$recommendations <- renderTable({
    recommendations()
  })
  #------------------------------------------------------------------------------------------------------------
  #Neighbourhood Search
  # Convert hdb to sf object
  hdb_sf <- st_as_sf(hdb, coords = c("long", "lat"), crs = 4326)
  
  # Filter data based on user input
  filtered_data_2 <- reactive(getFilteredDf(input, output, session))
  
  # Render map
  output$map_2 <- neighbourhoodMap
  
  # Render selected information table
  output$selected_info_table <- neighbourhoodTable
}


# Run the Shiny app
shinyApp(ui, server)