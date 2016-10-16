data x1;
input var1;
cards;
1
3
5
6
;
run;

data x2;
set x1;
retain count 0;
count=count+1;
run;
