# library(plyr)

transportation.aerodrome    <- "Aerodrome"
transportation.airport      <- "Airport"
transportation.busstop      <- "BusStop"
transportation.ferryport    <- "Ferryport"
transportation.trainstation <- "TrainStation"
transportation.bicycle_rental <- "BicycleRentalService"
transportation.boat_rental    <- "BoatRentalService"
transportation.car_rental     <- "CarRentalService"
transportation.boat_sharing   <- "BoatSharingService"
transportation.car_sharing    <- "CarSharingService"
transportation.modelled_types <- c(transportation.aerodrome,
                                   transportation.airport,
                                   transportation.busstop,
                                   transportation.ferryport,
                                   transportation.trainstation,
                                   transportation.bicycle_rental,
                                   transportation.boat_rental,
                                   transportation.car_rental,
                                   transportation.boat_sharing,
                                   transportation.car_sharing)
# not modelled
transportation.taxi <- "Taxi"
transportation.bus_station <- "BusStation"
transportation.funicular <- "Funicular"

transportation.clean_nuts2 <- function(nuts2) {
  colnames(nuts2) <- c("region_denomination", "nuts2_code")
  nuts2
}

transportation.clean_nuts3 <- function(nuts3) {
  colnames(nuts3) <- c("province_denomination", "nuts3_code")
  nuts3
}

transportation.clean_tpoints <- function(tpoints) {
  colnames(tpoints) <- c("id", "name", "highway",
                         "public_transport", "operator", "shelter",
                         "bus", "route_ref",  "network",
                         "bench", "wheelchair", "amenity", "railway",
                         "website", "train", "covered", "line",
                         "route", "alt_name", "ferry", "contact_website",
                         "opening_hours", "contact_phone", "email", "contact_mobile_phone",
                         "station", "aeroway", "contact_email", "contact_fax",
                         "official_name",
                         "lat", "lon",
                         "code_rip", "code_region", "code_province",
                         "code_cm", "code_pcm",
                         "province_denomination",  "cm_denomination", "pcm_denomination",
                         "sigla", "shape_len", "shape_area")
  tpoints$id <- as.character(as.numeric(tpoints$id))
  tpoints$code_rip <- NULL
  tpoints$code_cm <- NULL
  tpoints$cm_denomination <- NULL
  tpoints$code_pcm <- NULL
  tpoints$pcm_denomination <- NULL
  tpoints$den_cm <- NULL
  tpoints$shape_len <- NULL
  tpoints$shape_area <- NULL
  tpoints$code_province <- NULL
  tpoints$sigla <- NULL
  tpoints$covered <- NULL
  tpoints$official_name <- NULL
  tpoints$alt_name <- NULL
  tpoints <- tpoints[which(!is.na(tpoints$name)),]
  tpoints
}

transportation.normalise_tags <- function(tpoints) {
  tpoints$website_address <- NA
  tpoints$email_address <- NA
  tpoints$phone_number <- NA
  tpoints$region_denomination <- NA
  tpoints$route_line <- NA
  tpoints <- ddply(tpoints, .variables = .(id), .fun = function(entry) {
    if (!is.na(entry$contact_phone))
      entry$phone_number <- entry$contact_phone
    else
      entry$phone_number <- entry$contact_mobile_phone
    
    if (!is.na(entry$route_ref))
      entry$route_line <- entry$route_ref
    else if (!is.na(entry$line))
      entry$route_line <- entry$line
    else
      entry$route_line <- entry$route
    
    if (!is.na(entry$contact_email))
      entry$email_address <- entry$contact_email
    else
      entry$email_address <- entry$email
    
    if (!is.na(entry$contact_website))
      entry$website_address <- entry$contact_website
    else
      entry$website_address <- entry$website
    
    if (!is.na(entry$bus) && entry$bus != "no")
      entry$bus <- "yes"
    
    if (!is.na(entry$shelter) && entry$shelter != "no")
      entry$shelter <- "yes"
    
    if (!is.na(entry$bench) && entry$bench != "no")
      entry$bench <- "yes"
    
    if (!is.na(entry$wheelchair) && entry$wheelchair != "no" && entry$wheelchair != "yes")
      entry$wheelchair <- "limited"
    
    entry})
  
  tpoints$website <- NULL
  tpoints$contact_website <- NULL
  tpoints$email <- NULL
  tpoints$contact_email <- NULL
  tpoints$contact_mobile_phone <- NULL
  tpoints$contact_phone <- NULL
  
  tpoints$line <- NULL
  tpoints$route <- NULL
  tpoints$route_ref <- NULL
  tpoints$fax <- tpoints$contact_fax
  tpoints$contact_fax <- NULL
  tpoints
}

transportation.attach_nuts_codes <- function(tpoints, nuts2, nuts3) {
  tpoints_normalised <- ddply(tpoints, .variables = .(id), .fun = function(entry) {
    switch(entry$code_region,
           "4" = {
             if (entry$province_denomination == "Trento")
               entry$region_denomination <- "Trento"
             else
               entry$region_denomination <- "Bolzano"
           },
           "5" = {
             entry$region_denomination <- "Veneto"
           },
           "3" = {
             entry$region_denomination <- "Lombardia"
           })
    entry
  })
  tpoints_normalised <- join(tpoints_normalised, nuts2,
                             by = c("region_denomination"),
                             type = "left", match = "first")
  tpoints_normalised <- join(tpoints_normalised, nuts3,
                             by = c("province_denomination"),
                             type = "left", match = "first")
  
  tpoints_normalised$code_region <- NULL
  tpoints_normalised$region_denomination <- NULL
  tpoints_normalised$province_denomination <- NULL
  tpoints_normalised
}

transportation.determine_transportation_service <- function(tpoints) {
  tpoints$type <- NA
  
  ferry_terminals <- tpoints[which(tpoints$amenity == "ferry_terminal" | tpoints$ferry == "yes"),]
  ferry_terminals$type <- transportation.ferryport
  
  boat_rental <- tpoints[which(tpoints$amenity == "boat_rental" | tpoints$ferry == "yes"),]
  boat_rental$type <- transportation.boat_rental
  
  bicycle_rental <- tpoints[which(tpoints$amenity == "bicycle_rental"),]
  bicycle_rental$type <- transportation.bicycle_rental
  
  car_sharing <- tpoints[which(tpoints$amenity == "car_sharing"), ]
  car_sharing$type <- transportation.car_sharing
  
  car_rental <- tpoints[which(tpoints$amenity == "car_rental"), ]
  car_rental$type <- transportation.car_rental
  
  taxi <- tpoints[which(tpoints$amenity == "taxi"), ]
  taxi$type <- transportation.taxi
  
  bus_stations <- tpoints[which(tpoints$amenity == "bus_station"), ]
  bus_stations$type <- transportation.bus_station
  
  bus_stops <- tpoints[which(tpoints$highway == "bus_stop" | tpoints$bus == "yes"),]
  bus_stops$type <- transportation.busstop
  
  railway_stations <- tpoints[which(tpoints$railway == "station" | tpoints$train == "yes"), ]
  railway_stations$type <- transportation.trainstation
  
  funicular <- tpoints[which(tpoints$station == "funicular"), ]
  funicular$type <- transportation.funicular
  
  aerodrome <-tpoints[which(tpoints$aeroway == "aerodrome"), ]
  aerodrome$type <- transportation.aerodrome
  
  tpoints_cleaned <- rbind(ferry_terminals, boat_rental, bicycle_rental,
                           car_sharing, car_rental, taxi,
                           bus_stations, bus_stops, railway_stations,
                           funicular, aerodrome)
  tpoints_cleaned$highway <- NULL
  tpoints_cleaned$public_transport <- NULL
  tpoints_cleaned$bus <- NULL
  tpoints_cleaned$amenity <- NULL
  tpoints_cleaned$railway <- NULL
  tpoints_cleaned$train <- NULL
  tpoints_cleaned$ferry <- NULL
  tpoints_cleaned$aeroway <- NULL
  tpoints_cleaned$station <- NULL
  tpoints_cleaned <- unique(tpoints_cleaned)
  tpoints_cleaned
}

transportation.main <- function(folder) {
  tpointsdata <- paste(folder, "transportation_points.csv", sep="")
  nuts2data <- paste(folder, "nuts2_codes.csv", sep="")
  nuts3data <- paste(folder, "nuts3_codes.csv", sep="")
  tpoints <- read.csv(tpointsdata, header = T, sep = ",", quote="\"",
                      stringsAsFactors = F, colClasses = "character", na.strings = c("", "-"))
  nuts2 <- read.csv(nuts2data, header = T, sep = ",", quote="\"",
                    stringsAsFactors = F, colClasses = "character", na.strings = c("", "-"))
  nuts3 <- read.csv(nuts3data, header = T, sep = ",", quote="\"",
                    stringsAsFactors = F, colClasses = "character", na.strings = c("", "-"))
  tpoints <- transportation.clean_tpoints(tpoints)
  tpoints <- transportation.normalise_tags(tpoints)
  nuts2 <- transportation.clean_nuts2(nuts2)
  nuts3 <- transportation.clean_nuts3(nuts3)
  tpoints <- transportation.attach_nuts_codes(tpoints, nuts2, nuts3)
  tpoints <- transportation.determine_transportation_service(tpoints)
  tpoints <- tpoints[which(tpoints$type %in% transportation.modelled_types),]
  return(tpoints)
  # data analysis: check out possible values
  # unique(tpoints$bus)
  # unique(tpoints$highway)
  # unique(tpoints$public_transport)
  # unique(tpoints$shelter)
  # unique(tpoints$bench)
  # unique(tpoints$wheelchair)
  # unique(tpoints$amenity)
  # unique(tpoints$railway)
  # unique(tpoints$train)
  # unique(tpoints$ferry)
  # unique(tpoints$station)
  # unique(tpoints$aeroway)
}