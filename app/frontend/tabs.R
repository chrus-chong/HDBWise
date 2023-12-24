print(getwd())
homeTab <- tabPanel("Home",
         includeHTML("./HDBWise/app/frontend/homepage.html"),
         tags$style(HTML("
    /* Style for carousel images */
    .carousel-inner img {
      width: 100%;
      height: 15vh;
      object-fit: cover;
    }

    /* Adjustments for small screens */
    @media (max-width: 767px) {
      .carousel-inner img {
        height: auto;
      }
    }
  ")))

nearbyAmenitiesTab <- tabPanel("Nearby Amenities",
         leafletOutput("map"),
         textInput("postcodeInput", "Enter Postal Code", ""),
         actionButton("submit", "Submit")
         )

priceAppreciationTab <- tabPanel("Price Appreciation",
         fluidPage(  
           sidebarPanel(
             # Input for start year
             numericInput("startYear", "Start Year:", min = 1990, max = 2023, value = 1990),
             
             # Input for end year
             numericInput("endYear", "End Year:", min = 1990, max = 2023, value = 2023),
             
             # Button to trigger an action
             actionButton("submitBtn", "Submit")
             ),
           
           mainPanel(
             # Output to display the ggmap plot
             plotOutput("mapPlot", width = "100%", height = "600px")  # Set height to "100%"
             )
           )
         )

comparisonTab <- tabPanel("Comparison", 
                         fluidPage(
                           sidebarLayout(
                             sidebarPanel(
                               textInput("hdb1", "Enter HDB 1 Postal Code:", value = ""),
                               textInput("hdb2", "Enter HDB 2 Postal Code:", value = ""),
                               actionButton("compareBtn", "Compare")
                             ),
                             mainPanel(
                               tableOutput("comparisonTable"),
                               verbatimTextOutput("disclaimer")
                               )
                             )
                           )
                         )

downpaymentTab <- tabPanel("Loan & Downpayment",
                           sidebarLayout(
                             sidebarPanel(
                               radioButtons("loanType", "Choose loan type:", choices = c("HDB Loan" = "HDB", "Bank Loan" = "BANK")),
                               numericInput("downpayment", "Maximum downpayment available:", value = 0),
                               actionButton("search", "Search")
                               ),
                             
                             mainPanel(
                               tableOutput("recommendations")
                               )
                             )
                           )

neighbourhoodSearchTab <- tabPanel("Neighbourhood Search",
                                   fluidPage(
                                     sidebarLayout(
                                       sidebarPanel(
                                         # Add input elements for filtering options
                                         selectInput("region", "Select Region", choices = unique(hdb$Region)),
                                         checkboxInput("near_school", "Near School"),
                                         checkboxInput("near_mall", "Near Mall"),
                                         checkboxInput("near_park", "Near Park"),
                                         checkboxInput("near_hawker", "Near Hawker"),
                                         selectInput("mrt_distance", "MRT Distance", choices = c("0.25km","0.5km", "1km", "2km")),
                                         selectInput("storey_range", "Storey Range", 
                                                     choices = c("07 TO 09", "04 TO 06", "01 TO 03", "10 TO 12", "01 TO 05", "06 TO 10", 
                                                                 "13 TO 15", "11 TO 15", "22 TO 24", "19 TO 21", "16 TO 18", "25 TO 27", 
                                                                 "21 TO 25", "16 TO 20", "28 TO 30", "26 TO 30", "31 TO 33", "37 TO 39", 
                                                                 "34 TO 36", "40 TO 42", "31 TO 35", "36 TO 40", "43 TO 45", "46 TO 48", 
                                                                 "49 TO 51")),
                                         sliderInput("sales_year", "Sales Year Range", min = 1986, max = 2023, value = c(1986, 2023), step = 1),
                                         actionButton("search_button", "Search")
                                         ),
                                       mainPanel(
                                         leafletOutput("map_2"),
                                         tableOutput("selected_info_table"),
                                         textOutput("out_of_range_message")
                                         )
                                       )
                                     )
                                   )