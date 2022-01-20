*STUDY: 
*AUTHOR:HZ;
*DATE:2021DEC21;

LIBNAME original "C:\Users\Stats";
LIBNAME D "C:\Users\Stats\";

*inclusion & exclusion criteria;
proc import out=original.ic_ec
						datafile="C:\Users.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.in_ex;
	set original.ic_ec;
	if IC1="Y" and IC2="Y" and IC3="Y" and IC4="Y" and EC1="N" and EC2="N" and EC3="N" then i=1;
	else i=0;
run;

data d.included;
	set d.in_ex;
	if i=1;
	keep pt group;
run;

data d.excluded;
	set d.in_ex;
	if i=0;
run;

*primary end point;
proc import out=original.cdai_lda_remission
						datafile="C:\Users\.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.cdai_lda_remission;
	set original.cdai_lda_remission;
	if CDAI_remission=. then i=0;
	else i=1;
run;

data d.cdai_remission;
	set d.cdai_lda_remission;
	if i=1;
run;

*Baseline characteristics;
*demographics;
proc import out=original.DM_Original
						datafile="C:\Users\S.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

*age birthdate sex weight;
data d.dm_short;
	set original.DM_Original;
	year=input(brthdat,4.);
	age = 2021-year;
	if age >=18;
	keep pt age brthdat sex vswt;
run;

*date of initial diagnosis;
proc import out=original.rh
						datafile="C:\Users\.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.rh_rhd;
	set original.rh;
	keep pt rhdtd;
	format rhdtd date9.;
	if rhdtd="" then delete;
run;

*Date of consent;
proc import out=original.vi
						datafile="C:\Users\.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.vi_consent;
	set original.vi;
	if visit_number=0;
	consentdate=input(put(consdat,8.),yymmdd8.);
	format consentdate date9.;
	keep pt consdat consentdate;
run;

proc sort data=d.vi_consent out=d.vi_consent;
	by pt;
run;

proc sort data=d.rh_rhd out=d.rh_rhd;
	by pt;
run;

data d.duration;
	merge d.vi_consent (in=a) d.rh_rhd (in=b);
	by pt;
	if a and b;
	duration=intck('day',rhdtd,consentdate);
run;

proc sort data=d.included out=d.included;
	by pt;
run;

proc sort data=d.dm_short out=d.dm_short;
	by pt;
run;
	
data characteristic;
	merge d.included (in = a) d.dm_short(in = b) d.duration(in=c);
	by pt;
	if a and b and c;
	keep pt age sex vswt duration group;
run;

*3.1 table 1;
title "3.1 table 1 characteristic table";
proc means data = characteristic mean median stderr min max clm;
	class group;
run;

*3.1 table 2;
title "3.1 table 2 sex proportion";
proc freq data = characteristic;
	tables sex;
run;

*3.2;
proc import out=original.AR
						datafile="C:\.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.ar;
	set original.ar;
	keep pt visit_number crpresn2;
	if crpresn = "#NULL!" then delete;
	if visit_number=0 or visit_number =12;
	crpresn2=input(crpresn,8.);
run;

*JC;
proc import out=original.JC
						datafile="C:\Users\.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.jc_tj;
	set original.jc;
	keep pt visit_number tj28jn;
	if visit_number=0 or visit_number =12;
	if tj28jn="" then delete;
run;

data d.jc_sj;
	set original.jc;
	keep pt visit_number sj28jn2;
	if visit_number=0 or visit_number =12;
	if sj28jn="#NULL!" then delete;
	sj28jn2=input(sj28jn,8.);
run;

*VAS;
proc import out=original.PA
						datafile="C:\.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.vas;
	set original.pa;
	keep pt evga visit_number;
	if visit_number =0 or visit_number =12;
run;

proc sort data=d.ar out=d.ar;
	by pt visit_number;
run;

proc sort data=d.jc_sj out=d.jc_sj;
	by pt visit_number;
run;

proc sort data=d.jc_tj out=d.jc_tj;
	by pt visit_number;
run;

proc sort data=d.vas out=d.vas;
	by pt visit_number;
run;

data clinical_descriptive;
	merge d.ar(in = b) d.jc_sj(in=c) d.jc_tj(in=d) d.vas(in=e);
	by pt visit_number;
	if b and c and d and e;
	sj28jn=sj28jn2;
	crpresn=crpresn2;
	keep pt visit_number crpresn tj28jn sj28jn evga;
run;

data clinical_descriptive_included;
	merge d.included (in = a) clinical_descriptive (in=f);
	by pt;
	if a and f;
	keep pt group visit_number crpresn tj28jn sj28jn evga;
run;

*baseline;
data clinical_descriptive_included_b;
	set clinical_descriptive_included;
	if visit_number=0;
run;
*12 month followup;
data clinical_descriptive_included_12;
	set clinical_descriptive_included;
	if visit_number=12;
run;

title "3.2 table 1 by treatment group at baseline";
proc means data = clinical_descriptive_included_b mean median stderr min max clm;
	class group;
run;

title "3.2 table 2 by treatment group at 12 month follow up visit";
proc means data = clinical_descriptive_included_12 mean median stderr min max clm;
	class group;
run;

title" 3.2 table 3 overall at baseline";
proc means data = clinical_descriptive_included_b mean median stderr min max clm;
run;

title "3.2 table 4 overall at 12 month follow up visit";
proc means data = clinical_descriptive_included_12 mean median stderr min max clm;
run;

title "3.2 table 5: t-TEST - between-group comparison of the physical global assessment of disease at 12 months ";
PROC TTEST data = clinical_descriptive_included_12;
	class group;
	var evga;
run;

*3.3;
data d.cdai_remission_12;
	set d.cdai_remission;
	if visit=4;
	keep pt CDAI_remission;
run;

proc sort data=d.cdai_remission_12 out=d.cdai_remission_12;
	by pt;
run;

proc sort data=tjc28sjc28_12 out=tjc28sjc28_12;
	by pt;
run;

data cdai_remission_12_group;
	merge d.cdai_remission_12 (in = aa) d.included (in=bb);
	by pt;
	if aa and bb;
	keep pt CDAI_remission group;
run;

*two way chi square test;
title "3.3 table 1 - part 1: Frequence table CDAI at 12 months and group proportions";
proc freq data=cdai_remission_12_group;
	tables CDAI_remission*group / out=cdai_remission_12_group_comb;
run;

proc sort data=cdai_remission_12_group_comb;
	by CDAI_remission group;
run;

title "3.3 table 1- part 2: Two way chi square by CDAI at 12 months and group proportions";
ods graphics on;
proc freq data=cdai_remission_12_group_comb;
	tables CDAI_remission*group /Chisq;
	weight count;
run;
ods graphics off;

data tjc28sjc28_12;
	set clinical_descriptive_included;
	if visit_number=12;
	if tj28jn<=1 and sj28jn<=1 then tjcsjc28=1;
	else tjcsjc28=0;
	keep pt tjcsjc28 group;
run;

title "3.3 table 2 - part 1: Frequency table of TJC28 and SJC28 at 12 months by group proportions";
proc freq data=tjc28sjc28_12;
	tables tjcsjc28*group / out=tjc28sjc28_12_comb;
run;

proc sort data=tjc28sjc28_12_comb;
	by tjcsjc28 group;
run;

title "3.3 table 2 - part 2: Two way chi square by TJC28 and SJC28 at 12 months and group proportions";
ods graphics on;
proc freq data=tjc28sjc28_12_comb;
	tables tjcsjc28*group /Chisq;
	weight count;
run;
ods graphics off;

*odds ratio;
data CDAI12_adjusted;
	merge cdai_remission_12_group (in = cc) characteristic (in=dd) clinical_descriptive_included_b (in=ee);
	by pt;
	if cc and dd and ee;
	keep pt CDAI_remission group age sex duration crpresn tj28jn sj28jn evga;
run;

title "3.3 table 3: odds ratio assessing treatment on cdai remission adjusted for covariates";
proc logistic data=CDAI12_adjusted descending; *predict 1 Yes demission;
	class sex group;
	model CDAI_remission = group age sex duration crpresn tj28jn sj28jn evga;
run;  *adjusted odds ratio for group e**(0.3389);

*TSQM;
proc import out=original.tq
						datafile="C:\.xlsx"
						dbms=excel replace;
		getnames=yes;
run;

data d.tq;
	set original.tq;
	if tsqm7=. or tsqm8=. or tsqm9=. then tsqmconvenience=(sum(tsqm7,tsqm8,tsqm9)-2)/12*100;
	else tsqmconvenience=(sum(tsqm7,tsqm8,tsqm9)-3)/18*100;
run;

proc sort data=d.tq out=d.tq;
	by pt;
run;
	
data tq;
	merge d.included (in = aaa) d.tq (in=bbb);
	by pt;
	if aaa and bbb;
	keep pt group visit_number tsqmconvenience;
run;

data tq6;
	set tq;
	if visit_number=6;
run;

title "3.3 Table 4: independent sample t-test impact of treatment on TSQM convenience at 6 months";
proc ttest data=tq6;
	class group;
	var tsqmconvenience;
run;

data tq0;
	set tq;
	if visit_number=0 then tsqm0=tsqmconvenience;
	if visit_number =0;
run;

data tq12;
	set tq;
	if visit_number=12 then tsqm12=tsqmconvenience;
	if visit_number =12;
run;

proc sort data=tq0 out=tq0;
	by pt;
run;
	
proc sort data=tq12 out=tq12;
	by pt;
run;

data tqchange0to12;
	merge tq0 (in = aaaa) tq12 (in=bbbb);
	by pt;
	if aaaa and bbbb;
	tqchange0to12=tsqm12-tsqm0;
	keep pt group tsqm0 tsqm12 tqchange0to12; 
run;

title "3.3 Table 5: independent sample t-test on impact of treatment on TSQM convenience change from baseline to 12 months months";
proc ttest data=tqchange0to12;
	class group;
	var tqchange0to12;
run; *significant;

*survival;
proc import out=original.discontinuation_date
	datafile = "C:\Users\.sav"
	dbms = SAV replace;
run;

proc summary data=original.discontinuation_date;
	var disdtd;
	output out=stats max=maxdate;
run;

data d.discontinuation_time;
	set original.discontinuation_date;
	maxtime=input(put(20180326,8.),yymmdd8.);
	format maxtime date9.;
	stime=maxtime-disdtd;
	if disdtd=. then event=0;
	else event=1;
run;

proc sort data=d.discontinuation_time out=d.discontinuation_time;
	by pt;
run;

%let cov=age sex duration crpresn tj28jn sj28jn evga;
data discontinuation_time_all;
	merge d.discontinuation_time (in = ab) characteristic (in=cd) clinical_descriptive_included_b (in=ef);
	by pt;
	if ab and cd and ef;
	keep pt event stime group age sex duration crpresn tj28jn sj28jn evga;
run;

title "3.3 Table 6: survival analysis of median time to study discontinuation by treatment group";
proc lifetest data=discontinuation_time_all plot=(s);
	time stime*event(0);
	strata group;
run; *1426.5 days;

title "3.3 Table 7: survival analysis of median time to study discontinuation by treatment group adjusted for covariates";
ods graphics on;
proc phreg data=discontinuation_time_all;
	class sex group;
	model stime*event(0) = group /rl;
	baseline covariates=discontinuation_time_all; 
run;
ods graphics off;
