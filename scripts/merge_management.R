# library(plyr)
management.clean_management <- function(manage) {
  colnames(manage) <- c("site_code", "org_name", "email",
                        "manag_conserv_measures", "manag_plan", "manag_plan_url",
                        "manag_status", "org_locatorname", "org_designator",
                        "org_adminunit", "org_postcode", "org_postname",
                        "org_address", "org_address_unstructured")
  manage$manag_conserv_measures <- NULL
  manage$manag_plan <- NULL
  manage$manag_plan_url <- NULL
  manage$manag_status <- NULL
  manage$org_locatorname <- NULL
  manage$org_designator <- NULL
  manage$org_adminunit <- NULL
  manage$org_postcode <- NULL
  manage$org_postname <- NULL
  manage$org_address <- NULL
  manage
}

management.retrieve_contact_info <- function(manage) {
  # add a fictitious id to use ddply
  manage$fake_id <- seq.int(nrow(manage))
  manage$telephones <- NA
  manage$fax <- NA
  manage <- ddply(manage, .variables = .(fake_id),
                  .fun = function(entry) {
                    if(is.na(entry$org_address_unstructured))
                      return(entry)
                    pre <- "(\\s*,\\s*)?"
                    phone_reg <- "tel[^,]*"
                    fax_reg <- "fax[^,]*"
                    new_entry <- entry
                    addr <- entry$org_address_unstructured
                    match <- regexpr(phone_reg, addr, ignore.case = T)
                    start <- match[1];
                    if (start >= 0) {
                      new_entry$telephones <- regmatches(addr, match)
                      addr <- gsub(paste(pre, phone_reg, ".?", sep = ""),
                                   "",
                                   addr, ignore.case = T)
                    }
                    
                    match <- regexpr(fax_reg, addr, ignore.case = T)
                    start <- match[1];
                    if (start >= 0) {
                      new_entry$fax <- regmatches(addr, match)
                      addr <- gsub(paste(pre, fax_reg, ".?", sep = ""),
                                   "",
                                   addr, ignore.case = T)
                    }
                    new_entry$org_address_unstructured <- addr
                    new_entry
                  })
  
  manage$fake_id <- NULL
  manage
}

management.main <- function(folder) {
  managementdata <- paste(folder, "management_ita.csv", sep="")
  manage <- read.csv(managementdata, header = T, sep = ",", quote="\"",
                     stringsAsFactors = F, colClasses = "character", na.strings = c(""))
  manage <- management.clean_management(manage)
  manage <- management.retrieve_contact_info(manage)
  manage
}
