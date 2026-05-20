-- ═══════════════════════════════════════════════════════════════
-- Query 03: Monthly Executive KPI Summary
-- Purpose: Time-series KPIs for Tableau and Power BI dashboards
-- Database: AdventureWorksDW2022
-- Author: Piumi Jayawardene
-- ═══════════════════════════════════════════════════════════════

USE AdventureWorksDW2022;
GO

WITH MonthlyInternet AS (
    SELECT
        OrderYear,
        OrderMonth,
        OrderMonthName,
        CAST(OrderYear AS VARCHAR(4)) + '-'
            + RIGHT('0' + CAST(OrderMonth AS VARCHAR(2)), 2) AS YearMonth,
        COUNT(DISTINCT SalesOrderNumber) AS InternetOrders,
        COUNT(DISTINCT CustomerKey) AS UniqueCustomers,
        SUM(OrderQuantity) AS UnitsSold,
        ROUND(SUM(SalesAmount), 2) AS InternetRevenue,
        ROUND(SUM(GrossProfit), 2) AS InternetProfit,
        ROUND(AVG(GrossMarginPct), 2) AS AvgInternetMarginPct,
        ROUND(AVG(SalesAmount / NULLIF(OrderQuantity, 0)), 2) AS AvgUnitPrice
    FROM dbo.vw_InternetSalesFull
    WHERE OrderYear IN (2012, 2013, 2014)
    GROUP BY
        OrderYear,
        OrderMonth,
        OrderMonthName
),
MonthlyReseller AS (
    SELECT
        OrderYear,
        OrderMonth,
        ROUND(SUM(SalesAmount), 2) AS ResellerRevenue,
        ROUND(SUM(GrossProfit), 2) AS ResellerProfit,
        COUNT(DISTINCT SalesOrderNumber) AS ResellerOrders
    FROM dbo.vw_ResellerSalesFull
    WHERE OrderYear IN (2012, 2013, 2014)
    GROUP BY
        OrderYear,
        OrderMonth
),
Combined AS (
    SELECT
        i.OrderYear,
        i.OrderMonth,
        i.OrderMonthName,
        i.YearMonth,
        i.InternetOrders,
        i.UniqueCustomers,
        i.UnitsSold,
        i.InternetRevenue,
        i.InternetProfit,
        i.AvgInternetMarginPct,
        i.AvgUnitPrice,
        ISNULL(r.ResellerRevenue, 0) AS ResellerRevenue,
        ISNULL(r.ResellerProfit, 0) AS ResellerProfit,
        ISNULL(r.ResellerOrders, 0) AS ResellerOrders,
        i.InternetRevenue + ISNULL(r.ResellerRevenue, 0) AS TotalRevenue,
        i.InternetProfit + ISNULL(r.ResellerProfit, 0) AS TotalProfit
    FROM MonthlyInternet i
    LEFT JOIN MonthlyReseller r
        ON i.OrderYear = r.OrderYear
        AND i.OrderMonth = r.OrderMonth
)
SELECT
    OrderYear,
    OrderMonth,
    OrderMonthName,
    YearMonth,
    InternetOrders,
    ResellerOrders,
    InternetOrders + ResellerOrders AS TotalOrders,
    UniqueCustomers,
    UnitsSold,
    InternetRevenue,
    ResellerRevenue,
    TotalRevenue,
    TotalProfit,

    ROUND(
        100.0 * TotalProfit /
        NULLIF(TotalRevenue, 0), 2
    ) AS OverallMarginPct,

    AvgUnitPrice,

    LAG(TotalRevenue, 1) OVER (
        ORDER BY OrderYear, OrderMonth
    ) AS PrevMonthRevenue,

    ROUND(
        TotalRevenue - LAG(TotalRevenue, 1) OVER (
            ORDER BY OrderYear, OrderMonth
        ), 2
    ) AS RevenueMoMChange,

    ROUND(
        100.0 * (TotalRevenue - LAG(TotalRevenue, 1) OVER (
            ORDER BY OrderYear, OrderMonth
        )) / NULLIF(LAG(TotalRevenue, 1) OVER (
            ORDER BY OrderYear, OrderMonth
        ), 0), 2
    ) AS RevenueMoMPct,

    LAG(TotalRevenue, 12) OVER (
        ORDER BY OrderYear, OrderMonth
    ) AS SameMonthPriorYear,

    ROUND(
        100.0 * (TotalRevenue - LAG(TotalRevenue, 12) OVER (
            ORDER BY OrderYear, OrderMonth
        )) / NULLIF(LAG(TotalRevenue, 12) OVER (
            ORDER BY OrderYear, OrderMonth
        ), 0), 2
    ) AS RevenueYoYPct,

    SUM(TotalRevenue) OVER (
        PARTITION BY OrderYear
        ORDER BY OrderMonth
        ROWS UNBOUNDED PRECEDING
    ) AS RunningAnnualRevenue

FROM Combined
ORDER BY
    OrderYear,
    OrderMonth;
GO