library(tidyverse)
library(data.table)

dir <- "/scratch/group/pract-txt-mine/sbuongiorno/"

congress <- fread(paste0("congress_app_data.csv"))
congress$date <- as.character(congress$date)

decades <- c("1950", "1960", "1970", "1980", "1990", "2000")

out <- data.frame()

for(d in decades) {
  filtered <- congress %>%
    filter(str_detect(date, d))
  
  filtered <- filtered %>%
    sample_n(500)
  
  out <- bind_rows(out, filtered)
  
}

fwrite(out, paste0(dir, "small_congress_app_data"))
