CREATE DATABASE VectorDemo;
Go

USE VectorDemo;
Go

--Enable Preview Features
ALTER DATABASE SCOPED CONFIGURATION
SET PREVIEW_FEATURES = ON;
GO



CREATE TABLE dbo.Documents
(
    DocumentId   INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Documents PRIMARY KEY CLUSTERED,

    Title        NVARCHAR(300) NOT NULL,

    Content      NVARCHAR(MAX) NOT NULL,

    Category     NVARCHAR(100) NULL,

    CreatedDate  DATETIME2(3) NOT NULL
        CONSTRAINT DF_Documents_CreatedDate
        DEFAULT SYSUTCDATETIME(),

    Embedding    VECTOR(5) NULL
);
GO

INSERT INTO dbo.Documents
(
    Title,
    Content,
    Category,
    Embedding
)
VALUES
(
    N'Password Recovery',
    N'Users can recover a forgotten password through the self-service recovery process.',
    N'Identity',
    CAST('[0.10, 0.20, 0.30, 0.40, 0.40]' AS VECTOR(5))
),
(
    N'Password Reset',
    N'Employees can reset their password using the corporate identity portal.',
    N'Identity',
    CAST('[0.11, 0.21, 0.29, 0.41, 0.39]' AS VECTOR(5))
),
(
    N'VPN Access',
    N'Users must connect to the corporate VPN before accessing internal applications.',
    N'Network',
    CAST('[0.80, 0.10, 0.20, 0.10, 0.30]' AS VECTOR(5))
),
(
    N'HR Leave Policy',
    N'Employees can request annual leave through the HR self-service portal.',
    N'HR',
    CAST('[0.20, 0.80, 0.10, 0.20, 0.10]' AS VECTOR(5))
),
(
    N'Laptop Security',
    N'Corporate laptops must use encryption and endpoint security controls.',
    N'Security',
    CAST('[0.70, 0.20, 0.60, 0.10, 0.20]' AS VECTOR(5))
);
GO


DECLARE @q VECTOR(5) =
    '[0.11, 0.19, 0.31, 0.39, 0.40]';

SELECT TOP (5)
       DocumentId,
       Title,
       Category,
       VECTOR_DISTANCE(
           'cosine',
           Embedding,
           @q
       ) AS Distance
FROM dbo.Documents
WHERE Embedding IS NOT NULL
ORDER BY Distance ASC;


CREATE VECTOR INDEX IX_Documents_Embedding
ON dbo.Documents(Embedding)
WITH
(
    METRIC = 'cosine',
    TYPE = 'diskann'
);
GO

--vector indexing
SELECT
    i.name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('dbo.Documents');


DECLARE @q VECTOR(5) =
    '[0.11, 0.19, 0.31, 0.39, 0.40]';

SELECT TOP (5)
       t.DocumentId,
       t.Title,
       t.Category,
       r.distance
FROM VECTOR_SEARCH(
        TABLE = dbo.Documents AS t,
        COLUMN = Embedding,
        SIMILAR_TO = @q,
        METRIC = 'cosine',
        TOP_N=5
     ) AS r
ORDER BY r.distance;


