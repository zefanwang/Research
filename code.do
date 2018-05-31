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
yd09 yd13 stress basel q1 q2 q3 q4

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


/* CET1 as Endogenous, Others Use Lags, 5 Lags */
xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time <= 29, lags(4) ///
end(cet1, lag(0, 5)) maxldep(5) maxlags(5) vce(robust) twostep
est sto e17
estat abond

xtdpdsys d.lnloan l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay q2 q3 q4 if time > 29, lags(4) ///
end(cet1, lag(0, 5)) maxldep(5) maxlags(5) vce(robust) twostep
est sto e18
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


/* AH IV */
ivreg d.d.lnloan (d.ld.lnloan = l2d.lnloan) d.(l(2/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay)

/* AB GMM */

/* AS nonlinear GMM */

/* For Banks subjected to the Stress Tests */
regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if stress == 1

/* For Banks subjected to Basel */
regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if basel == 1

/* For Banks subjected to both the Stress Test and Basel */
regress d.lnloan l(1/4)d.lnloan l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if stress == 1 | basel == 1



/* security over loan */

gen sl = sc/idlnls

regress sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay

regress sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29


xtreg sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay, fe

xtreg sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay, fe

xtreg sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, fe

xtreg sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, fe

xtdpdsys sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay, lags(4)

xtdpdsys sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, lags(4)

xtdpdsys sl l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, lags(4)

xtdpdsys d.lnsc l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay, lags(4)

xtdpdsys d.lnsc l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29, lags(4)

xtdpdsys d.lnsc l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29, lags(4)

regress d.lnsc l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay

regress d.lnsc l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time <= 29

regress d.lnsc l.cet1 l(1/4)d.fedfunds ///
l(1/4)d.lngdp l(1/4).inf l(1/4).unrate l(1/4)d.lnpi ///
l.chr l.npl l.lnasset l.lr l.intexpy l.profit l.nonixay if time > 29


/* Regression - Common Stocks */
/* OLS */
regress d.lncs l(1/4)d.lncs l.rbc1rwaj l(1/4)d.fedfunds l(1/4)d.lngdp ///
l(1/4).inf l(1/4).unrate l(1/4)d.lnpi l.ntlnlsr l.lnasset l.lr ///
l.intexpy l.profit l.nonixay

/* Regression - Retained Earnings */
/* OLS */
regress grre l(1/4).grre l.rbc1rwaj l(1/4)d.fedfunds l(1/4)d.lngdp ///
l(1/4).inf l(1/4).unrate l(1/4)d.lnpi l.ntlnlsr l.lnasset l.lr ///
l.intexpy l.profit l.nonixay

/* Fixed Effects */

/* AH IV */

/* AB GMM */

/* AS nonlinear GMM */

/* BB system GMM */

























