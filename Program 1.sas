proc import datafile="/home/u64280361/CHARGING_STATIONS/WORKING.FILE/Amzon.xlsx"
    out=work.amazon
    dbms=xlsx;
 run;
/* To check missing values and duplicates  */
proc freq data=work.amazon;
run;


/*To treat missing values    */
proc stdize data=work.amazon reponly method=median out=ec_data_num;
    var Price Units_Sold Inventory Discount_Percentage Rating Return_Rate;
run;


/*if there is any numeric missing value left */
proc means data=ec_data_clean_final n nmiss;
run;

/*if there is any categorical missing value left */
proc freq data=ec_data_clean_final;
    tables Category Supplier / missing;
run;

/*Calculate revenue and estimate profit  */
data ec_analysis;
    set ec_data_clean_final;

    /* Revenue before discount */
    Revenue = Price * Units_Sold;

    /* Profit estimate after discount and returns */
    Profit_Estimate = Revenue * (1 - Discount_Percentage/100) * (1 - Return_Rate/100);
run;

/*Identify loss making products*/
proc sql;
    create table loss_products as
    select Product_ID, Category, Price, Units_Sold, Discount_Percentage, Revenue, Profit_Estimate
    from ec_analysis
    where Profit_Estimate < 0
    order by Profit_Estimate;
quit;
/* Insights: There are no products where discounts are hurting profitability. */



/*High return products  */
proc sql;
    create table high_return as
    select Product_ID, Category, Units_Sold, Return_Rate, Revenue, Profit_Estimate
    from ec_analysis
    where Return_Rate > 0.2
    order by Return_Rate desc;
quit;
/*Insights:	P1007 is the highest return product  */

/* Inventory insuffciency */
data inventory_analysis;
    set ec_analysis;
    Stock_Days = Inventory / (Units_Sold + 0.0001); /* Avoid divide by zero */
run;
/* calculating how long the current inventory will last, which is called inventory insufficiency or stock days. Here’s why: */


proc sql;
    create table slow_moving as
    select Product_ID, Category, Inventory, Units_Sold, Stock_Days
    from inventory_analysis
    order by Stock_Days desc;
quit;

proc print data=slow_moving(obs=10);
run;
/* identifying the slow-moving products in  inventory — the items that have been in stock the longest */

/*Category and profitability */
proc sql;
    create table category_profit as
    select Category,
           sum(Revenue) as Total_Revenue,
           sum(Profit_Estimate) as Total_Profit
    from ec_analysis
    group by Category
    order by Total_Profit desc;
quit;

proc print data=category_profit;
run;

/*Supplier level profitability  */
proc sql;
    create table supplier_profit as
    select Supplier,
           sum(Revenue) as Total_Revenue,
           sum(Profit_Estimate) as Total_Profit
    from ec_analysis
    group by Supplier
    order by Total_Profit desc;
quit;

proc print data=supplier_profit;
run;

/* Top 10 Loss-Making Products */
proc sgplot data=loss_products(obs=10);
    vbar Product_ID / response=Profit_Estimate datalabel;
    title "Top 10 Loss-Making Products";
run;

/* Category Profitability */
proc sgplot data=category_profit;
    vbar Category / response=Total_Profit datalabel;
    title "Category Profitability";
run;

/* Supplier Profitability */
proc sgplot data=supplier_profit;
    vbar Supplier / response=Total_Profit datalabel;
    title "Supplier Profitability";
run;

/* Inventory: Top Slow-Moving Products */
proc sgplot data=slow_moving(obs=10);
    vbar Product_ID / response=Stock_Days datalabel;
    title "Top 10 Slow-Moving Products (High Stock Days)";
run;


































