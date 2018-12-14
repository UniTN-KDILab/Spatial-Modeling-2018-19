# requires plyr
# library(plyr)
# ---------------- cleaning functions ----------------------------------

sites.clean_wdpa <- function(wdpa) {
  colnames(wdpa) <- c("type", "wdpa_id", "wdpa_pid", "pa_def",
                      "site_name", "original_name",
                      "designation_native", "designation", "designation_type",
                      "iucn_cat", "int_crit",
                      "marine",
                      "marine_area", "gis_marine_area", "area", "gis_area",
                      "no_take", "no_take_area",
                      "status", "status_year",
                      "gov_type", "ownership_type", "management_authority", "mang_plan",
                      "verified", "metadata_id", "subloc", "parent_iso3", "iso3")   
  
  wdpa$type <- NULL
  wdpa$pa_def <- NULL
  wdpa$original_name <- NULL
  wdpa$designation_native <- NULL
  wdpa$iucn_cat <- NULL
  wdpa$int_crit <- NULL
  wdpa$gis_area <- NULL
  wdpa$gis_marine_area <- NULL
  wdpa$no_take <- NULL
  wdpa$no_take_area <- NULL
  wdpa$gov_type <- NULL
  wdpa$ownership_type <- NULL
  wdpa$mang_plan <- NULL
  wdpa$verified <- NULL
  wdpa$metadata_id <- NULL
  wdpa$subloc <- NULL
  wdpa$parent_iso3 <- NULL
  wdpa$iso3 <- NULL
  wdpa
}

sites.clean_nuts2 <- function(nuts2) {
  colnames(nuts2) <- c("region", "region_code")
  nuts2
}

sites.clean_sites <- function(sites) {
  colnames(sites) <- c("country_code", "site_code", "site_name", "natura_site_type",
                       "date_compilation", "date_update", "date_spa", "spa_legal_reference",
                       "date_prop_sci", "date_conf_sci", "date_sac", "sac_legal_reference",
                       "explanations", "n2k_area", "n2k_length", "n2k_marine_area_percentage",
                       "lon", "lat",
                       "documentation", "quality", "designation", "othercharact")
  # remove fields not required and very heavy to carry around
  sites$spa_legal_reference <- NULL
  sites$sac_legal_reference <- NULL
  sites$designation <- NULL
  sites$othercharact <- NULL
  sites$documentation <- NULL
  sites$quality <- NULL
  sites$explanations <- NULL
  sites
}

# ----------------------------------------------------------------------

sites.make_zones <- function(zsc, zps) {
  zsc$zsc <- NULL
  zones <- rbind(zps, zsc)
  zones_cleaned <- unique(zones)
  colnames(zones) <- c("region", "site_code")
  zones
}

sites.rename_region <- function(region) {
  if (region == "Friuli Venezia Giulia")
    region <- "Friuli-Venezia Giulia"
  else if (region == "Emilia Romagna")
    region <- "Emilia-Romagna"
  region
}

sites.retrieve_region_code <- function(zones, nuts2) {
  regions <- unlist(lapply(zones$region, sites.rename_region))
  zones <- data.frame(region = regions, site_code = zones$site_code)
  zones <- join(zones, nuts2, by = c("region"), type = "left", match = "first")
  zones
}

sites.make_natura2k <- function(sites, zones) {
  # join sites with regions
  sites_zones <- join(sites, zones, by = c("site_code"), type = "left", match = "first")
  #  entry having sitetype to C is both a SPA and a SCI, we wish two separate entries
  sites_normalised <- ddply(sites_zones, .variables = .(site_code), .fun = function(entry) {
    new_entry <- entry
    new_entry$n2k_area <- as.character(as.double(new_entry$n2k_area) / 100) # normalise with wdpa area
    if (entry$natura_site_type == "C") {
      spa_site <- new_entry
      spa_site$natura_site_type <- "A"
      sci_site <- new_entry
      sci_site$natura_site_type <- "B"
      new_entry <- rbind(spa_site, sci_site)
    }
    new_entry
  })
  # now habitat and birds have the same, common columns
  sites_normalised
}

sites.merge_natura2k_wdpa <- function(sites, wdpa) {
  # we require to merge based on the site type
  wdpa$natura_site_type <- NA # add field
  wdpa_normalised <- ddply(wdpa, .variables = .(wdpa_pid, designation),
                           .fun = function(entry) {
                             new_entry <- entry
                             if (entry$designation == "Site of Community Importance (Habitats Directive)") {
                               new_entry$natura_site_type <- "B"
                             } else if (entry$designation == "Special Protection Area (Birds Directive)") {
                               new_entry$natura_site_type <- "A"
                             }
                             return(new_entry)
                           })
  merged_data <- join(sites, wdpa_normalised,
                      by = c("natura_site_type", "site_name"),
                      type = "left", match = "first")
  merged_data <- merged_data[which(!(is.na(merged_data$wdpa_id) |
                                       is.na(merged_data$site_code))),]
  merged_data
}

sites.main <- function(folder) {
  zpsdata <- paste(folder, "zps_italy.csv", sep="")
  zscdata <- paste(folder, "zsc_italy.csv", sep="")
  nuts2data <- paste(folder, "nuts2_codes.csv", sep="")
  natura2kdata <- paste(folder, "natura2ksites_it.csv", sep="")
  wdpadata <- paste(folder,"./wdpa_ita.csv", sep="")
  zps <- read.csv(zpsdata, header = T, sep = ",", quote="\"",
                  stringsAsFactors = F, colClasses = "character")
  zsc <- read.csv(zscdata, header = T, sep = ",",
                  stringsAsFactors = F, quote = "\"",
                  colClasses = "character")
  zones <- sites.make_zones(zsc, zps)
  
  nuts2 <- read.csv(nuts2data, header = T, sep = ",", quote="\"",
                  stringsAsFactors = F, colClasses = "character", na.strings = c(""))
  nuts2 <- sites.clean_nuts2(nuts2)
  locations <- sites.retrieve_region_code(zones, nuts2)
  rm(nuts2, zones)
  sites <- read.csv(natura2kdata, header = T, sep = ",", quote="\"",
                  stringsAsFactors = F, colClasses = "character")
  sites <- sites.clean_sites(sites)
  natura2k <- sites.make_natura2k(sites, locations)
  wdpa <- read.csv(wdpadata, header = T, sep = ",", quote="\"",
                   stringsAsFactors = F, colClasses = "character")
  wdpa <- sites.clean_wdpa(wdpa)
  merged_data <- sites.merge_natura2k_wdpa(natura2k, wdpa)
  merged_data
}
