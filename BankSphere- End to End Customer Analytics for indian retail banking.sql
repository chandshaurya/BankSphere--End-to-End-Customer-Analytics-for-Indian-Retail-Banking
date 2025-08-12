create database BankSphere;
use BankSphere;

               #### Project : BankSphere- End to End Customer Analytics for indian retail banking ####

CREATE TABLE IF NOT EXISTS `customers` (
    `customer_id` INT PRIMARY KEY,
    `CustomerName` VARCHAR(255),
    `Gender` VARCHAR(255),
    `age` INT,
    `City` VARCHAR(255),
    `State` VARCHAR(255),
    `Pincode` INT,
    `DateOfBirth` VARCHAR(255),
    `Age` INT,
    `MaritalStatus` VARCHAR(255),
    `Education` VARCHAR(255),
    `Occupation` VARCHAR(255),
    `AnnualIncome` INT,
    `AccountOpenDate` VARCHAR(255),
    `CustomerSegment` VARCHAR(255),
    `account_type` VARCHAR(255)
);


CREATE TABLE IF NOT EXISTS `loans` (
    `customer_id` INT,
    `loan_type` VARCHAR(255),
    `loan_amount` FLOAT,
    `emi` FLOAT,
    `default_flag` INT,
    `credit_score` INT,
    `LoanType` VARCHAR(255),
    `LoanStatus` VARCHAR(255),
    `InterestRate` FLOAT,
    `TenureYears` INT
);

truncate loans;
CREATE TABLE IF NOT EXISTS `transactions` (
    `transaction_id` VARCHAR(255) PRIMARY KEY,
    `customer_id` INT,
    `date` VARCHAR(255),
    `amount` FLOAT,
    `type` VARCHAR(255),
    `channel` VARCHAR(255),
    `TransactionType` VARCHAR(255),
    `MerchantCategory` VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS `profitability` (
    `customer_id` INT,
    `cost_to_serve` FLOAT,
    `net_margin` FLOAT,
    `CustomerLifetimeValue` FLOAT,
    `NetProfitMargin` FLOAT,
    `RevenueGenerated` FLOAT
);


-- Data Cleaning and modifying

ALTER TABLE transactions
DROP COLUMN channel;

UPDATE transactions
SET date = STR_TO_DATE(date, '%d-%m-%Y');

UPDATE customers
SET AccountOpenDate = STR_TO_DATE(AccountOpenDate, '%d-%m-%Y');

ALTER TABLE loans
DROP COLUMN LoanType;


-- Data Explore

select * From customers;
select * From loans;
select * From profitability;
select * From transactions;

-- No. of Customers

select Count(*) from customers;

--   City

select distinct(City) from customers;

-- No. of State
select count(distinct(State)) as State from customers;


-- Data Analysis::: 

### Customer Demographics & Segmentation Analysis


-- What is the exact count and percentage of total customers in each CustomerSegment? 

SELECT 
    CustomerSegment, 
    COUNT(*) AS Customer_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS Percentage
FROM 
    customers
GROUP BY 
    CustomerSegment
Order by Customer_count desc;
    
    
--  Which top 5 State and City combinations have the highest number of customers? 

select 
	State,
    City,
    count(*) as Customers
From
    customers
Group by
	State , City
Order by Customers Desc
Limit 5;

-- How many customers fall into predefined income brackets (e.g., <5 Lakhs, 5-10 Lakhs, 10-20 Lakhs, 20+ Lakhs)? 


SELECT 
    CASE 
        WHEN AnnualIncome < 500000 THEN '< 5 lakhs'
        WHEN AnnualIncome BETWEEN 500000 AND 999999 THEN '5-10 lakhs'
        WHEN AnnualIncome BETWEEN 1000000 AND 1999999 THEN '10-20 lakhs'
        ELSE '20+ lakhs'
    END AS Income,
    COUNT(*) AS Customers
FROM 
    customers
group by
    Income;
    
-- What is the distribution of customers across different age groups (e.g., 18-25, 26-35, 36-50, 51+)?

SELECT 
    AgeGroup,
    COUNT(*) AS Customers
FROM 
    (
    SELECT 
        CASE 
            WHEN Age < 18 THEN 'Below 18'
            WHEN Age BETWEEN 18 AND 25 THEN '18-25'
            WHEN Age BETWEEN 26 AND 35 THEN '26-35'
            WHEN Age BETWEEN 36 AND 50 THEN '36-50'
            ELSE '51+'
        END AS AgeGroup
    FROM 
        customers
    ) AS subquery
GROUP BY 
    AgeGroup;

-- What is the average AnnualIncome and Age for customers in the 'Platinum' segment versus the 'Silver' segment? 

Select 
	CustomerSegment, 
    Round(Avg(Age),0) as Average_Age, 
    Avg(AnnualIncome) as Average_income
from 
    customers
where 
    CustomerSegment In ( 'Platinum' , 'Silver')
group by
    CustomerSegment;
    
-- What is the average tenure (in years) of customers in each CustomerSegment? 

SELECT 
    CustomerSegment,
    ROUND(AVG(DATEDIFF(CURDATE(),AccountOpenDate) / 365), 2) AS Average_Tenure_Years
FROM 
    customers
GROUP BY 
    CustomerSegment;

-- Which Occupation has the highest average AnnualIncome, and which has the lowest? 
(
    SELECT Occupation, ROUND(AVG(AnnualIncome), 2) AS Avg_AnnualIncome
    FROM customers
    GROUP BY Occupation
    ORDER BY Avg_AnnualIncome DESC
    LIMIT 1
)
UNION 
(
    SELECT Occupation, ROUND(AVG(AnnualIncome), 2) AS Avg_AnnualIncome
    FROM customers
    GROUP BY Occupation
    ORDER BY Avg_AnnualIncome ASC
    LIMIT 1
);

-- How many new customers has the bank acquired each year, based on AccountOpenDate

select  
      Year(STR_TO_DATE(AccountOpenDate, '%d-%m-%Y')) as Account_open_year , 
      count(*) as customers
from 
      customers
group by 
	Account_open_year ;
    
-- ### Loan Portfolio & Risk Analysis 
    
-- What is the loan default rate (default_flag = 1) for each CustomerSegment? 

select
	CustomerSegment,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS Default_rate
From
	customers
inner join 
	loans
On 
	customers.customer_id = loans.customer_id
Where 
	loans.default_flag = 1
group by
	CustomerSegment;
    
-- What is the average ratio of LoanAmount to AnnualIncome for customers who have defaulted versus those who have not? 

select
	default_flag ,
    ROUND(Avg(loan_amount/AnnualIncome) , 2) AS Ratio
From
	customers
inner join 
	loans
On 
	customers.customer_id = loans.customer_id
group by
	default_flag ;
    
-- Which top 5 City locations have the highest total LoanAmount at risk (from defaulted loans)? 

select
	City,
    Round(Sum(loan_amount), 2) as LoanAmount_at_risk
From
	customers
inner join 
	loans
On 
	customers.customer_id = loans.customer_id
Where 
	loans.default_flag = 1
group by
	City
Order by
	LoanAmount_at_risk Desc
Limit 5;

--  Which LoanType has the highest number of defaults and the highest total defaulted amount? 

select
	loan_type,
    Round(Sum(loan_amount), 2) as LoanAmount_at_risk
From
	customers
inner join 
	loans
On 
	customers.customer_id = loans.customer_id
Where 
	loans.default_flag = 1
group by
	loan_type
Order by
	LoanAmount_at_risk Desc;
    
-- Is the average InterestRate significantly higher for loans that have defaulted? 
    
  select
	default_flag,
    Round(Avg(InterestRate), 2) as InterestRate
From
	customers
inner join 
	loans
On 
	customers.customer_id = loans.customer_id
group by
	default_flag
Order by
	InterestRate Desc;  

-- How many customers hold more than one 'Active' loan simultaneously?

SELECT 
    COUNT(*) AS Number_of_Customers
FROM 
    (
    SELECT 
        customer_id
    FROM 
        loans
    WHERE 
        loanStatus = 'Active'
    GROUP BY 
        customer_id
    HAVING 
        COUNT(customer_id) > 1
    ) AS subquery;
    

### Transaction & Profitability Analysis 

-- Who are the top 20 most profitable customers and what CustomerSegment do they belong to? 

SELECT 
    CustomerName,
    CustomerSegment,
    SUM(NetProfitMargin) AS Total_Profit
FROM 
    customers
JOIN 
    transactions ON customers.customer_id = transactions.customer_id
Join
	profitability ON profitability.customer_id = transactions.customer_id
GROUP BY 
     CustomerName, CustomerSegment
ORDER BY 
    Total_Profit DESC
LIMIT 20;

-- Which top 5 States contribute the most to the bank's overall Profitability? 

SELECT 
    State,
    SUM(NetProfitMargin) AS Total_Profit
FROM 
    customers
JOIN 
    transactions ON customers.customer_id = transactions.customer_id
Join
	profitability ON profitability.customer_id = transactions.customer_id
GROUP BY 
     State
ORDER BY 
    Total_Profit DESC
LIMIT 5;

-- What is the average number of transactions per month for a 'Gold' segment customer versus a 'Regular' segment customer? 

SELECT 
    CustomerSegment,
    COUNT(*) / COUNT(DISTINCT YEAR(date), MONTH(date)) AS Avg_Transactions_Per_Month
FROM 
    customers
JOIN 
    transactions ON customers.customer_id = transactions.customer_id
WHERE 
    CustomerSegment IN ('Gold', 'Regular')
GROUP BY 
    CustomerSegment
ORDER BY 
    Avg_Transactions_Per_Month DESC;

-- What is the average TransactionAmount for 'Online Payment' versus 'ATM Withdrawal'? 

SELECT 
    TransactionType,
    Avg(amount) AS Avg_Transactions_Amount
FROM 
    transactions
WHERE 
    TransactionType IN ('Online Payment', 'ATM Withdrawal')
GROUP BY 
    TransactionType
ORDER BY 
    Avg_Transactions_Amount DESC;
    
-- Is there a correlation between the total number of transactions a customer makes and their overall Profitability?

SELECT 
    SUM((Total_Transactions - avg_txn) * (Total_Profitability - avg_profit)) / (COUNT(*) - 1)
    / (stddev_txn * stddev_profit) AS correlation_coefficient
FROM (
    SELECT 
        customer_id,
        Total_Transactions,
        Total_Profitability,
        (SELECT AVG(Total_Transactions) FROM (
            SELECT COUNT(t.transaction_id) AS Total_Transactions
            FROM customers c
            JOIN transactions t ON c.customer_id = t.customer_id
            JOIN profitability p ON p.customer_id = t.customer_id
            GROUP BY c.customer_id
        ) AS x) AS avg_txn,
        (SELECT AVG(Total_Profitability) FROM (
            SELECT SUM(p.NetProfitMargin) AS Total_Profitability
            FROM customers c
            JOIN transactions t ON c.customer_id = t.customer_id
            JOIN profitability p ON p.customer_id = t.customer_id
            GROUP BY c.customer_id
        ) AS y) AS avg_profit,
        (SELECT STDDEV_POP(Total_Transactions) FROM (
            SELECT COUNT(t.transaction_id) AS Total_Transactions
            FROM customers c
            JOIN transactions t ON c.customer_id = t.customer_id
            JOIN profitability p ON p.customer_id = t.customer_id
            GROUP BY c.customer_id
        ) AS z) AS stddev_txn,
        (SELECT STDDEV_POP(Total_Profitability) FROM (
            SELECT SUM(p.NetProfitMargin) AS Total_Profitability
            FROM customers c
            JOIN transactions t ON c.customer_id = t.customer_id
            JOIN profitability p ON p.customer_id = t.customer_id
            GROUP BY c.customer_id
        ) AS w) AS stddev_profit
    FROM (
        SELECT 
            c.customer_id,
            COUNT(t.transaction_id) AS Total_Transactions,
            SUM(p.NetProfitMargin) AS Total_Profitability
        FROM 
            customers c
        JOIN 
            transactions t ON c.customer_id = t.customer_id
        JOIN
            profitability p ON p.customer_id = t.customer_id
        GROUP BY 
            c.customer_id
    ) AS base
) AS subquery;

-- Which quarter of the year sees the highest total transaction volume?

SELECT 
    QUARTER(Date) AS Quarter,
    SUM(amount) AS Total_Transaction_Volume
FROM 
    transactions
GROUP BY 
    QUARTER(STR_TO_DATE(Date, '%Y-%m-%d'))
ORDER BY 
    Total_Transaction_Volume DESC
LIMIT 1;

-- What is the average Profitability of customers who have never taken a loan?

select
	c.CustomerName,
    avg(NetProfitMargin) as Average_Profitability
From 
	customers as c
Join 
	loans as l on c.customer_id = l.customer_id
Join
	profitability as p on p.customer_id = l.customer_id
where
	default_flag = 0
group by
	c.CustomerName
order by
	c.CustomerName;
    
    
-- profitability for customers who have never taken a loan

SELECT 
    c.customer_id,
    c.CustomerName,
    SUM(p.NetProfitMargin) AS Total_Profitability
FROM 
    customers c
LEFT JOIN 
    profitability p 
    ON c.customer_id = p.customer_id
WHERE 
    c.customer_id NOT IN (
        SELECT DISTINCT customer_id
        FROM loans
    )
GROUP BY 
    c.customer_id, c.CustomerName
ORDER BY 
    Total_Profitability DESC;


### Cross-Functional & Behavioral Analysis 

-- What is the demographic profile (avg. Age, Occupation, AnnualIncome) of customers who have defaulted on a 'Personal Loan'?

select
	CustomerName,
    Occupation,
    Avg(Age) as age,
    sum(AnnualIncome) as AnnualIncome
    
From 
	customers as c
Join 
	loans as l on c.customer_id = l.customer_id
Where
	loan_type IN ('Personal')
group by
	CustomerName,
    Occupation;
    
-- How many 'Platinum' customers with an AnnualIncome over 20 Lakhs do not currently have an active 'Home Loan'? 
select
	CustomerSegment,
    Count(*)
From 
	customers as c
Join 
	loans as l on c.customer_id = l.customer_id
Where
	CustomerSegment IN ('Platinum') and loan_type in ('Home') and AnnualIncome >2000000
group by
	CustomerSegment;

--  Do customers who default tend to have a higher frequency of 'ATM Withdrawal' transactions in the months leading up to the default? 	

Select 
    Month(STR_TO_DATE(Date, '%Y-%m-%d')) as Month,
    Count(t.TransactionType) as Frequency
From 
	transactions as t
Join 
	loans as l on l.customer_id = t.customer_id 
Join 
	customers as c on  l.customer_id = c.customer_id 
where
	TransactionType In ('ATM Withdrawal') and default_flag = 1
group by
	Month(STR_TO_DATE(Date, '%Y-%m-%d')) 
Order by Month;

--  Which TransactionType is most common among customers under the age of 30? 

Select
	TransactionType,
    Count(Distinct(c.customer_id)) as Customer

From 
	
	transactions as t
Join 
	customers as c on  t.customer_id = c.customer_id 
Where
	Age < 30
group by
	TransactionType;
    
-- Do customers with more than one type of loan have a higher overall CLV score? 

SELECT 
    LoanTypeCategory,
    AVG(CustomerLifetimeValue) AS Avg_Profitability
FROM (
    SELECT 
        l.customer_iD,
        CASE 
            WHEN COUNT(DISTINCT l.loan_type) > 1 THEN 'Multiple Loan Types'
            ELSE 'Single Loan Type'
        END AS LoanTypeCategory,
        p.CustomerLifetimeValue
    FROM 
        loans l
    JOIN 
        profitability p ON l.customer_iD = p.customer_iD
    GROUP BY 
        l.customer_iD, p.CustomerLifetimeValue
) AS sub
GROUP BY 
    LoanTypeCategory;

                              
                              
                              
                              --- project__end 
