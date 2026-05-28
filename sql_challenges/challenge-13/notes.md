# OLTP vs OLAP Notes

## OLTP (Online Transaction Processing)

- Usually handles **few GBs** of data
- Designed to **capture and process daily transactions**
- Stores **recent operational, detailed, live data**
- Workload consists of:
  - Many **reads**
  - Mostly **writes/updates/inserts**
- Uses a **normalized schema** to reduce redundancy and maintain consistency
- Optimized for:
  - Fast transactions
  - Data integrity
  - Concurrent users

### Examples
- Banking systems
- E-commerce checkout systems
- ATM transactions
- Airline reservation systems

### Important Facts
- Uses **ACID properties**:
  - Atomicity
  - Consistency
  - Isolation
  - Durability
- Queries are usually short and simple
- High transaction throughput is critical
- Data changes frequently in real time

---

## OLAP (Online Analytical Processing)

- Usually handles **terabytes or petabytes** of data
- Designed to **analyze tendencies, trends, and generate reports**
- Stores **historical data**
- Workload consists of:
  - Mostly **reads**
  - Very few writes
- Uses a **denormalized schema** for faster analytical queries
- Commonly implemented using a **Star Schema**

### Examples
- Business intelligence dashboards
- Sales trend analysis
- Data warehouses
- Financial forecasting

### Important Facts
- Queries are usually complex and involve:
  - Aggregations
  - Joins
  - Large scans
- Optimized for:
  - Fast analytical queries
  - Reporting
  - Decision-making
- Often used by analysts and executives instead of operational users

---

# Star Schema

A database schema commonly used in OLAP systems.

- Contains:
  - One central **Fact Table**
  - Multiple surrounding **Dimension Tables**
- Structure resembles a star

## Benefits
- Faster analytical queries
- Simpler reporting queries
- Easy aggregation and filtering

---

# Fact Table

The central table in a star schema.

- Contains:
  - Numerical measurements (metrics)
  - Aggregated business data
  - Foreign keys to dimension tables

### Examples of Metrics
- Revenue
- Quantity sold
- Profit
- Number of transactions

### Important Facts
- Fact tables are usually very large
- Designed for aggregation operations like:
  - `SUM`
  - `AVG`
  - `COUNT`

---

# Dimension Tables

Tables connected to the fact table that provide descriptive context.

### Examples
- Time dimension
- Customer dimension
- Product dimension
- Location dimension

### Important Facts
- Usually smaller than fact tables
- Contain descriptive attributes
- Used for filtering and grouping data

---

# ETL (Extract, Transform, Load)

Process used to move data from OLTP systems into OLAP/data warehouse systems.

## Steps

1. **Extract**
   - Retrieve data from source systems (OLTP databases)

2. **Transform**
   - Clean data
   - Standardize formats
   - Remove duplicates
   - Apply business rules

3. **Load**
   - Insert transformed data into the OLAP/data warehouse

### Important Facts
- ETL pipelines are often scheduled:
  - Hourly
  - Daily
  - Weekly
- Modern systems may also use:
  - ELT (Extract, Load, Transform)
  - Real-time streaming pipelines

---

# Key Differences Between OLTP and OLAP

| Feature | OLTP | OLAP |
|---|---|---|
| Purpose | Daily transactions | Analytics & reporting |
| Data Type | Current/live data | Historical data |
| Storage Size | GBs | TBs/PBs |
| Operations | Inserts, updates, deletes | Reads and aggregations |
| Schema | Normalized | Denormalized |
| Query Complexity | Simple | Complex |
| Users | Customers/employees | Analysts/managers |
| Speed Focus | Transaction speed | Query performance |
| Example | Banking app | Business dashboard |
