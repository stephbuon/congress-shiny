library(tidyverse)
library(lubridate)
library(tidytext)
library(data.table)
library(foreach)
library(doParallel)
library(itertools)


j = 1 
cores=35
cl <- makeCluster(35, outfile = "") 

registerDoParallel(cl)

import_stopwords_as_regex <- function() {
  
  stopwords <- read_csv("/scratch/group/pract-txt-mine/sbuongiorno/congress-shiny/preprocess-data/stopwords_text2vec.csv") 
  
  stopwords <- stopwords %>%
    summarise(all = paste0(stop_word, collapse="|"))
  
  stopwords <- stopwords$all 
  
  return(stopwords) }

remove_stopwords <- function(data_decade_subset) {
  
  data_decade_subset <- data_decade_subset %>%
    filter(!str_detect(word, "[[:digit:]]"))
  
  data_decade_subset$word <- str_replace(data_decade_subset$word, "'s", "")
  
  stopwords <- import_stopwords_as_regex()
  
  data_decade_subset <- data_decade_subset %>%
    filter(!str_detect(word, stopwords))
  
  return(data_decade_subset) }

dir <- "/scratch/group/pract-txt-mine/sbuongiorno"
fname <- "congress_app_data.csv"

data <- fread(paste0(dir, "/", fname))

data <- data %>%
  mutate(year = year(date)) %>%
  mutate(decade = year - year %% 10)
  
decades <- c(1900, 1910, 1920, 1930, 1940, 1950, 1960, 1970, 1980, 1990, 2000)

for (d in decades) {
  filtered_data <- data %>%
    filter(decade == d)
  
  filtered_data <- foreach(m = isplitRows(filtered_data, chunks=35), .combine='rbind',
                          .packages='tidytext') %dopar% {
                            unnest_tokens(m, ngrams, text, token = "word", n = j)
                          }
  
  filtered_data <- remove_stopwords(filtered_data)
  
  fwrite(filtered_data, paste0(dir, "/clean_congress_tokens_", d, ".csv"))
  
}

