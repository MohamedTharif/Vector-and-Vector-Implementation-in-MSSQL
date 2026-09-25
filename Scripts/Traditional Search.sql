--Condition based search
SELECT
    ProductReviewID,
    ProductID,
    ReviewerName,
    Comments
FROM Production.ProductReview
WHERE Comments like '%bike%';



--FUll text search
SELECT 
    FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;


    USE AdventureWorks2025;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT
    ProductReviewID,
    ProductID,
    ReviewerName,
    Comments
FROM Production.ProductReview
WHERE CONTAINS(Comments, '"bike"');

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

