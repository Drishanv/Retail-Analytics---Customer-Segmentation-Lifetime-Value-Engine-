# 🏪 Consumer360 – Retail Customer Intelligence Engine

## 📌 Project Overview

Consumer360 is a retail analytics project designed to transform raw transactional data into actionable customer intelligence.

The objective is to identify high-value customers ("Whales") and potential churn risks using RFM (Recency, Frequency, Monetary) segmentation.

This repository contains the implementation of **Week 1 – Data Engineering & Architecture**.

---

# 🗂 Week 1: Data Engineering & Architecture

## 🎯 Objective

Establish a production-grade data foundation to enable scalable customer analytics.

Deliverables completed:

- Star Schema implementation
- Data cleaning & ingestion
- Single Customer View (SCV)
- ER Diagram validation
- SQL performance validation (< 2 seconds)

---

# 📦 Dataset Description

- Retail transactional dataset
- Granularity: **One row per product per invoice**
- Multiple rows can belong to a single invoice
- Cleaned dataset size: **407,664 transactions**
- Unique customers: **4,312**
- Unique products: **4,017**

---

# 🧹 Data Cleaning Performed

The following transformations were applied before ingestion:

- Removed cancelled invoices (InvoiceNo starting with 'C')
- Removed negative quantities (product returns)
- Removed NULL CustomerID records
- Ensured numeric formatting consistency
- Created derived column: `LineAmount = Quantity × UnitPrice`

### Why Cleaning Was Necessary

RFM segmentation requires completed, positive transactions with identifiable customers.  
Cleaning ensures accurate behavioral modeling and prevents distortion of monetary metrics.

---

# 🏗 Data Warehouse Architecture

## ⭐ Star Schema Model

### Fact Table: `fact_sales`

| Column | Description |
|--------|------------|
| SaleID | Surrogate Primary Key |
| InvoiceNo | Transaction ID |
| CustomerID | Foreign Key to dim_customer |
| StockCode | Foreign Key to dim_product |
| InvoiceDate | Purchase timestamp |
| Quantity | Units purchased |
| UnitPrice | Price per unit |
| LineAmount | Derived revenue column |

Granularity: One row per product per invoice.

---

### Dimension Table: `dim_customer`

| Column | Description |
|--------|------------|
| CustomerID | Primary Key |

---

### Dimension Table: `dim_product`

| Column | Description |
|--------|------------|
| StockCode | Primary Key |

---

# 🔗 ER Diagram Validation

The schema was validated using MySQL Reverse Engineering.

Confirmed:

- One-to-Many relationships:
  - dim_customer → fact_sales
  - dim_product → fact_sales
- Proper primary and foreign key enforcement
- Referential integrity maintained

---

# 👤 Single Customer View (SCV)

A SQL view was created to aggregate transaction-level data into customer-level intelligence.

## Metrics Calculated:

- **Recency** → Days since last purchase
- **Frequency** → Number of distinct invoices
- **Monetary** → Total spend per customer
- **SpendRank** → Ranking by total spend (DENSE_RANK)

Purpose:

Convert transaction-level data into customer-level analytical foundation for RFM segmentation (Week 2).

---

# ⚡ Performance Validation

Requirement: Query execution < 2 seconds.

Test Query:
```sql
SELECT * FROM vw_single_customer_view;
