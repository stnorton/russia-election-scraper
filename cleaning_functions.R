##########################
## CLEANER FUNCTIONS    ##
## SEAN NORTON          ##
## LAST UPDATE: 12/2018 ##
##########################

#These functions clean data from my Russian election webscraper
#Please note that due to inconsistent formatting, I cannot guarantee that this
#will work on any given election - you may have to add if statements to fit
#the particular quirks of your elections

#vote.cleaning returns vote data, aggregated at the level you downloaded it at
#if you're using the scraper as-is, this is probably the municipal district level
#vote.file.cleaning is an internal function to vote.cleaning - I have included it
#otuside of the vote.cleaning function body to make it more modular

#candidate.cleaning cleans candidate data, which is generally at the election level

##VOTE--------------------------------------------------------------------------

vote.cleaning <- function(vote_folder){
  
  library(readxl)
  
  #listing all spreadsheets
  vote_files <- list.files(vote_folder, full.names = T)
  
  if(vote_files[1] == paste0(vote_folder,"/", 'majvote')){
    
    maj_path <- vote_files[1]
    maj_vote <- list.files(maj_path, full.names = T)
    
    party_path <- vote_files[2]
    party_vote <- list.files(party_path, full.names = T)
    
    vote_files <- c(maj_vote, party_vote)
  }
  
  #lappyling
  res <- lapply(X = vote_files, FUN = vote.file.cleaner)
  
  return(res)
  
}

#function to clean a single spreadsheet

vote.file.cleaner <- function(sheet){
  
  sheet_name <- sheet #for error handling
  
  
  sheet <- read_xls(sheet, col_names = T)
  
  #error handling for sheets that are blank due to results not being reported
  
  if(nrow(sheet) <= 8){
    return(NA)
  } 
  
  #drop all rows for which first column is NA
  
  na_rows <- which(is.na(sheet[ , 1]))
  sheet <- sheet[-na_rows, ]
  
  #pulling election name
  
  elec_name <- as.character(colnames(sheet)[1])
  
  
  #pulling election date
  
  elec_date_row <- grep(x = sheet[ ,1, drop = T], 
                        pattern = "дата",
                        ignore.case = T)
  
  if(length(elec_date_row) == 0){
    elec_date <- NA
  } else {
    elec_date <- as.character(sheet[elec_date_row, 1])
  }
  
  #pulling election disctrict
  elec_dist_row <- grep(x = sheet[ ,1, drop = T],
                        pattern = 'Наименование',
                        ignore.case = T)
  if(length(elec_dist_row) == 0){
    elec_dist <- NA
  } else {
    elec_dist <- as.character(sheet[elec_dist_row, 1])
  }
  
  
  #pulling registered voters
  
  reg_voters_row <- grep(x = sheet[ ,2, drop = T],
                         pattern = "Число избирателей.*включенных",
                         ignore.case = T)
  
  if(length(reg_voters_row) == 0){
    reg_voters_row <- grep(x = sheet[ ,2, drop = T],
                           pattern = "Число избирателей.*внесенных",
                           ignore.case = T)
  }
  
  if(length(reg_voters_row) == 0){
    reg_voters_row <- grep(x = sheet[ ,2, drop = T],
                           pattern = "Число избирателей.*внесённых",
                           ignore.case = T)
  }
  
  reg_voters <- as.numeric(sheet[reg_voters_row, 3])
  
  if(is.na(reg_voters)){
    stop(print(paste0(sheet_name, "has an error with reg_voters; doublecheck")))
  }
  
  
  #pulling invalid votes
  
  invalid_row <- grep(x = sheet[ ,2, drop = T],
                      pattern = "Число недействительных",
                      ignore.case = T)
  invalid_votes <- as.numeric(sheet[invalid_row, 3])
  
  if(is.na(invalid_votes)== T|length(invalid_row) !=1){
    stop(print(paste0(sheet_name, "has an error with invalid_votes; doublecheck")))
  }
  
  
  #pulling valid votes
  
  valid_row <- grep(x = sheet[ ,2, drop = T],
                    pattern = "Число действительных",
                    ignore.case = T)
  valid_votes <- as.numeric(sheet[valid_row, 3])
  
  if(is.na(valid_votes)|length(valid_row)!= 1){
    stop(print(paste0(sheet_name, "has an error with invalid_votes; doublecheck")))
  }
  
  #pulling only candidate data, with votes
  
  last_info_row <- grep(x = sheet[ , 2, drop = T],
                        pattern = "не учтенных при получении",
                        ignore.case = T)
  
  if (length(last_info_row)==0){
    last_info_row <- grep(x = sheet[ , 1, drop = T],
                          pattern = "Число голосов избирателей",
                          ignore.case = T)
  }
  
  if (length(last_info_row)==0){
    last_info_row <- grep(x = sheet[ , 2, drop = T],
                          pattern = "неучтенных",
                          ignore.case = T)
  }
  
  if (length(last_info_row)==0){
    last_info_row <- grep(x = sheet[ , 2, drop = T],
                          pattern = "не учтенных",
                          ignore.case = T)
  }
  
  
  
  if(length(last_info_row) != 1){
    last <- length(last_info_row)
    last_info_row <- last_info_row[last]
  }
  
  if(is.na(last_info_row)){
    stop(print(paste0(sheet_name, "has an error with last_info_row; doublecheck")))
  }
  
  final_candidate_row = grep(x = sheet[ ,1, drop = T],
                             pattern = 'Данные территориальной избирательной комиссии о числе открепительных удостоверений',
                             ignore.case = T)
  if(length(final_candidate_row) == 0){
    final_candidate_row = grep(x = sheet[ ,2, drop = T],
                               pattern = "Число открепительных удостоверений, полученных территориальной избирательной комиссией",
                               ignore.case = T)
  }
  
  
  candidate_start <- last_info_row + 1
  end <- nrow(sheet)
  
  if(length(final_candidate_row) != 0){
    end <- final_candidate_row -1}
  
  candidate_data <- sheet[candidate_start:end, 2:3] ##NB: this is a test line may need to change back to [,-1]
  
  #merging data back in
  
  candidate_data$elec_name <- elec_name
  candidate_data$elec_date <- elec_date
  candidate_data$reg_voters <- reg_voters
  candidate_data$valid <- valid_votes
  candidate_data$invalid <- invalid_votes
  candidate_data$district <- elec_dist
  
  #returning
  
  return(candidate_data)
  
}

##CANDIDATE---------------------------------------------------------------------

candidate.cleaner <- function(filename){
  
  #this function cleans candidate data spreadsheets into an R dataframe
  
  #dependency check
  library(readxl)
  
  #read in
  tryCatch(
    {cand_df <- read_xls(filename, col_names = F)},
    error = function (e){
      print(paste(filename, "cannot be opened; corrupted or does not exist"))
    })
  
  #storing election name for later matching
  election_name <- as.character(cand_df[1,1])
  
  #finding start of non-junk rows
  start_row <- grep(x = cand_df[ , 1, drop = T], pattern = "ФИО" )[1]
  name_col <- 1
  
  if(is.na(start_row)){
    start_row <- grep(x = cand_df[ , 2, drop = T], pattern = "ФИО" )[1]
    name_col <- 2
  }
  
  #removing junk rows - this wrapped in a tryCatch in case something goes wrong
  tryCatch({
    
    cand_df <- cand_df[-c(1:start_row-1), ]
    
    
    #colnames
    colnames(cand_df) <- cand_df[1, ]
    
    #remove junk cols - requires finding the column with party name, which is not
    # standard
    party_col <- grep(x = colnames(cand_df), pattern = "Субъект выдвижения",
                      ignore.case = T)
    if(length(party_col) == 0){
      party_col <- grep(x = colnames(cand_df), pattern = "партия",
                        ignore.case = T)
    }
    
    #removing colnames row
    cand_df <- cand_df[-1, ]
    
    #removing unneeded columns
    cand_df <- cand_df[ , c(name_col, party_col)]
    
    #colnames
    colnames(cand_df) <- c("name", "party")
    
    #removing all NA rows (hopefully just an artifact of the dataframe)
    na_rows <- which(is.na(cand_df$name) & is.na(cand_df$party))
    if(length(na_rows) != 0){
      cand_df <- cand_df[-na_rows, ]
    }
    
    
    #adding election name
    cand_df$election <- rep(election_name, nrow(cand_df))
    
    #return value
    
    return(cand_df)},
    error = function(e){
      print(paste(filename, "is not standard formatting; cannot be cleaned"))
    })
}