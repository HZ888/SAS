*Table 1;
*2016-08-05HZ statins and pneunomia reanalyze;
*;
libname cprd 'C:\';
libname statins 'C:\';
libname hes 'C:\';
libname cohort 'C:\';

data tableone;
set exposure_covariate;
if caseid=id then caseoutcome=1;
else caseoutcome=0;
run;

proc freq data=tableone; table caseoutcome;run;

data case;
	set tableone;
	if caseoutcome=1;
	year=year(t0);
run;

proc means data=case mean median; var dof age;run;

proc freq data=case;
	by caseoutcome;
	table male year smoking cov_asthma alcohol cov_copd cov_dm cov_hypertension cov_stroke cov_mi cov_revasc cov_flu_v pneu_v cov_pneum cov_immuno   cov_ib cov_ics cov_atb;
run;

data control;
	set tableone;
	if caseoutcome=0;
	year=year(t0);
run;

proc means data=control mean median; var dof age;run;

proc freq data=control;
	by caseoutcome;
	table male year smoking cov_asthma alcohol cov_copd cov_dm cov_hypertension cov_stroke cov_mi cov_revasc cov_flu_v pneu_v cov_pneum cov_immuno   cov_ib cov_ics cov_atb;
run;
