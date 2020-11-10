*2016-08-01 HZ statins and pneunomia reanalyze;
*;
libname cprd 'C:\';
libname statins 'C:\';
libname hes 'C:\';
libname cohort 'C:\';

proc sort data=cohort.selected;by id;run;
proc sort data=statins.cc;by id;run;

data exposure;
	merge cohort.selected statins.cc;
	by id;
run;

proc sql;
	create table exposure as
	select c.*, s.exposure
	from statins.cc as c, cohort.selected as s
	where c.id=s.id
	order by caseid, id;
quit;

data exposure2;
	set exposure;
	retain strata 0;
	if first.caseid then strata=1;
	if caseid ne lag(caseid) then strata+1;
run;

proc sql;
	create table exposure_covariate as
	select e.*, s.smoking, s.cov_asthma, s.cov_copd, s.cov_pneum, s.cov_immuno, s.cov_ib, s.cov_ics, s.cov_atb, s.pneu_v, s.cov_flu_v, 
s.cov_hypertension, s.cov_mi, s.cov_revasc, s.cov_stroke, s.cov_dm, s.alcohol
	from exposure2 as e, cohort.covariate as s
	where e.id=s.id
	order by caseid, id;
quit;


proc logistic data=exposure_covariate;
	strata caseid;
	model outcome(event='1')=exposure;
run;

proc logistic data=exposure_covariate;
	strata caseid;
	model outcome(event='1')=exposure dof t0 age male;
run;

proc logistic data=exposure_covariate;
class 
	strata caseid;
	model outcome(event='1')=exposure dof t0 age male smoking cov_asthma cov_copd cov_pneum cov_immuno cov_ib cov_ics cov_atb pneu_v cov_flu_v ps;
run;



