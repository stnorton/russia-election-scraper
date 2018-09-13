# russia-election-scraper
Scraper for Russian election data at the poll level

Last update: 13 September 2018

This scraper is designed to pull Russian election data at the poll level from any Russian regional election commission website. It is still under active development, with the end goal being an R package.

The functions for scraping are in the file "ruselecscraper.R"

The file "yekatarinburgscrape.R" is an example of this scraper in use. Note that this is based on an earlier version of the scraper, and there is no longer any need to provide an `api_link` argument.

Please feel free to use this code, but I take no responsibility for your use of it and provide no guarantee that it will work. 
Feel free to submit bug fixes/improvements as well.

# Using the Scraper

The basic work flow for scraping is as follows:
1. Ensure R locale is configured for Russian if you are using windows.
2. Use RSelenium (or rvest in session mode) to navigate the search boxes on the site and pull the links to the desired election. See example code to see this in action.
3. Pull out mixed elections - these will need to be scraped with seperate functions.
4. Remove problematic elections from list of links, scrape them seperately if desired (see example code).
	* I reccomend using lapply() with the safe scraping functions - if the scraping fails, it will reutrn a null list entry corresponding to the index for the link at which it failed
5. If candidate data is desired, use the candidate scraper
6. There is a beta turnout scraping function; turnout is not avaiable for all elections (seems to be available for all federal elections) and I have not yet written an error handler to skip elections for which turnout is unavailable (9/5/18) 
7. Clean data and analyze away!

# Mixed elections
*NB: This is still in beta. Due to idiosyncratic formatting, this code is very buggy (as of 9/13) and will likely require modification on your end.*
The suite of functions includes a function called `mixed.election.scraping`.
This function will scrape mixed elections, and create a folder structure that seperates the majoritarian and party vote.
Majority vote will be in a folder named `majvote` and party list vote in `partyvote`.




# Crediting the Author

I would appreciate a citation or acknowledgement if this scraper is used to produce any published work.

Contact details:
* Sean Norton
* UNC - Chapel Hill; Department of Political Science
* stnorton (at) live.unc.edu

# Reporting bugs, suggesting improvements, etc.

Please report any bugs and suggested fixes in the "Issues" tab. Feel free to clone the repo and make improvements. Please contact me with any significant improvements, as I would like to update the scraper.

# Known bugs (as of 9/5/2018)

* When a `vibid` isn't present in a url, the function `api.extracting` returns the entire url. I am working on a way to recognize this and drop vibid from the result.
* When there is no data for an election, the scraper cannot recognize this and crashes when it reaches the `api.caller` function.
* `httr::GET()` very occassionally fails to load all the functions associated with `GET()`, namely `verbose()`. This appears to be a bug with R that may not be fixable from my end.  `library(httr)` would resolve the issue. I do not use this in my code becuase it creates conflicts with other packages that I use.
