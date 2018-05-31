option nolabel;
/******************************************** Exhibit 4 *********************************************/
/* use total book equity from merged compustat data */
data book_e4;
   set tmp1.book;
   year=year(datadate);
   month=month(datadate);
   rename lpermno=permno;
   keep lpermno seq year month;
run;

proc sort data=book_e4 nodupkey; by permno year; run;

/* generate a data set which contains fiscal year end market cap */
data mktcap;
   set tmp1.stock;
   mktcap=abs(prc)*shrout;
   year=year(date);
   month=month(date);
   keep permno mktcap year month;
run;

/* generate a data set which only contains June's market cap */
data mktcap6;
   set tmp1.stock;
   where month(date)=6;
   mktcap6=abs(prc)*shrout;
   year=year(date);
   keep permno mktcap6 year;
   run;

/* merge fiscal year end market cap with book equity to get a data set contains bpal_t=seq_t/mktcap */
proc sort data=book_e4; by permno year month; run;
proc sort data=mktcap; by permno year month; run;

data bpal_t;
   merge book_e4(in=in1) mktcap(in=in2);
   by permno year month;
   if in1 and in2;
   drop month;
run;

/* merge June's mktcap6 into the main data set */
proc sort data=bpal_t; by permno year; run;
proc sort data=mktcap6; by permno year; run;

data bpal_t;
   merge bpal_t mktcap6;
   by permno year;
   bpal_t=seq/mktcap;   /* generate bpal at time t by seq/mktcap */
run;

/* generate another data set with lag of bpal and lag of book equity by using year+1 */
data bpal_t1;
   set bpal_t;
   year=year+1;
   rename bpal_t=bpal_t1 seq=seq_t1;
   drop mktcap mktcap6;
run;

/* merge the lag of bpal and seq back into the main data set */
proc sort data=bpal_t1; by permno year; run;

data bpal;
   merge bpal_t bpal_t1;
   by permno year;
   bpac_t1=seq_t1/mktcap6;   /* generate lag of bpac by dividing lag of book equity by June's market cap */
   bpac_bpal=bpac_t1-bpal_t1;   /* generate the difference of lag of bpal and bpac */
   drop mktcap mktcap6;
run;

/* Fama-MacBeth Regression, regress bpal_t on bpal_t1 and bpal_bpac by year, from 1950 to 2011 */
proc sort data=bpal; by year; run;

/* run regression on cross-sectional data */
proc reg data=bpal noprint outest=outest edf;
   by year;
   model bpal_t = bpal_t1 bpac_bpal;
run;
quit;

data outest;
   set outest;
   r1_r2=bpal_t1-bpac_bpal;
   r2dr1=bpac_bpal/bpal_t1;
   rename bpal_t1=r1 bpac_bpal=r2;
   keep year bpal_t1 bpac_bpal _RSQ_ r1_r2 r2dr1;
run;

/* proc means to get time series average */
proc means data=outest mean t;
   var r1 r2 _RSQ_ r1_r2 r2dr1;
   output out=exhibit4 mean= t= /autoname;
   title " Exhibit 4 All Smaple ";
run;

data exhibit4;
   set exhibit4;
   size="All Sample";
   drop _type_ _freq_ _RSQ__t r2dr1_t;
run;

/* generate different size portfolio by using NYSE median */
/* first use original data to get NYSE stock */
data NYSE_stock;
   set tmp1.stock;
   where exchcd=1 and month(date)=6;
   mktcap=abs(prc)*shrout;
   year=year(date);
run;

/* use proc means to get June's NYSE median for every year */
proc sort data=NYSE_stock; by year; run;
proc means data=NYSE_stock noprint;
   by year;
   var mktcap;
   output out=NYSE_median(drop=_type_ _freq_) median=mktcap;
run;

/* create size portfolio by comparing stocks' June market cap with NYSE_median every year */
proc sort data=mktcap6; by year; run;
data size;
   merge mktcap6 NYSE_median;
   by year;
   if mktcap6 ge mktcap then size="large";
   if mktcap6 lt mktcap then size="small";
run;

/* merge size portfolio back with the bpal data set */
proc sort data=bpal; by permno year; run;
proc sort data=size; by permno year; run;

data bpal;
   merge bpal size;
   by permno year;
run;

proc sort data=bpal; by size year; run;

/* run regression on cross-sectional data */
proc reg data=bpal noprint outest=outest_e4_size edf;
   by size year;
   model bpal_t = bpal_t1 bpac_bpal;
run;
quit;

data outest_e4_size;
   set outest_e4_size;
   r1_r2=bpal_t1-bpac_bpal;
   r2dr1=bpac_bpal/bpal_t1;
   rename bpal_t1=r1 bpac_bpal=r2;
   keep size year bpal_t1 bpac_bpal _RSQ_ r1_r2 r2dr1;
run;

/* proc means to get time series average */
proc sort data=outest_e4_size; by size; run;
proc means data=outest_e4_size mean t;
   by size;
   var r1 r2 _RSQ_ r1_r2 r2dr1;
   output out=exhibit4size(drop=_type_ _freq_ _RSQ__t r2dr1_t) mean= t= /autoname;
   title " Exhibit 4 Small and large Size ";
run;

data exhibit4;
   set exhibit4 exhibit4size;
   rename r1_mean=r1 r2_mean=r2 r1_r2_mean=r1_r2 _rsq__mean=rsquare r2dr1_mean=r2dr1;
run;

data exhibit4;
   attrib size r1 r1_t r2 r2_t r1_r2 r1_r2_t rsquare r2dr1 label='';
   set exhibit4;
run;

proc print data=exhibit4;
   title "Exhibit 4";
   format r1 r1_t r2 r2_t r1_r2 r1_r2_t rsquare r2dr1 10.3; 
run;

/******************************************** Exhibit 5 **********************************************/
/* use seq/cshpri to get book price per share */
data book_e5;
   set tmp1.book;
   year=year(datadate);
   month=month(datadate);
   logbook=log(abs(seq));
   rename lpermno=permno datadate=date;
   keep datadate lpermno logbook year month;
run;

/* generate change in log of book price per share */
proc sort data=book_e5; by permno year; run;
data book_e5c;
   set book_e5;
   by permno year;
   bookc=dif(logbook);
   if lag(permno) ne permno then bookc=.;
   drop date logbook;
run;

/* generate lag returns and cumulative r12 r24 r36 returns, and delete data without change bookprice per share and generate log return */
data stock_e5;
   set tmp1.stock;
   year=year(date);
   month=month(date);
   keep permno ret year month;
run;

proc sort data=stock_e5; by permno year month; run;

%macro loop36;
data stock_e5lag(drop=lag37);
   set stock_e5;
   by permno year month;
   %do k=1 %to 36;
   lag&k = lag&k.(ret);
   %end;
   if lag&k.(permno) ne permno then lag&k=.;
   r12 = sum(OF lag1-lag12);
   r24 = sum(OF lag13-lag24);
   r36 = sum(OF lag13-lag36);
   cr12 = log(abs(1+r12));
   cr24 = log(abs(1+r24));
   cr36 = log(abs(1+r36));
   run;
%mend;
%loop36;

/* merge change in book price per share with stock data set by year and month */

proc sort data=stock_e5lag; by permno year month; run;
proc sort data=book_e5c; by permno year month; run;

data bret;
   merge book_e5c(in=in1) stock_e5lag(in=in2);
   by permno year month;
   if in1 and in2;
run;

/* Fama-Macbeth Regression of regressing change in bookprice per share on cr12 cr24 and cr36, cross-sectional on year */
proc sort data=bret; by year; run;
proc reg data=bret noprint outest=outestret edf;
   by year;
   model bookc = cr12 cr24 cr36;
run;
quit;

/* get time series average */
proc means data=outestret mean t;
   var cr12 cr24 cr36 _RSQ_;
   output out=exhibit5(drop=_type_ _freq_) mean=r1 r2 r3 rsquare t=t1 t2 t3;
   title " Exhibit 5 All Sample ";
run;

data exhibit5;
   set exhibit5;
   size="All Sample";
run;

/* form portofolio on size */
/* merge size portfolio back with the booklagret data set */
proc sort data=bret; by permno year; run;
proc sort data=size; by permno year; run;

data brsize;
   merge bret(in=in1) size(in=in2);
   by permno year;
   if in1 and in2;
run;

/* do Fama-MacBeth Regression again on Size Portfolio */
proc sort data=brsize; by size year; run;

/* run regression on cross-sectional data */
proc reg data=brsize noprint outest=outestbrsize edf;
   by size year;
   model bookc = cr12 cr24 cr36;
run;
quit;

/* get time series average */
proc sort data=outestbrsize; by size; run;
proc means data=outestbrsize mean t;
   by size;
   var cr12 cr24 cr36 _RSQ_;
   output out=exhibit5size(drop=_type_ _freq_) mean=r1 r2 r3 rsquare t=t1 t2 t3;
   title " Exhibit 5 Different Sample Size ";
run;

data exhibit5;
   set exhibit5 exhibit5size;
run;

data exhibit5;
   attrib size r1 r2 r3 t1 t2 t3 rsquare label='';
   set exhibit5;
run;

proc print data=exhibit5;
   title "Exhibit 5";
   format r1 r2 r3 t1 t2 t3 rsquare 10.3;
run;


/********************************************* Exhibit 6 **************************************************/

/************* construct a data set with all information on bpal, bpac and bpmc **************/
data ret_e6;
   set tmp1.stock;
   mktcap=abs(prc)*shrout;
   year=year(date);
   month=month(date);
   keep permno mktcap ret year month;
run;

proc sort data=ret_e6; by permno year month; run;
proc sort data=book_e4; by permno year month; run;

data bpal_e6;   /* contains monthly return and yearly book equity */
   merge book_e4 ret_e6;
   by permno year month;
run;

/* create a data set main_e6 which contains all the information on mktcap and bpal, bpac, bpmc */
data main_e6;
   set bpal_e6;
   if month le 6 then year_tool=year-2;
   else if month gt 6 then year_tool=year-1;
run;

/* merge book equity with the main data set by year_tool to make seq available from nexte year's July to June of year after next year */
data book_e6;
   set book_e4;
   year_tool=year;
   drop year;
run;

proc sort data=main_e6; by permno year_tool; run;
proc sort data=book_e6 out=book_tool(rename=(seq=seq_tool)); by permno year_tool; run;

data main_e6;
   merge main_e6 book_tool;
   by permno year_tool;
run;

/* create and merge the market cap for fiscal year end into the main data set */
data mktcap_fy;
   set main_e6;
   where seq ^= .;
   rename year=year_tool mktcap=mktcap_fy;
   keep permno year mktcap year;
run;

proc sort data=mktcap_fy; by permno year_tool; run;

data main_e6;
   merge main_e6 mktcap_fy;
   by permno year_tool;
run;

/* create and merge the market cap fro June into the main data set */
data mktcap_6;
   set mktcap6;
   year_tool=year-1;
   keep permno year_tool mktcap6;
run;

proc sort data= mktcap_6; by permno year_tool; run;

data main_e6;
   merge main_e6 mktcap_6;
   by permno year_tool;
run;

/* create lag market cap as the bpmc monthly update */
proc sort data=main_e6; by permno year month; run;

data main_e6;
   set main_e6;
   by permno year month;
   mktcap_lag=lag(mktcap);
   bpal=seq_tool/mktcap_fy;
   bpac=seq_tool/mktcap6;
   bpmc=seq_tool/mktcap_lag;
   where seq_tool ^= .;
run;

/* create and merge the size factor into the main date set */
data size_e6;
   set Nyse_median;
   year_tool=year-1;
   rename mktcap=mktcap_median;
   keep year_tool mktcap;
run;

proc sort data=size_e6; by year_tool; run;
proc sort data=main_e6; by year_tool; run;

data main_e6;
   merge main_e6 size_e6;
   by year_tool;
   if mktcap6 ge mktcap then size="large";
   if mktcap6 lt mktcap then size="small";
   drop year_tool;
run;

/******** create return for bpal ********/
/* rank the data set according to variable bpal by month*/
proc sort data=main_e6; by permno year month; run;
proc sort data=main_e6; by year month; run;

proc rank data=main_e6 out=rank_bpal groups=3;
   by year month;
   var bpal;
   ranks rbpal;
run;

/* create 4 portfolio based on size and rank of bpal */
data smallvalue_bpal bigvalue_bpal smallgrowth_bpal biggrowth_bpal;
   set rank_bpal;
   if size="small" and rbpal=2 then output smallvalue_bpal;
   if size="large" and rbpal=2 then output bigvalue_bpal;
   if size="small" and rbpal=0 then output smallgrowth_bpal;
   if size="large" and rbpal=0 then output biggrowth_bpal;
run;

/* calculate the value weighted return for each portfolio based on lag market cap */
/* Small Value */
proc sort data=smallvalue_bpal; by year month; run;

proc means data=smallvalue_bpal noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_sv_bpal(drop=_type_ _freq_) mean=ret_sv;
run;

/* Big Value */
proc sort data=bigvalue_bpal; by year month; run;

proc means data=bigvalue_bpal noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_bv_bpal(drop=_type_ _freq_) mean=ret_bv;
run;

/* Small Growth */
proc sort data=smallgrowth_bpal; by year month; run;

proc means data=smallgrowth_bpal noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_sg_bpal(drop=_type_ _freq_) mean=ret_sg;
run;

/* Big Growth */
proc sort data=biggrowth_bpal; by year month; run;

proc means data=biggrowth_bpal noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_bg_bpal(drop=_type_ _freq_) mean=ret_bg;
run;

/* merge return together and calculate return for HML_bpal */
data hml_bpal;
   merge ret_sv_bpal ret_bv_bpal ret_sg_bpal ret_bg_bpal;
   by year month;
   hml_bpal=1/2*(ret_sv+ret_bv)-1/2*(ret_sg+ret_bg);
   keep year month hml_bpal;
run;

/******** create return for bpac ********/
/* rank the data set according to variable bpac by month*/
proc rank data=main_e6 out=rank_bpac groups=3;
   by year month;
   var bpac;
   ranks rbpac;
run;

/* create 4 portfolio and calculate value weighted return for each portfolio */
data smallvalue_bpac bigvalue_bpac smallgrowth_bpac biggrowth_bpac;
   set rank_bpac;
   if size="small" and rbpac=2 then output smallvalue_bpac;
   if size="large" and rbpac=2 then output bigvalue_bpac;
   if size="small" and rbpac=0 then output smallgrowth_bpac;
   if size="large" and rbpac=0 then output biggrowth_bpac;
run;

/* Small Value */
proc sort data=smallvalue_bpac; by year month; run;

proc means data=smallvalue_bpac noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_sv_bpac(drop=_type_ _freq_) mean=ret_sv;
run;

/* Big Value */
proc sort data=bigvalue_bpac; by year month; run;

proc means data=bigvalue_bpac noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_bv_bpac(drop=_type_ _freq_) mean=ret_bv;
run;

/* Small Growth */
proc sort data=smallgrowth_bpac; by year month; run;

proc means data=smallgrowth_bpac noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_sg_bpac(drop=_type_ _freq_) mean=ret_sg;
run;

/* Big Growth */
proc sort data=biggrowth_bpac; by year month; run;

proc means data=biggrowth_bpac noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_bg_bpac(drop=_type_ _freq_) mean=ret_bg;
run;

/* merge return together and calculate return for HML_bpal */
data hml_bpac;
   merge ret_sv_bpac ret_bv_bpac ret_sg_bpac ret_bg_bpac;
   by year month;
   hml_bpac=1/2*(ret_sv+ret_bv)-1/2*(ret_sg+ret_bg);
   keep year month hml_bpac;
run;

/******** create return for bpmc ********/
/* rank the data set according to variable bpmc by month*/
proc rank data=main_e6 out=rank_bpmc groups=3;
   by year month;
   var bpmc;
   ranks rbpmc;
run;

/* create 4 portfolio and calculate value weighted return for each portfolio */
data smallvalue_bpmc bigvalue_bpmc smallgrowth_bpmc biggrowth_bpmc;
   set rank_bpmc;
   if size="small" and rbpmc=2 then output smallvalue_bpmc;
   if size="large" and rbpmc=2 then output bigvalue_bpmc;
   if size="small" and rbpmc=0 then output smallgrowth_bpmc;
   if size="large" and rbpmc=0 then output biggrowth_bpmc;
run;

/* Small Value */
proc sort data=smallvalue_bpmc; by year month; run;

proc means data=smallvalue_bpmc noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_sv_bpmc(drop=_type_ _freq_) mean=ret_sv;
run;

/* Big Value */
proc sort data=bigvalue_bpmc; by year month; run;

proc means data=bigvalue_bpmc noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_bv_bpmc(drop=_type_ _freq_) mean=ret_bv;
run;

/* Small Growth */
proc sort data=smallgrowth_bpmc; by year month; run;

proc means data=smallgrowth_bpmc noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_sg_bpmc(drop=_type_ _freq_) mean=ret_sg;
run;

/* Big Growth */
proc sort data=biggrowth_bpmc; by year month; run;

proc means data=biggrowth_bpmc noprint;
   by year month;
   var ret;
   weight mktcap_lag;
   output out=ret_bg_bpmc(drop=_type_ _freq_) mean=ret_bg;
run;

/* merge return together and calculate return for HML_bpal */
data hml_bpmc;
   merge ret_sv_bpmc ret_bv_bpmc ret_sg_bpmc ret_bg_bpmc;
   by year month;
   hml_bpmc=1/2*(ret_sv+ret_bv)-1/2*(ret_sg+ret_bg);
   keep year month hml_bpmc;
run;

/* select returns from different portfolios and construct return for HML_bpal 
proc sql;
   create table hml_bpal_return as
   select a.year, a.month, 1/2*(ret_sv+ret_bv)-1/2*(ret_sg+ret_bg) as hml_bpal
   from smallvalue as a, bigvalue as b, smallgrowth as c, biggrowth as d
   where a.year=b.year=c.year=d.year and a.month=b.month=c.month=d.month;
quit; */


/********** constructe factors portforlio **********/
/* importing STR from txt file
data str;
   infile "C:\Users\buec-lab\Desktop\str.txt";
   input @1 year 4.
         @5 month 2.
		 @9 str 5.;
run;

libname zefan "C:\Users\buec-lab\Desktop";
data zefan.str;
   set str;
   where year between 1950 and 2011;
run; */

/* merge str into factors */
data factors;
   set tmp1.factors;
   year=year(dateff);
   month=month(dateff);
   drop dateff;
run;

proc sort data=factors; by year month; run;
proc sort data=tmp1.str out=str; by year month; run;

data factor;
   merge factors(in=in1) str(in=in2);
   by year month;
   if in1 and in2;
   str=str/100;
run;

/* create a data set used for regressions */
data hml_regression;
   merge factor(in=in1) hml_bpal(in=in2) hml_bpac(in=in3) hml_bpmc(in=in4);
   by year month;
   if in1 and in2 and in3 and in4;
   smb=smb-rf;
   umd=umd-rf;
   str=str-rf;
   hml_bpal=hml_bpal-rf;
   hml_bpac=hml_bpac-rf;
   hml_bpmc=hml_bpmc-rf;
run;

/******** run time-series regression on competing portfolios *********/
/* regression 1 */
proc reg data=hml_regression outest=outest_1(where=(_type_="PARMS" or _type_="T" or _type_="PVALUE")) noprint tableout edf;
   model hml_bpal=mktrf smb str umd hml_bpac;
   title " Regression 1 ";
run;
quit;
   
/* regression 2 */
proc reg data=hml_regression outest=outest_2(where=(_type_="PARMS" or _type_="T" or _type_="PVALUE")) noprint tableout edf;
   model hml_bpac=mktrf smb str umd hml_bpal;
   title " Regression 2 ";
run;
quit;

/* regression 3 */
proc reg data=hml_regression outest=outest_3(where=(_type_="PARMS" or _type_="T" or _type_="PVALUE")) noprint tableout edf;
   model hml_bpal=mktrf smb str umd hml_bpmc;
   title " Regression 3 ";
run;
quit;

/* regression 4 */
proc reg data=hml_regression outest=outest_4(where=(_type_="PARMS" or _type_="T" or _type_="PVALUE")) noprint tableout edf;
   model hml_bpmc=mktrf smb str umd hml_bpal;
   title " Regression 4 ";
run;
quit;

data exhibit_6;
   set outest_1 outest_2 outest_3 outest_4;
run;

proc transpose data=exhibit_6(drop=_RMSE_ _model_ _IN_ _P_ _EDF_) out=exhibit6;
   var intercept mktrf smb str umd hml_bpal hml_bpac hml_bpmc _RSQ_;
run;

data exhibit6;
   set exhibit6;
   drop col3 col6 col9 col12;
   rename col1=AL_1 col2=t_1 col4=AC_2 col5=t_2 col7=AL_3 col8=t_3 col10=MC_4 col11=t_4;
run;

proc print data=exhibit6;
   format al_1 t_1 ac_2 t_2 al_3 t_3 mc_4 t_4 10.3;
   title " Exhitib 6 ";
run;

/* figure 1 */
proc reg data=hml_regression noprint outest=outest_f1;
   model hml_bpal = mktrf smb umd str;
   output out = hmlal r = hmlal_r;
run;
quit;

data outest_f1;
   set outest_f1;
   keep intercept;
   rename intercept=bpal_intercept;
run;

data adjret;
   set hmlal;
   if _n_=1 then set outest_f1;
   adjret_al = (hmlal_r + bpal_intercept)*100;
run;


proc reg data=hml_regression noprint outest=outest_f2;
   model hml_bpac = mktrf smb umd str;
   output out = hmlac r = hmlac_r;
run;
quit;

data adjret;
   merge adjret hmlac(keep=year month hmlac_r);
   by year month;
run;

data outest_f2;
   set outest_f2;
   keep intercept;
   rename intercept=bpac_intercept;
run;

data adjret;
   set adjret;
   if _n_=1 then set outest_f2;
   adjret_ac = (hmlac_r + bpal_intercept)*100;
run;


proc reg data=hml_regression noprint outest=outest_f3;
   model hml_bpmc = mktrf smb umd str;
   output out = hmlmc r = hmlmc_r;
run;
quit;

data adjret;
   merge adjret hmlmc(keep=year month hmlmc_r);
   by year month;
run;

data outest_f3;
   set outest_f3;
   keep intercept;
   rename intercept=bpmc_intercept;
run;

data adjret;
   set adjret;
   if _n_=1 then set outest_f3;
   adjret_mc = (hmlmc_r + bpmc_intercept)*100;
   date = mdy(month,1,year);
   format date monyy7.;
run;

data figure;
   set adjret;
   cadjret_al + adjret_al;
   cadjret_ac + adjret_ac;
   cadjret_mc + adjret_mc;
run;


symbol1 interpol=join
        value=none
        color=red;
symbol2 interpol=join
        value=none
        color=blue;

symbol3 interpol=join
        value=none
        color=black;

legend1 label=none position=center;
proc gplot data=figure;
   symbol i=spline;
   plot cadjret_al*date cadjret_ac*date cadjret_mc*date / overlay legend=legend1;
   title "Exhibit 2";
run;
quit;


/* Create Table for Raw Return */
proc reg data=hml_regression noprint outest=outest_t1(where=(_type_="PARMS" or _type_="T" or _type_="PVALUE")) noprint tableout edf;;
   model hml_bpal = mktrf smb umd str;
run;
quit;

proc reg data=hml_regression outest=outest_t2(where=(_type_="PARMS" or _type_="T" or _type_="PVALUE")) noprint tableout edf;
   model hml_bpac=mktrf smb str umd;
run;
quit;

proc reg data=hml_regression outest=outest_t3(where=(_type_="PARMS" or _type_="T" or _type_="PVALUE")) noprint tableout edf;
   model hml_bpmc=mktrf smb str umd;
run;
quit;

data exhibit_t6;
   set outest_t1 outest_t2 outest_t3;
run;

proc transpose data=exhibit_t6(drop=_RMSE_ _model_ _IN_ _P_ _EDF_) out=exhibit_raw6;
   var intercept mktrf smb str umd _RSQ_;
run;

data exhibit_raw6;
   set exhibit_raw6;
   drop col3 col6 col9;
   rename col1=AL col2=t_AL col4=AC col5=t_AC col7=MC col8=t_MC;
run;

proc print data=exhibit_raw6;
   format al t_Al ac t_AC MC t_MC 10.3;
   title " Exhibit Raw Return ";
run;



