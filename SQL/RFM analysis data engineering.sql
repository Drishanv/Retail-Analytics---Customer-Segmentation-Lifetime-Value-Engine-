/* ============================================================
   PROJECT 1: Consumer360 - Retail RFM Engine
   WEEK 1: Data Engineering & Schema Design
   PURPOSE: Create Star Schema (Fact + Dimensions)
   DATABASE: consumer360
   ============================================================ */

-- Create DB 

CREATE DATABASE IF NOT EXISTS retail_analytics;
USE retail_analytics;

-- Creating dim customer table

CREATE TABLE dim_customer (
    CustomerID INT PRIMARY KEY,
    Country VARCHAR(100)
);

-- Creating dim product table

CREATE TABLE dim_product (
    StockCode VARCHAR(20) PRIMARY KEY,   
    Description VARCHAR(255)            
);

-- Creating fact sales table

CREATE TABLE fact_sales (
    SaleID BIGINT AUTO_INCREMENT PRIMARY KEY,  -- Surrogate key
    
    InvoiceNo VARCHAR(20),        -- Transaction ID
    CustomerID INT,               -- Foreign key to dim_customer
    StockCode VARCHAR(20),        -- Foreign key to dim_product
    
    InvoiceDate DATETIME,         -- Purchase timestamp
    Quantity INT,                 -- Units purchased
    UnitPrice DECIMAL(10,2),      -- Price per unit
    LineAmount DECIMAL(12,2),     -- Quantity * UnitPrice (derived column)

    -- Indexes for performance optimization
    INDEX idx_customer (CustomerID),
    INDEX idx_invoice (InvoiceNo),
    INDEX idx_date (InvoiceDate),
    INDEX idx_product (StockCode),

    -- Foreign key constraints
    CONSTRAINT fk_customer FOREIGN KEY (CustomerID)
        REFERENCES dim_customer(CustomerID),

    CONSTRAINT fk_product FOREIGN KEY (StockCode)
        REFERENCES dim_product(StockCode)
);

-- For loading data

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/Drishan/Downloads/RFM analysis data.csv'
INTO TABLE fact_sales
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(InvoiceNo,
 StockCode,
 @Description,
 Quantity,
 @InvoiceDate,
 UnitPrice,
 CustomerID,
 @Country,
 LineAmount)
SET InvoiceDate = STR_TO_DATE(@InvoiceDate, '%Y-%m-%d %H:%i:%s');

-- Quick sanity check of number of rows in our dataset

SELECT COUNT(*) FROM fact_sales;

-- Populate customer dimension table

INSERT INTO dim_customer (CustomerID, Country)
SELECT DISTINCT CustomerID, 'Unknown'
FROM fact_sales
WHERE CustomerID NOT IN (SELECT CustomerID FROM dim_customer);

-- Populate Product dimension table

INSERT INTO dim_product (StockCode, Description)
SELECT DISTINCT StockCode, 'Unknown'
FROM fact_sales
WHERE StockCode NOT IN (SELECT StockCode FROM dim_product);

-- Creating the single customer view 

DROP VIEW IF EXISTS vw_single_customer_view;

CREATE VIEW vw_single_customer_view AS

WITH customer_agg AS (
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS LastPurchaseDate,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        SUM(LineAmount) AS MonetaryValue
    FROM fact_sales
    GROUP BY CustomerID
),

snapshot AS (
    SELECT DATE_ADD(MAX(InvoiceDate), INTERVAL 1 DAY) AS SnapshotDate
    FROM fact_sales
)

SELECT
    c.CustomerID,

    -- Recency = Days since last purchase
    DATEDIFF(s.SnapshotDate, c.LastPurchaseDate) AS Recency,

    c.Frequency,
    ROUND(c.MonetaryValue, 2) AS MonetaryValue,

    -- Rank customers by spending
    DENSE_RANK() OVER (ORDER BY c.MonetaryValue DESC) AS SpendRank

FROM customer_agg c
CROSS JOIN snapshot s;

-- SQL query performance check

SELECT * 
FROM vw_single_customer_view;
