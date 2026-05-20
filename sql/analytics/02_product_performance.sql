-- ═══════════════════════════════════════════════════════════════
-- Query 02: Product Category & Subcategory Performance
-- Purpose: Product mix and margin analysis for dashboards
-- Database: AdventureWorksDW2022
-- Author: Piumi Jayawardene
-- ═══════════════════════════════════════════════════════════════

USE AdventureWorksDW2022;
GO

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
        ROUND(SUM(TotalProductCost), 2) AS TotalCost,
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
),
CategoryTotals AS (
    SELECT
        Category,
        OrderYear,
        SUM(Revenue) AS CategoryRevenue,
        SUM(GrossProfit) AS CategoryProfit
    FROM ProductMetrics
    GROUP BY Category, OrderYear
),
AnnualTotal AS (
    SELECT SUM(Revenue) AS TotalRevenue
    FROM ProductMetrics
)
SELECT
    pm.Category,
    pm.SubCategory,
    pm.ProductName,
    pm.OrderYear,
    pm.UnitsSold,
    pm.Orders,
    pm.Revenue,
    pm.GrossProfit,
    pm.TotalCost,
    pm.AvgMarginPct,
    pm.AvgSellingPrice,
    pm.AvgListPrice,

    ROUND(
        (pm.AvgListPrice - pm.AvgSellingPrice)
        / NULLIF(pm.AvgListPrice, 0) * 100, 2
    ) AS AvgDiscountPct,

    ROUND(
        100.0 * pm.Revenue /
        NULLIF(ct.CategoryRevenue, 0), 2
    ) AS PctOfCategoryRevenue,

    ROUND(
        100.0 * pm.Revenue /
        NULLIF(at_total.TotalRevenue, 0), 2
    ) AS PctOfTotalRevenue,

    RANK() OVER (
        PARTITION BY pm.Category
        ORDER BY pm.Revenue DESC
    ) AS RankInCategory,

    RANK() OVER (
        ORDER BY pm.Revenue DESC
    ) AS OverallRevenueRank

FROM ProductMetrics pm
JOIN CategoryTotals ct
    ON pm.Category = ct.Category
    AND pm.OrderYear = ct.OrderYear
CROSS JOIN AnnualTotal at_total
ORDER BY
    pm.Category,
    pm.Revenue DESC;
GO