/* ------------------------------------------------------------------ *
 * E-commerce sales & inventory analysis — Program 1.sas
 * Source: Himanshiyadav99/E-commerce-sales-and-inventory-analysis-
 *
 * The upstream script opens with:
 *   proc import datafile="/home/u64280361/.../Amzon.xlsx" out=work.amazon dbms=xlsx;
 * That workbook lives outside the repo, so this bundle seeds a small
 * sample with the same columns and then runs the author's analysis
 * exactly as written.
 * ------------------------------------------------------------------ */

data ec_data_clean_final;
    input Product_ID $ Category $ Supplier $ Price Units_Sold Inventory
          Discount_Percentage Rating Return_Rate;
    datalines;
P1001 Clothing Supplier_A 25.0 120 300 10 4.2 0.05
P1002 Electronics Supplier_B 199.0 40 500 5 4.5 0.10
P1003 Toys Supplier_C 15.5 80 90 20 3.9 0.25
P1004 Home Supplier_A 45.0 60 200 0 4.0 0.02
P1005 Clothing Supplier_B 30.0 200 150 15 4.7 0.08
P1006 Electronics Supplier_C 350.0 10 400 25 4.1 0.30
P1007 Toys Supplier_A 12.0 150 40 30 3.5 0.35
P1008 Home Supplier_B 60.0 20 600 0 4.3 0.01
P1009 Clothing Supplier_C 22.0 90 110 12 4.4 0.06
P1010 Electronics Supplier_A 120.0 55 250 8 4.6 0.09
;
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

proc print data=loss_products;
    title "Loss-Making Products";
run;

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

proc sql;
    create table slow_moving as
    select Product_ID, Category, Inventory, Units_Sold, Stock_Days
    from inventory_analysis
    order by Stock_Days desc;
quit;

proc print data=slow_moving(obs=10);
run;

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
