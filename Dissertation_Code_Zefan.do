/* Append bank level data across periods */
foreach num of numlist 1/64 {
	import delimited using "C:\Users\zefan\Desktop\data\data_`num'.csv", rowrange(9:) varnames(9)
	gen time = `num'
	tempfile data`num'
	save `data`num''
	clear
}

use `data1', clear

foreach num of numlist 2/64 {
	append using `data`num''
}

tempfile data_bank
save `data_bank'
clear

/* Merge federal funds rate into bank data */
import delimited using "C:\Users\zefan\Desktop\data\fedfunds.csv", rowrange(572:) varnames(1)
gen mydate = date(date, "YMD")
format mydate %td
gen month = month(mydate)
keep if inlist(month, 1, 4, 7, 10)
sort mydate
gen time = _n
keep time fedfunds
tempfile fedfunds
save `fedfunds'
clear

use `data_bank'
merge m:1 time using `fedfunds'
drop _merge
save `data_bank', replace
clear

/* Merge real & nominal gdp into bank data */
import delimited using "C:\Users\zefan\Desktop\data\real_gdp.csv", rowrange(222:) varnames(1)
gen time = _n
keep time gdpc1
tempfile real_gdp
save `real_gdp'
clear

use `data_bank'
merge m:1 time using `real_gdp'
drop _merge
save `data_bank', replace
clear

import delimited using "C:\Users\zefan\Desktop\data\gdp.csv", rowrange(222:) varnames(1)
gen time = _n
keep time gdp
tempfile gdp
save `gdp'
clear

use `data_bank'
merge m:1 time using `gdp'
drop _merge
save `data_bank', replace
clear

/* Merge unemployment rate into bank data */
import delimited using "C:\Users\zefan\Desktop\data\unemployment_rate.csv", rowrange(650:) varnames(1)
gen mydate = date(date, "YMD")
format mydate %td
gen month = month(mydate)
keep if inlist(month, 1, 4, 7, 10)
sort mydate
gen time = _n
keep time unrate
tempfile unemployment
save `unemployment'
clear

use `data_bank'
merge m:1 time using `unemployment'
drop _merge
save `data_bank', replace
clear

/* Merge state level person income into bank data */
import delimited using "C:\Users\zefan\Desktop\data\state_personal_income.csv", rowrange(5:65) varnames(5)
drop q1 q2 q3
replace geoname = "Alaska" if geoname == "Alaska*"
replace geoname = "Hawaii" if geoname == "Hawaii*"
statastates, name(geoname)
drop if state_abbrev == ""
drop geoname geofips state_fips _merge

local i = 1
foreach v of varlist _all {
rename `v' personal_income`i'
local i = `i' + 1
}
rename personal_income65 stalp

reshape long personal_income, i(stalp) j(time)
sort stalp time
tempfile personal_income
save `personal_income'
clear

use `data_bank'
sort stalp time
merge m:1 stalp time using `personal_income'
drop _merge
save `data_bank', replace
clear

/* Merge cpi into bank data */
import delimited using "C:\Users\zefan\Desktop\data\cpi.csv", rowrange(662:) varnames(1)
gen mydate = date(date, "YMD")
format mydate %td
gen month = month(mydate)
keep if inlist(month, 1, 4, 7, 10)
sort mydate
gen time = _n
keep time cpiaucsl
tempfile cpi
save `cpi'
clear

use `data_bank'
merge m:1 time using `cpi'
drop _merge
save `data_bank', replace
clear

/* Merge bhc data into bank data */
foreach num of numlist 1/64 {
	import delimited using "C:\Users\zefan\Desktop\data\bhc\bhc`num'.txt", delimiters("^") rowrange(3:) colrange(1:300) varnames(1)
	keep rssd9001 bhck2170
	gen time = `num'
	rename rssd9001 rssdhcr
	destring, replace
	tempfile bhc`num'
	save `bhc`num''
	clear
}

use `bhc1', clear

foreach num of numlist 2/64 {
	append using `bhc`num''
}

sort rssdhcr time
tempfile data_bhc
save `data_bhc'
clear

use `data_bank'
sort rssdhcr time
merge m:1 rssdhcr time using `data_bhc'
drop if _merge == 2
drop _merge

sort cert time

xtset cert time

/* Generate log of variables and unify unit of measurement*/
/* Log of loan */
gen idlnls_1000 = idlnls*1000
gen lnloan = cond(idlnls_1000, log(idlnls_1000), 0,.)

/* Log of security */
gen sc_1000 = sc*1000
gen lnsc = cond(sc_1000, log(sc_1000), 0,.)

/* Log of real gdp */
gen gdpc1_billion = gdpc1*1000000000
gen lngdp = cond(gdpc1_billion, log(gdpc1_billion), 0,.)

/* Log of common stocks */
gen eqcs_1000 = eqcs*1000
gen lncs = cond(eqcs_1000, log(eqcs_1000), 0,.)

/* Log of state personal income */
gen personal_income_1000 = personal_income*1000
gen personal_income_1000_real = (personal_income_1000/cpiaucsl)*100
gen lnpi = cond(personal_income_1000_real, log(personal_income_1000_real), 0,.)

/* Growth rate of retained earnings */
gen grre = 100*(equptot - l.equptot)/l.equptot

/* Generate other variables */
/* Size: log of asset */
gen asset_1000 = asset*1000
gen lnasset = cond(asset_1000, log(asset_1000), 0,.)

/* Liquidity ratio: (cash + securities)/total assets */
gen lr = 100*(chbal + sc)/asset

/* Inflation: (cpi - cpi(-1))/cpi(-1) */
gen inf = 100*(cpiaucsl - l.cpiaucsl)/l.cpiaucsl

/* Profitability: (income of domestic office loans + leases)/total assets */
gen profit = 100*ilndom/asset /* lots of missing value in leases, might need to get rid of ils*/

/* Net charge-offs/total assets */
gen chr = 100*ntlnls/asset

/* Credit risks, non-performing loans: (past due 30-89 + past due 90+ + nonaccrual)/asset */
gen npl = 100*(p3asset + p9asset + naasset)/asset

/* Higher quality risk-based capital ratio */
gen cet1 = 100*(rbct1j - eqpp)/rwajt

/* Dummy variable for break 2009, the end of 2008 */
gen yd09 = 0
replace yd09 = 1 if t > 29

/* Dummy variable for break 2013, the end of 2012 */
gen yd13 = 0
replace yd13 = 1 if t > 45

/* Dummy variable for quarter */
gen q1 = (time == 2 | time == 6 | time == 10 | time == 14 | time == 18 | time == 22 | time == 26 | time == 30 | time == 34 | time == 38 | time == 42 | time == 46 | time == 50 | time == 54 | time == 58 | time == 62)
gen q2 = (time == 3 | time == 7 | time == 11 | time == 15 | time == 19 | time == 23 | time == 27 | time == 31 | time == 35 | time == 39 | time == 43 | time == 47 | time == 51 | time == 55 | time == 59 | time == 63)
gen q3 = (time == 4 | time == 8 | time == 12 | time == 16 | time == 20 | time == 24 | time == 28 | time == 32 | time == 36 | time == 40 | time == 44 | time == 48 | time == 52 | time == 56 | time == 60 | time == 64)
gen q4 = (time == 1 | time == 5 | time == 9  | time == 13 | time == 17 | time == 21 | time == 25 | time == 29 | time == 33 | time == 37 | time == 41 | time == 45 | time == 49 | time == 53 | time == 57 | time == 61)

/* Dummy variable for Stress Tests for the supervised largest banks */
gen stress = 0

/* 2017 */
replace stress = 1 if rssdhcr == 1562859 & (time == 64 | time == 63 | time == 62) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 64 | time == 63 | time == 62) /* American Express */
replace stress = 1 if rssdhcr == 1231968 & (time == 64 | time == 63 | time == 62) /* BancWest, BNP Paribas */
replace stress = 1 if rssdhcr == 1073757 & (time == 64 | time == 63 | time == 62) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 64 | time == 63 | time == 62) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 64 | time == 63 | time == 62) /* BB&T */
replace stress = 1 if rssdhcr == 1391237 & (time == 64 | time == 63 | time == 62) /* BBVA Compass */
replace stress = 1 if rssdhcr == 1231333 & (time == 64 | time == 63 | time == 62) /* BMO Financial */
replace stress = 1 if rssdhcr == 2277860 & (time == 64 | time == 63 | time == 62) /* Capital One */
replace stress = 1 if rssdhcr == 1036967 & (time == 64 | time == 63 | time == 62) /* CIT Group */
replace stress = 1 if rssdhcr == 1951350 & (time == 64 | time == 63 | time == 62) /* Citigroup */
replace stress = 1 if rssdhcr == 1132449 & (time == 64 | time == 63 | time == 62) /* Citizens Financial Group */
replace stress = 1 if rssdhcr == 1199844 & (time == 64 | time == 63 | time == 62) /* Comerica Incorporated */
replace stress = 1 if rssdhcr == 1242423 & (time == 64 | time == 63 | time == 62) /* Deutsche Bank Trust */
replace stress = 1 if rssdhcr == 3846375 & (time == 64 | time == 63 | time == 62) /* Discover Financial Service */
replace stress = 1 if rssdhcr == 1070345 & (time == 64 | time == 63 | time == 62) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 64 | time == 63 | time == 62) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1857108 & (time == 64 | time == 63 | time == 62) /* HSBC North America */
replace stress = 1 if rssdhcr == 1068191 & (time == 64 | time == 63 | time == 62) /* Huntington Bancshares */
replace stress = 1 if rssdhcr == 1039502 & (time == 64 | time == 63 | time == 62) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 64 | time == 63 | time == 62) /* KeyCorp */
replace stress = 1 if rssdhcr == 1037003 & (time == 64 | time == 63 | time == 62) /* M&T Bank */
replace stress = 1 if rssdhcr == 2162966 & (time == 64 | time == 63 | time == 62) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 2961897 & (time == 64 | time == 63 | time == 62) /* MUFG Americas */
replace stress = 1 if rssdhcr == 1199611 & (time == 64 | time == 63 | time == 62) /* Northern Trust */
replace stress = 1 if rssdhcr == 1069778 & (time == 64 | time == 63 | time == 62) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 64 | time == 63 | time == 62) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1239254 & (time == 64 | time == 63 | time == 62) /* Santander Holdings */
replace stress = 1 if rssdhcr == 1111435 & (time == 64 | time == 63 | time == 62) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 64 | time == 63 | time == 62) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1238565 & (time == 64 | time == 63 | time == 62) /* TD Group */
replace stress = 1 if rssdhcr == 1119794 & (time == 64 | time == 63 | time == 62) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 1120754 & (time == 64 | time == 63 | time == 62) /* Wells Fargo & Company */
replace stress = 1 if rssdhcr == 1027004 & (time == 64 | time == 63 | time == 62) /* Zions Bancorporation */

/* 2016 */
replace stress = 1 if rssdhcr == 1562859 & (time == 61 | time == 60 | time == 59 | time == 58) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 61 | time == 60 | time == 59 | time == 58) /* American Express */
replace stress = 1 if rssdhcr == 1231968 & (time == 61 | time == 60 | time == 59 | time == 58) /* BancWest, BNP Paribas */
replace stress = 1 if rssdhcr == 1073757 & (time == 61 | time == 60 | time == 59 | time == 58) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 61 | time == 60 | time == 59 | time == 58) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 61 | time == 60 | time == 59 | time == 58) /* BB&T */
replace stress = 1 if rssdhcr == 1391237 & (time == 61 | time == 60 | time == 59 | time == 58) /* BBVA Compass */
replace stress = 1 if rssdhcr == 1231333 & (time == 61 | time == 60 | time == 59 | time == 58) /* BMO Financial */
replace stress = 1 if rssdhcr == 2277860 & (time == 61 | time == 60 | time == 59 | time == 58) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 61 | time == 60 | time == 59 | time == 58) /* Citigroup */
replace stress = 1 if rssdhcr == 1132449 & (time == 61 | time == 60 | time == 59 | time == 58) /* Citizens Financial Group */
replace stress = 1 if rssdhcr == 1199844 & (time == 61 | time == 60 | time == 59 | time == 58) /* Comerica Incorporated */
replace stress = 1 if rssdhcr == 1242423 & (time == 61 | time == 60 | time == 59 | time == 58) /* Deutsche Bank Trust */
replace stress = 1 if rssdhcr == 3846375 & (time == 61 | time == 60 | time == 59 | time == 58) /* Discover Financial Service */
replace stress = 1 if rssdhcr == 1070345 & (time == 61 | time == 60 | time == 59 | time == 58) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 61 | time == 60 | time == 59 | time == 58) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1857108 & (time == 61 | time == 60 | time == 59 | time == 58) /* HSBC North America */
replace stress = 1 if rssdhcr == 1068191 & (time == 61 | time == 60 | time == 59 | time == 58) /* Huntington Bancshares */
replace stress = 1 if rssdhcr == 1039502 & (time == 61 | time == 60 | time == 59 | time == 58) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 61 | time == 60 | time == 59 | time == 58) /* KeyCorp */
replace stress = 1 if rssdhcr == 1037003 & (time == 61 | time == 60 | time == 59 | time == 58) /* M&T Bank */
replace stress = 1 if rssdhcr == 2162966 & (time == 61 | time == 60 | time == 59 | time == 58) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 2961897 & (time == 61 | time == 60 | time == 59 | time == 58) /* MUFG Americas */
replace stress = 1 if rssdhcr == 1199611 & (time == 61 | time == 60 | time == 59 | time == 58) /* Northern Trust */
replace stress = 1 if rssdhcr == 1069778 & (time == 61 | time == 60 | time == 59 | time == 58) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 61 | time == 60 | time == 59 | time == 58) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1239254 & (time == 61 | time == 60 | time == 59 | time == 58) /* Santander Holdings */
replace stress = 1 if rssdhcr == 1111435 & (time == 61 | time == 60 | time == 59 | time == 58) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 61 | time == 60 | time == 59 | time == 58) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1238565 & (time == 61 | time == 60 | time == 59 | time == 58) /* TD Group */
replace stress = 1 if rssdhcr == 1119794 & (time == 61 | time == 60 | time == 59 | time == 58) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 1120754 & (time == 61 | time == 60 | time == 59 | time == 58) /* Wells Fargo & Company */
replace stress = 1 if rssdhcr == 1027004 & (time == 61 | time == 60 | time == 59 | time == 58) /* Zions Bancorporation */

/* 2015 */
replace stress = 1 if rssdhcr == 1562859 & (time == 57 | time == 56 | time == 55 | time == 54) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 57 | time == 56 | time == 55 | time == 54) /* American Express */
replace stress = 1 if rssdhcr == 1073757 & (time == 57 | time == 56 | time == 55 | time == 54) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 57 | time == 56 | time == 55 | time == 54) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 57 | time == 56 | time == 55 | time == 54) /* BB&T */
replace stress = 1 if rssdhcr == 1391237 & (time == 57 | time == 56 | time == 55 | time == 54) /* BBVA Compass */
replace stress = 1 if rssdhcr == 1231333 & (time == 57 | time == 56 | time == 55 | time == 54) /* BMO Financial */
replace stress = 1 if rssdhcr == 2277860 & (time == 57 | time == 56 | time == 55 | time == 54) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 57 | time == 56 | time == 55 | time == 54) /* Citigroup */
replace stress = 1 if rssdhcr == 1132449 & (time == 57) /* Citizens Financial Group */
replace stress = 1 if rssdhcr == 3833526 & (time == 56 | time == 55 | time == 54) /* Citizens Financial Group */
replace stress = 1 if rssdhcr == 1199844 & (time == 57 | time == 56 | time == 55 | time == 54) /* Comerica Incorporated */
replace stress = 1 if rssdhcr == 1242423 & (time == 57 | time == 56 | time == 55 | time == 54) /* Deutsche Bank Trust */
replace stress = 1 if rssdhcr == 3846375 & (time == 57 | time == 56 | time == 55 | time == 54) /* Discover Financial Service */
replace stress = 1 if rssdhcr == 1070345 & (time == 57 | time == 56 | time == 55 | time == 54) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 57 | time == 56 | time == 55 | time == 54) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1857108 & (time == 57 | time == 56 | time == 55 | time == 54) /* HSBC North America */
replace stress = 1 if rssdhcr == 1068191 & (time == 57 | time == 56 | time == 55 | time == 54) /* Huntington Bancshares */
replace stress = 1 if rssdhcr == 1039502 & (time == 57 | time == 56 | time == 55 | time == 54) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 57 | time == 56 | time == 55 | time == 54) /* KeyCorp */
replace stress = 1 if rssdhcr == 1037003 & (time == 57 | time == 56 | time == 55 | time == 54) /* M&T Bank */
replace stress = 1 if rssdhcr == 2162966 & (time == 57 | time == 56 | time == 55 | time == 54) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 2961897 & (time == 57 | time == 56 | time == 55 | time == 54) /* MUFG Americas */
replace stress = 1 if rssdhcr == 1199611 & (time == 57 | time == 56 | time == 55 | time == 54) /* Northern Trust */
replace stress = 1 if rssdhcr == 1069778 & (time == 57 | time == 56 | time == 55 | time == 54) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 57 | time == 56 | time == 55 | time == 54) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1239254 & (time == 57 | time == 56 | time == 55 | time == 54) /* Santander Holdings */
replace stress = 1 if rssdhcr == 1111435 & (time == 57 | time == 56 | time == 55 | time == 54) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 57 | time == 56 | time == 55 | time == 54) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1119794 & (time == 57 | time == 56 | time == 55 | time == 54) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 1120754 & (time == 57 | time == 56 | time == 55 | time == 54) /* Wells Fargo & Company */
replace stress = 1 if rssdhcr == 1027004 & (time == 57 | time == 56 | time == 55 | time == 54) /* Zions Bancorporation */

/* 2014 */
replace stress = 1 if rssdhcr == 1562859 & (time == 53 | time == 52 | time == 51 | time == 50) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 53 | time == 52 | time == 51 | time == 50) /* American Express */
replace stress = 1 if rssdhcr == 1073757 & (time == 53 | time == 52 | time == 51 | time == 50) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 53 | time == 52 | time == 51 | time == 50) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 53 | time == 52 | time == 51 | time == 50) /* BB&T */
replace stress = 1 if rssdhcr == 1391237 & (time == 53 | time == 52 | time == 51 | time == 50) /* BBVA Compass */
replace stress = 1 if rssdhcr == 1231333 & (time == 53 | time == 52 | time == 51 | time == 50) /* BMO Financial */
replace stress = 1 if rssdhcr == 2277860 & (time == 53 | time == 52 | time == 51 | time == 50) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 53 | time == 52 | time == 51 | time == 50) /* Citigroup */
replace stress = 1 if rssdhcr == 3833526 & (time == 53 | time == 52 | time == 51 | time == 50) /* Citizens Financial Group */
replace stress = 1 if rssdhcr == 1199844 & (time == 53 | time == 52 | time == 51 | time == 50) /* Comerica Incorporated */
replace stress = 1 if rssdhcr == 3846375 & (time == 53 | time == 52 | time == 51 | time == 50) /* Discover Financial Service */
replace stress = 1 if rssdhcr == 1070345 & (time == 53 | time == 52 | time == 51 | time == 50) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 53 | time == 52 | time == 51 | time == 50) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1857108 & (time == 53 | time == 52 | time == 51 | time == 50) /* HSBC North America */
replace stress = 1 if rssdhcr == 1068191 & (time == 53 | time == 52 | time == 51 | time == 50) /* Huntington Bancshares */
replace stress = 1 if rssdhcr == 1039502 & (time == 53 | time == 52 | time == 51 | time == 50) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 53 | time == 52 | time == 51 | time == 50) /* KeyCorp */
replace stress = 1 if rssdhcr == 1037003 & (time == 53 | time == 52 | time == 51 | time == 50) /* M&T Bank */
replace stress = 1 if rssdhcr == 2162966 & (time == 53 | time == 52 | time == 51 | time == 50) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 1199611 & (time == 53 | time == 52 | time == 51 | time == 50) /* Northern Trust */
replace stress = 1 if rssdhcr == 1069778 & (time == 53 | time == 52 | time == 51 | time == 50) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 53 | time == 52 | time == 51 | time == 50) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1239254 & (time == 53 | time == 52 | time == 51 | time == 50) /* Santander Holdings */
replace stress = 1 if rssdhcr == 1111435 & (time == 53 | time == 52 | time == 51 | time == 50) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 53 | time == 52 | time == 51 | time == 50) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1119794 & (time == 53 | time == 52 | time == 51 | time == 50) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 2961897 & (time == 53 | time == 52 | time == 51 | time == 50) /* UnionBanCal, MUFG */
replace stress = 1 if rssdhcr == 1120754 & (time == 53 | time == 52 | time == 51 | time == 50) /* Wells Fargo & Company */
replace stress = 1 if rssdhcr == 1027004 & (time == 53 | time == 52 | time == 51 | time == 50) /* Zions Bancorporation */

/* 2013 */
replace stress = 1 if rssdhcr == 1562859 & (time == 49 | time == 48 | time == 47 | time == 46) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 49 | time == 48 | time == 47 | time == 46) /* American Express */
replace stress = 1 if rssdhcr == 1073757 & (time == 49 | time == 48 | time == 47 | time == 46) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 49 | time == 48 | time == 47 | time == 46) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 49 | time == 48 | time == 47 | time == 46) /* BB&T */
replace stress = 1 if rssdhcr == 1391237 & (time == 49 | time == 48 | time == 47 | time == 46) /* BBVA Compass */
replace stress = 1 if rssdhcr == 1231333 & (time == 49 | time == 48 | time == 47 | time == 46) /* BMO Financial */
replace stress = 1 if rssdhcr == 2277860 & (time == 49 | time == 48 | time == 47 | time == 46) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 49 | time == 48 | time == 47 | time == 46) /* Citigroup */
replace stress = 1 if rssdhcr == 3833526 & (time == 49 | time == 48 | time == 47 | time == 46) /* Citizens Financial Group */
replace stress = 1 if rssdhcr == 1199844 & (time == 49 | time == 48 | time == 47 | time == 46) /* Comerica Incorporated */
replace stress = 1 if rssdhcr == 3846375 & (time == 49 | time == 48 | time == 47 | time == 46) /* Discover Financial Service */
replace stress = 1 if rssdhcr == 1070345 & (time == 49 | time == 48 | time == 47 | time == 46) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 49 | time == 48 | time == 47 | time == 46) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1857108 & (time == 49 | time == 48 | time == 47 | time == 46) /* HSBC North America */
replace stress = 1 if rssdhcr == 1068191 & (time == 49 | time == 48 | time == 47 | time == 46) /* Huntington Bancshares */
replace stress = 1 if rssdhcr == 1039502 & (time == 49 | time == 48 | time == 47 | time == 46) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 49 | time == 48 | time == 47 | time == 46) /* KeyCorp */
replace stress = 1 if rssdhcr == 1037003 & (time == 49 | time == 48 | time == 47 | time == 46) /* M&T Bank */
replace stress = 1 if rssdhcr == 2162966 & (time == 49 | time == 48 | time == 47 | time == 46) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 1199611 & (time == 49 | time == 48 | time == 47 | time == 46) /* Northern Trust */
replace stress = 1 if rssdhcr == 1069778 & (time == 49 | time == 48 | time == 47 | time == 46) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 49 | time == 48 | time == 47 | time == 46) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1111435 & (time == 49 | time == 48 | time == 47 | time == 46) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 49 | time == 48 | time == 47 | time == 46) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1119794 & (time == 49 | time == 48 | time == 47 | time == 46) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 2961897 & (time == 49 | time == 48 | time == 47 | time == 46) /* UnionBanCal, MUFG */
replace stress = 1 if rssdhcr == 1120754 & (time == 49 | time == 48 | time == 47 | time == 46) /* Wells Fargo & Company */
replace stress = 1 if rssdhcr == 1027004 & (time == 49 | time == 48 | time == 47 | time == 46) /* Zions Bancorporation */

/* 2012 */
replace stress = 1 if rssdhcr == 1562859 & (time == 45 | time == 44 | time == 43 | time == 42) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 45 | time == 44 | time == 43 | time == 42) /* American Express */
replace stress = 1 if rssdhcr == 1073757 & (time == 45 | time == 44 | time == 43 | time == 42) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 45 | time == 44 | time == 43 | time == 42) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 45 | time == 44 | time == 43 | time == 42) /* BB&T */
replace stress = 1 if rssdhcr == 1391237 & (time == 45 | time == 44 | time == 43 | time == 42) /* BBVA Compass */
replace stress = 1 if rssdhcr == 1231333 & (time == 45 | time == 44 | time == 43 | time == 42) /* BMO Financial */
replace stress = 1 if rssdhcr == 2277860 & (time == 45 | time == 44 | time == 43 | time == 42) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 45 | time == 44 | time == 43 | time == 42) /* Citigroup */
replace stress = 1 if rssdhcr == 3833526 & (time == 45 | time == 44 | time == 43 | time == 42) /* Citizens Financial Group */
replace stress = 1 if rssdhcr == 1199844 & (time == 45 | time == 44 | time == 43 | time == 42) /* Comerica Incorporated */
replace stress = 1 if rssdhcr == 3846375 & (time == 45 | time == 44 | time == 43 | time == 42) /* Discover Financial Service */
replace stress = 1 if rssdhcr == 1070345 & (time == 45 | time == 44 | time == 43 | time == 42) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 45 | time == 44 | time == 43 | time == 42) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1857108 & (time == 45 | time == 44 | time == 43 | time == 42) /* HSBC North America */
replace stress = 1 if rssdhcr == 1068191 & (time == 45 | time == 44 | time == 43 | time == 42) /* Huntington Bancshares */
replace stress = 1 if rssdhcr == 1039502 & (time == 45 | time == 44 | time == 43 | time == 42) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 45 | time == 44 | time == 43 | time == 42) /* KeyCorp */
replace stress = 1 if rssdhcr == 2945824 & (time == 45 | time == 44 | time == 43 | time == 42) /* MetLife */
replace stress = 1 if rssdhcr == 1037003 & (time == 45 | time == 44 | time == 43 | time == 42) /* M&T Bank */
replace stress = 1 if rssdhcr == 2162966 & (time == 45 | time == 44 | time == 43 | time == 42) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 1199611 & (time == 45 | time == 44 | time == 43 | time == 42) /* Northern Trust */
replace stress = 1 if rssdhcr == 1069778 & (time == 45 | time == 44 | time == 43 | time == 42) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 45 | time == 44 | time == 43 | time == 42) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1111435 & (time == 45 | time == 44 | time == 43 | time == 42) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 45 | time == 44 | time == 43 | time == 42) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1119794 & (time == 45 | time == 44 | time == 43 | time == 42) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 2961897 & (time == 45 | time == 44 | time == 43 | time == 42) /* UnionBanCal, MUFG */
replace stress = 1 if rssdhcr == 1120754 & (time == 45 | time == 44 | time == 43 | time == 42) /* Wells Fargo & Company */
replace stress = 1 if rssdhcr == 1027004 & (time == 45 | time == 44 | time == 43 | time == 42) /* Zions Bancorporation */

/* 2011 */
replace stress = 1 if rssdhcr == 1562859 & (time == 41 | time == 40 | time == 39 | time == 38) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 41 | time == 40 | time == 39 | time == 38) /* American Express */
replace stress = 1 if rssdhcr == 1073757 & (time == 41 | time == 40 | time == 39 | time == 38) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 41 | time == 40 | time == 39 | time == 38) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 41 | time == 40 | time == 39 | time == 38) /* BB&T */
replace stress = 1 if rssdhcr == 2277860 & (time == 41 | time == 40 | time == 39 | time == 38) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 41 | time == 40 | time == 39 | time == 38) /* Citigroup */
replace stress = 1 if rssdhcr == 1070345 & (time == 41 | time == 40 | time == 39 | time == 38) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 41 | time == 40 | time == 39 | time == 38) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1039502 & (time == 41 | time == 40 | time == 39 | time == 38) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 41 | time == 40 | time == 39 | time == 38) /* KeyCorp */
replace stress = 1 if rssdhcr == 2945824 & (time == 41 | time == 40 | time == 39 | time == 38) /* MetLife */
replace stress = 1 if rssdhcr == 2162966 & (time == 41 | time == 40 | time == 39 | time == 38) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 1069778 & (time == 41 | time == 40 | time == 39 | time == 38) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 41 | time == 40 | time == 39 | time == 38) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1111435 & (time == 41 | time == 40 | time == 39 | time == 38) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 41 | time == 40 | time == 39 | time == 38) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1119794 & (time == 41 | time == 40 | time == 39 | time == 38) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 1120754 & (time == 41 | time == 40 | time == 39 | time == 38) /* Wells Fargo & Company */

/* 2010 */
replace stress = 1 if rssdhcr == 1562859 & (time == 37 | time == 36 | time == 35 | time == 34) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 37 | time == 36 | time == 35 | time == 34) /* American Express */
replace stress = 1 if rssdhcr == 1073757 & (time == 37 | time == 36 | time == 35 | time == 34) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 37 | time == 36 | time == 35 | time == 34) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 37 | time == 36 | time == 35 | time == 34) /* BB&T */
replace stress = 1 if rssdhcr == 2277860 & (time == 37 | time == 36 | time == 35 | time == 34) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 37 | time == 36 | time == 35 | time == 34) /* Citigroup */
replace stress = 1 if rssdhcr == 1070345 & (time == 37 | time == 36 | time == 35 | time == 34) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 37 | time == 36 | time == 35 | time == 34) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1039502 & (time == 37 | time == 36 | time == 35 | time == 34) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 37 | time == 36 | time == 35 | time == 34) /* KeyCorp */
replace stress = 1 if rssdhcr == 2945824 & (time == 37 | time == 36 | time == 35 | time == 34) /* MetLife */
replace stress = 1 if rssdhcr == 2162966 & (time == 37 | time == 36 | time == 35 | time == 34) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 1069778 & (time == 37 | time == 36 | time == 35 | time == 34) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 37 | time == 36 | time == 35 | time == 34) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1111435 & (time == 37 | time == 36 | time == 35 | time == 34) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 37 | time == 36 | time == 35 | time == 34) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1119794 & (time == 37 | time == 36 | time == 35 | time == 34) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 1120754 & (time == 37 | time == 36 | time == 35 | time == 34) /* Wells Fargo & Company */

/* 2009 */
replace stress = 1 if rssdhcr == 1562859 & (time == 33 | time == 32 | time == 31 | time == 30) /* Ally Financial */
replace stress = 1 if rssdhcr == 1275216 & (time == 33 | time == 32 | time == 31 | time == 30) /* American Express */
replace stress = 1 if rssdhcr == 1073757 & (time == 33 | time == 32 | time == 31 | time == 30) /* Bank of America */
replace stress = 1 if rssdhcr == 3587146 & (time == 33 | time == 32 | time == 31 | time == 30) /* The Bank of New York Mellon */
replace stress = 1 if rssdhcr == 1074156 & (time == 33 | time == 32 | time == 31 | time == 30) /* BB&T */
replace stress = 1 if rssdhcr == 2277860 & (time == 33 | time == 32 | time == 31 | time == 30) /* Capital One */
replace stress = 1 if rssdhcr == 1951350 & (time == 33 | time == 32 | time == 31 | time == 30) /* Citigroup */
replace stress = 1 if rssdhcr == 1070345 & (time == 33 | time == 32 | time == 31 | time == 30) /* Fifth Third Bancorp */
replace stress = 1 if rssdhcr == 2380443 & (time == 33 | time == 32 | time == 31 | time == 30) /* The Goldman Sachs */
replace stress = 1 if rssdhcr == 1039502 & (time == 33 | time == 32 | time == 31 | time == 30) /* JPMorgan Chase & Co. */
replace stress = 1 if rssdhcr == 1068025 & (time == 33 | time == 32 | time == 31 | time == 30) /* KeyCorp */
replace stress = 1 if rssdhcr == 2945824 & (time == 33 | time == 32 | time == 31 | time == 30) /* MetLife */
replace stress = 1 if rssdhcr == 2162966 & (time == 33 | time == 32 | time == 31 | time == 30) /* Morgan Stanley */
replace stress = 1 if rssdhcr == 1069778 & (time == 33 | time == 32 | time == 31 | time == 30) /* The PNC Financial Service */
replace stress = 1 if rssdhcr == 3242838 & (time == 33 | time == 32 | time == 31 | time == 30) /* Regions Financial Corporation */
replace stress = 1 if rssdhcr == 1111435 & (time == 33 | time == 32 | time == 31 | time == 30) /* State Street */
replace stress = 1 if rssdhcr == 1131787 & (time == 33 | time == 32 | time == 31 | time == 30) /* SunTrust Banks */
replace stress = 1 if rssdhcr == 1119794 & (time == 33 | time == 32 | time == 31 | time == 30) /* U.S. Bancorp */
replace stress = 1 if rssdhcr == 1120754 & (time == 33 | time == 32 | time == 31 | time == 30) /* Wells Fargo & Company */

/* Stress Tests for all banks, 2013, consolidated asset >= 10000000 */
replace stress = 1 if time > 45 & bhck2170 != . & bhck2170 >= 10000000 & stress == 0

replace stress = 1 if time > 45 & asset > 10000000 & stress == 0

sort time rssdhcr
by time rssdhcr: egen sum_asset = total(asset)
replace stress = 1 if time > 45 & sum_asset >= 10000000 & rssdhcr != 0

sort cert time

/* Dummy variable for Basel III, 2013, consolidated asset >= 500000 */ 
gen basel = 0

replace basel = stress if time > 45

replace basel = 1 if time > 45 & bhck2170 != . & bhck2170 >= 500000

replace basel = 1 if time > 45 & asset >= 500000

replace basel = 1 if time > 45 & sum_asset >= 500000

/* Create bank groups across time */
sort cert time

xtset cert time

tempfile bankdata

save `bankdata'

/* Banks subjected to either Basel & Stress tests */
keep if time > 29 & (stress == 1 | basel == 1)

contract cert

rename _freq either

replace either = 1

sort cert

tempfile either

save `either'

clear

use `bankdata'

merge m:1 cert using `either'

replace either = 0 if either == .

drop _merge

tempfile bankdata1

save `bankdata1'

/* Banks subjected to Stress tests */
keep if time > 29 & stress == 1

contract cert

rename _freq stresstime

replace stresstime = 1

sort cert

tempfile stresstime

save `stresstime'

clear

use `bankdata1'

merge m:1 cert using `stresstime'

replace stresstime = 0 if stresstime == .

drop _merge

tempfile bankdata2

save `bankdata2'

/* Banks subjected to Basel */
keep if time > 29 & basel == 1

contract cert

rename _freq baseltime

replace baseltime = 1

sort cert

tempfile baseltime

save `baseltime'

clear

use `bankdata2'

merge m:1 cert using `baseltime'

replace baseltime = 0 if baseltime == .

drop _merge

tempfile bankdata3

save `bankdata3'

/* Banks subjected to Both */
keep if time > 29 & stress == 1 & basel == 1

contract cert

rename _freq both

replace both = 1

sort cert

tempfile both

save `both'

clear

use `bankdata3'

merge m:1 cert using `both'

replace both = 0 if both == .

drop _merge

tempfile bankdata4

save `bankdata4'

/* Banks subjected to Neither */
keep if time > 29 & stress == 0 & basel == 0

contract cert

rename _freq neither

replace neither = 1

sort cert

tempfile neither

save `neither'

clear

use `bankdata4'

merge m:1 cert using `neither'

replace neither = 0 if neither == .

drop _merge


/* Save Data */
sort cert time

xtset cert time

save C:\Users\zefan\Desktop\Dissertation\latex_proposal\data, replace

/* Import data */
clear

use "C:\Users\zefan\Desktop\Dissertation\latex_proposal\data.dta"

keep cert time name stalp ///
lnloan lncs grre lnsc sc idlnls ///
cet1 rbc1aaj rbc1rwaj rbcrwaj rbct1cer fedfunds ///
lngdp inf unrate lnpi ///
nonixay intexpy chr npl lr profit lnasset ///
yd09 yd13 stress basel q1 q2 q3 q4 either stresstime baseltime both neither

sort cert time

xtset cert time

/*
/* Generate Lag Variables for Predetermined Variables */
gen lcet1 = l.cet1
gen lchr = l.chr
gen llr = l.lr
gen lasset = l.lnasset
gen lintexpy = l.intexpy
gen lnpl = l.npl
gen lprofit = l.profit
gen lnonixay = l.nonixay
*/

/* Regression - Loans */
/* No Dynamic Lags of Dependent Vairables */
/* OLS - Inconsistent & Misspecification */
regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29
est sto e1

regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29
est sto e2

/*
regress d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29

/* Not Lag, Contempraneous Capital Ratio - Inconsistent */
regress d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29

regress d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29
*/


/* Fixed Effect - Consistent & Misspecification */
xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe
est sto e3

xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe
est sto e4


/*
xtreg d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, fe

xtreg d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, fe

/* Not Lag, Contempraneous Capital Ratio */
xtreg d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, fe

xtreg d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, fe

xtreg d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, fe

xtreg d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, fe


/* Random Effects */
xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, re

xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, re
*/


/* Dynamic Model with Lags of Dependent Variable */
/* OLS */
/*
regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay i.time
*/


/* Break at 2009, OLS - Inconsistent */
regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29
est sto e5

regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29
est sto e6

/*
regress d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29

/* Not Lag, Contempraneous Capital Ratio */
regress d.lnloan l(1/4)d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress d.lnloan l(1/4)d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29

regress d.lnloan l(1/4)d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress d.lnloan l(1/4)d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29
*/

/*
/* Fixed Effects */
xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay, fe
*/

/* Break at 2009, FE - Inconsistent */
xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe
est sto e7

xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe
est sto e8


/*
xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, fe

xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, fe

/* Not Lag, Contempraneous Capital Ratio */
xtreg d.lnloan l(1/4)d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, fe

xtreg d.lnloan l(1/4)d.lnloan cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, fe

xtreg d.lnloan l(1/4)d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, fe

xtreg d.lnloan l(1/4)d.lnloan cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l(0/4).unrate l(0/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, fe


/* Random Effects */
xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, re

xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, re
*/


/* BB system GMM */

/*
tabulate time, generate(t)
*/

/* xtdpdsys */
/* One Step, GMM Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4)
est sto e9
estat sargan

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4)
est sto e10
estat sargan


/* One Step, Robust Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)
est sto e11
estat abond

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)
est sto e12
estat abond


/* Two Step, Robust Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep
est sto e13
estat abond

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep
est sto e14
estat abond


/* Two Step, Robust Variance, Allow 5 Lags as Instruments */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) maxldep(5) vce(robust) twostep

estat abond

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) maxldep(5) vce(robust) twostep

estat abond


/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) maxldep(3) vce(robust) twostep
est sto e15
estat abond

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) maxldep(3) vce(robust) twostep
est sto e16
estat abond


/* Cross Sectional Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) vce(robust) twostep

estat abond

/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) maxldep(3) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4) vce(robust) twostep

estat abond


xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4) vce(robust)

estat abond


xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4)

estat abond


/* Banks subjected to Basel */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Neither */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 0 & basel == 0, ///
lags(4) vce(robust) twostep

estat abond


/* Time Series Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) maxldep(3) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & stresstime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Basel */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & baseltime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & both == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Neither */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & neither == 1, ///
lags(4) vce(robust) twostep

estat abond


/* Regression - Common Stocks */
/* Two Step, Robust Variance */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

estat abond

xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

estat abond


/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) maxldep(3) vce(robust) twostep

estat abond

xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) maxldep(3) vce(robust) twostep

estat abond


/* Cross Sectional Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) vce(robust) twostep

estat abond

/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) maxldep(3) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Basel */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Neither */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 0 & basel == 0, ///
lags(4) vce(robust) twostep

estat abond


/* Time Series Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) maxldep(3) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & stresstime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Basel */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & baseltime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & both == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Neither */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & neither == 1, ///
lags(4) vce(robust) twostep

estat abond


/* Regression - Retained Earnings */
/* Two Step, Robust Variance */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

estat abond

xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

estat abond


/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) maxldep(3) vce(robust) twostep

estat abond

xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) maxldep(3) vce(robust) twostep

estat abond


/* Cross Sectional Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) vce(robust) twostep

estat abond

/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) maxldep(3) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Basel */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Neither */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 0 & basel == 0, ///
lags(4) vce(robust) twostep

estat abond


/* Time Series Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Two Step, Robust Variance, Allow 3 Lags as Instruments */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) maxldep(3) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & stresstime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Basel */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & baseltime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & both == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Neither */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & neither == 1, ///
lags(4) vce(robust) twostep

estat abond


/*
Steps:
Compare effects of risk-based capital ratio and monetary policy.
Take full advantage of panel data, both cross-sectional and time-series.
1. Compare effects for all banks before and after 2009.  Overall effects before and after.
2. Compare effects for different bank groups (basel, stress test, both, neither) after 2009.  Cross-sectional Effects.
3. Compare effects for the same bank group before 2009 and after 2009.  For example, compare effects
for banks that are subjected to the stress test after 2009 to the effects for the same banks before
2009.  Time-series Effects.
4. Do above things for common stocks and retained earnings.  Do the same things for other two, no need for interaction terms.
These will provide an overall and whole picture of the analysis.
This is Great!
A month to run all the results.
A month to write up all the summaries.
A month to organize all the details.
Schedule a date to defend.
*/


/* Result Table */
esttab e1 e2 e3 e4 using table1.tex, ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lr L.lnasset) ///
label ///
mgroups("OLS" "FE", pattern(1 0 1 0)) ///
nonumbers mtitles("pre 2009" "post 2009" "pre 2009" "post 2009") ///
addnote("All Variables Are in Lag Form") ///
coeflabel(L.cet1 "Capital Ratio" L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")


esttab e5 e6 e7 e8 using table2.tex, ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lr L.lnasset) ///
label ///
mgroups("OLS" "FE", pattern(1 0 1 0)) ///
nonumbers mtitles("pre 2009" "post 2009" "pre 2009" "post 2009") ///
addnote("All Variables Are in Lag Form") ///
coeflabel(L.cet1 "Capital Ratio" L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")


esttab e9 e10 e11 e12 using table3.tex, ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lr L.lnasset) ///
label ///
mgroups("One Step" "Robust", pattern(1 0 1 0)) ///
nonumbers mtitles("pre 2009" "post 2009" "pre 2009" "post 2009") ///
addnote("All Variables Are in Lag Form") ///
coeflabel(L.cet1 "Capital Ratio" L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")


esttab e13 e14 e15 e16 using table4.tex, ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lr L.lnasset) ///
label ///
mgroups("Two Step R" "3 Lags IV", pattern(1 0 1 0)) ///
nonumbers mtitles("pre 2009" "post 2009" "pre 2009" "post 2009") ///
addnote("All Variables Are in Lag Form") ///
coeflabel(L.cet1 "Capital Ratio" L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")







/* Proxy - More Essential Capial: (CS + RE)/Risk-Weighted Assets */




/* Conclusion - Two Reasons */
/* 1. Before 2009, situation was good, banks were making loans, and based on capital 
level, they can make loan as long as they have enough capital, thus capital is 
significant in banks' lending decision.  However, after 2009, macro situation was not good,
banks make lending decision based on perceived risks and macro condition more, not capital 
level since they have already fulfilled the requirements. */

/* 2. Proxy of Tier 1 capital minus prefered equity is not good.  It is not essential enough,
so try to use a more essential proxy such as common stock equity + retained earnings as capital 
measurement. */

/* 3. Loan Growth - Two most important factros are assets (bank size) and liquidity ratio.  
They are both significant across bank groups and time periods.  Non-performing loan is significant 
in the pre-preiods.  Federal funds rate is mostly significant during the pre-periods, but not so 
during the post-periods.  Other variables serve as control and are not so significant.
Risk-based capital ratio is not significant across bank groups and time periods.  However, the sign 
changes.  The capital ratio is usually positive during the pre-periods, but negative during the 
post-periods.  This could be that the more capital a bank has, the more it can lend during the 
pre-periods.  However, during the post-periods, the capital ratio could potentially negatively 
affect lending, but both at an insignificant way. */

/* 4. Most problems root in the liquidity issue.  For example, banks use short-term deposite to fund 
long-term lending.  Thus the capital requirement which requires more equity actually aim to mitigate the 
liquidity issue during bad times.  Maybe this is the reason why liquidity ratio is a more binding 
constraint than capital ratio. */

/* Problems */
/* 1. Hard to pin down which bank specific variables are endogenous.  For system GMM, endogeneity 
has implications on the instruments used.  For now, can only use general methods such as lags and 
system GMM to mitigate endogeneity issue. */

/* 2. The model for common stock and retained earings might be misspecified.  Simple replace loan 
growth with those might not be correct.  Currently not aware of models for common stock and retained 
earings in the literature. might not be true */

/* 3. Maybe for the models, I included too many variables which are unnecessary.  By including the 
additional insignificant varialbe, multicollinearity is introduced, which would inflate the standard 
error.  Thus, most variables become insignificant when using two step robust variance GMM due to 
the reason that the standard error is inflated.  The way to check this is reducing the insignificant or 
unnecessary variabls from the models.  I will need to do this! */

/* 4. Two channels: 1. shift assets to safe assets, so reduce loan and lending.  2. Stricter capital 
requirement increase funding cost of bank, which is passed along to borrower, thus reduce lending.  
One could calculate a roguh estimation of lending rate by using income from loan/loan amount.  And maybe 
I can run a regression using this lending rate. Would this be a good approximate?  How about the cost 
of loan?  Net income?  Might not be a good approximation. */

/* 5. Summarize the other part of literature review.  Summarize both sides of the arguement.  Briefly 
summarize the Positive Relationship v.s. the Negative Relationship.  And briefly summarize and mention 
all the related literature from the economic insights.  Briefly summarize the conclusion from the 
credit crunch literature and the calibaration, lending rate literature.  Explain the argument from both 
sides, positive relationship?  Negative relationship?  Different times?  General Equilibrium?  
Transitional Effects?  */

/* 6. Compare the effect of lagged level of capital ratio and the lag of change in capital 
ratio.  The effect of lagged level of capital ratio might be insignificant because bank would cut lending 
to achieve higher ratio (negative), or it will be able to lend more if it has more capital (positive). 
However, by using the change in the capital ratio, one might see how changes in capital ratio would 
affect the lending growth rate.  If change is positive and large, then lending growth rate would slower, 
then it will be a negative realtionship.  This will purify the effects of the positive effects.  This 
is actually important, I will need to do this !!! use lag of change in capital ratio instead of using 
lagged level of capital ratio.  This might be able to show more information, and help my regression 
analysis alot !!!!!!  */

/* 7. In addition, you might want to add more lagged change in capital ratio to see how these lags 
would affect bank lending growth rate accumulativelly.  You need to add more lags of the lagged 
change in capital ratio or lagged capital ratio into the regressions.  Since sometimes the lagged 
variables are significant.  I will add 4 more lags of change in capital ratio and capital ratio into 
regression to see the yearly effects.  More lags might be needed, we will see.  */

/* 8. The overall effects would be the sum of the coefficients, or the sum and division if the model 
includes the lagged dependent variabls to count for the overall long-term effects.  */

/* 9. R square and adjusted R square are low for panel regression thought. Meaningless.  */

/* 10. Including more lags of capital ratio or change in capital ratio might be essential since one 
of the lags could be so significant that the cumulative effect would be driven by the lag.  */

/* 11. According to other paper and literature, just look at the sum of coefficients of lags is 
sufficient to determine the overall effects.  Or are we talking about the coeffecient of the sum 
of all the lags ?  and significance?  */

/* 12. Delete the insignificant and unnecessary factors to reduce multicollinearity and reduce 
the std to see if anything will become significant.  The multicollinearity issue might inflate 
the variance and make everything insignificant.  And two step robust variance.  */

/* 13. Outliers? Not necessary to drop the outliers.  No reason?  */

/* 14. Main results: siginificant positive relationship according to FE and One step GMM variance 
system GMM, negative relationship for OLS (which might not be correct).  The significant positve 
relationship become insignificant when use robust variance.  However, if we add more lags of capital 
ratio into the model.  The relationship is not significant before 2009, but significant positive 
after 2009, which is similar to the literature.  The change in the ratio gives the similar results. 
Not exactly the same, might becasue that some observations are dropped when use the change in the 
ratio, especially those observations around 2009 when regressions are run for different periods. Strigint relationship after 2009, and other factors such as Federal Funds rate, asset, non-performing 
loan and liquidity ratio remain important.  Now we need to drop unnecessory and insignificant variables to see if that will reduce multicolinearity 
issume.  */

/* 15. Robustness check, dropped some variables to reduce multicollinearity, changed sample periods 
to see how the results change. Change instruments used.  */

/* 16. Robustness check gives the same results using different sample periods and factors.  Except for 
federal funds rate become insignificant when sample periods change.  */

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 30, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 31, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

/* Two Step, Robust, use real Common Equity Tier 1 Ratio for after 2015 */
regress d.lnloan l.rbct1cer l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54



xtreg d.lnloan l.rbct1cer l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54, fe vce(robust)



xtdpdsys d.lnloan l.rbct1cer l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54, lags(4) vce(robust) twostep



xtdpdsys d.lnloan l(1/5).rbct1cer l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54, lags(4) vce(robust) twostep

test l1.rbct1cer l2.rbct1cer l3.rbct1cer l4.rbct1cer l5.rbct1cer
lincom l1.rbct1cer + l2.rbct1cer + l3.rbct1cer + l4.rbct1cer + l5.rbct1cer










xtdpdsys d.lnloan l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 30, lags(4) vce(robust) twostep

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1

xtdpdsys d.lnloan l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 31, lags(4) vce(robust) twostep

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1



xtdpdsys d.lnloan l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54, lags(4) vce(robust) twostep

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1

/* Two Step, Robust, use change in real Common Equity Tier 1 Ratio for after 2015 */
xtdpdsys d.lnloan ld.rbct1cer l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54, lags(4) vce(robust) twostep



xtdpdsys d.lnloan l(1/5)d.rbct1cer l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 54, lags(4) vce(robust) twostep

test ld.rbct1cer l2d.rbct1cer l3d.rbct1cer l4d.rbct1cer l5d.rbct1cer
lincom ld.rbct1cer + l2d.rbct1cer + l3d.rbct1cer + l4d.rbct1cer + l5d.rbct1cer



/* Two Step, Robust Variance, with more lags included, dropped insignificant and unnecessary 
factors to reduce multicollinearity issues and reduce variace of variables */
xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit q2 q3 q4, lags(4) vce(robust) twostep

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1



xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy q2 q3 q4, lags(4) vce(robust) twostep

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1



xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.npl l.lnasset l.lr l.intexpy q2 q3 q4, lags(4) vce(robust) twostep

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.npl l.lnasset l.lr l.intexpy q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.npl l.lnasset l.lr l.intexpy q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.npl l.lnasset l.lr l.intexpy q2 q3 q4 if time > 31, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.npl l.lnasset l.lr l.intexpy q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1



xtdpdsys d.lnloan l.cet1 l5.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l5.cet1
lincom l1.cet1 + l5.cet1



/* Choose Lags */
regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4

estat ic

regress d.lnloan l(1/4)d.lnloan l(1/13).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4

estat ic

/* 13 Lags */
xtdpdsys d.lnloan l(1/13).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1 l6.cet1 l7.cet1 l8.cet1 ///
l9.cet1 l10.cet1 l11.cet1 l12.cet1 l13.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1 + l6.cet1 + l7.cet1 + l8.cet1 + ///
l9.cet1 + l10.cet1 + l11.cet1 + l12.cet1 + l13.cet1

xtdpdsys d.lnloan l(1/13).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1 l6.cet1 l7.cet1 l8.cet1 ///
l9.cet1 l10.cet1 l11.cet1 l12.cet1 l13.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1 + l6.cet1 + l7.cet1 + l8.cet1 + ///
l9.cet1 + l10.cet1 + l11.cet1 + l12.cet1 + l13.cet1

xtdpdsys d.lnloan l(1/13).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1 l6.cet1 l7.cet1 l8.cet1 ///
l9.cet1 l10.cet1 l11.cet1 l12.cet1 l13.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1 + l6.cet1 + l7.cet1 + l8.cet1 + ///
l9.cet1 + l10.cet1 + l11.cet1 + l12.cet1 + l13.cet1






/* Retained Earnings */
/* Capital Ratio & Federal Funds Rate do not matter */
/* Assets (-), Non-performing Loan (-), Liquidity Ratio (-) might matter more, Non-Interest Expense (-) Sometimes */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds



xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds



xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys grre l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1



/* OLS */
regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29



/* Fixed Effects */
xtreg grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, fe

xtreg grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtreg grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtreg grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe vce(robust)

xtreg grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe vce(robust)






/* Common Stock Equity */
/* Capital Ratio does not matter, Federal Funds Rate matters before 2009 (-) */
/* Assets (-), Liquidity Ratio (+), Profit (-) might matter */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds



xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds



xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

xtdpdsys d.lncs l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1



/* OLS */
regress d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4

regress d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29

regress d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29



/* Fixed Effects */
xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, fe

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe vce(robust)

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe vce(robust)






/* Conclusion */
/* 
Significant factors:  
Loan Growth: Capital Ratio (marginally), Federal Funds Rate, Non-Performing Loan, Liquidity Ratio, Assets Level, Lags.
Retained Earnings Growth: Non-Performing Loan, Liquidity Ratio, Assets Level.
Common Stock Equity Growth: Federal Funds Rate, Liquidity Ratio, Assets Level, Profit, Lags.
Can't run sample after 2015 with the data, colinearity
*/










/* CET1 as Endogenous, Others Use Lags, 5 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) ///
end(cet1, lag(0, 5)) maxldep(5) maxlags(5) vce(robust) twostep

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) ///
end(cet1, lag(0, 5)) maxldep(5) maxlags(5) vce(robust) twostep

estat abond


/*
/* CET1 as Predetermined, Other as Endogeneous, 10 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(10) maxlags(10) pre(cet1, lag(0, 10)) end(chr npl lnasset lr intexpy profit nonixay, lag(0, 10))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(10) maxlags(10) pre(cet1, lag(0, 10)) end(chr npl lnasset lr intexpy profit nonixay, lag(0, 10))

estat abond

/* CET1 as Predetermined, Other as Endogeneous, 5 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(5) maxlags(5) pre(cet1, lag(0, 5)) end(chr npl lnasset lr intexpy profit nonixay, lag(0, 5))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(5) maxlags(5) pre(cet1, lag(0, 5)) end(chr npl lnasset lr intexpy profit nonixay, lag(0, 5))

estat abond

/* CET1 as Predetermined, Other as Endogeneous, 3 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(3) maxlags(3) pre(cet1, lag(0, 3)) end(chr npl lnasset lr intexpy profit nonixay, lag(0, 3))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(3) maxlags(3) pre(cet1, lag(0, 3)) end(chr npl lnasset lr intexpy profit nonixay, lag(0, 3))

estat abond

/* All as Endogeneous, 10 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(10) maxlags(10) end(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 10))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(10) maxlags(10) end(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 10))

estat abond

/* All as Endogeneous, 5 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(5) maxlags(5) end(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 5))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(5) maxlags(5) end(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 5))

estat abond

/* All as Endogeneous, 3 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(3) maxlags(3) end(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 3))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(3) maxlags(3) end(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 3))

estat abond

/* All as Predetermined, 5 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(5) maxlags(5) pre(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 5))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(5) maxlags(5) pre(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 5))

estat abond

/* All as Predetermined, 3 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time <= 29, lags(4) twostep vce(robust) ///
maxldep(3) maxlags(3) pre(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 3))

estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi if time > 29, lags(4) twostep vce(robust) ///
maxldep(3) maxlags(3) pre(cet1 chr npl lnasset lr intexpy profit nonixay, lag(0, 3))

estat abond
*/


/* xtabond2 */
/* All as Exogeneous */
xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, gmm(ld.lnloan, laglimits(1 5) collapse) ///
iv(l.cet1 l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay) twostep robust

xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, gmm(ld.lnloan, laglimits(1 5) collapse) ///
iv(l.cet1 l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay) twostep robust

/* CET1 as Predetermined, Other as Endogeneous */
xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, ///
gmm(ld.lnloan cet1 l.(chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust

xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, ///
gmm(ld.lnloan cet1 l.(chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust

/* All as Endogeneous */
xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, ///
gmm(ld.lnloan l.(cet1 chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust

xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, ///
gmm(ld.lnloan l.(cet1 chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust

/* Orthogonal Differencing, All as Exogeneous */
xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, gmm(ld.lnloan, laglimits(1 5) collapse) ///
iv(l.cet1 l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay) twostep robust orthogonal

xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, gmm(ld.lnloan, laglimits(1 5) collapse) ///
iv(l.cet1 l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay) twostep robust orthogonal

/* Orthogonal Differencing, CET1 as Predetermined, Other as Endogeneous */
xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, ///
gmm(ld.lnloan cet1 l.(chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust orthogonal

xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, ///
gmm(ld.lnloan cet1 l.(chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust orthogonal

/* Orthogonal Differencing, All as Endogeneous */
xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, ///
gmm(ld.lnloan l.(cet1 chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust orthogonal

xtabond2 d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, ///
gmm(ld.lnloan l.(cet1 chr npl lnasset lr intexpy profit nonixay), laglimits(1 3) collapse) ///
iv(l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi) twostep robust orthogonal


/* Berrospide & Edge (2010), Internation BHCs, GMM */
/* Pooled OLS */
regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l.chr l.lr if t <= 29

regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l.chr l.lr if t > 29

/* Fixed Effects */
xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l.chr l.lr if t <= 29, fe

xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l.chr l.lr if t > 29, fe

/* System GMM */
/* All as Exogeneous */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l.chr l.lr if t <= 29, lags(4) twostep vce(robust)

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l.chr l.lr if t > 29, lags(4) twostep vce(robust)

/* CET1 as Predetermined, Other as Endogeneous */
xtdpdsys d.lnloan l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf if t <= 29, lags(4) ///
maxldep(3) maxlags(3) pre(cet1) end(chr lr) twostep vce(robust)

xtdpdsys d.lnloan l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf if t > 29, lags(4) ///
maxldep(3) maxlags(3) pre(cet1) end(chr lr) twostep vce(robust)

/* All as Endogeneous */
xtdpdsys d.lnloan l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf if t <= 29, lags(4) ///
maxldep(3) maxlags(3) end(cet1 chr lr) twostep vce(robust)

xtdpdsys d.lnloan l(1/4)d.fedfunds l(1/4)d.lngdp l(1/4).inf if t > 29, lags(4) ///
maxldep(3) maxlags(3) end(cet1 chr lr) twostep vce(robust)


/* Gambacorta & Mistrulli (2004), Italian Banks, AB-GMM */
/* Pooled OLS */
regress d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l.lnasset l.lr l.intexpy if t <= 29

regress d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l.lnasset l.lr l.intexpy if t > 29

/* Fixed Effects */
xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l.lnasset l.lr l.intexpy if t <= 29, fe

xtreg d.lnloan l(1/4)d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l.lnasset l.lr l.intexpy if t > 29, fe

/* System GMM */
/* All as Exogeneous */
xtdpdsys d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l.lnasset l.lr l.intexpy if t <= 29, lags(4) twostep vce(robust)

xtdpdsys d.lnloan l.cet1 l(0/4)d.fedfunds ///
l(0/4)d.lngdp l(0/4).inf l.lnasset l.lr l.intexpy if t > 29, lags(4) twostep vce(robust)

/* CET1 as Predetermined, Other as Endogeneous */
xtdpdsys d.lnloan l(0/4)d.fedfunds l(0/4)d.lngdp l(0/4).inf if t <= 29, lags(4) ///
maxldep(3) maxlags(3) pre(cet1) end(lnasset lr intexpy) twostep vce(robust)

xtdpdsys d.lnloan l(0/4)d.fedfunds l(0/4)d.lngdp l(0/4).inf if t > 29, lags(4) ///
maxldep(3) maxlags(3) pre(cet1) end(lnasset lr intexpy) twostep vce(robust)

/* All as Endogeneous */
xtdpdsys d.lnloan l(0/4)d.fedfunds l(0/4)d.lngdp l(0/4).inf if t <= 29, lags(4) ///
maxldep(3) maxlags(3) end(cet1 lnasset lr intexpy) twostep vce(robust)

xtdpdsys d.lnloan l(0/4)d.fedfunds l(0/4)d.lngdp l(0/4).inf if t > 29, lags(4) ///
maxldep(3) maxlags(3) end(cet1 lnasset lr intexpy) twostep vce(robust)












/* Output Printout */
/* Loan Growth */
/* Two Step, Robust Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

estat abond

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

estat abond


/* Cross Sectional Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Basel */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1 & basel == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Neither */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 0 & basel == 0, ///
lags(4) vce(robust) twostep

estat abond


/* Time Series Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & stresstime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to Basel */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & baseltime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & both == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Neither */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & neither == 1, ///
lags(4) vce(robust) twostep

estat abond


/* Regression - Common Stocks */
/* Two Step, Robust Variance */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

estat abond

xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

estat abond


/* Cross Sectional Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4)

/* Banks subjected to Basel */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1 & basel == 1, ///
lags(4)

/* Banks subjected to Neither */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 0 & basel == 0, ///
lags(4) vce(robust) twostep

estat abond

/* Time Series Comparison */
/* Banks subjected to Either */
/* Two Step, Robust Variance */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to the Stress Tests */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & stresstime == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Basel */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & baseltime == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & both == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Neither */
xtdpdsys d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & neither == 1, ///
lags(4) vce(robust) twostep

estat abond


/* Regression - Retained Earnings */
/* One Step, Robust Variance */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

estat abond

xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

estat abond


/* Cross Sectional Comparison */
/* Banks subjected to Either */
/* One Step, Robust Variance */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), ///
lags(4) vce(robust)

estat abond

/* Banks subjected to the Stress Tests */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Basel */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & basel == 1, ///
lags(4) vce(robust) twostep

estat abond

/* Banks subjected to both the Stress Test and Basel */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1 & basel == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Neither */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 0 & basel == 0, ///
lags(4) vce(robust)

estat abond


/* Time Series Comparison */
/* Banks subjected to Either */
/* One Step, Robust Variance */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & either == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to the Stress Tests */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & stresstime == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Basel */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & baseltime == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to both the Stress Test and Basel */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & both == 1, ///
lags(4) vce(robust)

estat abond

/* Banks subjected to Neither */
/* Two-Step Unavailable, Use One-Step */
xtdpdsys grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29 & neither == 1, ///
lags(4) vce(robust)

estat abond

















/* Regression Results */



/* xtdpdsys */
/* One Step, GMM Variance - significant positive, positive, positive */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e1

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e2

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e3

esttab e1 e2 e3 using table1.tex, replace b(a2) ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.cet1 "Capital Ratio" LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e1 e2 e3 using tableA.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* One Step, Robust Variance - insignificant, insignificant, insignificant */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust)

est sto e4

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

est sto e5

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

est sto e6

esttab e4 e5 e6 using tableB.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* Two Step, Robust Variance - insignificant, insignificant, insignificant */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

est sto e7

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e7a

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

est sto e8

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e8a

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

est sto e9

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e9a

esttab e7 e8 e9 using table2.tex, replace b(a2) ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.cet1 "Capital Ratio" LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e7 e8 e9 using tableC.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e7a e8a e9a using table2a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")



/* Two Step, Robust Variance, with more lags included 
overall - first lag significant positive, other insignificant 
before 2009 - insignificant, after 2009 - first & fifth lags significant positive, other insignificant
after 1st quarter of 2009 - first & fifth lags significant positive, other insignificant 
after 2nd quarter of 2009 - first & fifth lags significant positive, other insignificant 
after 3rd quarter of 2009 - first & fifth lags significant positive, overall significant positive at 10% 
weakly significant positive, maybe just insignificant 
Conclusion: Remain the same significance level, so can not conclude significant cumulative effects */
/* Loan Growth - Only Cumulatively Significant When t = 32 */
/* Lags matter, GMM */
xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

est sto e10

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e10a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e10b

/* cap drop res
predict res, e
tsline res
kdensity res, normal */

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

est sto e11

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e11a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e11b

/* cap drop res
predict res, e
tsline res
kdensity res, normal */

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

est sto e12

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e12a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e12b

/* cap drop res
predict res, e
tsline res
kdensity res, normal */

esttab e10 e11 e12 using table3.tex, replace b(a2) ///
keep(L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds ///
L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e10 e11 e12 using tableD.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e10a e11a e12a using table3a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e10b e11b e12b using table3b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Capital Ratio")



xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

est sto e13

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e13a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e13b

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

est sto e14

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e14a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e14b

esttab e13 e14 using table4.tex, replace b(a2) ///
keep(L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds ///
L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
addnote("All variables are in lag form") ///
coeflabel(L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e13 e14 using tableE.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
addnote("All variables are in lag form") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e13a e14a using table4a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e13b e14b using table4b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Capital Ratio")



/* OLS (Standard) - significant negative overall, insignificant before 2009, significant negative after 2009 */
regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4

est sto e15

regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29

est sto e16

regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29

est sto e17

esttab e15 e16 e17 using tableF.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* OLS (Robust) - significant negative overall, insignificant before 2009, significant negative after 2009 */
regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, vce(robust)

est sto e18

regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, vce(robust)

est sto e19

regress d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, vce(robust)

est sto e20

esttab e18 e19 e20 using tableG.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* Fixed Effects (Standard) - insignificant, significant positive, insiginicant, robust - insignificant */
xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, fe

est sto e21

xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe

est sto e22

xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe

est sto e23

esttab e21 e22 e23 using tableH.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* FE (Robust) */
xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, fe vce(robust)

est sto e24

xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe vce(robust)

est sto e25

xtreg d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe vce(robust)

est sto e26

esttab e24 e25 e26 using tableI.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* Two Step, Robust Variance, with more lags included, and change in the capital ratio used, 
might have issue with cutoff period */
xtdpdsys d.lnloan l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1

est sto e27

xtdpdsys d.lnloan l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1

est sto e28

xtdpdsys d.lnloan l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1

est sto e29

xtdpdsys d.lnloan l(1/5)d.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test ld.cet1 l2d.cet1 l3d.cet1 l4d.cet1 l5d.cet1
lincom ld.cet1 + l2d.cet1 + l3d.cet1 + l4d.cet1 + l5d.cet1

est sto e30

esttab e27 e28 e29 e30 using tableJ.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009" "Cutoff 2009Q3") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" LD.cet1 "Change in Capital Ratio (-1)" L2D.cet1 "Change in Capital Ratio (-2)" L3D.cet1 "Change in Capital Ratio (-3)" ///
L4D.cet1 "Change in Capital Ratio (-4)" L5D.cet1 "Change in Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* Banks subjected to Either Basel or Stress tests */
xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & (stress == 1 | basel == 1), lags(4) vce(robust) twostep

est sto e31

/* Banks subjected to Both Basel and Stress tests */
xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 1 & basel == 1, lags(4) vce(robust)

est sto e32

/* Banks subjected to Neither Basel nor Stress tests */
xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29 & stress == 0 & basel == 0, lags(4) vce(robust) twostep

est sto e33

esttab e31 e32 e33 using tableK.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("Either Basel or Stress" "Both" "Neither") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lnloan "Loan Growth (-1)" L2D.lnloan "Loan Growth (-2)" L3D.lnloan "Loan Growth (-3)" ///
L4D.lnloan "Loan Growth (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")






/* Retained Earnings */
/* Lags might not matter, no correlation, GMM, OLS */
/* Capital Ratio & Federal Funds Rate do not matter */
/* Assets (-), Non-performing Loan (-) for GMM, Liquidity Ratio (-) for OLS, Non-interest expense for FE */
xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust)

est sto e34

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e34a

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust)

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e34b

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

est sto e35

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e35a

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e35b

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

est sto e36

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e36a

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e36b

esttab e34 e35 e36 using table5.tex, replace b(a2) wide ///
keep(L.grre L2.grre L3.grre L4.grre L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 ///
LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.grre "Retained Earnings (-1)" L2.grre "Retained Earnings (-2)" L3.grre "Retained Earnings (-3)" /// 
L4.grre "Retained Earnings (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e34 e35 e36 using tableL.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(L.grre "Retained Earnings (-1)" L2.grre "Retained Earnings (-2)" L3.grre "Retained Earnings (-3)" /// 
L4.grre "Retained Earnings (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e34a e35a e36a using table5a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e34b e35b e36b using table5b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Capital Ratio")



/* OLS - Insignificant lag terms, and correlation between fixed effects and X is weak */
regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, vce(robust)

est sto e37

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e37a

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, vce(robust)

est sto e38

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e38a

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, vce(robust)

est sto e39

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e39a

esttab e37 e38 e39 using table6.tex, replace b(a2) ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.grre "Retained Earnings (-1)" L2.grre "Retained Earnings (-2)" L3.grre "Retained Earnings (-3)" /// 
L4.grre "Retained Earnings (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e37 e38 e39 using tableM.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(L.grre "Retained Earnings (-1)" L2.grre "Retained Earnings (-2)" L3.grre "Retained Earnings (-3)" /// 
L4.grre "Retained Earnings (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e37a e38a e39a using table6a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")



regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4

est sto e40

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29

est sto e41

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29

est sto e42

esttab e40 e41 e42 using tableN.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(L.grre "Retained Earnings (-1)" L2.grre "Retained Earnings (-2)" L3.grre "Retained Earnings (-3)" /// 
L4.grre "Retained Earnings (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")






/* Common Stock Equity */
/* Capital Ratio does not matter overall, but maybe individually (-) */
/* Federal Funds Rate matters before 2009 (-), and when t = 32 */
/* Assets (-), Liquidity Ratio (+), Profit (-) might matter */
/* Banks might adjust capital through common stock equity, not retained earnings */
xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

est sto e43

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e43a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e43b

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

est sto e44

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e44a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e44b

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

est sto e45

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e45a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e45b

esttab e43 e44 e45 using table7.tex, replace b(a2) wide ///
keep(LD.lncs L2D.lncs L3D.lncs L4D.lncs L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 ///
LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e43 e44 e45 using tableO.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e43a e44a e45a using table7a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e43b e44b e45b using table7b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Capital Ratio")



xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

est sto e46

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e46a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e46b

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

est sto e47

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e47a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e47b

esttab e46 e47 using table8.tex, replace b(a2) wide ///
keep(LD.lncs L2D.lncs L3D.lncs L4D.lncs L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 ///
LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
addnote("All variables are in lag form") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e46 e47 using tableP.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
addnote("All variables are in lag form") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e46a e47a using table8a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e46b e47b using table8b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Capital Ratio")



/* Fixed Effects */
xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, fe vce(robust)

est sto e48

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e48a

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe vce(robust)

est sto e49

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e49a

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe vce(robust)

est sto e50

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e50a

esttab e48 e49 e50 using table9.tex, replace b(a2) ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e48 e49 e50 using tableQ.tex, replace b(a2) wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, the negative numbers in parentheses indicate lag order, lag 1 if no parenthese") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" LD.fedfunds "Monetary Policy (-1)" ///
L2D.fedfunds "Monetary Policy (-2)" L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" ///
LD.lngdp "GDP (-1)" L2D.lngdp "GDP (-2)" L3D.lngdp "GDP (-3)" L4D.lngdp "GDP (-4)" ///
L.inf "Inflation (-1)" L2.inf "Inflation (-2)" L3.inf "Inflation (-3)" L4.inf "Inflation (-4)" ///
L.unrate "Unemployment (-1)" L2.unrate "Unemployment (-2)" L3.unrate "Unemployment (-3)" L4.unrate "Unemployment (-4)" ///
LD.lnpi "State Personal Income (-1)" L2D.lnpi "State Personal Income (-2)" ///
L3D.lnpi "State Personal Income (-3)" L4D.lnpi "State Personal Income (-4)" ///
L.chr "Net Charge-off" L.npl "Nonperforming Loan" L.lnasset "Asset" ///
L.lr "Liquidity Ratio" L.intexpy "Interest Expense" L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e48a e49a e50a using table9a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")



/* Conclusion */
/* 
Significant factors:  
Loan Growth: Capital Ratio (marginally), Federal Funds Rate, Non-Performing Loan, Liquidity Ratio, Assets Level, Lags.
Retained Earnings Growth: Non-Performing Loan, Liquidity Ratio, Assets Level.
Common Stock Equity Growth: Federal Funds Rate, Liquidity Ratio, Assets Level, Profit, Lags.
Can't run sample after 2015 with the data, colinearity
Banks might adjust capital through common stock euqity, not retained earnings.  Does this mean 
that common stock equity is more adjustable than retained earnings?  Maybe not, maybe common stock 
equity is adjusted only because of profitability, not caused by capital level since capital ratio does 
not matter in the regression.
*/




xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if (time > 33 & time < 54), lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1




xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 48, lags(4) vce(robust) twostep

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincom l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1








/* Presentation Results */
/* xtdpdsys */
/* One Step, GMM Variance - significant positive, positive, positive */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e1

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e2

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4)

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincom ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e3

esttab e1 e2 e3 using tablep1.tex, replace b(a2) wide ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.cet1 "Capital Ratio" LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")



/* Two Step, Robust Variance - insignificant, insignificant, insignificant */
xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

est sto e7

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e7a

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

est sto e8

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e8a

xtdpdsys d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

est sto e9

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e9a

esttab e7 e8 e9 using tablep2.tex, replace b(a2) wide nonotes noobs ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel(L.cet1 "Capital Ratio" LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e7a e8a e9a using tablep2a.tex, replace b(a2) noobs wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")



/* Two Step, Robust Variance, with more lags included 
overall - first lag significant positive, other insignificant 
before 2009 - insignificant, after 2009 - first & fifth lags significant positive, other insignificant
after 1st quarter of 2009 - first & fifth lags significant positive, other insignificant 
after 2nd quarter of 2009 - first & fifth lags significant positive, other insignificant 
after 3rd quarter of 2009 - first & fifth lags significant positive, overall significant positive at 10% 
weakly significant positive, maybe just insignificant 
Conclusion: Remain the same significance level, so can not conclude significant cumulative effects */
/* Loan Growth - Only Cumulatively Significant When t = 32 */
/* Lags matter, GMM */
xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

est sto e10

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e10a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e10b

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

est sto e11

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e11a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e11b

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

est sto e12

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e12a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e12b

esttab e10 e11 e12 using tablep3.tex, replace b(a2) wide ///
keep(L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds ///
L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e10a e11a e12a using tablep3a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e10b e11b e12b using tablep3b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Capital Ratio")



xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

est sto e13

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e13a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e13b

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

est sto e14

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e14a

xtdpdsys d.lnloan l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e14b

esttab e13 e14 using tablep4.tex, replace b(a2) wide ///
keep(L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds ///
L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
addnote("All variables are in lag form") ///
coeflabel(L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e13a e14a using tablep4a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e13b e14b using tablep4b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Capital Ratio")



/* Retained Earnings */
/* Lags might not matter, no correlation, GMM, OLS */
/* Capital Ratio & Federal Funds Rate do not matter */
/* Assets (-), Non-performing Loan (-) for GMM, Liquidity Ratio (-) for OLS, Non-interest expense for FE */
xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust)

est sto e34

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e34a

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust)

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e34b

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

est sto e35

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e35a

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust)

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e35b

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

est sto e36

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e36a

xtdpdsys grre l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust)

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e36b

esttab e34 e35 e36 using tablep5.tex, replace b(a2) wide ///
keep(L.grre L2.grre L3.grre L4.grre L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 ///
LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(L.grre "Retained Earnings (-1)" L2.grre "Retained Earnings (-2)" L3.grre "Retained Earnings (-3)" /// 
L4.grre "Retained Earnings (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e34a e35a e36a using tablep5a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e34b e35b e36b using tablep5b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Capital Ratio")



/* OLS - Insignificant lag terms, and correlation between fixed effects and X is weak */
regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, vce(robust)

est sto e37

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e37a

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, vce(robust)

est sto e38

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e38a

regress grre l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, vce(robust)

est sto e39

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e39a

esttab e37 e38 e39 using tablep6.tex, replace b(a2) wide nonote ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel(L.grre "Retained Earnings (-1)" L2.grre "Retained Earnings (-2)" L3.grre "Retained Earnings (-3)" /// 
L4.grre "Retained Earnings (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e37a e38a e39a using tablep6a.tex, replace b(a2) noobs wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")



/* Common Stock Equity */
/* Capital Ratio does not matter overall, but maybe individually (-) */
/* Federal Funds Rate matters before 2009 (-), and when t = 32 */
/* Assets (-), Liquidity Ratio (+), Profit (-) might matter */
/* Banks might adjust capital through common stock equity, not retained earnings */
xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

est sto e43

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e43a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e43b

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

est sto e44

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e44a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e44b

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

est sto e45

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e45a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e45b

esttab e43 e44 e45 using tablep7.tex, replace b(a2) wide ///
keep(LD.lncs L2D.lncs L3D.lncs L4D.lncs L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 ///
LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
addnote("All variables are in lag form, number in parenthese indicate lag order") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e43a e44a e45a using tablep7a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e43b e44b e45b using tablep7b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Capital Ratio")



xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

est sto e46

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e46a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e46b

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

est sto e47

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e47a

xtdpdsys d.lncs l(1/5).cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 32, lags(4) vce(robust) twostep

test l1.cet1 l2.cet1 l3.cet1 l4.cet1 l5.cet1
lincomest l1.cet1 + l2.cet1 + l3.cet1 + l4.cet1 + l5.cet1

est sto e47b

esttab e46 e47 using tablep8.tex, replace b(a2) wide ///
keep(LD.lncs L2D.lncs L3D.lncs L4D.lncs L.cet1 L2.cet1 L3.cet1 L4.cet1 L5.cet1 ///
LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
addnote("All variables are in lag form") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e46a e47a using tablep8a.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Monetary Policy")

esttab e46b e47b using tablep8b.tex, replace b(a2) noobs ///
label ///
nonumbers mtitles("Pre 2009Q3" "Post 2009Q3") ///
coeflabel((1) "Cumulative Capital Ratio")



/* Fixed Effects */
xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4, fe vce(robust)

est sto e48

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e48a

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, fe vce(robust)

est sto e49

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e49a

xtreg d.lncs l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, fe vce(robust)

est sto e50

test ld.fedfunds l2d.fedfunds l3d.fedfunds l4d.fedfunds
lincomest ld.fedfunds + l2d.fedfunds + l3d.fedfunds + l4d.fedfunds

est sto e50a

esttab e48 e49 e50 using tablep9.tex, replace b(a2) wide nonote ///
keep(L.cet1 LD.fedfunds L2D.fedfunds L3D.fedfunds L4D.fedfunds L.chr L.npl L.lnasset L.lr L.intexpy L.profit L.nonixay) ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel(LD.lncs "Common Stock Equity (-1)" L2D.lncs "Common Stock Equity (-2)" L3D.lncs "Common Stock Equity (-3)" /// 
L4D.lncs "Common Stock Equity (-4)" L.cet1 "Capital Ratio (-1)" L2.cet1 "Capital Ratio (-2)" L3.cet1 "Capital Ratio (-3)" ///
L4.cet1 "Capital Ratio (-4)" L5.cet1 "Capital Ratio (-5)" ///
LD.fedfunds "Monetary Policy (-1)" L2D.fedfunds "Monetary Policy (-2)" ///
L3D.fedfunds "Monetary Policy (-3)" L4D.fedfunds "Monetary Policy (-4)" L.chr "Net Charge-off" ///
L.npl "Nonperforming Loan" L.lnasset "Asset" L.lr "Liquidity Ratio" L.intexpy "Interest Expense" ///
L.profit "Income on Loan" L.nonixay "Intermediation Cost")

esttab e48a e49a e50a using tablep9a.tex, replace b(a2) noobs wide ///
label ///
nonumbers mtitles("All Sample" "Pre 2009" "Post 2009") ///
coeflabel((1) "Cumulative Monetary Policy")



/* Conclusion */
/* 
Significant factors:  
Loan Growth: Capital Ratio (marginally), Federal Funds Rate, Non-Performing Loan, Liquidity Ratio, Assets Level, Lags.
Retained Earnings Growth: Non-Performing Loan, Liquidity Ratio, Assets Level.
Common Stock Equity Growth: Federal Funds Rate, Liquidity Ratio, Assets Level, Profit, Lags.
Can't run sample after 2015 with the data, colinearity
Banks might adjust capital through common stock euqity, not retained earnings.  Does this mean 
that common stock equity is more adjustable than retained earnings?  Maybe not, maybe common stock 
equity is adjusted only because of profitability, not caused by capital level since capital ratio does 
not matter in the regression.
*/




