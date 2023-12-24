library(ggplot2)
library(tidyr)
library(sf)
library(jsonlite)
library(rvest)
library(dplyr)
library(geosphere)
library(shiny)
library(ggmap)
library(leaflet)
library(purrr)
library(rsconnect)


#Read all coordinates
print(getwd())
hdb <- read.csv("./HDBWise/data/hdb_latest.csv")
hawker_geojson <- st_read("./HDBWise/data/HawkerCentres.geojson")
schools <- read.csv("./HDBWise/data/school_coordinates.csv")
parks <- read.csv("./HDBWise/data/parks_coordinates_clean.csv")
malls <- read.csv("./HDBWise/data/shoppingmall_coordinates_clean.csv")

#Data Cleaning
#Get postal codes
hdb$postal <- substr(hdb$full_address, nchar(hdb$full_address) - 5, nchar(hdb$full_address))

#Get Sales Year
hdb$saleYear <- substr(hdb$month, 1, 4)

## This only keeps data for the past 8 years. Saves space so that it can be hosted online for free
## For complete data, remove this line and run locally
hdb <- hdb %>% filter(saleYear >= 2016)

## Groups them by latitude, longitude. Then subsequently groups them by saleYear
## For all rows with same saleYear (within each lat,long grouping), merge into a single row with avg_resale_price
grouped_hdb <- hdb %>%
  group_by(lat, long, saleYear) %>%
  summarize(avg_resale_price = mean(resale_price))

#Flat Type cleaning
hdb$flat_type <- gsub("-", " ", hdb$flat_type)
hdb$flat_type <- gsub("MULTIGENERATION", "MULTI GENERATION", hdb$flat_type)

hdb$flat_model <- toupper(hdb$flat_model)


hdb <- separate(hdb, col=storey_range, into=c('bottom', 'top'), sep=' TO ', remove = FALSE)
hdb$bottom <- as.numeric(hdb$bottom)
hdb$top <- as.numeric(hdb$top)

##Add "region" column to df
region_boundaries <- st_read("./HDBWise/data/MasterPlan2019RegionBoundaryNoSeaGEOJSON.geojson")
region_boundaries <- st_make_valid(region_boundaries)

# Convert HDB data to sf object
hdb_sf <- st_as_sf(hdb, coords = c("long", "lat"), crs = 4326)

# Perform spatial join
hdb_with_region <- st_join(hdb_sf, region_boundaries)

# Extract Region Information:
# Parse the "Description" field to get the value corresponding to "REGION_N"
hdb_with_region$Region <- gsub(".*<th>REGION_N<\\/th> <td>(.*?) REGION<\\/td>.*", "\\1", hdb_with_region$Description, perl = TRUE)

# Drop unnecessary columns
hdb_with_region <- select(hdb_with_region, -c("Description", "Name"))

# Extract Region Information:
# Replace "REGION_N" with the actual column name that corresponds to the region information in region_boundaries
hdb$Region <- hdb_with_region$Region


# # # Preprocess the data to get the latest price for each flat
hdb$saleYear <- as.numeric(substr(hdb$month, 1, 4))


#1: Creating df for hawker from GeoJson

# Function to extract attributes from HTML content
extract_attributes <- function(description) {
  webpage <- read_html(description)
  rows <- html_nodes(webpage, "tr")
  data <- list()
  
  for (i in 1:length(rows)) {
    th <- html_nodes(rows[i], "th")
    td <- html_nodes(rows[i], "td")
    
    if (length(th) > 0 && length(td) > 0) {
      attribute_name <- html_text(th)
      attribute_value <- html_text(td)
      data[[attribute_name]] <- attribute_value
    }
  }
  
  return(data)
}

# Apply the function to each row in your dataframe
extracted_data <- lapply(hawker_geojson$Description, extract_attributes)

# Convert the list of data to a dataframe
df_extracted_data <- do.call(rbind, extracted_data)

# Convert row names to a column
df_extracted_data$Attribute <- row.names(df_extracted_data)
row.names(df_extracted_data) <- NULL

# Extract Longitude and Latitude from Geometry
lon_lat <- strsplit(gsub("POINT Z \\((.*)\\)", "\\1", hawker_geojson$geometry), " ")
df_lon_lat <- do.call(rbind.data.frame, lon_lat)
colnames(df_lon_lat) <- c("Lon", "Lat", "Z")

# Remove the "c(" and the Z coordinate
df_lon_lat$Lon <- gsub("c\\(", "", df_lon_lat$Lon)
df_lon_lat$Z <- NULL

# Remove trailing commas from Lon and Lat columns
df_lon_lat$Lon <- gsub(",.*", "", df_lon_lat$Lon)
df_lon_lat$Lat <- as.numeric(gsub(",.*", "", df_lon_lat$Lat))

# Combine Data
hawker_df <- cbind(df_extracted_data[, c("NAME", "ADDRESSSTREETNAME", "ADDRESSPOSTALCODE")], df_lon_lat)

# Remove leading spaces from Lon column
hawker_df$Lon <- as.numeric(gsub("^\\s+", "", hawker_df$Lon))


#2: Assign hawker that is within 1km radius to block
# Define a function to find hawker centers within 2km
find_nearby_hawkers <- function(hdb_lon, hdb_lat) {
  distances <- distHaversine(cbind(hawker_df$Lon, hawker_df$Lat), c(hdb_lon, hdb_lat))
  nearby_hawkers <- hawker_df[distances <= 1000, c("NAME", "Lon", "Lat")]
  return(nearby_hawkers)
}

# Initialize a list to store hawker information
hawker_info_list <- list()

# Loop through each row in hdb_df
for (i in 1:nrow(hdb)) {
  hdb_lat <- as.numeric(hdb[i, "lat"])
  hdb_lon <- as.numeric(hdb[i, "long"])
  nearby_hawkers <- find_nearby_hawkers(hdb_lon, hdb_lat)
  hawker_info_list[[i]] <- nearby_hawkers
}

# Add hawker information to hdb_df
hdb$hawker_info <- hawker_info_list

#3: Assign school that is within 1km radius to block
find_nearby_schools <- function(hdb_lon, hdb_lat) {
  distances <- distHaversine(cbind(schools$LONGITUDE, schools$LATITUDE), c(hdb_lon, hdb_lat))
  nearby_schools <- schools[distances <= 1000, c("BUILDING", "LONGITUDE", "LATITUDE")]
  return(nearby_schools)
}

# Initialize a list to store school information
schools_info_list <- list()

# Loop through each row in hdb_df
for (i in 1:nrow(hdb)) {
  hdb_lat <- as.numeric(hdb[i, "lat"])
  hdb_lon <- as.numeric(hdb[i, "long"])
  nearby_schools <- find_nearby_schools(hdb_lon, hdb_lat)
  schools_info_list[[i]] <- nearby_schools
}

# Add hawker information to hdb_df
hdb$school_info <- schools_info_list


#4: Assign park that is within 1km radius to block
parks <- parks %>% rename(LONGITUDE = X, LATITUDE = Y)

find_nearby_parks <- function(hdb_lon, hdb_lat) {
  distances <- distHaversine(cbind(parks$LONGITUDE, parks$LATITUDE), c(hdb_lon, hdb_lat))
  nearby_parks <- parks[distances <= 1000, c("index", "LONGITUDE", "LATITUDE")]
  return(nearby_parks) 
}

parks_info_list <- list()

# Loop through each row in hdb_df
for (i in 1:nrow(hdb)) {
  hdb_lat <- as.numeric(hdb[i, "lat"])
  hdb_lon <- as.numeric(hdb[i, "long"])
  nearby_parks <- find_nearby_parks(hdb_lon, hdb_lat)
  parks_info_list[[i]] <- nearby_parks
}

# Add hawker information to hdb_df
hdb$park_info <- parks_info_list


#5: Assign mall that is within 1km radius to block
find_nearby_malls <- function(hdb_lon, hdb_lat) {
  distances <- distHaversine(cbind(malls$LONGITUDE, malls$LATITUDE), c(hdb_lon, hdb_lat))
  nearby_malls <- malls[distances <= 1000, c("address", "LONGITUDE", "LATITUDE")]
  return(nearby_malls) 
}

malls_info_list <- list()

# Loop through each row in hdb_df
for (i in 1:nrow(hdb)) {
  hdb_lat <- as.numeric(hdb[i, "lat"])
  hdb_lon <- as.numeric(hdb[i, "long"])
  nearby_malls <- find_nearby_malls(hdb_lon, hdb_lat)
  malls_info_list[[i]] <- nearby_malls
}

# Add hawker information to hdb_df
hdb$malls_info <- malls_info_list

#6: Get amenities number
hdb <- hdb %>% mutate(Num_Hawker = map_dbl(hawker_info, nrow))
hdb <- hdb %>% mutate(Num_School = map_dbl(school_info, nrow))
hdb <- hdb %>% mutate(Num_Parks = map_dbl(park_info, nrow))
hdb <- hdb %>% mutate(Num_Malls = map_dbl(malls_info, nrow))

