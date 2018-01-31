#Підвантажуємо наші бібліотеки для скрапінгу

library(RSelenium)  #Якщо бібліотеку не встановлено, то запустіть функцію: install.packages("RSelenium")
library(rvest)      #Якщо бібліотеку не встановлено, то запустіть функцію: install.packages("rvest")
library(dplyr)      #Якщо бібліотеку не встановлено, то запустіть функцію: install.packages("dplyr")
library(openxlsx)   #Якщо бібліотеку не встановлено, то запустіть функцію: install.packages("openxlsx")
  
#Створюємо підключення до емітатора браузера

remDr <- remoteDriver(remoteServerAddr = "localhost",
                      port = 4445L, 
                      browserName = "firefox")
#Відкриваємо підключення до браузера
remDr$open()

#Задаємо пошукове слдово/слова
searchTerm <- "водка+воздух"

#Створюємо посилання для пошуку
url <- paste0("https://www.google.com.ua/search?q=",searchTerm, "&source=lnms&tbm=isch&sa=X")

#Вікдриваємо згенероване вище посилання у браузері
remDr$navigate(url)

#Робимо 10 скролів сторінки із зображеннями
for(i in 1:10){
  webElem <- remDr$findElement("css", "body")
  webElem$sendKeysToElement(list(key = "end"))
  Sys.sleep(2)
}

#Скачуємо код сторінки
page_source<-remDr$getPageSource()

#Беремо зі сторінки тільки гіперпосилання на окремі сторінки із інформацією про зображення
files <- html(page_source[[1]]) %>% html_nodes("a") %>% html_attr("href")

#Відсіюємо зайві посилання (усі гіперпосилання на зображення у гуглі мають у собі слово imgre)
files <- files[grepl("imgres", files)]

#Створюємо пусту таблицю для запису інформації про зображення
fls <- data_frame(site = NA, #У цю колонку запишемо адресу сторінки, де це зображення розміщено
                  descr = NA, #Сюди впишемо назву сторінки, де це зображення розміщено
                  img = NA) #Посилання саме на зображення

#Тепер для кожного гіперпосилання застосуємо такі команди через цикл for
for(i in files) { #Для кожного елементу і у векторі files
  remDr$navigate(paste0("https://www.google.com",i)) #Кожен елемент поєднуємо з https://www.google.com, щоб утворити повне посилання і навігуємо сторінку по утвореному посиланню
  page_source<-remDr$getPageSource() #Скачуємо код сторінки, на яку тільки що пронавігували
  fls <- bind_rows(fls,data_frame(site = (html(page_source[[1]]) %>% html_nodes(css = ".irc_pt.irc_tas.i3598.irc_lth") %>% html_attr("href"))[2], #Витягуємо з коду посилання на сторінку
                      descr = (html(page_source[[1]]) %>% html_nodes(css = ".irc_pt.irc_tas.i3598.irc_lth") %>% html_text())[2], #Витягуємо з коду назву сторінки
                      img = (html(page_source[[1]]) %>% html_nodes(".irc_mi") %>% html_attr("src"))[2])) #Витягуємо з коду посилання на зображення
  Sys.sleep(0.5) #Даємо браузеру відпочити перед наступним прогоном циклу
}

fls <- fls %>% filter(!is.na(img)) #Відфільтровуємо з утвореної таблиці пусті строки

dir.create(searchTerm) #Створюємо папку для зображень

#Скачуємо зображення у вище утворену папку через цикл for
for(i in 1:nrow(fls)){  #Для кожного і у векторі від одного до кількості рядків у таблиці
  tryCatch({ #Функція, яка призводить до ігнорування помилок у циклі
    download.file(fls$img[i],paste0(searchTerm,"/",searchTerm,i,".jpg")) #Скачуємо і-тий елемент у векторі fls$img (сюди ми помістили вище посилання на зображення) і називаємо файл по принципу пошуковий запит+і.jpg
  },error = function(e) NULL)
}

########################################
# ТЕПЕР ОФОРМИМО ЦЕ ВСЕ В ОДНУ ФУНКЦІЮ #
########################################

image_search <- function(searchTerm, scrolls = 10) {
  require(RSelenium)
  require(rvest)
  
  #Створюємо підключення до емітатора браузера
  
  remDr <- remoteDriver(remoteServerAddr = "localhost",
                        port = 4445L, 
                        browserName = "firefox")
  #Відкриваємо підключення до браузера
  remDr$open()
  
  searchTerm <- gsub(" ", "+", searchTerm)

  #Створюємо посилання для пошуку
  url <- paste0("https://www.google.com.ua/search?q=",searchTerm, "&source=lnms&tbm=isch&sa=X")
  
  #Вікдриваємо згенероване вище посилання у браузері
  remDr$navigate(url)
  
  #Робимо scrolls скролів сторінки із зображеннями
  for(i in 1:scrolls){
    webElem <- remDr$findElement("css", "body")
    webElem$sendKeysToElement(list(key = "end"))
    Sys.sleep(2)
  }
  
  #Скачуємо код сторінки
  page_source<-remDr$getPageSource()
  
  #Беремо зі сторінки тільки гіперпосилання на окремі сторінки із інформацією про зображення
  files <- html(page_source[[1]]) %>% html_nodes("a") %>% html_attr("href")
  
  #Відсіюємо зайві посилання (усі гіперпосилання на зображення у гуглі мають у собі слово imgre)
  files <- files[grepl("imgres", files)]
  
  #Створюємо пусту таблицю для запису інформації про зображення
  fls <- data_frame(site = NA, #У цю колонку запишемо адресу сторінки, де це зображення розміщено
                    descr = NA, #Сюди впишемо назву сторінки, де це зображення розміщено
                    img = NA) #Посилання саме на зображення
  
  #Тепер для кожного гіперпосилання застосуємо такі команди через цикл for
  for(i in files) { #Для кожного елементу і у векторі files
    remDr$navigate(paste0("https://www.google.com",i)) #Кожен елемент поєднуємо з https://www.google.com, щоб утворити повне посилання і навігуємо сторінку по утвореному посиланню
    page_source<-remDr$getPageSource() #Скачуємо код сторінки, на яку тільки що пронавігували
    fls <- bind_rows(fls,data_frame(site = (html(page_source[[1]]) %>% html_nodes(css = ".irc_pt.irc_tas.i3598.irc_lth") %>% html_attr("href"))[2], #Витягуємо з коду посилання на сторінку
                                    descr = (html(page_source[[1]]) %>% html_nodes(css = ".irc_pt.irc_tas.i3598.irc_lth") %>% html_text())[2], #Витягуємо з коду назву сторінки
                                    img = (html(page_source[[1]]) %>% html_nodes(".irc_mi") %>% html_attr("src"))[2])) #Витягуємо з коду посилання на зображення
    Sys.sleep(0.5) #Даємо браузеру відпочити перед наступним прогоном циклу
  }
  
  fls <- fls %>% filter(!is.na(img)) #Відфільтровуємо з утвореної таблиці пусті строки
  
  fls$ID <- 1:nrow(fls) #Додамо колоку з айді для того, щоб ми могли потім співставити зображення із інформацією в таблиці
  
  dir.create(searchTerm) #Створюємо папку для зображень
  
  #Скачуємо зображення у вище утворену папку через цикл for
  for(i in 1:nrow(fls)){  #Для кожного і у векторі від одного до кількості рядків у таблиці
    tryCatch({ #Функція, яка призводить до ігнорування помилок у циклі
      download.file(fls$img[i],paste0(searchTerm,"/",searchTerm,i,".jpg")) #Скачуємо і-тий елемент у векторі fls$img (сюди ми помістили вище посилання на зображення) і називаємо файл по принципу пошуковий запит+і.jpg
    },error = function(e) NULL)
  }
  openxlsx::write.xlsx(fls, paste0(searchTerm,".xlsx")) #Таблицю запишемо в ексель
  return(fls) #Функція повертає нам таблицю з інформацією про зображення
}

#Протестуємо нашу функцію

haifisch <- image_search("тупорила+акула", scrolls = 5)

#Скачало 365 фотографій тупорилої акули!
