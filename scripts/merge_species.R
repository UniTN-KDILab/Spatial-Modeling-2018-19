species.clean_birds <- function(birds) {
  colnames(birds) <- c("country_code", "site_code", "species_name",
                       "species_code", "ref_supergroup", "supergroup",
                       "sensitive", "non_present", "population_type",
                       "lowerbound", "upperbound", "counting_unit",
                       "abundance_cat", "dataquality", "population",
                       "conservation", "isolation", "global",
                       "introduction_candidate")
  # remove fields not required from birds
  birds$ref_supergroup <- NULL
  birds$sensitive <- NULL
  birds$population_type <- NULL
  birds$lowerbound <- NULL
  birds$upperbound <- NULL
  birds$counting_unit <- NULL
  birds$dataquality <- NULL
  birds$population <- NULL
  birds$conservation <- NULL
  birds$isolation <- NULL
  birds$global <- NULL
  birds$introduction_candidate <- NULL
  birds
}

species.clean_habitats <- function(habitats) {
  
  colnames(habitats) <- c("country_code", "site_code", "supergroup",
                          "species_name", "species_code", "motivation",
                          "sensitive", "non_present", "lowerbound",
                          "upperbound", "abundance_cat", "counting_unit",
                          "introduction_candidate")
  # remove fields not required from habitat
  habitats$motivation <- NULL
  habitats$sensitive <- NULL
  habitats$lowerbound <- NULL
  habitats$upperbound <- NULL
  habitats$counting_unit <- NULL
  habitats$introduction_candidate <- NULL
  habitats
}

species.main <- function(folder) {
  birdsdata <- paste(folder, "birds_species_it.csv", sep="")
  habitatsdata <- paste(folder, "habitat_species_it.csv", sep="")
  birds <- read.csv(birdsdata, header = T, sep = ",", quote="\"",
                    stringsAsFactors = F, colClasses = "character", na.strings = c(""))
  habitats <- read.csv(habitatsdata, header = T, sep = ",", quote="\"",
                       stringsAsFactors = F, colClasses = "character", na.strings = c(""))
  birds <- species.clean_birds(birds)
  habitats <- species.clean_habitats(habitats)
  # now habitat and birds have the same, common columns
  species <- rbind(birds, habitats)
  lut <- c("present", "common", "very rare", "rare", "present", "present")
  names(lut) <- c("p", "c", "v", "r", "a", "d")
  species$abundance_cat <- lapply(species$abundance_cat,
                                  function(x){lut[tolower(x)]})
  species$non_present <- NULL
  species  
}
