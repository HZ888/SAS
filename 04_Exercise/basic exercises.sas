*AUTHOR: ;
*DATE:2021DEC17 SAS exercise;
libname e1 'C:\Users\Stats\Dropbox\SAS';
libname cprd 'C:\';
LIBNAME D 'C:\Users\Stats\Dropbox\SAS';
LIBNAME D1 "C:\Users\Stats\Dropbox\SAS";

*open datasets;
data medication;
	infile 'C:\.csv' dsd missover;
	input definition$ m dose$ prodcode$;
	keep definition;
run;

proc import out=statins.covariate
						datafile="C:\.xlsx"
						dbms=excel replace;
		sheet="therapy";
		getnames=yes;
run;

*TEXT DELIMITED FILE TXT;
DATA E2;
	INFILE="C:\Users\Stats\Dropbox\SAS\data01_initial.TXT";
	DELIMITER='';
	DBMS=EXCEL REPLACE; *tab replace;
	GETNAMES = YES; *first row name;
	MIXED = YES;
	USEDATE = YES;
	SCANTIME = YES;
	RANGE = "Trans_Apr$";
RUN;

PROC IMPORT OUT=D1;
	DATAFILE = ".csv";
	DBMS = CSV REPLACE;
	GETNAMES = YES;
	DATAROW = 2;
RUN;

PROC IMPORT OUT = D2;
	DATATABLE = "";
	DBMS = ACCESS REPLACE;
	DATABASE = ".MDB";
	SCANMEMO = YES;
	USEDATE = YES;
	SCANTIME = YES;
	MIXED = YES;
	RANGE = "Employees$";

RUN;

proc import out = work.D4
			datafile = "C:\Users\Stats\Dropbox\SAS\data01.xlsx"
			dbms = excel replace;
	getnames = yes;
run;

data d3;
	set d.data01_initial d.data02_cleaned;
run;

proc contents data=d.data01_initial;
run;

*format;
proc print data=d.data01_initial label split = "*";
	format sales 12.2 license $3. date date6.;
	format date ddmmyy8.;
	format date ddmmyy10.;
	label name = "first*name";
run;

data work.d6;
	set d.data01_initial;
	label
		SSN = "";
run;

proc format;
	value sales 0-<3000="low"
				3000-<6000="mid"
				6000-<10000="high"
run;

proc print data=d.data01_initial;
	format sales sales.;
run;

*merge datasets;
data nolinkage;
	merge linkage(in=in1) ids_cprd(in=in2);
	by id;
	if in2 and not in1;
	keep id;
run;

data work.merge;
	merge d.data01_initial (IN = A) work.D2 (in = b);
	by respondent;
	if a=0 and b=1; 
run;

*TRANSFORM DATASETS AND CALCULATE SCORES;
data work.d2;
	set d.data01_initial;
	if upcase(license) NE 'FREEWARE';
run;

data rest dsat;
	set d.data01_initial;
	if satisfaction01 = 6 then output work.dsat;
	else output work.rest;
run;

data statin.medication;
	set medication;
	prodcod=input(prodcode,7.);
run;

data statin;
	set statins.medications;
	if definition='statins' then i=1;
	else if i=0;
	if i=0 then delete;
run;

data d (rename=(prodcod=productcode));
	set statins.statincode;
run;

DATA TRANSFORMED;
	SET D.DATA01_INITIAL;
	rev_satisfied = 8 - satisfaction04;
	trust = mean (trust01 - trust04);
	logscale = log(sales);
RUN;

data work.new2;
	set d.data01_initial;
	length new $5.;
	format satisfaction01 3.2 enquiries percent4.2;
	if satisfaction01 < 3 then do;
				new = license;
				category = low;
	end;
	*unique=catx("|");
	revsat01=satisfaction01*-1;
	revsat02=-satisfaction01;
run;

proc print data = work.new2;
	where UPCASE(license) = "FREEWARE";
run;

proc sort data=d.data01_initial out=work.d5;
	by sales;
run;

data cprdstatins_full;
	set statins.cprdstatins_full;
	if definition='statins' then do;
	if index(drugsubstancename,"atorvast")>0 then atorv=1;
	else atorv=0;
	end;
	if definition='TB' then tb=1;
	else tb=0;
	if definition not in('statins','TB','other lipid lowering agents','fibrate') then other=1;
	else other=0;
run;

proc print data = d1.data02_cleaned;
run;

DATA transformed;
	set d1.data02_cleaned;
	rev_satisfaction04 = 8 - satisfaction04;
	satisfaction = mean(of satisfaction01-satisfaction03);
	logsales = log(sales);
	salesq = sales**2;
	if license = "Premium" then premium =1; else premium = 0;
	if size = "Small" then Small = 1; else Small = 0;
	if size = "Medium" then Medium = 1; else Medium = 0;
run;

proc print data=d1.data03_aggregated;
run;

proc sort data=d1.data03_aggregated out=work.dsorted;
	by sales enquiries;
run;

data work.sorted;
	set work.dsorted;
	by sales enquiries;
	if first.license then lake=0;
	retain lake;
run;

proc means data = d1.data01_initial 
	maxdec=2 nonobs N Nmiss Mean Median Std p25 p75 Min Max;
run;


*reliability - correlation alpha;
title "trust cronbach";
proc corr data=d1.data02_cleaned alpha;
	var trust01-trust04;
run;


*frequence tables;
Title "Frequency Table - One Way";
proc freq data=e1.data01_initial;
	table license size;
run;

Title "Frequency Table - Two way";
proc freq data=e1.data01_initial;
	table license*size;
run;

Title "Frequency Table - Two way/Option List";
proc freq data=e1.data01_initial;
	table license*size/LIST;
run;

Title "Frequency Table - Two way/OPTION CROSS LIST";
proc freq data=e1.data01_initial;
	table license*size/CROSSLIST;
run;

Title "Frequency Table - Two way/OPTION LIST WITH OUTPUT";
proc freq data=e1.data01_initial;
	table license*size/LIST OUT=WORK.FREQ;
run;

TITLE "PROC MEAN - all numeric varibleS";
PROC MEANS DATA=e1.data01_initial;
run;

TITLE "PROC MEAN - all numeric varibleS";
PROC MEANS DATA=e1.data01_initial MEAN KURT SKEW;
	VAR TRUST01;
RUN;

TITLE "PROC MEAN - all numeric varibleS";
PROC MEANS DATA=e1.data01_initial MEAN KURT SKEW;
	CLASS LICENSE;
	VAR TRUST01;
run;

TITLE 'CHARACTERISTIC TABLES';
PROC MEANS DATA = D.DATA01_INITIAL skew N mean stderr clm;
	class size;
	var sales;
RUN;

TITLE 'FREQUENCY TABLES';
PROC FREQ DATA = D.DATA01_INITIAL;
	TABLE LICENSE SIZE;
RUN;

TITLE 'FREQUENCY TABLES';
PROC FREQ DATA = D.DATA01_INITIAL;
	TABLE LICENSE SIZE/LIST OUT=WORK.FREQ;
RUN;

title "satisfaction01 freq - one way";
proc freq data=d.data01_initial;
	tables satisfaction01;
run;

title "satisfaction01 and trust01 freq - one way";
proc freq data=d.data01_initial;
	tables satisfaction01 trust01;
run;

title "satisfaction01 and trust01 freq - N way";
proc freq data=d.data01_initial;
	tables satisfaction01*trust01;
run;

title "satisfaction01 and trust01 freq - N way/OPTION LIST";
proc freq data=d.data01_initial;
	tables satisfaction01*trust01/list;
run;

title "satisfaction01 and trust01 freq - N way/OPTION cross list";
proc freq data=d.data01_initial;
	tables satisfaction01*trust01/crosslist;
run;

title "satisfaction01 and trust01 freq - N way/OPTION LIST with output";
proc freq data=d.data01_initial;
	tables satisfaction01*trust01/list out=work.freq;
run;

*HISTOGRAM;
ods graphics on;
title 'historgram for sales';
proc univariate data=d.data01_initial;
	class size;
	var sales;
	histogram sales;
	inset skewness kurtosis;
	probplot sales;
	inset skewness kurtosis;
run;

title 'box and whisker plot by size';
proc sgplot data = d.data01_initial;
	vbox sales/ category = size;
run;
ods graphics off;

proc univariate data = d.data01_initial;
	var sales enquiries;
	histogram ;
run;

*histogram;
proc univariate data = d1.data02_cleaned;
	var sales trust01-trust04;
	histogram sales trust01-trust04/normal;
run;

proc freq data=d1.data02_cleaned;
	tables license size;
run;

proc corr data=d1.data02_cleaned;
run;

proc freq data=d1.data02_cleaned;
	tables license*size;
run;

proc means data = d1.data01_initial 
		maxdec=2 nonobs N Nmiss Mean Median Std p25 p75 Min Max;
	class size license;
run;


*scatter plot;
proc sgscatter data = d.data01_initial;
	plot trust01*satisfaction01/ datalabel=enquiries group=license ;
run;

proc sgscatter data = d.data01_initial;
	plot trust01*trust02 ;
run;

title 'scatter plot for 02';
proc sgplot data = d.data01_initial;
	scatter x = satisfaction02 y = trust02 / group = size;
run; 

title 'scatter plot for 02 with ellipse';
proc sgplot data = d.data01_initial;
	scatter x = satisfaction02 y = trust02;
	ellipse x = satisfaction02 y = trust02; 
run;

proc sgscatter data = d.data01_initial;
	where size = 'Small';
	matrix trust01 trust02 trust03 trust04 sales / group = license diagonal = (histogram kernel); 
run;

proc sgscatter data = d.data01_initial;
	plot trust01*trust02 ;
run;

ods graphics on /
	width = 3 in
	outputfmt = gif
	imagemap = on
	imagename = 'MyBoxplot'
	border = off;

ods html file = "Boxplot-Body.html"
	style = journal;
proc sgplot data = d.data01_initial;
	title "Satisfaction Distribution by License";
	hbox Satisfaction01 / category = license;
run;
ods html style = htmlblue;
ods graphics on / reset = all;

*single line graph;
proc sgplot data=d1.data02_cleaned (where =(satisfaction01>4 and license="Freeware"));
	series x=satisfaction01 y=sales;
run;

*multiple line graph;
proc sgplot data=d1.data02_cleaned (where =(satisfaction01>4 and license="Freeware"));
	series x=satisfaction01 y=sales;
	series x=satisfaction01 y=enquiries;
run;

*scatter graphs;
title "scatter plot of sales on trust";
proc sgplot data=d1.data02_cleaned;
	scatter y = sales x=trust01;
run;

*group scatter graphs;
title "scatter plot of sales on trust";
proc sgplot data=d1.data02_cleaned;
	scatter y = sales x=trust01/group=license;
run;

title "scattered plot";
proc sgscatter data=d1.data03_aggregated;
	matrix enquiries sales trust;
run;

*simple bar graph;
title "simple bar graph";
proc sgplot data = d1.data03_aggregated;
	vbar size / stat = mean response = sales;
run;

*box and whisker plot;
title "sales by size plot";
proc sgplot data = d1.data03_aggregated;
	vbox sales / category = size;
run;

*example;
title "sales by size";
proc sgplot data=d1.data03_aggregated;
	vbar size / stat = mean response = sales dataskin = sheen fillattrs = (color=turquoise) transparency=0.2;
	xaxis labelattrs=(weight=bold);
	yaxis labelattrs=(weight=bold);
run;
	
*panel;
title "sales";
proc sgpanel data=d1.data03_aggregated;
	panelby license /novarname;
	scatter x=trust y=enquiries;
run;




*create table, listings, figure;
proc sql;
	create table therapy001 as
	select distinct t.*, a.*
	from  cprd.therapy001 as t, statins.statincode as a
	where t.product_code=a.prodcod
	order by t.id;
quit;

proc sort data=therapy001;
	by id product_code;
run;

data therapy1;
	set therapy001;
	by id product_code;
	if first.id;
	keep id product_code;
run;

data full;
	set cprdfull;
	count+1;
	by id date;
	if first.date then count=1;
run;

proc sql;
	create table statins.cprdfull as
	select distinct id, date,
							sum(dose2) as dose, max(count) as count, max(other) as other
	from cprd
	group by id, date
	order by id, date;
quit;

proc datasets nolist;
	delete therapy1-therapy46;
run;
quit;

proc compare base=statincode compare=covariatestatins_code;
	var prodcod;
	with product code;
run;

*loop;
%macro therapy;
proc sql;
	%do i=1 %to 46;
	create table therapy&i as
	select distinct t.*, a.*
	from cprd.therapy&i as t, statins.statincode as a
	where t.product_code=a.prodcod
	order by id;
	%end;
quit;

%do i=1 %to i=46;
proc sort data=therapy&i;
	by id date;
%end;
run;

%mend therapy;
%therapy;

*count distinct id;
proc sql;
	select count(distinct id)
	from nolinkage;
quit;

*t-TEST two groups;
TITLE 'PROC TTEST - SALES VS license';
PROC TTEST data = d.data01_initial;
	class license;
	var sales;
run;

ods graphics on;
*anova class variable;
title 'one way anova ';
proc glm data = d.data01_initial plots=diagnostics(unpack);
	class size;
	model sales = size;
	means size / hovtest;
run;
quit;
ods graphics off;

*one way binomial proportions;
title "focus on big customers";
ods graphics on;
proc freq data=work.sizes;
	tables size / binomial(p=.5);
	weight Count;
run;
ods graphics off;

*two way chi square test;
proc freq data=d1.data05_regression_dummies;
	tables size*license / out=work.combination;
run;

proc sort data=work.combination;
	by size license;
run;

title "Two way chi square by size and license proportions";
ods graphics on;
proc freq data=work.combination;
	tables size*license /Chisq;
	weight count;
run;
ods graphics off;

*REGRESSION;
proc glm data=d.data01_initial;
	class satisfaction01;
	model sales = satisfaction01;
	means satisfaction01 /hovtest;
run;

title "post hoc pairwise comparison";
proc glm data = d.data01_initial;
	class satisfaction01;
	model sales = satisfaction01;
	lsmeans satisfaction01 /pdiff = all adjust = tukey;
	lsmeans satisfaction01 /pdiff = control("1") adjust =dunnett;
run;
quit;
ods graphics off;

*regression;
title "regression";
ods graphics on;
proc reg data = d1.data03_aggregated;
	model sales = trust enquiries satisfaction /vif collin dw stb clb alpha=.05 dwprob;
	output out=work.regagg student = std_resid cookd=cooks H=Hats;
run;
quit;
ods graphics off;

title "outliers";
proc sort data=work.regagg;
	by descending Cooks;
run;

proc print data=work.regagg noobs;
run;
*logged;

*Linear regression;
ods graphics on / width = 1000 imagemap = on;

proc sgscatter data = d.data01_initial;
	plot sales * satisfaction01 / reg;
run;

proc corr data = d.data01_initial plots = matrix(nvar = all histogram);
	var _numeric_;
run;

proc reg data = d.data01_initial;
	model sales = satisfaction02 trust01 enquiries /selection = stepwise details=all;
run;

*logistic regression;
proc logistic data = d.data01_initial;
	class size (param = ref ref = "Small");
	units enquiries = 10 sales = 100;
	model license (event = "freeware") = size | enquiries | sales / clodds=pl selection = stepwise details;
run;

*model selection;
proc reg data = d.data01_initial;

*GLM;
%let sat = satisfaction01 satisfaction02 satisfaction03 satisfaction04;
%let trust = trust01 trust02 trust03 trust04;

ods graphics on;
proc glmselect data = d.data01_initial plots = all;
	class &sat;
	model sales = &sat &trust/ select = SBC selection = stepwise choose = validate;
	partition fraction (test = 0.25 validate = 0.25);
	store out = work.r1;
run;

*glm glmm;
proc plm restore = work.r1;
 	score data=work.r1 out=r11;
 	code file="C:\Users\Stats\Dropbox\SAS\r11.sas";
run;

proc glm plots = all;
	lsmeans license/ diff;
run;
ods graphics off;


*independent sample t-test;
proc ttest data=d1.data05_regression_dummies;
	class license;
	var enquiries;
run;

proc means data=d1.data05_regression_dummies;
run;

*non parametric t-test;
ods graphics on;
proc npar1way data=d1.data05_regression_dummies wilcoxon HL;
	class license;
	var enquiries;
run;
ods graphics off;

*paired t-test;
ods graphics on;
proc ttest data=d1.data05_regression_dummies;
	paired sales*enquiries;
run;
ods graphics off;

*one way chi square test;
proc freq data=d1.data05_regression_dummies;
	tables size/out=work.sizes;
run;

ods graphics on;
title "sizes of customers";
proc freq data=work.sizes order =data;
	tables size / nocum chisq testp=(50 35 15)
		plots(only)=deviationplot(type=dotplot);
	weight Count;
run;
ods graphics off;





*predictive model;
*random sampling;
proc surveyselect data=d.data01_initial 
					method = srs
					rep =1
					sampsize = 100
					seed = 12345
					out=work.d5 
					outall;
	id _all_;
run;

proc print data=work.d5;
run;

*survival;
proc sql;
	select count (distinct id) from work.d;
quit;
