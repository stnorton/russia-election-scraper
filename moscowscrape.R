###################
##Moscow Scrape  ##
##Sean Norton    ##
##Started 27.6.18##
###################

## This script scrapes Moscow's electoral data

##LIBRARY-----------------------------------------------------------------------
library(rvest) #webscraping
library(RSelenium) #webscraping
library(httr)

#set wd
setwd("C:/Users/stnor/OneDrive - University of North Carolina at Chapel Hill/Projects/local-elections/Moscow")

##NEEDED TO DISPLAY CYRILLIC CORRECTLY IF COMPUTER NOT CONFIGURED IN RUSSIAN
##RUN ON OPENING SCRIPT EVERY TIME
Sys.setlocale("LC_CTYPE", "Russian")

#sourcing functions written for scraping
source("../ruselecscraper.R", encoding = "utf-8")

##GETTING LINKS-----------------------------------------------------------------
rd <- rsDriver(browser = "chrome")

#seting up client
browser <- rd[["client"]]

#navigating to website
browser$navigate("http://www.moscow_city.vybory.izbirkom.ru/region/moscow_city")

#selecting start/end date
start_input <- browser$findElement(using="css", "#start_date")

end_input <- browser$findElement(using = "css", "#end_date")

#entering
start_input$clearElement()
start_input$sendKeysToElement(list("01.01.2000"))

end_input$clearElement()
end_input$sendKeysToElement(list("01.08.2018"))

enter_button <- browser$findElement(using="css", "td:nth-child(3) input")

enter_button$clickElement()

##Don't need to select levels since Moscow is a federal city

#getting links for each election
links_raw <- browser$findElements(using = "css", ".vibLink")
link_urls <- unlist(lapply(links_raw, function(x){x$getElementAttribute('href')}))

#getting election names for naming folders/files
links_name <- unlist(lapply(links_raw, function(x){x$getElementText()}))

saveRDS(link_urls, file = "mos_links.rds")
saveRDS(links_name, file = "mos_names.rds")

#stopping server
rd[["server"]]$stop()

#reloading when needed
link_urls <- readRDS("mos_links.rds")
links_name <- readRDS("mos_names.rds")

##DUMA 2003---------------------------------------------------------------------

fed_duma_link <- link_urls[1] 

##functions to extract link to majority vote results
##getting regional level links
reg_links <- lapply(X = fed_duma_link, FUN = safe.dist.link.extracting)
reg_links <- unlist(reg_links)

##getting tik level results
tik_links <- sapply(X = reg_links, FUN = safe.dist.link.extracting)
tik_links <- unlist(tik_links)


#getting results for protocol 1 (direct election)
dist_majvote_links <- sapply(tik_links, safe.direct.link.extractor,
                             node = "tr:nth-child(13) a")

##creating directories to store results
dir.create("Duma 2003")
dir.create("Duma 2003/majvote")

#creating filenames
numbers <- 1:length(dist_majvote_links)
majvote_filenames <- paste0("./Duma 2003/majvote/result", numbers, ".xls")

##getting API variables
duma_api <- api.extracting(dist_majvote_links)

#these do not have vibids
check <- mapply(safe.api.caller, roots = duma_api$roots, vrns = duma_api$vrns, 
                tvds = duma_api$tvds, vibids = "", type = duma_api$types,
                global = duma_api$global, region = duma_api$region,
                sub_region = duma_api$sub_region,
                filenames = majvote_filenames)

#getting party list vote
dir.create("Duma 2003/partyvote")

#getting links
dist_partyvote_links <- sapply(X = tik_links, safe.direct.link.extractor,
                               node = "tr:nth-child(15) a")

#creating filenames
numbers <- 1:length(dist_partyvote_links)
partyvote_filenames <- paste0("./Duma 2003/partyvote/result", numbers, ".xls")

#call
duma_api <- api.extracting(dist_partyvote_links)

#these do not have vibids
check <- mapply(safe.api.caller, roots = duma_api$roots, vrns = duma_api$vrns, 
                tvds = duma_api$tvds, vibids = "", type = duma_api$types,
                global = duma_api$global, region = duma_api$region,
                sub_region = duma_api$sub_region,
                filenames = partyvote_filenames,
                SIMPLIFY = F)
test <- lapply(check, is.null)
which(is.null(test))

##DUMA 2016---------------------------------------------------------------------

seventh_duma <- grep(links_name,
                     pattern = "Выборы депутатов Государственной Думы Федерального Собрания Российской Федерации седьмого созыва")

sev_duma_link <- link_urls[seventh_duma] 

##functions to extract link to majority vote results
##getting regional level links
reg_links <- lapply(X = sev_duma_link, FUN = safe.dist.link.extracting)
reg_links <- unlist(reg_links)

##getting tik level results
tik_links <- sapply(X = reg_links, FUN = safe.dist.link.extracting)
tik_links <- unlist(tik_links)


#getting results for protocol 1 (direct election)
dist_majvote_links <- sapply(tik_links, safe.direct.link.extractor,
                             node = ":nth-child(15) a")

##creating directories to store results
dir.create("Duma 2016")
dir.create("Duma 2016/majvote")

#creating filenames
numbers <- 1:length(dist_majvote_links)
majvote_filenames <- paste0("./Duma 2016/majvote/result", numbers, ".xls")

##getting API variables
duma_api <- api.extracting(dist_majvote_links)

#these do have vibids
check <- mapply(safe.api.caller, roots = duma_api$roots, vrns = duma_api$vrns, 
                tvds = duma_api$tvds, vibids = duma_api$vibids, type = duma_api$types,
                global = duma_api$global, region = duma_api$region,
                sub_region = duma_api$sub_region,
                filenames = majvote_filenames)

#getting party list vote
dir.create("Duma 2016/partyvote")

#getting links
dist_partyvote_links <- sapply(X = tik_links, safe.direct.link.extractor,
                               node = ":nth-child(17) a")

#creating filenames
numbers <- 1:length(dist_partyvote_links)
partyvote_filenames <- paste0("./Duma 2016/partyvote/result", numbers, ".xls")

#call
duma_api <- api.extracting(dist_partyvote_links)

#these do have vibids
check <- mapply(safe.api.caller, roots = duma_api$roots, vrns = duma_api$vrns, 
                tvds = duma_api$tvds, vibids = duma_api$vibids, type = duma_api$types,
                global = duma_api$global, region = duma_api$region,
                sub_region = duma_api$sub_region,
                filenames = partyvote_filenames,
                SIMPLIFY = F)
test <- lapply(check, is.null)
which(is.null(test))

##ALL OTHER ELECTIONS-----------------------------------------------------------

#need to pull out city duma elections to scrape seperately, as the electoral
#system switched from PR to mixed several times

city_duma <- grep(links_name,
                  pattern = "Московской городской Думы")
link_urls <- link_urls[-city_duma]
links_name <- links_name[-city_duma]

#need to pull out Duma 2016 as well, since they moved back to mixed
seventh_duma <- grep(links_name,
                     pattern = "Выборы депутатов Государственной Думы Федерального Собрания Российской Федерации седьмого созыва")
link_urls <- link_urls[-seventh_duma]
links_name <- links_name[-seventh_duma]

#pulling out first duma election
link_urls <- link_urls[-1]

#scraper should work on everything else
check <- lapply(X = link_urls, 
                FUN = safe.russian.election.scraping,
                encoding = "windows-1251")

#internet connection went out at 75 -- decided to chunk into 100s to avoid
# looking malicious
check <- lapply(X = link_urls[75:100],
                FUN = safe.russian.election.scraping,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

##next batch
check <- lapply(X = link_urls[101:200],
                FUN = safe.russian.election.scraping,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

##next batch
check <- lapply(X = link_urls[201:300],
                FUN = safe.russian.election.scraping,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

##batch
check <- lapply(X = link_urls[301:400],
                FUN = safe.russian.election.scraping,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

##batch
check <- lapply(X = link_urls[401:500],
                FUN = safe.russian.election.scraping,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

##final batch
check <- lapply(X = link_urls[500:534],
                FUN = safe.russian.election.scraping,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

##CITY DUMA ELECTIONS-----------------------------------------------------------

city_duma_links <- link_urls[city_duma]
city_duma_names <- links_name[city_duma]

#first set of elections is actually a special election - can just run
# the normal scraper on this

check <- safe.russian.election.scraping(city_duma_links[1],
                                        encoding = "windows-1251")

##rewriting scraper function to work for these elecctions
# this is taken from nizhnyscrape.R

#modifying scraper to deal with this

index.result.extracting <- function(link, ...){
  
  link <- read_html(link, ...)
  text <- link %>%
    html_nodes("a") %>%
    html_text()
  
  indices <- grep(text, pattern = "Сводная таблица")
  
  xpaths <- sapply(indices,  function (x) paste0("(//a)", "[", x, "]"))
  
  res <- sapply(X = xpaths, FUN = index.xpath.extracting, link = link)
  
  return(res)
  
}

index.xpath.extracting <- function(xpath, link){
  
  res <- link %>%
    html_node(xpath = xpath) %>%
    html_attr("href")
  
  return(res)
}

cityduma.election.scraping <- function(base_link, ...){
  
  ##check for package dependency
  library(rvest)
  
  #getting name for folder/reading in link
  base_page <- read_html(base_link, ...)
  
  name <- base_page %>%
    html_node(css = ".w2 .headers") %>%
    html_text()
  
  if(name == "Сведения о выборах"){
    name <- base_page %>%
      html_node(css = ".w2:nth-child(2) b") %>%
      html_text()
  }
  
  
  name <- dir.name.generating(name)
  
  dir.create(path = name)
  
  #extracting links to districts
  
  dist_links <- dist.link.extracting(base_link)
  
  result_links <- unlist(sapply(X = dist_links, FUN = index.result.extracting,
                                ...))
  
  majvote_links <- result_links[c(TRUE, FALSE)]
  partyvote_links <- result_links[c(FALSE, TRUE)]
  
  #extracting api variables from results
  maj_api_variables <- api.extracting(majvote_links)
  party_api_variables <- api.extracting(partyvote_links)
  
  #creating subdirectories
  maj_dir_name <- paste0("./", name, "/", "majvote")
  dir.create(maj_dir_name)
  
  party_dir_name <- paste0("./", name,"/", "partyvote")
  dir.create(party_dir_name)
  
  #creating filenames
  numbers <- 1: length(majvote_links)
  maj_filenames <- paste0("./", name, "/majvote/", "result", numbers, ".xls")
  party_filenames <- paste0("./", name, "/partyvote/", "result", numbers, ".xls")
  
  #running the api call
  
  res <- mapply(api.caller, roots = maj_api_variables$roots,
                vrns = maj_api_variables$vrns,
                tvds = maj_api_variables$tvds,
                vibids = maj_api_variables$vibids,
                type = maj_api_variables$types,
                global = maj_api_variables$global,
                region = maj_api_variables$region,
                sub_region = maj_api_variables$sub_region,
                filenames =  maj_filenames)
  
  res2 <- mapply(api.caller, roots = party_api_variables$roots,
                 vrns = party_api_variables$vrns,
                 tvds = party_api_variables$tvds,
                 vibids = party_api_variables$vibids,
                 type = party_api_variables$types,
                 global = party_api_variables$global,
                 region = party_api_variables$region,
                 sub_region = party_api_variables$sub_region,
                 filenames =  party_filenames)
  
  
  return(list(res, res2))
  
}

#running the modified scraper
check <- lapply(X = city_duma_links[2:3],
                FUN = cityduma.election.scraping,
                encoding = "windows-1251")

#And Moscow switched back to SMSP at the most recent election
check <- safe.russian.election.scraping(city_duma_links[4],
                                        encoding = "windows-1251")

##CANDIDATE DATA----------------------------------------------------------------

#no data for Duma 2003
link_urls <- link_urls[-1]

#batching these again
check <- lapply(X = link_urls[1:100],
                FUN = safe.candidate.scraper,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

#batch two
check <- lapply(X = link_urls[101:200],
                FUN = safe.candidate.scraper,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

#batch three
check <- lapply(X = link_urls[201:300],
                FUN = safe.candidate.scraper,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

#batch four
check <- lapply(X = link_urls[301:400],
                FUN = safe.candidate.scraper,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)

#batch final
check <- lapply(X = link_urls[401:539],
                FUN = safe.candidate.scraper,
                encoding = "windows-1251")
nulls <- sapply(check, is.null)
which(nulls == T)
