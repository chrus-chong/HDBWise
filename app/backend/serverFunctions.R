library(dplyr)
library(ggmap)
library(leaflet)
library(shiny)

## Retrieve data after data cleaning operations.
print(getwd())
load("./HDBWise/data cleaning/cleanedData.RData")

## Nearby Amenities Functions
nearbyMap <- renderLeaflet({
  leaflet() %>%
    setView(lng = 103.8198, lat = 1.3521, zoom = 12) %>%
    addProviderTiles("CartoDB.Positron") %>%
    addLegend(
      position = "bottomright",
      colors = c("green", "orange", "purple", "brown"),
      labels = c("Park", "School","Hawker", "Mall"),
      title = "Legend"
    )
})

nearbyHandler <- function(input, output, session) {
  req(input$postcodeInput)
  selected_postcode <- as.numeric(input$postcodeInput)
  filtered_houses <- hdb[hdb$postal == selected_postcode,]
  
  if (nrow(filtered_houses) == 0) {
    showModal(modalDialog(
      title = "Warning",
      "I regret to inform you that the requested block is not present in the database. I apologize for any inconvenience this may have caused.",
      easyClose = TRUE,
      footer = NULL
    ))
  } else {
    leafletProxy("map") %>%
      clearGroup(group = "houses") %>%
      clearMarkers() %>%
      addMarkers(
        data = filtered_houses,
        lng = ~long,
        lat = ~lat,
        label = ~paste(town, postal),
        group = "houses"
      ) %>%
      addCircleMarkers(
        data = filtered_houses$hawker_info[[1]],
        radius = 5,
        fillOpacity = 0.8,
        color = "purple",
        stroke = FALSE,
        group = "hawker_info",
        popup = ~NAME
      ) %>%
      addCircleMarkers(
        data = filtered_houses$school_info[[1]],
        radius = 5,
        fillOpacity = 0.8,
        color = "orange",
        stroke = FALSE,
        group = "school_info",
        popup = ~BUILDING
      ) %>%
      addCircleMarkers(
        data = filtered_houses$park_info[[1]],
        radius = 5,
        fillOpacity = 0.8,
        color = "green",
        stroke = FALSE,
        group = "park_info"
      ) %>%
      addCircleMarkers(
        data = filtered_houses$malls_info[[1]],
        radius = 5,
        fillOpacity = 0.8,
        color = "brown",
        stroke = FALSE,
        group = "malls_info",
        popup = ~address
      )
  }
}


## Price Appreciation Function
priceAppreciationHandler <- function(input, output, session) {
  # Generate the ggmap plot based on selected years
  start <- input$startYear
  end <- input$endYear
  selected_data <- filter(grouped_hdb, saleYear >= start & saleYear <= end)
  
  selected_data <- selected_data %>%
    group_by(lat, long) %>%
    summarise(
      price_appreciation = ((last(avg_resale_price) - first(avg_resale_price))/first(avg_resale_price))*100
    )
  map <- get_map('Singapore', zoom = 11)
  
  output$mapPlot <- renderPlot({
    ggmap(map, extent = "device") +
      stat_summary_2d(data = selected_data, aes(x = long, y = lat, 
                                                z = price_appreciation), fun = mean, alpha = 0.6, bins = 40) +
      scale_fill_gradient(
        name = paste("Appreciation in price from ", start, " to ", end, " (%).", sep=""),
        low = "green",
        high = "red",
        guide = guide_legend(title = paste("Appreciation in price from ", start, " to ", end, " (%).", sep=""))
      )
  })
}

## Comparison Function
comparisonHandler <- function(input, output, session) {
  
  hdb1_data <- filter(hdb, postal == input$hdb1)
  hdb2_data <- filter(hdb, postal == input$hdb2) 
  
  # Data Entry
  numtrans1 <- nrow(hdb1_data)
  numtrans2 <- nrow(hdb2_data)
  
  # Filter data (saleYear >= 2018) for meanPrice calculations
  hdb1_data_filtered <- filter(hdb1_data, saleYear >= 2018)
  hdb2_data_filtered <- filter(hdb2_data, saleYear >= 2018)
  
  meanPrice1 <- mean(hdb1_data_filtered$resale_price / hdb1_data_filtered$floor_area_sqm)
  meanPrice2 <- mean(hdb2_data_filtered$resale_price / hdb2_data_filtered$floor_area_sqm)
  
  numhawker1 <- round(mean(hdb1_data$Num_Hawker), 0)
  numhawker2 <- round(mean(hdb2_data$Num_Hawker), 0)
  numschool1 <- round(mean(hdb1_data$Num_School), 0)
  numschool2 <- round(mean(hdb2_data$Num_School), 0)
  numpark1 <- round(mean(hdb1_data$Num_Parks), 0)
  numpark2 <- round(mean(hdb2_data$Num_Parks), 0)
  nummall1 <- round(mean(hdb1_data$Num_Malls), 0)
  nummall2 <- round(mean(hdb2_data$Num_Malls), 0)
  
  comparison_data <- data.frame(
    HDB_Unit = c(input$hdb1, input$hdb2),
    num_trans = c(numtrans1, numtrans2),
    Mean_Price_PerSQM = c(meanPrice1, meanPrice2),
    num_hawker = c(numhawker1, numhawker2),
    num_school = c(numschool1, numschool2),
    num_park = c(numpark1, numpark2),
    num_mall = c(nummall1, nummall2)
  ) 
  colnames(comparison_data) <- c("HDB", "No. of Transactions", "Mean Price /sqm", "No. of Hawker", "No. of Schools", "No. of Parks", "No. of Malls")
  output$comparisonTable <- renderTable({
    comparison_data
  })
  
  #Display disclaimers below table
  output$disclaimer <- renderText({
    "Disclaimer:\n1.All amenities are located within a 1km radius.\n2.Mean Price is derived based on data from 2018 onwards."
  })
}

## Loan and Downpayment Function
downpaymentFunction <- function(input, output, session){
  downpayment <- input$downpayment
  loanType <- input$loanType
  
  # Calculate the maximum price based on the downpayment and loan type
  max_price <- if(loanType == "HDB") {
    downpayment / 0.15
  } else {
    downpayment / 0.25
  }
  
  # Filter the data based on the max price
  filtered_data <- hdb %>%
    filter(resale_price <= max_price) %>%
    filter(saleYear >= 2020) %>%
    arrange(desc(resale_price))
  
  # Select only specific columns
  selected_columns <- c("town", "flat_type", "flat_model", "floor_area_sqm", "street_name", 
                        "resale_price", "lease_commence_date", "storey_range", "full_address",
                        "nearest_mrt", "nearest_distance_to_mrt", "saleYear")
  
  filtered_data <- filtered_data %>%
    select(all_of(selected_columns))
  
  return(filtered_data)
}

# Neighbourhood Search Function
getFilteredDf <- function(input, output, session) {
  filtered_df <- hdb
  
  if (!is.null(input$region)) {
    filtered_df <- filtered_df[filtered_df$Region %in% input$region, ]
  }
  
  if (input$near_school) {
    filtered_df <- filtered_df[filtered_df$Num_School != 0, ]
  }
  
  if (input$near_mall) {
    filtered_df <- filtered_df[filtered_df$Num_Malls != 0, ]
  }
  
  if (input$near_park) {
    filtered_df <- filtered_df[filtered_df$Num_Parks != 0, ]
  }
  
  if (input$near_hawker) {
    filtered_df <- filtered_df[filtered_df$Num_Hawker != 0, ]
  }
  
  if (!is.null(input$mrt_distance)) {
    distance_threshold <- as.numeric(gsub("km", "", input$mrt_distance))
    filtered_df <- filtered_df[filtered_df$nearest_distance_to_mrt <= distance_threshold, ]
  }
  
  if (!is.null(input$storey_range)) {
    filtered_df <- filtered_df[grep(input$storey_range, filtered_df$storey_range), ]
  }
  
  filtered_df <- filtered_df[filtered_df$saleYear >= input$sales_year[1] &
                               filtered_df$saleYear<= input$sales_year[2], ]
  
  return(filtered_df)
}

neighbourhoodMap <- renderLeaflet({
  leaflet() %>%
    addTiles() %>%
    addCircleMarkers(data = filtered_data_2(),
                     ~long, ~lat,
                     radius = 5,
                     color = "blue",
                     fillOpacity = 0.8,
                     popup = ~paste("Postal Code: ", postal, "<br>Address: ", address))
})

neighbourhoodTable <- renderTable({
  # Get the clicked point from the map
  click <- input$map_2_click
  
  # If no click event, return NULL
  if (is.null(click)) return(NULL)
  
  
  # Extract the clicked coordinates and round to a certain decimal place
  clicked_coords <- c(round(click$lat, 6), round(click$lng, 4))
  
  # # Find the data points within a small distance to the clicked coordinates
  selected_data_2 <- filtered_data_2() %>%
    filter(lat >= clicked_coords[1] - 0.000200, lat <= clicked_coords[1] + 0.000200,
           long >= clicked_coords[2] - 0.0002, long <= clicked_coords[2] + 0.0002)
  
  
  
  # If there are no matching data points, return NULL
  if (nrow(selected_data_2) == 0) return(NULL)
  
  # Create a table of selected information
  table_data <- data.frame(
    Town = selected_data_2$town,
    Flat_Type = selected_data_2$flat_type,
    Flat_Model = selected_data_2$flat_model,
    Floor_Area_Sqm = selected_data_2$floor_area_sqm,
    Resale_Price = selected_data_2$resale_price,
    Street_Name = selected_data_2$street_name,
    Block = selected_data_2$block,
    Remaining_Lease = selected_data_2$remaining_lease,
    Address = selected_data_2$address,
    Sale_Year = selected_data_2$saleYear
  )
  
  # Return the table data
  table_data
})