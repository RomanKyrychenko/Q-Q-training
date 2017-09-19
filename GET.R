library(httr)
library(jsonlite)
library(magrittr)

vader <- GET("http://swapi.co/api/people/?search=vader")

vader2 <- GET("http://swapi.co/api/people/", query = list(search = "vader"))

str(vader)

listviewer::jsonedit(vader)

vader$content

vader$status_code
vader$headers$`content-type`
names(vader)

text_content <- content(vader, as = "text", encoding = "UTF-8")
text_content

listviewer::jsonedit(text_content)

parsed_content <- content(vader, as = "parsed")
names(parsed_content)
parsed_content$count
str(parsed_content$results)
parsed_content$results[[1]]$name
parsed_content$results[[1]]$terrain

json_content <- text_content %>% fromJSON
json_content
vader_data <- json_content$results
names(vader_data)
vader_data$name
vader_data$terrain

json_parse <- function(req) {
  text <- content(req, as = "text", encoding = "UTF-8")
  if (identical(text, "")) warn("Нема чого парсить")
  fromJSON(text)
}

planets <- GET("http://swapi.co/api/planets") %>% stop_for_status() %>% json_parse()

names(planets)
planets$count
length(planets$results$name)

planets$`next`

next_page <- GET(planets$`next`) %>% stop_for_status() %>% json_parse()

next_page$results$name

planets <- GET("http://swapi.co/api/planets") %>% stop_for_status() %>% json_parse()
next_page <- planets$`next`
planets <- planets$results

while(!is.null(next_page)) {
  more_planets <- GET(next_page) %>% stop_for_status() %>% json_parse()
  planets <- rbind(planets, more_planets$results)
  next_page <- more_planets$`next`
}

length(planets$name)
planets$name
head(planets)

xlsx::write.xlsx(planets,"planets.xlsx")