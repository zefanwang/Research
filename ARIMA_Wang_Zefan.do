/* Econ 825 */
/* Homework 1 */
/* Zefan Wang */
/* 03/16/2016 */

/* Import Data */
insheet using "C:\Temp\econ825\hw_arima\US_IFS_2006.csv", names comma clear
describe
list time base   /* 8 missing value at beginning */

/* Time Series */
gen time_1=q(1957q1)+_n-1
format time_1 %tq
tsset time_1

describe
list time time_1

save "C:\Temp\econ825\hw_arima\US_IFS_2006.dta", replace
use "C:\Temp\econ825\hw_arima\US_IFS_2006.dta", clear

/* Summary and Time Series Plots */
codebook base
tsline base

/* 1. Unit Root Test */
/* 1.1 Stanard ADF Test */
gen yyy=log(base)
label var yyy "log(base)"
tsline yyy
tsline d.yyy
tsline d2.yyy
gen trend=_n

scalar T=191   /* 9 missing values */
scalar pmax=int(12*((T+1)/100)^0.25)
scalar miss=8   /* 8 missing values at beginning */

/* level */
scalar diff=0
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg yyy trend l.yyy l(1/14)d.yyy
estat ic
matrix y_order=r(S)
reg yyy trend l.yyy l(1/13)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/12)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/11)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/10)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/9)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/8)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/7)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/6)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/5)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/4)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/3)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/2)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy ld.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))

matlist y_order   /* AIC:16-3=13, BIC:15-3=12 */
dfuller yyy, trend lag(13)   /* -1.618>-3.44 accept H0, Unit Root, DS with Drift */
dfuller yyy, trend lag(12)   /* -1.854>-3.44 accept H0, Unit Root, DS with Drift */

/* first-difference */
scalar diff=1
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg d.yyy ld.yyy l(1/14)d2.yyy
estat ic
matrix dy_order=r(S)
reg d.yyy ld.yyy l(1/13)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/12)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/11)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/10)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/9)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/8)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/7)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/6)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/5)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/4)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/3)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/2)d2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy ld2.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))

matlist dy_order   /* AIC:16-2=14, BIC:13-2=11 */
dfuller d.yyy, lag(14)   /* -3.224<-2.885 reject H0, Accept C.S. */
dfuller d.yyy, lag(11)   /* -3.071<-2.885 reject H0, Accept C.S. */

/* AIC: yyy ~ I(1) with drift */
/* BIC: yyy ~ I(1) with drift */

/* 1.2 ADF Test with Seasonal Dummies */
gen quarter=quarter(dofq(time_1))
gen sd_1=(quarter==1)
gen sd_2=(quarter==2)
gen sd_3=(quarter==3)
gen sd_4=(quarter==4)
list time_1 quarter sd_* in 1/20, sep(4)

/* level */
scalar diff=0
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg yyy trend l.yyy l(1/14)d.yyy sd_1 sd_2 sd_3
estat ic
matrix y_order=r(S)
reg yyy trend l.yyy l(1/13)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/12)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/11)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/10)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/9)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/8)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/7)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/6)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/5)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/4)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/3)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy l(1/2)d.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy ld.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy trend l.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))

matlist y_order   /* AIC:14-6=8, BIC:8-6=2 */
reg yyy trend l.yyy l(1/8)d.yyy sd_1 sd_2 sd_3   /* AIC:-2.035 > -3.44 accept H0, Unit Root, DS with Drift */
reg yyy trend l.yyy l(1/2)d.yyy sd_1 sd_2 sd_3   /* BIC:-4.021 < -3.44 reject H0, TS */

/* first-difference AIC */
scalar diff=1
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg d.yyy ld.yyy l(1/14)d2.yyy sd_1 sd_2 sd_3
estat ic
matrix dy_order=r(S)
reg d.yyy ld.yyy l(1/13)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/12)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/11)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/10)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/9)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/8)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/7)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/6)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/5)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/4)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/3)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/2)d2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy ld2.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy sd_1 sd_2 sd_3 if _n>p_reg
estat ic
matrix dy_order=(dy_order \ r(S))

matlist dy_order   /* AIC:12-5=7 */
reg d.yyy ld.yyy l(1/7)d2.yyy sd_1 sd_2 sd_3   /* -3.506 < -2.885 reject H0, Accept C.S. */

/* AIC: yyy ~ I(1) with drift */
/* BIC: yyy ~ T.S. */

/* 2. Seasonal Unit Root Test */
/* hegy4 */
hegy4 yyy, det(strend) lag(1/4) level(75)   /* accept at 0 frequency, reject at other frequencies */

/* sroot */
sroot yyy, lags(4) trend season(quarter)   /* accept at 0 frequency, reject at other frequencies */

/* has one unit root, difference once */

/* 3.1 ARIMA Modeling */
/* AIC ~ I(1) */
tsline d.yyy
corrgram d.yyy, lags(24)   /* T=191, by default, lag=min{int[T/2]-2,40}=40 */
ac d.yyy, lags(24) level(95)
pac d.yyy, lags(24) level(95)

/* Standard ARMA models */
arima yyy, arima(4,1,0)
arima yyy, arima(2,1,0)
arima yyy, arima(2,1,1)
arima yyy, arima(1,1,1)
arima yyy, arima(1,1,0)
arima d.yyy, ar(1/4)
arima d.yyy, ar(1 4)
arima d.yyy, ar(1)
arima d.yyy, ma(1/4)

cap drop res
predict res, residuals
tsline res
corrgram res, lags(24)
wntestq res, lags(24)
armaroots

/* Additive Seasonal ARMA models */
arima d.yyy, ar(1 4) ma(1 4)
arima d.yyy, ar(1 4)

cap drop res
predict res, residuals
tsline res
corrgram res, lags(24)
wntestq res, lags(24)	
armaroots

/* Pure SARMA models */
arima d.yyy, sarima(1,0,1,4)
arima d.yyy, sarima(1,0,0,4)
arima yyy, sarima(1,1,1,4)

cap drop res
predict res, residuals
tsline res
corrgram res, lags(24)
wntestq res, lags(24)	
armaroots

/* Multiplicative Seasonal ARMA */
arima yyy, arima(1,1,1) sarima(1,0,1,4)
arima d.yyy, ar(1) ma(1) mar(1,4) mma(1,4)
arima yyy, arima(1,1,1) mar(1,4)

cap drop res
predict res, residuals
tsline res
corrgram res, lags(24)
wntestq res, lags(24)	
armaroots

/* 3.2 Structure ARMA */
reg d.yyy sd_1 sd_2 sd_3
cap drop res
predict res, residuals
ac res, lags(24) level(95)
pac res, lags(24) level(95)

arima d.yyy sd_1 sd_2 sd_3, ar(4) ma(4)
arima d.yyy sd_1 sd_2 sd_3, ar(2) ma(4)   /* good keep */
arima d.yyy sd_1 sd_2 sd_3, ar(4) ma(2)   /* good keep */
arima d.yyy sd_1 sd_2 sd_3, ar(2) ma(2)
arima d.yyy sd_1 sd_2 sd_3, ar(8) ma(8)
arima d.yyy sd_1 sd_2 sd_3, ar(4) ma(8)
arima d.yyy sd_1 sd_2 sd_3, ar(4) ma(6)   /* keep */
arima d.yyy sd_1 sd_2 sd_3, ar(6) ma(4)
arima d.yyy sd_1 sd_2 sd_3, ar(4)
arima d.yyy sd_1 sd_2 sd_3, ar(8) ma(4)
arima d.yyy sd_1 sd_2 sd_3, ar(8) ma(2)

cap drop res
predict res, residuals
tsline res
corrgram res, lags(24)
wntestq res, lags(24)	
armaroots

/* model selection */
quietly arima d.yyy sd_1 sd_2 sd_3, ar(2) ma(4)
estat ic
quietly arima d.yyy sd_1 sd_2 sd_3, ar(4) ma(2)   /* best according to both AIC and BIC */
estat ic
quietly arima d.yyy sd_1 sd_2 sd_3, ar(4) ma(6)
estat ic

/* 4. Forecast yyy */
/* 4.1 In-Sample Fitted Values */
arima d.yyy sd_1 sd_2 sd_3, ar(4) ma(2)

cap drop y_fit	
predict y_fit, y
label var y_fit "In-sample fitted values of levels"
list time y_fit
tsline yyy y_fit if tin(1957q1,2006q2)

cap drop y_error mse rmspe mppe mappe
gen y_error=y_fit-yyy
replace y_error=. if time_1<tq(1957q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

/* 4.2 Dynamic Forecasts */
arima d.yyy sd_1 sd_2 sd_3 if tin(1957q1,1998q4), ar(4) ma(2)

cap drop y_dyn
predict y_dyn, y dynamic(tq(1999q1))		
label var y_dyn "dynamic forecasts of levels"
list time y_dyn if time_1>=tq(1999q1)
tsline yyy y_dyn if tin(1999q1,)

cap drop y_error mse rmspe mppe mappe
gen y_error=y_dyn-yyy
replace y_error=. if time_1<tq(1999q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

/* 4.3 One-Step-Ahead Forecast */
arima d.yyy sd_1 sd_2 sd_3 if tin(1957q1,1998q4), ar(4) ma(2)

cap drop y_h1
predict y_h1, y 
label var y_h1 "1-step-ahead forecasts of levels"
list time y_h1 if time_1==tq(1999q1)

cap drop y_hat
gen y_hat = .
cap drop y_hat_table
gen y_hat_table = .
label var y_hat_table "yyy, ARIMA, h=1"

set more off
local h = 1                  /* set the h for h-step-ahead-forcast */ 
local i=168                  /* set last obs of estimation sample */
local l=`i'+`h'
local k=198                  /* set last obs of forecast sample */

while `i' <=`k'-`h' {

	quietly arima d.yyy sd_1 sd_2 sd_3 in 1/`i', ar(4) ma(2)

cap drop y_hat	
predict y_hat, y 
		
local j=`i'+`h' 
*	list time y_hat in `j'/`j'
replace y_hat_table = y_hat in `j'/`j'

local i=`i'+1
}

list time yyy y_hat_table in `l'/`k'
tsline yyy y_hat_table in `l'/`k'

cap drop y_error mse rmspe mppe mappe
gen y_error=y_hat_table-yyy
egen mse= mean(y_error^2)
gen rmspe= sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop y_h1
gen y_h1=y_hat_table

/* 4.4 Four-Step-Ahead Forecast */
arima d.yyy sd_1 sd_2 sd_3 if tin(1957q1,1998q4), ar(4) ma(2)

cap drop y_h4
predict y_h4, y dynamic(tq(1999q1))
label var y_h4 "4-step-ahead forecasts of levels"
list time y_h4 if time_1==tq(1999q4)		/* forecasts start in 1999Q4 */

cap drop y_hat
gen y_hat = .
cap drop y_hat_table
gen y_hat_table = .
label var y_hat_table "yyy, ARIMA, h=4"

set more off
local h = 4                  /* set the h for h-step-ahead-forcast */ 
local i=168                  /* set last obs of estimation sample */
local t0=tq(1998q4)			/* set ending date of estimation sample */
local l=`i'+`h'
local k=198                  /* set last obs of forecast sample */

while `i' <=`k'-`h' {

	quietly arima d.yyy sd_1 sd_2 sd_3 in 1/`i', ar(4) ma(2)

cap drop y_hat	
predict y_hat, y dynamic(`t0'+1)
		
local j=`i'+`h' 
*	list time y_hat in `j'/`j'
replace y_hat_table = y_hat in `j'/`j'

local i=`i'+1
local t0=`t0'+1
}
list time yyy y_hat_table in `l'/`k'
tsline yyy y_hat_table in `l'/`k'

cap drop y_error mse rmspe mppe mappe
gen y_error=y_hat_table-yyy
egen mse= mean(y_error^2)
gen rmspe= sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop y_h4
gen y_h4=y_hat_table

tsline yyy y_fit y_dyn y_h1 y_h4 if tin(1999q1,2006q3)





























