# russia-election-scraper
Scraper for Russian election data at the poll level

Last update: 25 June 2018

This scraper is designed to pull Russian election data at the poll level from any Russian regional election commission website.

The functions for scraping are in the file "ruselecscraper.R"

The file "yekatarinburgscrape.R" is an example of this scraper in use.

Please feel free to use this code, but I take no responsibility for your use of it and provide no guarantee that it will work. 
Feel free to submit bug fixes/improvements as well.

#Using the Scraper

The basic work flow for scraping is as follows:
1. Ensure R locale is configured for Russian if you are using windows.
2. Use RSelenium (or rvest in session mode) to navigate the search boxes on the site and pull the links to the desired election. See example code to see this in action.
3. Determine if any election pages are idiosyncratically formatted (see Problems with Certain Elections)
4. Remove problematic elections from list of links, scrape them seperately if desired (see example code).
5. If candidate data is desired, use the candidate scraper
6. Clean data and analyze away!

#Problems with Certain Elections

Unfortunately, the Russian Central Election Commission does not standardize how the regions present results.
The code can handle some of these issues so long as there is only one set of results for each district. 
However, there are still issues with certain types of elections:
* Any election with a mixed election system. The 2003 Federal Duma elections are a prominent example, but some city councils use this system as well.
* Certain cities report mayoral elections directly at the precinct level. This is only an issue if you want to avoid having a seperate spreadsheet for each polling station.
* Any election where the table of disaggregated results is not reffered to using "Сводная таблица".
See the example code for a work-around for Duma 2003 elections. Code can easily be modified to select different nodes if the formatting is idiosyncratic.


#Crediting the Author

No citation is necessary for use of the scraper (though you are free to cite me if you wish!). I would appreciate an acknowledgement.

Contact details:
* Sean Norton
* UNC - Chapel Hill; Department of Political Science
* stnorton (at) live.unc.edu


