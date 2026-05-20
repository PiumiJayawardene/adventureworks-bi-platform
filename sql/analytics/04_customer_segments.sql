-- ═══════════════════════════════════════════════════════════════
-- Query 04: Customer Segmentation & Lifetime Value
-- Purpose: Customer intelligence and CLV analysis
-- Database: AdventureWorksDW2022
-- Author: Piumi Jayawardene
-- ═══════════════════════════════════════════════════════════════

USE AdventureWorksDW2022;
GO

WITH CustomerMetrics AS (
    SELECT
        CustomerKey,
        CustomerName,
        Gender,
        YearlyIncome,
        Occupation,
        Education,
        NumberCarsOwned,
        TerritoryGroup,
        TerritoryRegion,
        Country,
        City,

        COUNT(DISTINCT SalesOrderNumber) AS TotalOrders,
        SUM(OrderQuantity) AS TotalUnitsPurchased,
        ROUND(SUM(SalesAmount), 2) AS LifetimeValue,
        ROUND(AVG(SalesAmount), 2) AS AvgOrderValue,
        ROUND(MIN(SalesAmount), 2) AS MinOrderValue,
        ROUND(MAX(SalesAmount), 2) AS MaxOrderValue,
        MIN(CAST(OrderDate AS DATE)) AS FirstPurchaseDate,
        MAX(CAST(OrderDate AS DATE)) AS LastPurchaseDate,

        DATEDIFF(
            DAY,
            MIN(CAST(OrderDate AS DATE)),
            MAX(CAST(OrderDate AS DATE))
        ) AS CustomerAgeDays,

        COUNT(DISTINCT Category) AS CategoriesPurchased
    FROM dbo.vw_InternetSalesFull
    GROUP BY
        CustomerKey,
        CustomerName,
        Gender,
        YearlyIncome,
        Occupation,
        Education,
        NumberCarsOwned,
        TerritoryGroup,
        TerritoryRegion,
        Country,
        City
),
Segmented AS (
    SELECT
        *,
        CASE
            WHEN TotalOrders >= 5 AND LifetimeValue >= 5000 THEN 'Champion'
            WHEN TotalOrders >= 3 AND LifetimeValue >= 2000 THEN 'Loyal'
            WHEN TotalOrders >= 2 THEN 'Returning'
            WHEN LifetimeValue >= 3000 THEN 'High Value'
            WHEN LifetimeValue >= 1000 THEN 'Mid Value'
            ELSE 'One-Time'
        END AS CustomerSegment,

        CASE
            WHEN YearlyIncome >= 100000 THEN 'High Income'
            WHEN YearlyIncome >= 60000 THEN 'Mid Income'
            ELSE 'Standard Income'
        END AS IncomeTier,

        NTILE(4) OVER (
            ORDER BY LifetimeValue DESC
        ) AS CLVQuartile
    FROM CustomerMetrics
)
SELECT
    CustomerSegment,
    IncomeTier,
    TerritoryGroup,
    COUNT(*) AS CustomerCount,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (), 2
    ) AS PctOfCustomers,

    ROUND(AVG(TotalOrders), 2) AS AvgOrdersPerCustomer,
    ROUND(AVG(LifetimeValue), 2) AS AvgCLV,
    ROUND(MIN(LifetimeValue), 2) AS MinCLV,
    ROUND(MAX(LifetimeValue), 2) AS MaxCLV,
    ROUND(AVG(AvgOrderValue), 2) AS AvgOrderValue,
    ROUND(SUM(LifetimeValue), 2) AS TotalSegmentRevenue,

    ROUND(
        100.0 * SUM(LifetimeValue) /
        SUM(SUM(LifetimeValue)) OVER (), 2
    ) AS PctOfTotalRevenue,

    ROUND(AVG(CAST(CustomerAgeDays AS FLOAT)), 0) AS AvgCustomerAgeDays,
    ROUND(AVG(CAST(CategoriesPurchased AS FLOAT)), 2) AS AvgCategoriesPerCustomer

FROM Segmented
GROUP BY
    CustomerSegment,
    IncomeTier,
    TerritoryGroup
ORDER BY
    AvgCLV DESC;
GO