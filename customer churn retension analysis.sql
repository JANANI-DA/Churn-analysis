-- CUSTOMER CHURN RETENSION ANALYSIS
CREATE DATABASE churn_project;
use churn_project;


-- Create the table
CREATE TABLE churn_data (
    customer_id VARCHAR(50) PRIMARY KEY,
    gender VARCHAR(10),
    senior_citizen TINYINT, -- 0 or 1
    partner VARCHAR(3),     -- 'Yes' or 'No'
    dependents VARCHAR(3),  -- 'Yes' or 'No'
    tenure INT,
    phone_service VARCHAR(10),
    multiple_lines VARCHAR(30),
    internet_service VARCHAR(20),
    online_security VARCHAR(30),
    online_backup VARCHAR(30),
    device_protection VARCHAR(30),
    tech_support VARCHAR(30),
    streaming_tv VARCHAR(30),
    streaming_movies VARCHAR(30),
    contract VARCHAR(20),
    paperless_billing VARCHAR(3), -- 'Yes' or 'No'
    payment_method VARCHAR(50),
    monthly_charges FLOAT,
    total_charges FLOAT,
    num_admin INT,
    num_tech INT,
    churn VARCHAR(3) -- 'Yes' or 'No'
);
SELECT 
    COUNT(*) 
FROM churn_data;
-- DATA CLEANING 
WITH ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS rn
  FROM churn_data
)
DELETE FROM churn_data
WHERE customer_id IN (
    SELECT customer_id FROM ranked WHERE rn > 1
);
SELECT COUNT(*) AS missing_total_charges
FROM churn_data
WHERE total_charges IS NULL OR total_charges = '';
-- QUESTIONS
-- 1)retrive all customer detail who have churned
SELECT *
FROM churn_data
WHERE churn = 'Yes';
-- 2)total number of the customer group by gender
SELECT gender, COUNT(*) AS total_customers
FROM churn_data
GROUP BY gender;
-- 3)customer who have tenure greater than 24 months andd are on a two year contract
SELECT *
FROM churn_data
WHERE tenure > 24
  AND contract = 'Two year';
  select contract from churn_data;
  -- 4) the average monthly charges for churned vs non churned customer
SELECT
    churn,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM churn_data
GROUP BY churn;
-- 5)customer use fiber optic internet service and have churned
SELECT
  COUNT(*) AS churned_fiber_users
FROM churn_data
WHERE internet_service = 'fiber optic'
  AND churn = 'yes';
-- 6) top 5 customer who paid the highest  total charges
WITH RankedCustomers AS (
  SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_charges DESC) AS row_num
  FROM churn_data
)
SELECT *
FROM RankedCustomers
WHERE row_num <= 5;
-- 7)the churn rate (%) for each contract  type
SELECT
  contract,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
    2
  ) AS churn_rate_percent
FROM churn_data
GROUP BY contract
ORDER BY churn_rate_percent DESC;
-- 8)check if senior citizens are more likely to churn compared to non-senior citizens
SELECT
  CASE WHEN senior_citizen = 1 THEN 'Senior' ELSE 'Non-Senior' END AS category,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
  ROUND(
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
    2
  ) AS churn_rate_percent
FROM churn_data
GROUP BY senior_citizen;

-- 9)the  most common payment among  churned customer
SELECT
    payment_method,
    COUNT(*) AS churned_customers_count
FROM churn_data
WHERE churn = 'Yes'
GROUP BY payment_method
ORDER BY churned_customers_count DESC
LIMIT 1;

-- 10)  the correlation between the number of tech tickets and customer churn.
select
    (
        SUM((num_tech - avg_num_tech) * (churn_numeric - avg_churn)) /
        (SQRT(SUM(POW(num_tech - avg_num_tech, 2)) * SUM(POW(churn_numeric - avg_churn, 2))))
    ) AS correlation
FROM (
    SELECT 
        num_tech,
        CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END AS churn_numeric,
        (SELECT AVG(num_tech) FROM churn_data) AS avg_num_tech,
        (SELECT AVG(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) FROM churn_data) AS avg_churn
    FROM churn_data
) AS subquery;

