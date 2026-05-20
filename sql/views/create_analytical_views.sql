-- ═══════════════════════════════════════════════════════════════
-- AdventureWorks BI Platform — Analytical Views
-- Purpose: Simplify BI queries by pre-joining core tables
-- Database: AdventureWorksDW2022
-- Author: Piumi Jayawardene
-- ═══════════════════════════════════════════════════════════════

USE AdventureWorksDW2022;
GO

-- View 1: Internet Sales with all dimensions joined
CREATE OR ALTER VIEW dbo.vw_InternetSalesFull AS
SELECT
    fs.SalesOrderNumber,
    fs.SalesOrderLineNumber,

    fs.OrderDateKey,
    dd.FullDateAlternateKey AS OrderDate,
    dd.CalendarYear AS OrderYear,
    dd.CalendarQuarter AS OrderQuarter,
    dd.MonthNumberOfYear AS OrderMonth,
    dd.EnglishMonthName AS OrderMonthName,
    dd.WeekNumberOfYear AS OrderWeek,
    dd.DayNumberOfWeek AS OrderDayOfWeek,

    dp.ProductKey,
    dp.EnglishProductName AS ProductName,
    dp.Color AS ProductColor,
    dp.ListPrice,
    dp.StandardCost,
    dps.EnglishProductSubcategoryName AS SubCategory,
    dpc.EnglishProductCategoryName AS Category,

    fs.CustomerKey,
    dc.FirstName + ' ' + dc.LastName AS CustomerName,
    dc.BirthDate,
    dc.Gender,
    dc.YearlyIncome,
    dc.TotalChildren,
    dc.EnglishEducation AS Education,
    dc.EnglishOccupation AS Occupation,
    dc.HouseOwnerFlag,
    dc.NumberCarsOwned,

    dg.City,
    dg.StateProvinceName AS StateProvince,
    dg.EnglishCountryRegionName AS Country,
    dst.SalesTerritoryRegion AS TerritoryRegion,
    dst.SalesTerritoryGroup AS TerritoryGroup,

    fs.OrderQuantity,
    fs.UnitPrice,
    fs.UnitPriceDiscountPct,
    fs.ExtendedAmount,
    fs.DiscountAmount,
    fs.ProductStandardCost,
    fs.TotalProductCost,
    fs.SalesAmount,
    fs.TaxAmt,
    fs.Freight,
    fs.SalesAmount - fs.TotalProductCost AS GrossProfit,

    CASE
        WHEN fs.SalesAmount > 0
        THEN ROUND((fs.SalesAmount - fs.TotalProductCost) / fs.SalesAmount * 100, 2)
        ELSE 0
    END AS GrossMarginPct,

    fs.PromotionKey

FROM dbo.FactInternetSales fs
JOIN dbo.DimDate dd 
    ON fs.OrderDateKey = dd.DateKey
JOIN dbo.DimProduct dp 
    ON fs.ProductKey = dp.ProductKey
JOIN dbo.DimProductSubcategory dps 
    ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
JOIN dbo.DimProductCategory dpc 
    ON dps.ProductCategoryKey = dpc.ProductCategoryKey
JOIN dbo.DimCustomer dc 
    ON fs.CustomerKey = dc.CustomerKey
JOIN dbo.DimGeography dg 
    ON dc.GeographyKey = dg.GeographyKey
JOIN dbo.DimSalesTerritory dst 
    ON fs.SalesTerritoryKey = dst.SalesTerritoryKey;
GO

-- View 2: Reseller Sales with dimensions joined
CREATE OR ALTER VIEW dbo.vw_ResellerSalesFull AS
SELECT
    fr.SalesOrderNumber,
    fr.SalesOrderLineNumber,

    dd.FullDateAlternateKey AS OrderDate,
    dd.CalendarYear AS OrderYear,
    dd.CalendarQuarter AS OrderQuarter,
    dd.MonthNumberOfYear AS OrderMonth,
    dd.EnglishMonthName AS OrderMonthName,

    dp.ProductKey,
    dp.EnglishProductName AS ProductName,
    dps.EnglishProductSubcategoryName AS SubCategory,
    dpc.EnglishProductCategoryName AS Category,

    dst.SalesTerritoryRegion AS TerritoryRegion,
    dst.SalesTerritoryGroup AS TerritoryGroup,
    dst.SalesTerritoryCountry AS Country,

    fr.OrderQuantity,
    fr.UnitPrice,
    fr.SalesAmount,
    fr.TotalProductCost,
    fr.SalesAmount - fr.TotalProductCost AS GrossProfit,

    CASE
        WHEN fr.SalesAmount > 0
        THEN ROUND((fr.SalesAmount - fr.TotalProductCost) / fr.SalesAmount * 100, 2)
        ELSE 0
    END AS GrossMarginPct

FROM dbo.FactResellerSales fr
JOIN dbo.DimDate dd 
    ON fr.OrderDateKey = dd.DateKey
JOIN dbo.DimProduct dp 
    ON fr.ProductKey = dp.ProductKey
JOIN dbo.DimProductSubcategory dps 
    ON dp.ProductSubcategoryKey = dps.ProductSubcategoryKey
JOIN dbo.DimProductCategory dpc 
    ON dps.ProductCategoryKey = dpc.ProductCategoryKey
JOIN dbo.DimSalesTerritory dst 
    ON fr.SalesTerritoryKey = dst.SalesTerritoryKey;
GO

PRINT 'Views created successfully.';
GO