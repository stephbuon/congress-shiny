library(tidyverse)

count_collocates <- function(collocates) {
  
  collocates$year <- format(collocates$year, format="%Y")
  
  collocates <- collocates %>%
    mutate(decade = year - year %% 10)
  
  if (keyword == "speakers") { 

    collocates <- collocates %>%
      mutate(decade = year - year %% 10)
    
    collocates <- collocates %>%
      count(new_speaker, grammatical_collocates, afinn, textblob, vader, decade)}
  
  else {
    collocates <- collocates %>%
      count(grammatical_collocates, afinn, textblob, vader, decade) }

return(collocates)}