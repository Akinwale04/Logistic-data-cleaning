# Logistic-data-cleaning
End-to-end data cleaning project in MySQL 8.0 on a 10,000-record logistics shipment dataset
# 🚚 Logistics Dataset — End-to-End Data Cleaning in MySQL

## 📌 Overview
This project performs a comprehensive data quality assessment and cleaning of a 10,000-record logistics shipment dataset using MySQL 8.0.

The objective was to transform raw, inconsistent data into a clean, analysis-ready dataset while preserving data integrity and documenting all transformation decisions.

---

## 🧰 Tools & Skills Used
- MySQL 8.0
- SQL (CTEs, Window Functions, CASE statements)
- Data Cleaning & Preprocessing
- Data Quality Assessment (6 dimensions framework)
- Outlier Treatment (Capping + Flagging)
- Missing Value Imputation (Median-based)

---

## 📊 Dataset Summary
- **Raw Records:** 10,000  
- **Final Records:** 9,808  
- **Columns:** 11  
- **Duplicates Removed:** 192  

---

## 🧠 Data Quality Framework
The dataset was assessed using six key data quality dimensions:

- **Completeness** – Handling NULL and missing values  
- **Consistency** – Standardizing categorical values  
- **Validity** – Ensuring correct data types and ranges  
- **Accuracy** – Correcting invalid values (e.g., negatives)  
- **Uniqueness** – Removing duplicate records  
- **Timeliness** – Standardizing date formats  

---

## 🧹 Data Cleaning Process

### 🔹 1. Duplicate Removal
- Removed 192 duplicate records  
- Used `ROW_NUMBER()` with partitioning on `shipment_id`  

---

### 🔹 2. Date Standardization
- Detected and standardized **5 different date formats**
- Used `REGEXP` + `STR_TO_DATE()`
- Applied logic to resolve ambiguous formats (DD-MM vs MM-DD)

---

### 🔹 3. Data Consistency
- Standardized categorical fields:
  - **Carrier names:** ~15 variants → 10 clean values  
  - **Status values:** ~8 variants → 4 standardized values  
- Used `TRIM(LOWER(...))` + `CASE` statements  

---

### 🔹 4. Outlier Treatment (Capping + Flagging)
Instead of removing extreme values:

- **weight_kg**
  - Capped at 500 kg  
  - Negative values corrected using `ABS()`  
  - Flag column created (`weight_kg_flag`)

- **delivery_days**
  - Converted from text → integer using `FLOOR(CAST(...))`
  - Capped at 60 days  
  - Flag column created (`delivery_days_flag`)

👉 This approach preserves anomalies while reducing their impact.

---

### 🔹 5. Missing Value Imputation
Used **median imputation** (robust to outliers):

| Column | Strategy | Grouping |
|--------|----------|----------|
| weight_kg | Median | product_category |
| delivery_days | Median | route + carrier |
| shipping_cost_usd | Cost-per-kg × weight | route + carrier |

---

### 🔹 6. Data Type Fixes
- `shipment_date`: VARCHAR → DATE  
- `delivery_days`: VARCHAR → INT  
- Enforced using `ALTER TABLE`

---

## 📈 Before vs After

| Metric | Before | After |
|------|--------|-------|
| Records | 10,000 | 9,808 |
| Duplicates | 192 | 0 |
| Date Formats | 5 | 1 |
| Carrier Variants | ~15 | 10 |
| Status Variants | ~8 | 4 |
| delivery_days Type | TEXT | INT |
| Outliers | Present | Capped + Flagged |
| NULL Values | Present | Imputed |

---

## 🛠️ SQL Techniques Demonstrated
- `ROW_NUMBER()` for deduplication  
- `REGEXP` for pattern detection  
- `STR_TO_DATE()` for date parsing  
- `CASE` for conditional transformations  
- `CTEs` for structured queries  
- `UPDATE ... JOIN` for imputation  
- `COALESCE(NULLIF(...))` for NULL handling  
- `ABS()` for correcting invalid values  
- `FLOOR(CAST(...))` for numeric conversion  

---

## 📁 Project Files
| File | Description |
|------|-------------|
| `logistic.sql` | Full SQL cleaning script |
| `Logistics_DQ_Assessment_Report.docx` | Detailed documentation of all decisions |
| `LOGISTICS_CLEANED_1.csv` | Final cleaned dataset |

---

## 💡 Key Takeaways
- Demonstrates real-world data cleaning using SQL  
- Applies structured data quality assessment methodology  
- Balances data integrity with practical cleaning techniques  
- Preserves important anomalies using flagging  

---


## ✅ Project Status
✔ Completed (May 2026)  
✔ Dataset cleaned and analysis-ready  

---
