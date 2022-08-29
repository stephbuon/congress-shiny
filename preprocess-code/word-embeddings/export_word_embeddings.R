library(tidyverse)
library(data.table)
library(text2vec)

import_stopwords_as_regex <- function() {
  
  stopwords <- read_csv("/scratch/group/pract-txt-mine/sbuongiorno/congress-shiny/preprocess-data/stopwords_text2vec.csv") 
  
  stopwords <- stopwords %>%
    summarise(all = paste0(stop_word, collapse="|"))
  
  stopwords <- stopwords$all 
  
  return(stopwords) }


clean_data_for_word_embeddings <- function(data_decade_subset) {
  
  data_decade_subset <- data_decade_subset %>%
    filter(!str_detect(word, "[[:digit:]]"))
  
  data_decade_subset$word <- str_replace(data_decade_subset$word, "'s", "")
  
  stopwords <- import_stopwords_as_regex()
  
  data_decade_subset <- data_decade_subset %>%
    filter(!str_detect(word, stopwords))
  
  return(data_decade_subset) }


view_most_similar_words <- function(word_vectors, keyword, n_view) {
  kw = word_vectors[keyword, , drop = F]
  
  cos_sim_rom = sim2(x = word_vectors, y = kw, method = "cosine", norm = "l2")
  
  print(head(sort(cos_sim_rom[,1], decreasing = TRUE), n_view)) }


export_word_embeddings <- function(dir, view_most_similar) {
  
  files <- list.files(path = dir, pattern = "congress_tokens_", full.names = TRUE)
  
  for (file in files) {
    data_decade_subset <- fread(file)
    
    data_decade_subset <- data_decade_subset %>%
      select(year, word) # added
    
    #data_decade_subset <- clean_data_for_word_embeddings(data_decade_subset)
    
    first_year_label <- first(data_decade_subset$year)
    #last_year_label <- last(data_decade_subset$year)
    
    vocab_list = list(data_decade_subset$word)
    
    it = itoken(vocab_list, progressbar = FALSE)
    vocab = create_vocabulary(it)
    
    # term_count_min is the minimum number of times a word is stated
    vocab = prune_vocabulary(vocab, term_count_min = 30)
    
    vectorizer = vocab_vectorizer(vocab)
    
    tcm = create_tcm(it, vectorizer, skip_grams_window = 5)
    
    glove = GlobalVectors$new(rank = 4, x_max = 100)
    
    wv_main = glove$fit_transform(tcm, n_iter = 1000, convergence_tol = 0.00000001, n_threads = 24)
    
    wv_context = glove$components
    
    # The developers of the method suggest that sum/mean may work best when creating a matrix
    print("Finding sum/mean")
    word_vectors = wv_main + t(wv_context)
    
    if (view_most_similar == TRUE) { # test to see if this works 
      view_most_similar_wrods(word_vectors, keyword, 30) }
    
    print(paste0("Checking if ", dir, "/", target_dir, " exists."))
    if(!dir.exists(file.path(dir, target_dir))) {
      print(paste0("Creating ", dir, target_dir, ".")) }
    
    ifelse(!dir.exists(file.path(dir, target_dir)), dir.create(file.path(dir, target_dir)), FALSE)
    
    fname <- paste0(dir, "/", target_dir, "/", "congress_word_vectors_", first_year_label, ".txt") #last_year_label, ".txt")
    
    print("Writing word embeddings to disk.")
    write.table(word_vectors, file = fname) } }

data_dir = "/scratch/group/pract-txt-mine/sbuongiorno/congress_tokens/"
#data_dir <- "/home/stephbuon/projects/congress-shiny/preprocess-data/"
target_dir <- "word_embeddings"
export_word_embeddings(data_dir, view_most_similar = FALSE)
