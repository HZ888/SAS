ods listing close;
ods graphics on;
ods noresults;
ods rtf file="C:\Users\nsouri\Dropbox (dementia team)\Statistical Analysis\File..rtf";

title1 'Effective Sample Size - Vladimir Grant';

data data1;
	do k=4 to 12 by 2; * k = number of clusters *;
	  do m = 10 to 50 by 5; * m = number of patients *;
	    do r = 0.01,0.05,0.10; * r = ICC *;
	      DE = 1 + r*(m-1);
		  n_unadjusted=k*m;
		  eff=n_unadjusted/DE;
		  n_adjusted=n_unadjusted*DE; 
		  difference = n_unadjusted - eff;
	      output;
	    end;
	  end;
	end;
	label 	k='Number of clusters (GMF/FHT)'
			m='Number of patients per per cluster'
			r='Intraclass correlation coefficient'
			n_unadjusted='Unadjusted sample size'
			DE = 'Design effect'
			eff = 'Effective sample size (if cluster effect not adjusted for)'
			n_adjusted = 'Adjusted sample size'
			difference = 'Difference btw unadjusted N and EFF';
run;
proc print data=data1 label; run;


ods rtf close; 
ods graphics off;
ods listing;


