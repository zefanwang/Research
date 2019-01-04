/* Econ 825 */
/* Homework 2 */
/* Zefan Wang */
/* 04/12/2016 */

clear
clear matrix
set memory 100m

/* A. Import Data */
insheet using"C:\Users\zefan\Desktop\Econ825\us.csv", names comma clear
describe

/* B. Time Series */
gen time=quarterly(date,"yq")
tsset time, quarterly

describe
list date time gdp85 gdpdef m1 govt, sep(4)

/* C. Summary Statistics & Time Series Plots */
codebook gdp85 gdpdef m1 govt
tsline gdp85
tsline gdpdef
tsline m1
tsline govt

gen y=log(gdp85)
gen p=log(gdpdef)
gen m=log(m1)
gen x=log(govt)
label var y "log(GDP)"
label var p "log(GDP Deflator)"
label var m "log(Money Supply)"
label var x "log(Government Purchase)"
tsline y
tsline p
tsline m
tsline x

tsline d.y
tsline d2.p
tsline d.m
tsline d.x

/* 1. VAR Modeling of (d.y, d2.p, d.m, d.x) */
/* 1.1 Fit a Standard VAR to (d.y, d2.p, d.m, d.x) */
varsoc d.y d2.p d.m d.x, maxlag(8) /* AIC: P=4, SBC: P=1 */

/* AIC: P=4 */
var d.y d2.p d.m d.x, lags(1/4)
varlmar, mlag(8) /* ok */
varstable /* not good, some of roots are close to unit */
varnorm /* ok, not good, P-value of JB test for d.m is smaller than 0.05 */

cap drop r_y r_p r_m r_x
predict r_y, equation(#1) residuals
predict r_p, equation(#2) residuals
predict r_m, equation(#3) residuals
predict r_x, equation(#4) residuals
tsline r_y
tsline r_p
tsline r_m
tsline r_x
corrgram r_y, lags(32) /* ok */
corrgram r_p, lags(32) /* ok */
corrgram r_m, lags(32) /* ok */
corrgram r_x, lags(32) /* ok */

/* BIC: P=1 */
var d.y d2.p d.m d.x, lag(1)
varlmar, mlag(8) /* lag2, lag4 and lag8 are significant */
varstable /* good */
varnorm /* some p-values are small - reject null of normal */

cap drop r_y r_p r_m r_x
predict r_y, equation(#1) residuals
predict r_p, equation(#2) residuals
predict r_m, equation(#3) residuals
predict r_x, equation(#4) residuals
tsline r_y
tsline r_p
tsline r_m
tsline r_x
corrgram r_y, lags(32) /* ok */
corrgram r_p, lags(32) /* not ok */
corrgram r_m, lags(32) /* not ok */
corrgram r_x, lags(32) /* ok */

/* 1.2 Fit an Augmented VAR to (d.y, d2.p, d.m, d.x) */
/* Seasonality */
gen quarter=quarter(dofq(time))
gen sd_1=(quarter==1)
gen sd_2=(quarter==2)
gen sd_3=(quarter==3)
gen sd_4=(quarter==4)
list time quarter sd_* in 1/20, sep(4)

varsoc d.y d2.p d.m d.x, exog(sd_1 sd_2 sd_3) maxlag(8) /* AIC: P=3, SBC: P=0 */

var d.y d2.p d.m d.x, exog(sd_1 sd_2 sd_3) lags(1/3)
test sd_1 sd_2 sd_3

varlmar, mlag(4) /* good, all greater than 0.01 */
varstable /* good, all invert roots are inside unit circle */
varnorm /* ok, p-values of d.m for skewness is smaller than 0.05 */

cap drop r_y r_p r_m r_x
predict r_y, equation(#1) residuals
predict r_p, equation(#2) residuals
predict r_m, equation(#3) residuals
predict r_x, equation(#4) residuals
tsline r_y
tsline r_p
tsline r_m
tsline r_x
corrgram r_y, lags(32) /* good */
corrgram r_p, lags(32) /* good */
corrgram r_m, lags(32) /* good */
corrgram r_x, lags(32) /* good */

/* 1.3 Testing the Effectiveness of Monetary and Fiscal Policies */
/* 1.3.1 Granger Causality Test */
var d.y d2.p d.m d.x, exog(sd_1 sd_2 sd_3) lags(1/3)

test [D_m]ld.y ld2.p l2d.y l2d2.p l3d.y l3d2.p [D_x]ld.y ld2.p l2d.y l2d2.p l3d.y l3d2.p /* H0: d.y & d2.p do not Granger-Cause d.m & d.x */
/* P-value is small, reject H0 of no Granger Causality */
test [D_y]ld.m ld.x l2d.m l2d.x l3d.m l3d.x [D2_p]ld.m ld.x l2d.m l2d.x l3d.m l3d.x /* H0: d.m & d.x do not Granger-Cause d.y & d2.p */
/* P-value is small, reject H0 of no Granger Causality */

/* 1.3.2 Test for Contemporaneous Effect via the Error Covariance Matrix */
var d.y d2.p d.m d.x, exog(sd_1 sd_2 sd_3) lags(1/3)
scalar ll_sys=e(ll)

reg d.y ld.y ld2.p ld.m ld.x sd_1 sd_2 sd_3
scalar ll_y=e(ll)
reg d2.p ld.y ld2.p ld.m ld.x sd_1 sd_2 sd_3
scalar ll_p=e(ll)
reg d.m ld.y ld2.p ld.m ld.x sd_1 sd_2 sd_3
scalar ll_m=e(ll)
reg d.x ld.y ld2.p ld.m ld.x sd_1 sd_2 sd_3
scalar ll_x=e(ll)

scalar lrt=2*(ll_sys-ll_y-ll_p-ll_m-ll_x)
scalar list ll_sys ll_y ll_p ll_m ll_x lrt
display invchi2(4,1-0.05)
/* lrt=17.298387 > chi2(9.487729), reject H0 of No Contemporaneous Effect */

/* 1.4 Impulse Response Analysis and Forecase Error Variance Decomposition */
cap drop dy d2p dm dx
gen dy=d.y
gen d2p=d2.p
gen dm=d.m
gen dx=d.x

/* Orthogonalized IRF & FEVD */

irf set oir_ovd, replace

var dy d2p dm dx, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order1, step(8) replace

irf table oirf, irf(order1) impulse(dm) response(dy d2p) level(90)
irf graph oirf, irf(order1) impulse(dm) response(dy d2p) level(90)

irf table oirf, irf(order1) impulse(dx) response(dy d2p) level(90)
irf graph oirf, irf(order1) impulse(dx) response(dy d2p) level(90)

irf table fevd, irf(order1) impulse(dm) response(dy d2p) level(99)
irf graph fevd, irf(order1) impulse(dm) response(dy d2p) level(99)

irf table fevd, irf(order1) impulse(dx) response(dy d2p) level(99)
irf graph fevd, irf(order1) impulse(dx) response(dy d2p) level(99)

/* Sum of OVD */
irf set oir_ovd, replace
var dy d2p dm dx, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order1, step(4) replace
irf table fevd, irf(order1) impulse(dy d2p dm dx) response(dy) level(99)
irf table fevd, irf(order1) impulse(dy d2p dm dx) response(d2p) level(99)

/* Generalized IRF & FEVD */
irf set gir_gvd, replace

var dm dy d2p dx, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order1, step(8) replace 	
irf table oirf, irf(order1) impulse(dm) response(dy d2p)
irf graph oirf, irf(order1) impulse(dm) response(dy d2p)
irf table fevd, irf(order1) impulse(dm) response(dy d2p)
irf graph fevd, irf(order1) impulse(dm) response(dy d2p)

var dx dy d2p dm, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order2, step(8) replace
irf table oirf, irf(order2) impulse(dx) response(dy d2p)
irf graph oirf, irf(order2) impulse(dx) response(dy d2p)
irf table fevd, irf(order2) impulse(dx) response(dy d2p)
irf graph fevd, irf(order2) impulse(dx) response(dy d2p)

/* Sum of GVD */
irf set gir_gvd, replace
var dy d2p dm dx, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order1, step(4) replace 
irf table fevd, irf(order1) impulse(dy) response(dy)
irf table fevd, irf(order1) impulse(dy) response(d2p)

irf set gir_gvd, replace
var d2p dy dm dx, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order2, step(4) replace 
irf table fevd, irf(order2) impulse(d2p) response(dy)
irf table fevd, irf(order2) impulse(d2p) response(d2p)

irf set gir_gvd, replace
var dm dy d2p dx, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order3, step(4) replace 
irf table fevd, irf(order3) impulse(dm) response(dy)
irf table fevd, irf(order3) impulse(dm) response(d2p)

irf set gir_gvd, replace
var dx dy d2p dm, exog(sd_1 sd_2 sd_3) lags(1/3)
irf create order4, step(4) replace 
irf table fevd, irf(order4) impulse(dx) response(dy)
irf table fevd, irf(order4) impulse(dx) response(d2p)

/* 2.0 Forecasting */
/* A. In-sample fitted values */
var d.y d2.p d.m d.x, exog(sd_1 sd_2 sd_3) lags(1/3)
cap drop fit_dy fit_d2p fit_dm fit_dx
predict fit_dy, equation(D_y) xb	
predict fit_d2p, equation(D2_p) xb	
predict fit_dm, equation(D_m) xb
predict fit_dx, equation(D_x) xb
label var fit_dy "d.y, VAR(1), in-sample fit"
label var fit_d2p "d2.p, VAR(1), in-sample fit"
label var fit_dm "d.m, VAR(1), in-sample fit"
label var fit_dx "d.x, VAR(1), in-sample fit"
	
list date fit_dy fit_d2p fit_dm fit_dx

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.y
gen y_fit=fit_dy
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d2.p
gen y_fit=fit_d2p
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.m
gen y_fit=fit_dm
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.x
gen y_fit=fit_dx
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

/* B. Dynammic forecasts */
/* estimation sample is fixed as (1960Q1-1986Q4), forecast horizon ranges from 1 to 20 (1987Q1-1991Q4)*/
var d.y d2.p d.m d.x if tin(,1986q4), exog(sd_1 sd_2 sd_3) lags(1/3)
fcast compute dyn_, step(20) replace
label var dyn_D_y "d.y, VAR(1), dynamic forecasts"
label var dyn_D2_p "d2.p, VAR(1), dynamic forecasts"
label var dyn_D_m "d.m, VAR(1), dynamic forecasts"
label var dyn_D_x "d.x, VAR(1), dynamic forecasts"

list date dyn_D_y dyn_D2_p dyn_D_m dyn_D_x	/* dyn_* actually starts in 1986Q4 (h=0) */

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.y
gen y_fit=dyn_D_y
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d2.p
gen y_fit=dyn_D2_p
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.m
gen y_fit=dyn_D_m
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.x
gen y_fit=dyn_D_x
gen y_error=y_fit-yyy
replace y_error=. if time<tq(1987q1)
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1


/* C. 1-step-ahead forecasts */
/* estimation sample starts (1960Q1-1986Q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=1 */
var d.y d2.p d.m d.x if tin(,1986q4), exog(sd_1 sd_2 sd_3) lags(1/3)
fcast compute h1_, step(1) replace		/* forecasts start in 1987Q1 */
list date h1_D_y h1_D2_p h1_D_x h1_D_m if date=="1987Q1"

cap drop y1_hat_table y2_hat_table y3_hat_table y4_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .
gen y4_hat_table = .

set more off
local h=1					/* set the h for h-step-ahead-forcast */ 
local i=108					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=128					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly var d.y d2.p d.m d.x in 1/`i', exog(sd_1 sd_2 sd_3) lags(1/3) 
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 
*	list date hat_D_y hat_D2_p hat_D_m hat_D_x in `j'/`j'
replace y1_hat_table = hat_D_y in `j'/`j'
replace y2_hat_table = hat_D2_p in `j'/`j'
replace y3_hat_table = hat_D_m in `j'/`j'
replace y4_hat_table = hat_D_x in `j'/`j'
local i=`i'+1
}
tsline d.y y1_hat_table in `l'/`k'
tsline d2.p y2_hat_table in `l'/`k'
tsline d.m y3_hat_table in `l'/`k'
tsline d.x y4_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table y4_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.y
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d2.p
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.m
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.x
gen y_fit=y4_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h1_D_y h1_D2_p h1_D_m h1_D_x
gen h1_D_y=y1_hat_table
gen h1_D2_p=y2_hat_table
gen h1_D_m=y3_hat_table
gen h1_D_x=y4_hat_table
label var h1_D_y "d.y, VAR(1), h=1"
label var h1_D2_p "d2.p, VAR(1), h=1"
label var h1_D_m "d.m, VAR(1), h=1"
label var h1_D_x "d.x, VAR(1), h=1"

/* D. 4-step-ahead forecasts */
/* estimation sample starts (1960Q1-1986Q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=4 */
var d.y d2.p d.m d.x if tin(,1986q4), exog(sd_1 sd_2 sd_3) lags(1/3)
fcast compute h4_, step(4) replace		/* forecasts start in 1987Q4 */
list date h4_D_y h4_D2_p h4_D_m h4_D_x if date=="1987Q4"

cap drop y1_hat_table y2_hat_table y3_hat_table y4_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .
gen y4_hat_table = .

set more off
local h=4					/* set the h for h-step-ahead-forcast */ 
local i=108					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=128					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly var d.y d2.p d.m d.x in 1/`i', exog(sd_1 sd_2 sd_3) lags(1/3) 
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 
*	list date hat_D_y hat_D2_p hat_D_m hat_D_x in `j'/`j'
replace y1_hat_table = hat_D_y in `j'/`j'
replace y2_hat_table = hat_D2_p in `j'/`j'
replace y3_hat_table = hat_D_m in `j'/`j'
replace y4_hat_table = hat_D_x in `j'/`j'
local i=`i'+1
}
tsline d.y y1_hat_table in `l'/`k'
tsline d2.p y2_hat_table in `l'/`k'
tsline d.m y3_hat_table in `l'/`k'
tsline d.x y4_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table y4_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.y
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d2.p
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.m
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.x
gen y_fit=y4_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h4_D_y h4_D2_p h4_D_m h4_D_x
gen h4_D_y=y1_hat_table
gen h4_D2_p=y2_hat_table
gen h4_D_m=y3_hat_table
gen h4_D_x=y4_hat_table
label var h4_D_y "d.y, VAR(1), h=4"
label var h4_D2_p "d2.p, VAR(1), h=4"
label var h4_D_m "d.m, VAR(1), h=4"
label var h4_D_x "d.x, VAR(1), h=4"

/* forecast comparison */
tsline d.y fit_dy dyn_D_y h1_D_y h4_D_y if tin(1987q1,)
tsline d2.p fit_d2p dyn_D2_p h1_D2_p h4_D2_p if tin(1987q1,)
tsline d.m fit_dm dyn_D_m h1_D_m h4_D_m if tin(1987q1,)
tsline d.x fit_dx dyn_D_x h1_D_x h4_D_x if tin(1987q1,)











































 


