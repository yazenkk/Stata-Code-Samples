// Data Quality Checks and Cleaning
// Yazen Kashlan

/*
This script imports survey results from a randomized evaluation.
This script is divided into the following 2 sections:
	1) Quality Checks
	2) Cleaning
*/


// setup workspace ==========================================================
pwd // check current directory
cd "~\documents"

// My Stata is running in the cloud so I direct package installation to
// a local forlder that I create: "~\user\Documents\StataPackages"
sysdir set PLUS ~\Documents\StataPackages
ssc install estout


// Section 1 - Quality Checks ===============================================
// Import data
use "Data\Main Dataset.dta", clear
duplicates report uniqueid // no duplicates in final dataset

// 1a) Survey Time Statistics -----------------------------------------------
// I calculate the average and median values of time spent surveying,
// considering only completed surveys

desc // Inspect variables visually. Variables well-labelled
// search for variables directly related to "time" and "survey"
lookfor time // survettime and surveytime2 seem relevant
lookfor survey // use survey_complete as condition

// Prepare a clean table of summary statistics
// I quietly run a conditional tabstat command and print it using esttab.
// Note that I ignore time spent on the second survey since the average 
// time spent there is around 1% of the time spent on the main survey
quietly estpost tabstat surveytime if survey_complete==1, ///
  statistics(mean p50) col(stat)
esttab, cell("mean(fmt(%9.2f) label(Mean)) p50(fmt(%9.2f) label(Median))") ///
  label noobs nonumber nomtitle varwidth(30)
/*
Resources Used
 -tabstat-        at -help tabstat-
 -esttab/estpost- at REPEC webpage:
                     http://repec.org/bocode/e/estout/estpost.html
*/


// 1b) Survey Time per Surveyor ----------------------------------------------
// I now compute the average time spent surveying per surveyor

// I first tabulate the surveyor variable to better understand it
tab surveyor, missing // include missing values in case

// I tabulate average survey time per surveyor
tabstat surveytime if survey_complete==1, by(surveyor)
// average survey time does not appear to vary much between surveyors

// 1c) hhid Duplicates Report -----------------------------------------------
// I explore the uniqueness of the household ID variables

duplicates report hhid // hhid variable is not unique. 3 duplicate hhids
duplicates list hhid   // duplicated hhids: 1802011 1807077 1813023

/*
Duplicate IDs can be problematic when working with cross-sectional data.
In such a case, I would explore duplication across other variables.
If all the variables for a single observation are duplicated, it would be
safe to drop that duplicate record.

Alternatively, in a panel dataset, where IDs reappear at different points in
time, duplicate IDs are essential for tracking unique IDs over time.

In our case, our observations are individual people and hhid likely refers 
to household ID. If our measurement is the individual-level rather than 
the household-level as uniqueID suggests, then duplicated household IDs are 
expected where respondents share a living space. This duplication is not 
problematic. It may actually enrich the analysis.

To confirm that duplicate hhids are not problematic, I report duplicates in 
terms of all variables.
*/

duplicates report
//There are no duplicates across all variables.


// Section 2 - Cleaning =====================================================

// 2a) Encode Surveyor Names ------------------------------------------------
// I anonymize personally identifiable information by replacing 
// surveyor names with corresponding numbers

desc surveyor // note that surveyor is in string format
// to convert variable from string to numeric, use encode 
encode surveyor, generate(surveyorID)
// to drop original string from new variable labels, use _strip_labels command
_strip_labels surveyorID
drop surveyor // drop old variable
rename surveyorID surveyor // rename surveyor
/*
Resources Used
 -_strip_labels- at -help _strip_labels-
*/

// 2b) Reassign Missing Values ----------------------------------------------
// I use missing value codes to recode missing values in the dataset

// tabulate variables of interest to understand their structure
tab burglaryyn, missing
tab vandalismyn, missing
tab trespassingyn, missing

// run for loop to recode missing values in variables of interest
foreach var in burglaryyn vandalismyn trespassingyn{
  replace `var' = .d if `var' == -999
  replace `var' = .r if `var' == -997
  replace `var' = .b if `var' == -777
  replace `var' = .n if `var' == -555
}
/*
Resources Used
 -foreach- at Analysis Factor webpage:
           https://www.theanalysisfactor.com/loops-in-stata-making-coding-easy/
*/

//confirm reassignments
tab burglaryyn, missing
tab vandalismyn, missing
tab trespassingyn, missing




