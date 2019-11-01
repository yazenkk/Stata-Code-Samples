// Stata Data Analysis Exercise
// Yazen Kashlan

/*
This script is divided into the following 3 sections:
	0) Explore and merge datasets
	1) Describe infant mortality data
	2) Story: infant mortality analysis
*/


// setup workspace ==========================================================
pwd // check current directory
cd "~\documents"

// My Stata runs in the cloud so I direct package installation to
// a local folder: "~\user\Documents\StataPackages"
sysdir set PLUS ~\Documents\StataPackages
ssc install outreg2
ssc install balancetable



// Section 0 - Explore and Merge Datasets ===================================

// Household Data
// This dataset contains general information about the
// household’s characteristics and the date of the survey
use "Data\household-13.dta", clear
br
desc
sum //summarize household data

// Deceased Data
// This dataset contains information on the children
// (born to mothers in the household) that have died.
use "Data\deceased-13.dta", clear
br
desc
sum // note sex variable coded 1 for boy and 3 for girl
duplicates report id_household //210 deaths in same household

// generate variable for age at death
generate days_per_lived_unit = 1/1440 if lived_unit == 1 // 1/24/60 day/min
replace  days_per_lived_unit = 1/24 if lived_unit == 2   // 1/24    day/hour
replace  days_per_lived_unit = 1 if lived_unit == 3      // 1/1     day/day
replace  days_per_lived_unit = 30 if lived_unit == 4     // 30      day/mnth
replace  days_per_lived_unit = 365 if lived_unit == 5    // 365     day/yr
gen age_at_death_days = lived*days_per_lived_unit // compute age in days
gen age_at_death_years = age_at_death_days/365 // ~365 days/yr
* hist age_at_death_years

tostring id_household, replace // convert hhid to string for merge

// merge children data:household data  (many children:one household)
merge m:1 id_household using "Data\household-13.dta", keep(match)
// 12,700 matched. Ignored rest because I look at HH data



// Section 1 - Describe child mortality at household level ==================
// I describe the households with children that have died within 
// 28 days of birth vs those that died with 1 year of birth

// create binary variable for early vs late death (28 days vs 1 yr)
gen early_death = 1 if age_at_death_days <= 28
replace early_death  = 0 if age_at_death_days > 28 & age_at_death_days <= 365

// label early death variable and values
label variable early_death "Died w/n 28 days vs 1 yr"
label define early_death_names 0 "late death" 1 "early death" 
label values early_death early_death_names

// reassign gender variable for easier interpretation
gen female = 1 if sex_deceased == 3
replace female = 0 if sex_deceased == 1

// to understand region effects, I encode province and district names
drop province_id // drop the old ID variable
encode province, gen(province_id) // generate a labelled alternative
label variable province_id "Province ID"
drop district_id // drop the old ID variable
encode district, gen(district_id) // generate a labelled alternative
label variable district_id "District ID"

//generate dummy variables for summary stats table
tab wall, generate(wall_type_)
tab roof, generate(roof_type_)
tab floor , generate(floor_type_)
tab latrine, gen(latrine_type_)
tab drinking_water, gen (water_type_)
tab ethnicity, gen (ethnicity_type_)
tab province_id, gen(province_name_)

// create balance table
balancetable early_death  ///
  month_birth_deceased year_birth_deceased female hh_size ///
  new_members new_members_number deaths deaths_number insurance ///
  wall_type_1 wall_type_5 roof_type_2 roof_type_6 ///
  floor_type_1 floor_type_6 latrine_type_1 latrine_type_3 ///
  water_type_2 water_type_3 province_name_1 province_name_2 ///
  province_name_3 province_name_4 province_name_5 ///
  using "BalanceTable.xlsx", observationscolumn ///
  ctitles("Late Death" "Early Death" "Difference" "N") ///
  varlabels replace


// Section 2 - Describe child mortality at household level ==================
// I explore how household characteristics might affect
// early death rates in the household.
// I use the logit model because my outcome variable is binary
// Standard OLS would yield unreasonable outcomes outside the [0,1] range

logit early_death i.province_id, or
outreg2 using "logit_reg.xls", replace // output reg results into MS Excel
estat classification // run estat to understand classification accuracies

logit early_death i.province_id i.latrine , or
outreg2 using "logit_reg.xls"
estat classification

logit early_death i.province_id hh_size deaths, or
outreg2 using "logit_reg.xls"
estat classification

logit early_death i.province_id hh_size deaths_number, or
outreg2 using "logit_reg.xls"
estat classification

logit early_death i.province_id hh_size deaths_number deaths, or
outreg2 using "logit_reg.xls"
estat classification














