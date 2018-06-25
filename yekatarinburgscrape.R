#######################
##Yekatrinburg Scrape##
##Sean Norton        ##
##Started: 20.6.18   ##
#######################

#This script scrapes federal and city election results for Yekatarinburg

##LIBRARY-----------------------------------------------------------------------
library(rvest) #webscraping
library(RSelenium) #webscraping
library(httr)

#set wd
setwd("C:/Users/stnor/OneDrive - University of North Carolina at Chapel Hill/Projects/local-elections/Yekatarinburg")

#sourcing functions written for scraping
source("ruselecscraper.R", encoding = "utf8")

##NEEDED TO DISPLAY CYRILLIC CORRECTLY IF COMPUTER NOT CONFIGURED IN RUSSIAN
##RUN ON OPENING SCRIPT EVERY TIME
Sys.setlocale("LC_CTYPE", "Russian")

##GETTING LINKS-----------------------------------------------------------------
rd <- rsDriver(browser = "chrome")

#seting up client
browser <- rd[["client"]]

#navigating to website
browser$navigate("http://www.sverdlovsk.vybory.izbirkom.ru/region/sverdlovsk")

#selecting start date
start_input <- browser$findElement(using="css", "#start_date")

#entering
start_input$clearElement()
start_input$sendKeysToElement(list("01.01.2000"))

enter_button <- browser$findElement(using="css", "td:nth-child(3) input")

enter_button$clickElement()

#selecting the levels needed
level_selector <- browser$findElement(using="css", ":nth-child(3) span")

level_selector$clickElement()

admin_selector <- browser$findElement(using="css", "#w_1 > tbody > tr > td > table > tbody > tr:nth-child(1) > td:nth-child(4) > div:nth-child(3) > div > ul > li:nth-child(4) > span > i")

admin_selector$clickElement()

federal_selector <- browser$findElement(using = "css", "#w_1 > tbody > tr > td > table > tbody > tr:nth-child(1) > td:nth-child(4) > div:nth-child(3) > div > ul > li:nth-child(2) > span > i")

federal_selector$clickElement()

#entering again
enter_button$clickElement()

#getting links for each election
links_raw <- browser$findElements(using = "css", ".vibLink")
link_urls <- unlist(lapply(links_raw, function(x){x$getElementAttribute('href')}))

#getting election names for naming folders/files
links_name <- unlist(lapply(links_raw, function(x){x$getElementText()}))

saveRDS(link_urls, file = "yek_links.rds")
saveRDS(links_name, file = "yek_names.rds")

#stopping server
rd[["server"]]$stop()

link_urls <- readRDS("yek_links.rds")
links_name <- readRDS("yek_names.rds")

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

##note that there are no vibids here

check <- mapply(api.caller, roots = duma_api$roots, vrns = duma_api$vrns, 
                tvds = duma_api$tvds, vibids = "", type = duma_api$types,
                filenames = majvote_filenames, 
                api_link = "http://www.nnov.vybory.izbirkom.ru/")

#getting party list vote
dir.create("Duma 2003/partyvote")

#getting links
dist_partyvote_links <- sapply(X = tik_links, safe.direct.link.extractor,
                               node = "tr:nth-child(15) a")

#creating filenames
numbers <- 1:length(dist_partyvote_links)
partyvote_filenames <- paste0("./Duma 2003/partyvote/result", numbers, ".xls")

#call
api_variables <- api.extracting(dist_partyvote_links)

#these do have vibids
check <- mapply(api.caller, roots = api_variables$roots, vrns = api_variables$vrns, 
                tvds = api_variables$tvds, vibids = api_variables$vibids, type = api_variables$types,
                filenames = partyvote_filenames, 
                api_link = "http://www.nnov.vybory.izbirkom.ru/")

##ALL OTHER ELECTIONS-----------------------------------------------------------
##6th city duma includes at large vote, but it's reported as its own "region" -
# regular scraper should work

#removing the duma 2003 and last election, as it won't happen until Sep 2018
link_urls <- link_urls[-c(1,18)]

check <- sapply(X = link_urls, FUN = russian.election.scraping,
                api_link = "http://www.sverdlovsk.vybory.izbirkom.ru/",
                encoding = "windows-1251")
##failed at head of city elections
##decided to skip this election because it is also formatted differently - will
## scrape seperately
check <- sapply(X = link_urls[7:16], FUN = russian.election.scraping,
                api_link = "http://www.sverdlovsk.vybory.izbirkom.ru/",
                encoding = "windows-1251")
#failed again at presidential election
check <- sapply(X = link_urls[16], FUN = russian.election.scraping,
                api_link = "http://www.sverdlovsk.vybory.izbirkom.ru/",
                encoding = "windows-1251")

