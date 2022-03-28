library(tidyverse)
library(tidytext)
library(textdata)
library(ggplot2)
library(countrycode)
library(tidyverse)
library(rvest)
library(qdapDictionaries)
library(udpipe)
library(rlist)

#after covid article
#https://news.wttw.com/2022/01/03/chicago-area-housing-market-soared-2021-may-slow-2022

fun_web <- function(web, xp){
  url <- read_html(web)
  article <- html_nodes(url, xpath = xp)
  paragraphs <- html_nodes(article, "p")
  text_list <- html_text(paragraphs)
  text <- paste(text_list, collapse = "")
}


#before covid article 
#https://news.wttw.com/2016/01/05/chicago-home-price-growth-lowest-among-20-major-cities

text_after <-tibble(
  text = fun_web(web = "https://news.wttw.com/2022/01/03/chicago-area-housing-market-soared-2021-may-slow-2022", 
                 xp = '//*[@id="node-38617"]/div[3]/div[3]/div')
  )

text_before <- tibble(
  text = fun_web(web = "https://news.wttw.com/2016/01/05/chicago-home-price-growth-lowest-among-20-major-cities", 
                 xp = '//*[@id="node-19133"]/div[3]/div[3]/div/div')
  )


word_token_after <- unnest_tokens(text_after, word_tokens,  text, token = "words")
word_token_before <- unnest_tokens(text_before, word_tokens,  text, token = "words")

text_all <- c()

text_all[1] <- text_after[[1]]
text_all[2] <- text_before[[1]]

date_v <- c("after","before")

lemma <- list()
lemma_freq <- list()
negation <- list()

for (i in 1:2) {
  # find lemma
  lemma[[i]] <- udpipe(text_all[i], "english") %>%
    filter(!upos %in% c("PUNCT", "CCONJ", "PART")) %>% 
    mutate_if(is.character, str_to_lower) %>% 
    mutate(doc_id = date_v[i]) %>% 
    anti_join(stop_words, by = c("lemma" = "word"))
  
  # find lemma frequency
  lemma_freq[[i]] <- document_term_frequencies(lemma[[i]], term = "lemma")
  
  # find negation words
  negation[[i]] <- tibble(text = text_all[i]) %>%
    unnest_tokens(bigrams, text, token = "ngrams", n = 2) %>%
    separate(bigrams, c("word1", "word2"), sep = " ") %>%
    filter(word1 %in% negation.words) %>%
    inner_join(lemma[[i]], by = c("word2" = "token")) %>%
    select(lemma) %>% 
    group_by(lemma) %>% 
    count(sort = TRUE) %>% 
    mutate(doc_id = date_v[i])
  
  # join sentiment dictionaries
  for (s in c("afinn", "bing")) {
    lemma_freq[[i]] <- lemma_freq[[i]] %>%
      left_join(get_sentiments(s), by = c("term" = "word")) %>%
      plyr::rename(replace = c(sentiment = s, value = s), warn_missing = FALSE)
    
    negation[[i]] <- negation[[i]] %>%
      left_join(get_sentiments(s), by = c("lemma" = "word")) %>%
      plyr::rename(replace = c(sentiment = s, value = s), warn_missing = FALSE)
  }
}


lemma_freq_df <- list.rbind(lemma_freq) %>% 
  tibble()
negation_df <- list.rbind(negation) %>% 
  tibble()


# deal with negation
# First, I create a df in order to subtract the words that should have negation
negation_df_n <- negation_df %>% 
  filter(!is.na(afinn) | !is.na(bing)) %>% 
  mutate(n_o = -n) %>% 
  rename(term = lemma, freq = n_o) %>% 
  select(doc_id, term, freq, afinn, bing)


lemma_freq_df <- rbind(lemma_freq_df, negation_df_n) %>% 
  group_by(doc_id, term, afinn, bing) %>% 
  summarise(count = sum(freq))

# Second, I create a df of the real (opposite) sentiment of the negation words
negation_df_s <- negation_df %>% 
  filter(!is.na(afinn) | !is.na(bing)) %>% 
  mutate(afinn = -afinn) %>% 
  mutate(bing = ifelse(bing == "positive", 
                       "negative", 
                       ifelse(bing == "negative", "positive", NA))) %>% 
  rename(term = lemma, count = n) %>% 
  select(doc_id, term, afinn, bing, count)
# reference for rbind list:
# https://rdrr.io/cran/rlist/man/list.rbind.html

lemma_freq_df <- rbind(lemma_freq_df, negation_df_s)

# first, I show the positive rate in bing dictionary for article before and after covid
lemma_freq_bing <- lemma_freq_df %>% 
  filter(!is.na(bing)) %>% 
  group_by(doc_id, bing) %>% 
  summarise(n = sum(count)) %>% 
  pivot_wider(names_from = bing, values_from = n) %>% 
  mutate(positive_rate = round(positive / (positive + negative), 4) * 100)


date_df <- tibble(date_v)
lemma_freq_bing <- left_join(date_df, lemma_freq_bing, by = c("date_v" = "doc_id"))

ggplot(data = lemma_freq_bing) +
  geom_histogram(aes(x = date_v, y = positive_rate), stat = "identity") +
  scale_x_discrete(guide = guide_axis(angle = 30), 
                   limits = lemma_freq_bing$date_v) +
  labs(title = "21. Positive Rate Time Trend about the attitude of chicago housing price (bing)") +
  theme_bw()

ggsave("21. Positive Rate Time Trend about the attitude of chicago housing price (bing).png")

# from the sentiment dictionary of bing, we can see that the positive rate of words toward chicago housing price before covid is much higher than after covid.

# second, I show the count in afinn dictionary for article before and after covid

ggplot(data = filter(lemma_freq_df, !is.na(afinn))) +
  geom_histogram(aes(x = afinn, fill = doc_id, stat = "count"), 
                 position = "dodge") +
  labs(title = "21. Sentiment analysis for chicago housing value before and after (afinn)") +
  scale_x_continuous(n.breaks = 7)

ggsave("21. Sentiment analysis for chicago housing value before and after (afinn).png")


nrc_data <- lemma_freq_df %>%
  left_join(get_sentiments("nrc"), by = c("term" = "word")) %>%
  plyr::rename(replace = c(sentiment = "nrc", value = "nrc"), 
               warn_missing = FALSE)

ggplot(data = filter(nrc_data, !is.na(nrc))) +
  geom_histogram(aes(nrc, fill = doc_id), stat = "count",position = "dodge") +
  labs(title = "21. Sentiment analysis for chicago housing value before and after (nrc)") 

ggsave("21. Sentiment analysis for chicago housing value before and after (nrc).png")



