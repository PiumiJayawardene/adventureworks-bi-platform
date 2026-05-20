"""
AdventureWorks BI Platform — Python Extraction Pipeline
========================================================
Connects to SQL Server AdventureWorksDW2022, runs analytical
queries, and exports clean CSV files for Tableau and Power BI.

Author: Piumi Jayawardene
Version: 1.0
"""

import pandas as pd
import pyodbc
import logging
from pathlib import Path

# ──────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(message)s",
    datefmt="%H:%M:%S"
)

log = logging.getLogger(__name__)

SERVER_NAME = r"PIUMI\SQLEXPRESS"
DATABASE = "AdventureWorksDW2022"

# This goes one folder up from /python into the project root
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "processed"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# ──────────────────────────────────────────────
# CONNECTION
# ──────────────────────────────────────────────

def get_connection():
    """
    Create SQL Server connection using Windows Authentication.
    """
    conn_str = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={SERVER_NAME};"
        f"DATABASE={DATABASE};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )

    try:
        conn = pyodbc.connect(conn_str)
        log.info(f"Connected to SQL Server: {SERVER_NAME} / {DATABASE}")
        return conn
    except pyodbc.Error as error:
        log.error(f"Connection failed: {error}")
        log.info("Troubleshooting tips:")
        log.info("1. Check SQL Server is running")
        log.info("2. Check SERVER_NAME matches SSMS")
        log.info("3. Install Microsoft ODBC Driver 17 for SQL Server if missing")
        raise


# ──────────────────────────────────────────────
# SQL QUERIES
# ──────────────────────────────────────────────

QUERIES = {
    "territory_revenue": """
        WITH InternetByTerritory AS (
            SELECT
                TerritoryGroup,
                TerritoryRegion,
                Country,
                OrderYear,
                OrderQuarter,
                CAST(OrderYear AS VARCHAR(4)) + '-Q' + CAST(OrderQuarter AS VARCHAR(1)) AS YearQuarter,
                'Internet' AS SalesChannel,
                COUNT(DISTINCT SalesOrderNumber) AS TotalOrders,
                COUNT(DISTINCT CustomerKey) AS UniqueCustomers,
                SUM(OrderQuantity) AS UnitsSold,
                ROUND(SUM(SalesAmount), 2) AS TotalRevenue,
                ROUND(SUM(GrossProfit), 2) AS TotalGrossProfit,
                ROUND(AVG(GrossMarginPct), 2) AS AvgMarginPct
            FROM dbo.vw_InternetSalesFull
            WHERE OrderYear IN (2012, 2013, 2014)
            GROUP BY
                TerritoryGroup,
                TerritoryRegion,
                Country,
                OrderYear,
                OrderQuarter
        ),
        ResellerByTerritory AS (
            SELECT
                TerritoryGroup,
                TerritoryRegion,
                Country,
                OrderYear,
                OrderQuarter,
                CAST(OrderYear AS VARCHAR(4)) + '-Q' + CAST(OrderQuarter AS VARCHAR(1)) AS YearQuarter,
                'Reseller' AS SalesChannel,
                COUNT(DISTINCT SalesOrderNumber) AS TotalOrders,
                0 AS UniqueCustomers,
                SUM(OrderQuantity) AS UnitsSold,
                ROUND(SUM(SalesAmount), 2) AS TotalRevenue,
                ROUND(SUM(GrossProfit), 2) AS TotalGrossProfit,
                ROUND(AVG(GrossMarginPct), 2) AS AvgMarginPct
            FROM dbo.vw_ResellerSalesFull
            WHERE OrderYear IN (2012, 2013, 2014)
            GROUP BY
                TerritoryGroup,
                TerritoryRegion,
                Country,
                OrderYear,
                OrderQuarter
        )
        SELECT *
        FROM InternetByTerritory
        UNION ALL
        SELECT *
        FROM ResellerByTerritory
        ORDER BY OrderYear, OrderQuarter, TotalRevenue DESC;
    """,

    "product_performance": """
        WITH ProductMetrics AS (
            SELECT
                Category,
                SubCategory,
                ProductName,
                OrderYear,
                SUM(OrderQuantity) AS UnitsSold,
                COUNT(DISTINCT SalesOrderNumber) AS Orders,
                ROUND(SUM(SalesAmount), 2) AS Revenue,
                ROUND(SUM(GrossProfit), 2) AS GrossProfit,
                ROUND(AVG(GrossMarginPct), 2) AS AvgMarginPct,
                ROUND(AVG(UnitPrice), 2) AS AvgSellingPrice,
                ROUND(AVG(ListPrice), 2) AS AvgListPrice
            FROM dbo.vw_InternetSalesFull
            WHERE OrderYear = 2014
            GROUP BY
                Category,
                SubCategory,
                ProductName,
                OrderYear
        )
        SELECT *
        FROM ProductMetrics
        ORDER BY Revenue DESC;
    """,

    "kpi_monthly": """
        WITH MonthlyInternet AS (
            SELECT
                OrderYear,
                OrderMonth,
                OrderMonthName,
                CAST(OrderYear AS VARCHAR(4)) + '-'
                    + RIGHT('0' + CAST(OrderMonth AS VARCHAR(2)), 2) AS YearMonth,
                COUNT(DISTINCT SalesOrderNumber) AS TotalOrders,
                COUNT(DISTINCT CustomerKey) AS UniqueCustomers,
                SUM(OrderQuantity) AS UnitsSold,
                ROUND(SUM(SalesAmount), 2) AS TotalRevenue,
                ROUND(SUM(GrossProfit), 2) AS TotalProfit,
                ROUND(AVG(GrossMarginPct), 2) AS AvgMarginPct,
                ROUND(AVG(SalesAmount / NULLIF(OrderQuantity, 0)), 2) AS AvgUnitPrice
            FROM dbo.vw_InternetSalesFull
            WHERE OrderYear IN (2012, 2013, 2014)
            GROUP BY
                OrderYear,
                OrderMonth,
                OrderMonthName
        )
        SELECT *
        FROM MonthlyInternet
        ORDER BY OrderYear, OrderMonth;
    """,

    "customer_segments": """
        WITH CustomerMetrics AS (
            SELECT
                CustomerKey,
                CustomerName,
                Gender,
                Occupation,
                YearlyIncome,
                TerritoryGroup,
                Country,
                COUNT(DISTINCT SalesOrderNumber) AS TotalOrders,
                ROUND(SUM(SalesAmount), 2) AS LifetimeValue,
                ROUND(AVG(SalesAmount), 2) AS AvgOrderValue,
                COUNT(DISTINCT Category) AS CategoriesPurchased
            FROM dbo.vw_InternetSalesFull
            GROUP BY
                CustomerKey,
                CustomerName,
                Gender,
                Occupation,
                YearlyIncome,
                TerritoryGroup,
                Country
        )
        SELECT
            *,
            CASE
                WHEN TotalOrders >= 5 AND LifetimeValue >= 5000 THEN 'Champion'
                WHEN TotalOrders >= 3 AND LifetimeValue >= 2000 THEN 'Loyal'
                WHEN TotalOrders >= 2 THEN 'Returning'
                WHEN LifetimeValue >= 3000 THEN 'High Value'
                WHEN LifetimeValue >= 1000 THEN 'Mid Value'
                ELSE 'One-Time'
            END AS CustomerSegment
        FROM CustomerMetrics
        ORDER BY LifetimeValue DESC;
    """
}


# ──────────────────────────────────────────────
# EXTRACT AND EXPORT
# ──────────────────────────────────────────────

def extract_all():
    """
    Run all analytical queries and export each result as a CSV file.
    """
    log.info("=" * 60)
    log.info("AdventureWorks BI — Extraction Pipeline")
    log.info("=" * 60)

    conn = get_connection()
    results = {}

    for query_name, sql in QUERIES.items():
        log.info(f"Extracting: {query_name}")

        try:
            df = pd.read_sql(sql, conn)
            output_path = OUTPUT_DIR / f"{query_name}.csv"
            df.to_csv(output_path, index=False)
            results[query_name] = len(df)
            log.info(f"✓ {len(df):,} rows exported → {output_path}")

        except Exception as error:
            results[query_name] = 0
            log.error(f"✗ Failed to extract {query_name}: {error}")

    conn.close()

    log.info("=" * 60)
    log.info("EXTRACTION COMPLETE ✓")
    log.info("=" * 60)

    for name, count in results.items():
        log.info(f"{name:<25} {count:>8,} rows")

    log.info(f"Output directory: {OUTPUT_DIR}")
    log.info("=" * 60)


if __name__ == "__main__":
    extract_all()