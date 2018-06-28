##SCRAPER
##This set of functions is designed to scrape Russian election data from
#links to the election results
##The links themselves can be scraped using RSelenium

##base_link refers to the link to the specific election that will be scraped
##api_link is the root domain for the region being scraped
##e.g. http://www.yaroslavl.vybory.izbirkom.ru/
##THIS SHOULD END IN A SLASH

##All directories created will be created in your wd - if you want files saved
  ##to a specific folder, run the scraper in that folder

##If filenames are gibberish, pass an encoding argument. Default is UTF-8,
  ## so if that isn't working, a safe bet is windows-1251
  # (argument is formatted as encoding = "windows-1251")

##If results are still gibberish and you're running a Windows machine:
  ##follow instructions for changing language for non-unicode programs
  ##at a minimum, change this location to Russian
  ## as of 20.6.18 if your Windows 10 is up-to-date, there is a beta option
  ## to use UTF-8; check this as well

##These functions depend on rvest

##adverb to handle transient errors
Safely <- function(fn, ..., max_attempts = 5) { 
  ##make sure S is capitalized if you will load purr, or there will be a conflict
  function(...) {
    this_env <- environment()
    for(i in seq_len(max_attempts)) {
      ok <- tryCatch({
        assign("result", fn(...), envir = this_env)
        TRUE
      },
      error = function(e) {
        FALSE
      }
      )
      if(ok) {
        return(this_env$result)
      }
    }
    msg <- sprintf(
      "%s failed after %d tries; returning NULL.",
      deparse(match.call()),
      max_attempts
    )
    warning(msg)
    NULL
  }
}


##VOTE DATA---------------------------------------------------------------------
dist.link.extracting <- function(link, ...){ #... allows you to pass encoding
  
  Sys.sleep(5) #no DDoS appearance
  
  link <- read_html(link, ...)
  links <- link %>%
    html_nodes(css = "select > option") %>%
    html_attr("value")
  links <- links[-which(is.na(links))]
  return(links)
}

safe.dist.link.extracting <- Safely(dist.link.extracting)


api.extracting <- function(links){
  
  roots <- sub(".*root=([0-9]*)&.*","\\1", links, perl = TRUE)
  vrns <- sub(".*vrn=([0-9]*)&.*","\\1", links, perl = TRUE)
  tvds <- sub(".*&tvd=([0-9]*)&.*","\\1", links, perl = TRUE)
  vibids <- sub(".*&vibid=([0-9]*)&.*","\\1", links, perl = TRUE)
  types <- sub(".*&type=([0-9]*).*", "\\1", links, perl = TRUE)
  global <- sub(".*global=([a-z0-9]*)&.*","\\1", links, perl = TRUE)
  region <- sub(".*&region=([0-9]*).*", "\\1", links, perl = TRUE)
  sub_region <- sub(".*&sub_region=([0-9]*).*", "\\1", links, perl = TRUE)
  
  return(list(roots = roots,vrns = vrns,tvds = tvds, vibids = vibids, types = types,
              global = global, region = region, sub_region = sub_region))
  
}

api.caller <- function(roots, vrns, tvds, vibids, type, global, region, sub_region,
                       filenames, api_link){
  
  stopifnot(is.character(filenames), is.character(type), is.character(api_link))
  
  api_url <- paste0(api_link, "servlet/ExcelReportVersion")
  
  Sys.sleep(5)
  
  httr::GET(
    url = api_url,
    query = list(
      region = region,
      sub_region=sub_region,
      root=roots,
      global=global,
      vrn=vrns,
      tvd=tvds,
      type=type,
      vibid=vibids,
      condition="",
      action="show",
      version="null",
      prver="0",
      sortorder="0"
    ),
    write_disk(filenames), ## CHANGE ME
    verbose()
  ) -> res
}

result.link.extracting <- function(link,...){
  #extracting links to results - exploits fact that last link is always the
  #one that i need
  Sys.sleep(1)
  
  link <- read_html(link,...)
  
  link_vec <- link %>% html_nodes(xpath = "//a") %>% html_text()
  link_index <- length(link_vec)
  
  xpath <- paste0("(//a)", "[", link_index, "]")
  
  result <- link %>% html_nodes(xpath = xpath) %>% html_attr("href")
  
  return(result)
  
}

safe.result.link.extracting <- Safely(result.link.extracting)

dir.name.generating <- function(filename){
  if(!dir.exists(filename)){return(filename)}
  i=1
  repeat {
    f = paste(filename,i,sep=" ")
    if(!dir.exists(f)){return(f)}
    i=i+1
  }
}


russian.election.scraping <- function(base_link, api_link, ...){
  
  Sys.sleep(5)
  
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
  
  if(nchar(name) > 68){
    name <- substring(name, first = 1, last = 68)
  }
  
  
  name <- dir.name.generating(name)
  
  dir.create(path = name)
  
  #extracting links to districts
  
  dist_links <- safe.dist.link.extracting(base_link)
  
  #extracting the result links
  result_links <- sapply(X = dist_links, FUN = safe.result.link.extracting)
  
  #extracting api variables from results
  api_variables <- api.extracting(result_links)
  
  #creating filenames
  numbers <- 1: length(result_links)
  filenames <- paste0("./", name, "/", "result", numbers, ".xls")
  
  #running the api call
  
  res <- mapply(api.caller, roots = api_variables$roots,
                vrns = api_variables$vrns,
                tvds = api_variables$tvds,
                vibids = api_variables$vibids,
                type = api_variables$types,
                global = api_variables$global,
                region = api_variables$region,
                sub_region = api_variables$sub_region,
                filenames =  filenames,
                api_link = api_link)
  
  
  return(res)
  
}

##for elections with mixed systems - use node argument to select which set of 
#results you want

direct.link.extractor <- function(link, node){
  
  Sys.sleep(1)
  
  vote_link <- read_html(link) %>%
    html_node(css = node) %>%
    html_attr("href")
}

safe.direct.link.extractor <- Safely(direct.link.extractor)

##CANDIDATE DATA----------------------------------------------------------------

candidate.link.extractor <- function(link, ...){
  
  Sys.sleep(2)
  
  #reading in website
  link <- read_html(link, ...)
  
  names <- link %>%
    html_nodes("a") %>%
    html_text()
  
  candidate_ind <- grep(names, 
                        pattern = "Сведения .* кандидат")
  
  
  ##for mixed elections - select only single mandate link
  if(length(candidate_ind) == 2){
    candidate_ind <- grep(names, 
                          pattern = "Сведения .* по одномандат")}
  
  ##once the candidate financial disclosures kick in, things get more complicated
  if(length(candidate_ind) > 2){
    candidate_ind <- grep(names,
                          pattern = "Сведения .* кандидат.* в")}
  
  ##if list was used to start expression instead
  if(length(candidate_ind) == 0){
    candidate_ind <- grep(names,
                          pattern = "Список .* кандидат")}
  
  ##if na was used instead of v
  if(length(candidate_ind) == 0){
    candidate_ind <- grep(names,
                          pattern = "Сведения .* кандидат.* на")
  }
  
  #creating xpath to extract link
  xpath <- paste0("(//a)", "[", candidate_ind, "]")
  
  res <- link %>% html_node(xpath = xpath) %>% html_attr("href")
  
  return(res)
}

safe.candidate.link.extractor <- Safely(candidate.link.extractor)

##function to generate file names
file.name.generating <- function(filename){
  test_name <- paste0(filename, ".xls")
  
  if(!file.exists(test_name)){return(filename)}
  i<-1
  repeat {
    f <- paste(filename,i,sep=" ")
    testf <- paste0(f, ".xls")
    if(!file.exists(testf)){return(f)}
    i<-i+1
  }
}



candidate.scraper <- function(base_link, api_link, ...){ ##... is to pass encoding

  #safety check
  library(rvest)
  stopifnot(is.character(base_link))
  stopifnot(is.character(api_link))
  
  ##reading in page
  base_page <- read_html(base_link, ...)
  
  name <- base_page %>%
    html_node(css = ".w2 .headers") %>%
    html_text()
  
  if(name == "Сведения о выборах"){
    name <- base_page %>%
      html_node(css = ".w2:nth-child(2) b") %>%
      html_text()
  }
  
  if(nchar(name) > 68){
    name <- substring(name, first = 1, last = 68)
  }
  
  name <- paste("candidates", name, sep = " ")
  
  name <- file.name.generating(name)
  
  filename <- paste0(name, ".xls")
  
  #getting link
  candidate_link <- safe.candidate.link.extractor(base_link, ...)
  
  #api variables
  api_variables <- api.extracting(candidate_link)
  
  check <- api.caller(roots = api_variables$roots,
                      vrns = api_variables$vrns,
                      tvds = api_variables$tvds,
                      vibids = api_variables$vibids,
                      type = api_variables$types,
                      global = api_variables$global,
                      region = api_variables$region,
                      sub_region = api_variables$sub_region,
                      filenames = filename,
                      api_link = api_link)
  
}

