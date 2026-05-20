-- ═══════════════════════════════════════════════════════════════
-- Query 01: Revenue & Profitability by Territory
-- Purpose: Territory performance analysis for Tableau and Power BI
-- Database: AdventureWorksDW2022
-- Author: Piumi Jayawardene
-- ═══════════════════════════════════════════════════════════════

USE AdventureWorksDW2022;
GO

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
        ROUND(AVG(GrossMarginPct), 2) AS AvgMarginPct,
        ROUND(AVG(UnitPrice), 2) AS AvgUnitPrice
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
        ROUND(AVG(GrossMarginPct), 2) AS AvgMarginPct,
        ROUND(AVG(SalesAmount / NULLIF(OrderQuantity, 0)), 2) AS AvgUnitPrice
    FROM dbo.vw_ResellerSalesFull
    WHERE OrderYear IN (2012, 2013, 2014)
    GROUP BY
        TerritoryGroup,
        TerritoryRegion,
        Country,
        OrderYear,
        OrderQuarter
),
Combined AS (
    SELECT * FROM InternetByTerritory
    UNION ALL
    SELECT * FROM ResellerByTerritory
)
SELECT
    TerritoryGroup,
    TerritoryRegion,
    Country,
    OrderYear,
    OrderQuarter,
    YearQuarter,
    SalesChannel,
    TotalOrders,
    UniqueCustomers,
    UnitsSold,
    TotalRevenue,
    TotalGrossProfit,
    AvgMarginPct,
    AvgUnitPrice,

    ROUND(
        100.0 * TotalRevenue /
        SUM(TotalRevenue) OVER (
            PARTITION BY OrderYear, SalesChannel
        ), 2
    ) AS PctOfAnnualRevenue,

    TotalRevenue - LAG(TotalRevenue, 1) OVER (
        PARTITION BY TerritoryRegion, SalesChannel
        ORDER BY OrderYear, OrderQuarter
    ) AS RevenueQoQChange,

    ROUND(
        100.0 * (TotalRevenue - LAG(TotalRevenue, 1) OVER (
            PARTITION BY TerritoryRegion, SalesChannel
            ORDER BY OrderYear, OrderQuarter
        )) / NULLIF(LAG(TotalRevenue, 1) OVER (
            PARTITION BY TerritoryRegion, SalesChannel
            ORDER BY OrderYear, OrderQuarter
        ), 0), 2
    ) AS RevenueQoQPct

FROM Combined
ORDER BY
    OrderYear,
    OrderQuarter,
    TotalRevenue DESC;
GO