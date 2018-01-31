library(rcheatsheet)
library(magrittr)
library(googlesheets)
library(httr)

fpath <- 'httr.xlsx'
sheet_data <- gs_title('httr') 
gs_download(sheet_data, to = fpath, overwrite = TRUE)

r <- GET("http://swapi.co/api/people/?search=vader")

fpath %>%
  read_all_sheets %>%
  make_cheatsheet
