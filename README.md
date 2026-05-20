# AdventureWorks Executive BI Platform
## SQL Server + Python + Tableau Retail KPI Suite

**Domain:** Manufacturing / Retail / Enterprise Sales  
**Professional Identity:** BI Analyst · Data Analyst · Dashboard Designer  
**Tools:** SQL Server Express · SSMS · T-SQL · Python · Tableau Public · GitHub  
**Dataset:** Microsoft AdventureWorksDW2022  
**Status:** Completed up to Tableau BI dashboard phase  
**Future Enhancement:** Power BI executive report with direct SQL Server connection and DAX measures  

---

## Project Overview

This project is an enterprise-style Business Intelligence platform built using Microsoft's AdventureWorksDW2022 data warehouse.

AdventureWorks Cycles is a fictional bicycle manufacturing and retail company with sales data across internet and reseller channels, product categories, customers, dates, and sales territories.

The purpose of this project is to build an executive KPI suite that helps leadership understand:

- Which territories generate the highest revenue
- Which product categories and subcategories perform best
- How monthly revenue and profit trends change over time
- Which customer segments contribute the most value
- How SQL Server data can be transformed into dashboard-ready outputs using Python

---

## Business Problem

AdventureWorks has sales data stored across fact and dimension tables in SQL Server. However, raw transactional data is not suitable for direct executive reporting.

Leadership needs a clean BI layer that can answer business questions such as:

- Which regions are driving revenue growth?
- Which products generate the highest sales and margin?
- What are the key monthly sales trends?
- Which customer groups represent the highest lifetime value?
- How can data be prepared for dashboard reporting in Tableau?

---

## Solution Built

The project follows a BI workflow:

```text
AdventureWorksDW2022 SQL Server Database
        ↓
Analytical SQL Views
        ↓
T-SQL KPI Queries
        ↓
Python Extraction Pipeline
        ↓
Processed CSV Files
        ↓
Tableau Executive Dashboards