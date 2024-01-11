/* 
Credit Card Spending Habits in India

LINK TO THE DATASET- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
   
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions,
Converting Data Types
  
*/

-- WE WILL BE STARTING WITH 
-- SHOWS THE RANGE OF THE DATA, WHEN THE FIRST TRANSACTION WAS MADE AND WHEN IT IS ENDED
-- SHOWS THE DIFFERENT TYPE OF CARDS THAT HAS BEEN USED
-- SHOWS THE DIFFERENT EXPENSE TYPE WHERE USERS LIKE TO SPEND THEIR MONEY

SELECT MIN(date) as first_transaction_date, MAX(date) AS last_transaction_date
FROM cc_transactions.cc;

SELECT DISTINCT card_type
FROM cc_transactions.cc;

SELECT DISTINCT exp_type
FROM cc_transactions.cc;

-- NOW LET'S DIVE INTO SOME ANALYSIS
-- TOP 5 CITIES WITH HIGHEST SPENDS
-- SHOWS THE  PERCENTAGE CONTRIBUTION OF TOP 5 CITIES IN INDIA
   
WITH top_5_pct as
(SELECT  DISTINCT city,
SUM(amount)OVER() AS total_spends_by_all_city,
SUM(amount) OVER(PARTITION BY city) AS total_spends_per_city
FROM cc_transactions.cc
)
SELECT * FROM (
SELECT city,
ROUND(total_spends_per_city/total_spends_by_all_city * 100,2) AS pct_count,
 DENSE_RANK() OVER(ORDER BY total_spends_per_city DESC)AS ranker
FROM top_5_pct) x
WHERE ranker <=5;

-- HIGHEST SPEND MONTH BY EACH CARD
-- SHOWS THE SEASONAL COMPARISON OF EACH CARD TYPE AND HOW WELL EACH OF THE CARD DO AND IN WHICH MONTH

WITH monthly_highest as
(SELECT card_type, YEAR(date) as yr, MONTH(date) as mth , SUM(amount) as total_spends_monthly,
DENSE_RANK() OVER(PARTITION BY card_type order by sum(amount)) AS ranker
FROM cc_transactions.cc
GROUP BY card_type, YEAR(date), MONTH(date))

SELECT card_type,yr,mth,total_spends_monthly
FROM monthly_highest
WHERE ranker = 1;

-- WHEN DOES A CARD REACHES TO A CUMMULATIVE SPENDS OF 10,00,000 INR 
-- SHOWS THE COMPARISON BETWEEN EACH CARD TYPE AND WHICH OF THE CARD IS CURRENTLY DOING THE BEST

WITH first_reach as
(SELECT * ,
SUM(amount) OVER(PARTITION BY card_type ORDER BY date,ind) AS cummulative_sum
FROM cc_transactions.cc)

SELECT * FROM 
(SELECT * ,
RANK() OVER(PARTITION BY card_type ORDER BY cummulative_sum) AS ranker
FROM first_reach
WHERE cummulative_sum >= 1000000
) x
WHERE x.ranker = 1;

-- CITY WHICH HAD LOWEST PERCENTAGE SPEND FOR GOLD TYPE
-- SHOWS THE CITY WHERE USERS DOESN'T LIKE TO SPEND WITH GOLD CARD TYPE 
-- FROM OUR ANALYSIS WE COULD SEE THAT GOLD CARD IS DOING AVERAGELY FINE BUT THERE ARE CITIES STILL HAS A VERY LOW PERCENTAGE FOR GOLD CARD

WITH gold_spends_pct as
(SELECT city,card_type, sum(amount) AS total_spends,
SUM(CASE WHEN card_type = 'Gold' THEN amount end) AS gold_amount
FROM cc_transactions.cc
GROUP BY city,card_type)
SELECT city, SUM(gold_amount)*1.0 / SUM(total_spends) AS total_amount
FROM gold_spends_pct
GROUP BY city
HAVING COUNT(gold_amount) > 0
ORDER BY total_amount
LIMIT 1;

-- SHOWS THE DIFFERENT CITIES AND THEIR HIGHEST SPENDS EXPENSE TYPE AND LOWEST SPENDS EXPENSE TYPE

WITH high_low as
(SELECT city,exp_type, SUM(amount) AS total_amount,
DENSE_RANK() OVER(PARTITION BY city ORDER BY sum(amount) DESC) as dsc_rnk,
DENSE_RANK() OVER(PARTITION BY city ORDER BY sum(amount) ASC) as asc_rnk
FROM cc_transactions.cc
GROUP BY city,exp_type
ORDER BY city,exp_type)

SELECT city, MAX(CASE WHEN dsc_rnk = 1 then exp_type end) as high_exp,
MAX(CASE WHEN asc_rnk = 1 then exp_type end) as low_exp
FROM high_low
GROUP BY city
;

--  SHOWS THE PERCENTAGE CONTRIBUTION OF FEMALES FOR EACH EXPENSE TYPE


SELECT exp_type, ROUND(100* SUM(CASE WHEN Gender = 'F' then amount else 0 end) / SUM(amount),2) as pct
FROM cc_transactions.cc
GROUP BY exp_type
ORDER BY pct DESC;

-- SHOWS THE CARDTYPE AND EXPENSE TYPE COMBINATION FOR MONTH OVER MONTH GROWTH IN JAN 2014


WITH MOM AS
(SELECT card_type,exp_type, YEAR(date) AS yr, MONTH(date) AS mth , SUM(amount) AS TOTAL_AMT
FROM cc_transactions.cc
GROUP BY card_type,exp_type,YEAR(date),MONTH(date)
)
, MOM_PREV AS
(SELECT * ,
LAG(TOTAL_AMT,1) OVER(PARTITION BY card_type,exp_type ORDER BY yr,mth) AS prev_sales
FROM MOM)
SELECT *, (TOTAL_AMT - prev_sales)/prev_sales AS MOM_GROWTH
FROM MOM_PREV
WHERE mth = 1 AND yr = 2014
ORDER BY MOM_GROWTH DESC
LIMIT 1
;

-- SHOWS THE TOTAL AMOUNT USERS LIKE TO SPEND IN DIFFERENT CITIES DURING WEEKENDS


SELECT city , sum(amount) / COUNT(*)  as total1
FROM cc_transactions.cc
WHERE DAYNAME(date) in ('Saturday','Sunday')
GROUP BY city;

-- SHOWS WHICH CITY TOOK LEAST NUMBER OF DAYS TO REACH ITS 500TH TRANSACTION AFTER THE FIRST TRANSACTION IN THE CITY


WITH trans_500 AS
(SELECT *, ROW_NUMBER() OVER(PARTITION BY city order by date,ind) AS rn
FROM cc_transactions.cc
)
SELECT city , DATEDIFF(min(date),max(date)) AS diff from trans_500
WHERE rn = 1 OR rn = 500
GROUP BY city
HAVING COUNT(*) = 2
ORDER BY diff;

