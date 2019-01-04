/* Econ 825 */
/* Homework 3 */
/* Zefan Wang */
/* 05/04/2016 */

clear
clear matrix
set memory 100m

			/*** Import Data ***/

insheet using "C:\Users\buec-lab\Desktop\Money.csv", names comma clear
/*insheet using "C:\Users\zefan\Desktop\Econ825\Money.csv", names comma clear*/

describe
gen time_1=q(1947q1)+_n-1
format time_1 %tq
tsset time_1

describe

			/*** Unit Root Test ***/
label var mp "log of real money balance M2"
label var y "log of real private output"
label var r "interest rate"
codebook mp y r
tsline mp
tsline y
tsline r

list time_1 mp y r
gen trend=_n

			/*** Unit Root Test for mp ***/
scalar T=168
scalar pmax=int(12*((T+1)/100)^0.25)
scalar miss=0

/* ADF Tests for mp */
cap drop yyy
gen yyy=mp
tsline yyy
ac yyy

scalar diff=0
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg yyy trend l.yyy l(1/13)d.yyy
estat ic
matrix y_order=r(S)
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

matlist y_order		/* AIC: P=1, BIC: P=1 */
dfuller yyy, trend lag(1)   /* accept null of unit root */

/* first-difference */
tsline d.yyy

scalar diff=1
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg d.yyy ld.yyy l(1/13)d2.yyy, noconst
estat ic
matrix dy_order=r(S)
reg d.yyy ld.yyy l(1/12)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/11)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/10)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/9)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/8)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/7)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/6)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/5)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/4)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/3)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/2)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy ld2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))

matlist dy_order		/* AIC: P=1-1=0, BIC: P=1-1=0 */
dfuller d.yyy, noconstant   /* reject null of unit root, mp is I(1) with drift */
/* reject null of Great Ratio Test */

/* ADF-GLS Test for mp */
dfgls yyy /* AIC,BIC: p=1 */
dfgls yyy, maxlag(1) /* Accept null */
dfgls d.yyy, notrend /* AIC:maxlag=4, BIC:maxlag=1 */
dfgls d.yyy, maxlag(4) notrend /* reject null of unit root */
dfgls d.yyy, maxlag(1) notrend /* reject null of unit root */
/* AIC,BIC: mp is I(1) with drift */

			/*** Unit Root Test for y ***/
scalar T=168
scalar pmax=int(12*((T+1)/100)^0.25)
scalar miss=0

/* ADF Tests for y */
cap drop yyy
gen yyy=y
tsline yyy
ac yyy

scalar diff=0
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg yyy trend l.yyy l(1/13)d.yyy
estat ic
matrix y_order=r(S)
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

matlist y_order		/* AIC: P=5-3=2, BIC: P=4-3=1 */
dfuller yyy, trend lag(2)   /* AIC: reject null of unit root */
dfuller yyy, trend lag(1)   /* BIC: accept null of unit root */

/* first difference */
tsline d.yyy

scalar diff=1
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg d.yyy ld.yyy l(1/13)d2.yyy, noconst
estat ic
matrix dy_order=r(S)
reg d.yyy ld.yyy l(1/12)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/11)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/10)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/9)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/8)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/7)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/6)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/5)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/4)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/3)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/2)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy ld2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))

matlist dy_order		/* BIC: P=1-1=0 */
dfuller d.yyy, noconstant   /* reject null of unit root, mp is I(1) with drift */
/* AIC:y is T.S.   BIC:y is I(1) with drift */

/* ADF-GLS Test for y */
dfgls yyy /* AIC:p=13 BIC:p=1 */
dfgls yyy, maxlag(13) /* AIC:Accept null */
dfgls yyy, maxlag(1) /* BIC:reject null */
dfgls d.yyy, notrend /* AIC:p=1, BIC:p=1 */
dfgls d.yyy, maxlag(1) notrend /* reject null of unit root */
/* AIC:y is I(1) with drift, BIC:y is T.S. */ 


	/*** Unit Root Test for R ***/
scalar T=168
scalar pmax=int(12*((T+1)/100)^0.25)
scalar miss=0

/* ADF Tests for R */
cap drop yyy
gen yyy=r
tsline yyy
ac yyy

scalar diff=0
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg yyy l.yyy l(1/13)d.yyy
estat ic
matrix y_order=r(S)
reg yyy l.yyy l(1/12)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/11)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/10)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/9)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/8)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/7)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/6)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/5)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/4)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/3)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy l(1/2)d.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy ld.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))
reg yyy l.yyy if _n>p_reg
estat ic
matrix y_order=(y_order \ r(S))

matlist y_order		/* AIC: P=9-2=7, BIC: P=9-2=7 */
dfuller yyy, lag(7)   /* AIC,BIC: accept null of unit root */

/* first difference */
tsline d.yyy

scalar diff=1
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

reg d.yyy ld.yyy l(1/13)d2.yyy, noconst
estat ic
matrix dy_order=r(S)
reg d.yyy ld.yyy l(1/12)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/11)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/10)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/9)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/8)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/7)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/6)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/5)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/4)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/3)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy l(1/2)d2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy ld2.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))
reg d.yyy ld.yyy if _n>p_reg, noconst
estat ic
matrix dy_order=(dy_order \ r(S))

matlist dy_order		/* AIC,BIC: P=7-1=6 */
dfuller d.yyy, lag(6) noconstant   /* reject null of unit root */
/* AIC,BIC: R is I(1) without drift */

/* ADF-GLS Test for R */
dfgls yyy, notrend /* AIC:p=7 BIC:p=7 */
dfgls yyy, maxlag(7) /* AIC:Accept null */
dfgls d.yyy, notrend /* AIC:p=4, BIC:p=6 */
dfgls d.yyy, maxlag(4) notrend /* reject null of unit root */
dfgls d.yyy, maxlag(6) notrend /* reject null of unit root */
/* R is I(1) without drift */


			/* Residual-Based Cointegration Test */
tsline mp y r

scalar T=168
scalar pmax=int(12*((T+1)/100)^0.25)
scalar miss=0
scalar diff=0		
scalar p_reg=pmax+1+diff+miss
scalar list pmax diff p_reg

/* Dependent Varible mp: log of real money balance m2 */
reg mp y r
cap drop res
predict res, residuals

reg res l.res l(1/13)d.res, noconst
estat ic
matrix res_order=r(S)
reg res l.res l(1/12)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/11)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/10)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/9)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/8)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/7)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/6)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/5)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/4)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/3)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/2)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res ld.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))

matlist res_order				/* AIC: P=1, SIC: P=1 */
dfuller res, lag(1) noconstant	/* 5% critical value: -3.42, reject null of no cointegration */


/* Dependent Variable y: log of real private output */
reg y mp r
cap drop res
predict res, residuals

reg res l.res l(1/13)d.res, noconst
estat ic
matrix res_order=r(S)
reg res l.res l(1/12)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/11)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/10)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/9)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/8)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/7)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/6)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/5)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/4)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/3)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/2)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res ld.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))

matlist res_order				/* AIC: P=9, SIC: P=0 */
dfuller res, lag(9) noconstant	/* 5% critical value: -3.42, reject null of no cointegration */
dfuller res, noconstant	/* 5% critical value: -3.42, reject null of no cointegration */

			
/* Dependent Variable r: interest rate */
reg r mp y
cap drop res
predict res, residuals

reg res l.res l(1/13)d.res, noconst
estat ic
matrix res_order=r(S)
reg res l.res l(1/12)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/11)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/10)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/9)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/8)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/7)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/6)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/5)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/4)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/3)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res l(1/2)d.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res ld.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))
reg res l.res if _n>p_reg, noconst
estat ic
matrix res_order=(res_order \ r(S))

matlist res_order				/* AIC: P=8, SIC: P=5 */
dfuller res, lag(8) noconstant	/* 5% critical value: -3.42, accept null of no cointegration */
dfuller res, lag(5) noconstant	/* 5% critical value: -3.42, reject null of no cointegration */


/****** Johansen's Approach ******/
varsoc mp y r, maxlag(4) /* AIC: P=3, SBC: P=2 */

var mp y r, lags(1/3)
varstable
varlmar, mlag(4) /* not OK */
cap drop r_mp r_y r_r
predict r_mp, equation(#1) residuals
predict r_y, equation(#2) residuals
predict r_r, equation(#3) residuals
tsline r_mp
tsline r_y
tsline r_r
corrgram r_mp, lags(32)	/* OK */
corrgram r_y, lags(32)	/* OK */
corrgram r_r, lags(32)	/* not OK */

vecrank mp y r, lags(3) max ic levela /* Rank is 1 */

/* ML Estimation of VECM */
vec mp y r, lags(3) rank(1)
vecstable
vecnorm
veclmar, mlag(4)

/* Granger Causality Test */
vec mp y r, lags(3) rank(1)
test [D_mp]:ld.y l2d.y ld.r l2d.r l1._ce1 /* reject null of no Granger-Causality */
display invchi2(5,1-.05)

/* Impulse Response Analysis and Forecast Error Variance Decomposition */
/* generalized IR and VD of MP to a one-time unit shock to Y */
irf set gir_gvd, replace

vec y mp r, lags(3) rank(1)
irf create order1, step(48)
irf table oirf, irf(order1) impulse(y) response(mp)
irf graph oirf, irf(order1) impulse(y) response(mp)
irf table fevd, irf(order1) impulse(y) response(mp)
irf graph fevd, irf(order1) impulse(y) response(mp)
irf table oirf, irf(order1) impulse(y) response()
irf graph oirf, irf(order1) impulse(y) response()

/* generalized IR of MP to a one-time unit shock to R */
vec r mp y, lags(3) rank(1)
irf create order2, step(48)
irf table oirf, irf(order2) impulse(r) response(mp)
irf graph oirf, irf(order2) impulse(r) response(mp)
irf table fevd, irf(order2) impulse(r) response(mp)
irf graph fevd, irf(order2) impulse(r) response(mp)
irf table oirf, irf(order2) impulse(r) response()
irf graph oirf, irf(order2) impulse(r) response()

/* sum of GVD */
vec mp y r, lags(3) rank(1)
irf create order3, step(48)
irf table fevd, irf(order3) impulse(mp) response(mp)
irf table oirf, irf(order3) impulse(mp) response()
irf graph oirf, irf(order3) impulse(mp) response()


/* Forecasting: VECM vs. VAR */

/* VECM 1-step-ahead forecasts */
/* estimation sample starts (1947q1-1982q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=1 */
vec mp y r if tin(,1982q4), lags(3) rank(1)
fcast compute h1_, step(1) replace difference nose		/* forecasts of levels & differences, 1983q1-1988q4 */
list date h1_* if date=="1983Q1"

cap drop y1_hat_table y2_hat_table y3_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .

set more off
local h=1					/* set the h for h-step-ahead-forcast */ 
local i=144					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=168					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly vec mp y r in 1/`i', lags(3) rank(1)
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 

replace y1_hat_table = hat_mp in `j'/`j'
replace y2_hat_table = hat_y in `j'/`j'
replace y3_hat_table = hat_r in `j'/`j'
local i=`i'+1
}
tsline mp y1_hat_table in `l'/`k'
tsline y y2_hat_table in `l'/`k'
tsline r y3_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=mp
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=y
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=r
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h1_mp h1_y h1_r
gen h1_mp=y1_hat_table
gen h1_y=y2_hat_table
gen h1_r=y3_hat_table
label var h1_mp "mp, VEC, h=1"
label var h1_y "y, VEC, h=1"
label var h1_r "r, VEC, h=1"

/* D. 4-step-ahead forecasts */
/* estimation sample starts (1947Q1-1982Q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=4 */
vec mp y r if tin(,1982q4), lags(3) rank(1)
fcast compute h4_, step(4) replace difference nose		/* forecasts of levels & differences, 1983-1988 */
list date h4_* if date=="1983Q4"

cap drop y1_hat_table y2_hat_table y3_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .

set more off
local h=4					/* set the h for h-step-ahead-forcast */ 
local i=144					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=168					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly vec mp y r in 1/`i', lags(3) rank(1)
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 

replace y1_hat_table = hat_mp in `j'/`j'
replace y2_hat_table = hat_y in `j'/`j'
replace y3_hat_table = hat_r in `j'/`j'
local i=`i'+1
}
tsline mp y1_hat_table in `l'/`k'
tsline y y2_hat_table in `l'/`k'
tsline r y3_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=mp
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=y
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=r
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h4_mp h4_y h4_r
gen h4_mp=y1_hat_table
gen h4_y=y2_hat_table
gen h4_r=y3_hat_table
label var h4_mp "mp, VEC, h=4"
label var h4_y "y, VEC, h=4"
label var h4_r "r, VEC, h=4"

/* forecast comparison */
tsline mp h1_mp h4_mp if tin(1983q1,)
tsline y h1_y h4_y if tin(1983q1,)
tsline r h1_r h4_r if tin(1983q1,)


/* unrestricted VAR of (d.mp,d.y,d.r) */
varsoc d.mp d.y d.r, maxlag(4) /* AIC: P=2 */

var d.mp d.y d.r, lags(1/2)
varstable
varlmar, mlag(4) /* not OK */
cap drop r_mp r_y r_r
predict r_mp, equation(#1) residuals
predict r_y, equation(#2) residuals
predict r_r, equation(#3) residuals
tsline r_mp
tsline r_y
tsline r_r
corrgram r_mp, lags(32)	/* OK */
corrgram r_y, lags(32)	/* OK */
corrgram r_r, lags(32)	/* not OK */


/* C. 1-step-ahead forecasts */
/* estimation sample starts (1947Q1-1982Q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=1 */
var d.mp d.y d.r if tin(,1982q4), lags(1/2)
fcast compute h1_, step(1) replace		/* forecasts start in 1987Q1 */
list date h1_D_mp h1_D_y h1_D_r if date=="1983Q1"

cap drop y1_hat_table y2_hat_table y3_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .

set more off
local h=1					/* set the h for h-step-ahead-forcast */ 
local i=144					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=168					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly var d.mp d.y d.r in 1/`i', lags(1/2) 
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 
*	list date hat_D_y hat_D2_p hat_D_m hat_D_x in `j'/`j'
replace y1_hat_table = hat_D_mp in `j'/`j'
replace y2_hat_table = hat_D_y in `j'/`j'
replace y3_hat_table = hat_D_r in `j'/`j'
local i=`i'+1
}
tsline d.mp y1_hat_table in `l'/`k'
tsline d.y y2_hat_table in `l'/`k'
tsline d.r y3_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.mp
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.y
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.r
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h1_D_mp h1_D_y h1_D_r
gen h1_D_mp=y1_hat_table
gen h1_D_y=y2_hat_table
gen h1_D_r=y3_hat_table
label var h1_D_mp "d.mp, VAR(1), h=1"
label var h1_D_y "d.y, VAR(1), h=1"
label var h1_D_r "d.r, VAR(1), h=1"

/* D. 4-step-ahead forecasts */
/* estimation sample starts (1960Q1-1986Q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=4 */
var d.mp d.y d.r if tin(,1982q4), lags(1/2)
fcast compute h4_, step(4) replace		/* forecasts start in 1987Q4 */
list date h4_D_mp h4_D_y h4_D_r if date=="1983Q4"

cap drop y1_hat_table y2_hat_table y3_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .

set more off
local h=4					/* set the h for h-step-ahead-forcast */ 
local i=144					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=168					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly var d.mp d.y d.r in 1/`i', lags(1/2) 
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 

replace y1_hat_table = hat_D_mp in `j'/`j'
replace y2_hat_table = hat_D_y in `j'/`j'
replace y3_hat_table = hat_D_r in `j'/`j'
local i=`i'+1
}
tsline d.mp y1_hat_table in `l'/`k'
tsline d.y y2_hat_table in `l'/`k'
tsline d.r y3_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.mp
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.y
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=d.r
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h4_D_mp h4_D_y h4_D_r
gen h4_D_mp=y1_hat_table
gen h4_D_y=y2_hat_table
gen h4_D_r=y3_hat_table
label var h4_D_mp "d.mp, VAR(1), h=4"
label var h4_D_y "d.y, VAR(1), h=4"
label var h4_D_r "d.r, VAR(1), h=4"


/* unrestricted VAR of (mp,y,r) */
varsoc mp y r, maxlag(4) /* AIC: P=3 */

var mp y r, lags(1/3)
varstable
varlmar, mlag(4) /* not OK */
cap drop r_mp r_y r_r
predict r_mp, equation(#1) residuals
predict r_y, equation(#2) residuals
predict r_r, equation(#3) residuals
tsline r_mp
tsline r_y
tsline r_r
corrgram r_mp, lags(32)	/* OK */
corrgram r_y, lags(32)	/* OK */
corrgram r_r, lags(32)	/* not OK */

/* C. 1-step-ahead forecasts */
/* estimation sample starts (1960Q1-1986Q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=1 */
var mp y r if tin(,1982q4), lags(1/3)
fcast compute h1_, step(1) replace		/* forecasts start in 1987Q1 */
list date h1_mp h1_y h1_r if date=="1983Q1"

cap drop y1_hat_table y2_hat_table y3_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .

set more off
local h=1					/* set the h for h-step-ahead-forcast */ 
local i=144					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=168					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly var mp y r in 1/`i', lags(1/3) 
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 

replace y1_hat_table = hat_mp in `j'/`j'
replace y2_hat_table = hat_y in `j'/`j'
replace y3_hat_table = hat_r in `j'/`j'
local i=`i'+1
}
tsline mp y1_hat_table in `l'/`k'
tsline y y2_hat_table in `l'/`k'
tsline r y3_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=mp
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=y
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=r
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h1_mp h1_y h1_r
gen h1_mp=y1_hat_table
gen h1_y=y2_hat_table
gen h1_r=y3_hat_table
label var h1_mp "mp, VAR(1), h=1"
label var h1_y "y, VAR(1), h=1"
label var h1_r "r, VAR(1), h=1"

/* D. 4-step-ahead forecasts */
/* estimation sample starts (1960Q1-1986Q4), then expands with one additonal observation at a time, forecast horizon is fixed as h=4 */
var mp y r if tin(,1982q4), lags(1/3)
fcast compute h4_, step(4) replace		/* forecasts start in 1987Q4 */
list date h4_mp h4_y h4_r if date=="1983Q4"

cap drop y1_hat_table y2_hat_table y3_hat_table
gen y1_hat_table = .
gen y2_hat_table = .
gen y3_hat_table = .

set more off
local h=4					/* set the h for h-step-ahead-forcast */ 
local i=144					/* set last obs of estimation sample*/
local l=`i'+`h'
local k=168					/* set last obs of forecast sample */
while `i' <=`k'-`h' {

quietly var mp y r in 1/`i', lags(1/3) 
fcast compute hat_, step(`h') replace nose		
		
local j=`i'+`h' 

replace y1_hat_table = hat_mp in `j'/`j'
replace y2_hat_table = hat_y in `j'/`j'
replace y3_hat_table = hat_r in `j'/`j'
local i=`i'+1
}
tsline mp y1_hat_table in `l'/`k'
tsline y y2_hat_table in `l'/`k'
tsline r y3_hat_table in `l'/`k'

list date y1_hat_table y2_hat_table y3_hat_table

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=mp
gen y_fit=y1_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=y
gen y_fit=y2_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop yyy y_fit y_error mse rmspe mppe mappe
gen yyy=r
gen y_fit=y3_hat_table
gen y_error=y_fit-yyy
egen mse=mean(y_error^2)
gen rmspe=sqrt(mse)      		
egen mppe=mean(y_error/yyy)
egen mappe=mean(abs(y_error/yyy))
list rmspe mppe mappe in 1/1

cap drop h4_mp h4_y h4_r
gen h4_mp=y1_hat_table
gen h4_y=y2_hat_table
gen h4_r=y3_hat_table
label var h4_mp "mp, VAR(1), h=4"
label var h4_y "y, VAR(1), h=4"
label var h4_r "r, VAR(1), h=4"








