library(plyr)
library(xlsx)
source("./merge_wdpa_natura2k.R")
source("./merge_management.R")
source("./merge_species.R")
source("./manage_transportation_points.R")
data_folder <- "./data/"
# arguments are arrays!
connect <- function(site_ids, transport_ids, num_connection=NA) {
  if (is.na(num_connection) || num_connection > length(transport_ids))
    num_connection <- length(transport_ids)

  temp <- data.frame(wdpaid = site_ids)
  ddply(temp, .variables = .(wdpaid), .fun = function(site_id) {
    data.frame(wdpaid = site_id,
               osmid = transport_ids[sample(length(transport_ids), num_connection)])
  })
}



set.seed(42)
# save all information related to trentino
trentino <- list()

sites <- sites.main(data_folder)
trento_sites <- sites[which(sites$region_code == "ITH2"),]
trento_sites <- trento_sites[1:10,]
bolzano_sites <- sites[which(sites$region_code == "ITH1"),]
bolzano_sites <- bolzano_sites[1:10,]
trentino$sites <- rbind(trento_sites, bolzano_sites)
rm(trento_sites, bolzano_sites)

# keep site ids, in  order to avoid pick data outside trentino
sites_ids <- data.frame(site_name = trentino$sites$site_name, wdpaid = trentino$sites$wdpa_id, site_code = trentino$sites$site_code)
sites_region <- data.frame(wdpaid = trentino$sites$wdpa_id, nuts2_code = trentino$sites$region_code)
rm(sites)

management <- management.main(data_folder)
trentino_management <- management[which(management$site_code %in% sites_ids$site_code),]
trentino_management <- join(trentino_management, sites_ids,   by = c("site_code"))
trentino_management$id <- lapply(trentino_management$wdpaid, function(x){paste("ma:", x, sep="")})
trentino$management <- trentino_management
rm(management, trentino_management)

species <- species.main(data_folder)
trentino_species <- species[which(species$site_code %in% sites_ids$site_code),]
trentino_species <- join(trentino_species, sites_ids,   by = c("site_code"))
ps_id <- paste(trentino_species$wdpaid, trentino_species$species_code, sep = "_")
trentino_species$ps_species_id <- ps_id
#trentino_species$ps_species_id <- lapply(ps_id, function(x){paste("speciesin:", x, sep="")})
#trentino_species$ps_species_id <- seq.int(nrow(trentino_species))
trentino$species <- trentino_species[1:200,]
rm(species, trentino_species)

tpoints <- transportation.main(data_folder)
tregion <- tpoints[which(tpoints$nuts2_code == "ITH2"),]
buses   <- tregion[which(tregion$type == transportation.busstop),]
buses <- buses[sample(nrow(buses), 5),]
trainstations <- tregion[which(tregion$type == transportation.trainstation),]
trainstations <- trainstations[sample(nrow(trainstations), 5),]
aerodrome <- tregion[which(tregion$type == transportation.aerodrome),]
connections.region <- connect(sites_ids$wdpaid, buses$id, 2)
connections.region <- rbind(connections.region, connect(sites_ids$wdpaid, trainstations$id, 2))
connections.region <- rbind(connections.region, connect(sites_ids$wdpaid, aerodrome$id))
connections_trento  <- connections.region
transports_trento  <- rbind(buses, trainstations, aerodrome)

tregion <- tpoints[which(tpoints$nuts2_code == "ITH1"),]
buses   <- tregion[which(tregion$type == transportation.busstop),]
buses <- buses[sample(nrow(buses), 5),]
trainstations <- tregion[which(tregion$type == transportation.trainstation),]
trainstations <- trainstations[sample(nrow(trainstations), 5),]
aerodrome <- tregion[which(tregion$type == transportation.aerodrome),]
connections.region <- connect(sites_ids$wdpaid, buses$id, 2)
connections.region <- rbind(connections.region, connect(sites_ids$wdpaid, trainstations$id, 2))
connections_bolzano  <- connections.region
transports_bolzano  <- rbind(buses, trainstations, aerodrome)

transports <- rbind(transports_bolzano, transports_trento)
connections <- rbind(connections_trento, connections_bolzano)
rm(tpoints, tregion,
   buses, trainstations, aerodrome, connections.region,
   connections_bolzano, connections_trento,
   transports_bolzano, transports_trento)
trentino$transports <- transports
trentino$connections <- connections[sample(nrow(connections), nrow(connections)),]
rm(transports, connections)

nuts2data <- paste(data_folder, "nuts2_codes.csv", sep="")
nuts3data <- paste(data_folder, "nuts3_codes.csv", sep="")
nuts2 <- read.csv(nuts2data, header = T, sep = ",", quote="\"",
         stringsAsFactors = F, colClasses = "character", na.strings = c("", "-"))
nuts2$region <- lapply(nuts2$region,
                       function(rname){
                         if (rname=="Trento" | rname=="Bolzano")
                           "Trentino-Alto Adige" 
                         else 
                           rname
                         })
nuts3 <- read.csv(nuts3data, header = T, sep = ",", quote="\"",
                  stringsAsFactors = F, colClasses = "character", na.strings = c("", "-"))
nuts3$regions <- lapply(nuts3$code, function(nuts3){substr(nuts3, 0, 4)})
write.xlsx(trentino$sites, file="data.xlsx", sheetName="sites", row.names=FALSE)
write.xlsx(trentino$management, file="data.xlsx", sheetName="management", row.names=FALSE, append = T)
write.xlsx(trentino$species, file="data.xlsx", sheetName="species", row.names=FALSE, append = T)
write.xlsx(trentino$transports, file="data.xlsx", sheetName="transports", row.names=FALSE, append = T)
write.xlsx(trentino$connections, file="data.xlsx", sheetName="connections", row.names=FALSE, append = T)
write.xlsx(nuts2, file="data.xlsx", sheetName="regions", row.names=FALSE, append = T)
write.xlsx(nuts3, file="data.xlsx", sheetName="provinces", row.names=FALSE, append = T)
rm(nuts2, nuts3)
