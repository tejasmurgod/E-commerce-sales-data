CREATE TABLE sales (
    unique_id UUID PRIMARY KEY,
    channel_name VARCHAR(100),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    customer_remarks TEXT,
    order_id UUID,
    order_date_time TIMESTAMP,
    issue_reported TIMESTAMP,
    issue_responded TIMESTAMP,
    survey_response_date DATE,
    customer_city VARCHAR(100),
    product_category VARCHAR(100),
    item_price NUMERIC(10,2),
    connected_handling_time INT,
    agent_name VARCHAR(100),
    supervisor VARCHAR(100),
    manager VARCHAR(100),
    tenure_bucket VARCHAR(50),
    agent_shift VARCHAR(50),
    csat_score INT
);

SELECT * FROM sales;

-- DATA CLEANING
-- NUmber of null values in the columns
SELECT 
    COUNT(*) FILTER (WHERE customer_remarks IS NULL OR customer_remarks = '') AS missing_customer_remarks,
    COUNT(*) FILTER (WHERE customer_city IS NULL OR customer_city = '') AS missing_customer_city,
    COUNT(*) FILTER (WHERE item_price IS NULL) AS missing_item_price,
    COUNT(*) FILTER (WHERE csat_score IS NULL) AS missing_csat
FROM sales;

UPDATE sales
SET customer_city = 'Unknown'
WHERE customer_city IS NULL OR customer_city = '';

SELECT unique_id, COUNT(*)
FROM sales
GROUP BY unique_id
HAVING COUNT(*) > 1;


DELETE FROM sales a
USING sales b
WHERE a.ctid < b.ctid
  AND a.order_id = b.order_id;

-- Sometimes category, sub_category, agent_shift have inconsistent casing
UPDATE sales
SET agent_shift = INITCAP(agent_shift);

-- Outlier check (Item Price & CSAT)
SELECT *
FROM sales
WHERE item_price < 0 OR item_price > 100000;

SELECT *
FROM sales
WHERE csat_score NOT BETWEEN 1 AND 5;

-- Data cleaning and identifying outliers in dataset is done, Dataset is ready for business analysis.
-- Lets check out some business problems


-- 🔹 1. What is the average CSAT score overall?
SELECT AVG(csat_score) as avg_cast FROM sales;
-- avg_csat score is 4.24



-- 🔹 2. Which channel (Incall, Outcall, etc.) has the highest CSAT score?
SELECT channel_name, ROUND(AVG(csat_score),2) as hig_csat
FROM sales
GROUP BY channel_name
ORDER BY hig_csat DESC;
-- ANS. "Outcall" 4.27 is the channel that has the highest csat score


-- 🔹 3. Which product category generates the most revenue?
SELECT product_category, SUM(item_price) AS total_revenue
FROM sales
GROUP BY product_category
ORDER BY total_revenue DESC;
-- "Mobile"	40622927.00 generates the most revenue.


-- 🔹 4. Which agents have handled the most calls?
SELECT agent_name, COUNT(*) as total_calls
FROM SALES
GROUP BY agent_name
ORDER BY total_calls DESC;
-- "Wendy Taylor"	429 has handled the most calls


-- 🔹 5. What is the average handling time per agent?
SELECT agent_name, AVG(connected_handling_time) AS avg_handle_time
FROM sales
WHERE connected_handling_time IS NOT NULL
GROUP BY agent_name
ORDER BY avg_handle_time DESC;
-- as there were more than 98% null values calculated avg for 242 NON NULL VALUES where "Sean Williams"	1986.00 has the highest avgerage handling time


-- 🔹 6. How long does it usually take to respond to an issue?
SELECT ROUND(AVG(EXTRACT(EPOCH FROM (issue_responded - issue_reported)))/60,2) AS avg_minutes_to_respond
FROM sales;
-- "avg_minutes_to_respond" is 136.89


-- 🔹 7. Which city has the most customer complaints (calls)?
SELECT customer_city, COUNT(*) as total_complaints
FROM SALES
GROUP BY customer_city
ORDER BY total_complaints DESC;
-- -- "customer_city"	"total_complaints" has the highest complaints
-- "Unknown"	68828
-- "HYDERABAD"	722

-- 🔹 8. Which tenure bucket (experience level) gives the best CSAT scores?
SELECT tenure_bucket, ROUND(AVG(csat_score),2) as avg_csat
FROM SALES
GROUP BY tenure_bucket
ORDER BY avg_csat DESC;
-- "61-90" has avgrage of 4.35 rating in tenure bucket


-- 🔹 9. Which shift (morning/evening/night) performs best in CSAT?
SELECT agent_shift, ROUND(AVG(csat_score),2) as best_csat
FROM SALES
GROUP BY agent_shift
ORDER BY best_csat DESC;
-- "Split" has the best rating of 4.43 in CSAT


-- 🔹 10. Who are the top 5 agents with highest CSAT scores?
SELECT agent_name, ROUND(AVG(csat_score),2) AS avg_csat, COUNT(*) AS total_calls
FROM sales
GROUP BY agent_name
HAVING COUNT(*) >= 5
ORDER BY avg_csat DESC
LIMIT 5;
-- "agent_name"			"avg_csat"	"total_calls"
-- "Pamela Robinson"	4.96			23
-- "Sean Gay"			4.91			22
-- "Virginia Lane"		4.91			111
-- "Taylor Nelson"		4.89			45
-- "Anthony Sims"		4.87			38


-- 🔹 11. Which supervisors manage agents with the highest total revenue?
SELECT supervisor,SUM(item_price) AS total_revenue
FROM sales
GROUP BY supervisor
ORDER BY total_revenue DESC;
-- Supervisor "Carter Park" with 4959271.00 makes the highest revenue


-- 🔹 12. How many orders had a response time over 1 hour?
SELECT 
    COUNT(*) FILTER (WHERE EXTRACT(EPOCH FROM (issue_responded - issue_reported))/60 > 60) AS orders_over_1hr
FROM sales;
-- "orders_over_1hr" are 18059


-- 🔹 13. Which product categories have the highest CSAT variance?
SELECT product_category, ROUND(VAR_SAMP(csat_score),2) AS csat_variance
FROM sales
GROUP BY product_category
ORDER BY csat_variance DESC;
-- top 3 "product_category"	"csat_variance"
--              "GiftCard"	3.86
-- 				"Furniture"	3.11
-- 				"Mobile"	3.06


-- 🔹 14. Distribution of call volume by day of the week?
SELECT TO_CHAR(order_date_time, 'Day') AS day_of_week, COUNT(*) AS total_calls
FROM sales
GROUP BY day_of_week
ORDER BY total_calls DESC;
--  top 3
"day_of_week"	"total_calls"
"Null"				68693
"Friday   "			2736
"Saturday "			2589


-- 🔹 15. Identify top 5 cities with highest average item price per order?
SELECT customer_city, ROUND(AVG(item_price),2) AS avg_order_value
FROM sales
GROUP BY customer_city
ORDER BY avg_order_value DESC
LIMIT 5;
-- Top 5 cities with highest order value
-- "customer_city"	"avg_order_value"
-- "TALIPARAMBA"		76544.50
-- "PONNUR"				70990.00
-- "TANUKU"				58499.00
-- "KOATH"				58499.00
-- "KANGAYAMPALAYAM"	56990.00


-- Created a sales table with customer, agent, product, and service interaction details.

-- Performed data cleaning: handled NULLs, standardized casing, removed duplicates, and flagged outliers.

-- Analyzed CSAT performance across channels, agents, shifts, and tenure buckets.

-- Derived business insights like top revenue categories, response time averages, busiest cities/days, and top-performing agents.

-- Identified supervisors, cities, and product categories driving revenue or variance, making the dataset ready for deeper business decisions.