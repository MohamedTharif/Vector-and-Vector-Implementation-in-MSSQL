

CREATE TABLE dbo.Documents
(
    DocumentId BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Documents PRIMARY KEY,

    Title NVARCHAR(300) NOT NULL,

    Content NVARCHAR(MAX) NOT NULL
);
GO


INSERT INTO dbo.Documents
(
    Title,
    Content
)
VALUES
(
    N'Work From Home Policy',

    N'
    Work From Home Policy

    Employees may work from home subject to manager approval.
    Employees must submit a work from home request through the approved
    company process.

    Employees working remotely must maintain a stable internet connection
    and remain available during their scheduled working hours.

    Company laptops must be used for accessing company systems.
    Employees must not share company credentials with other individuals.

    Sensitive company information must not be stored on personal devices.
    Employees must connect to approved VPN services when accessing internal
    applications from outside the corporate network.

    Remote employees are expected to attend scheduled meetings and maintain
    normal communication with their teams.

    Any security incident, lost company device, or suspected credential
    compromise must immediately be reported to the IT security team.

    Managers are responsible for approving remote work requests and ensuring
    that business operations are not affected by remote working arrangements.

    Employees working remotely must follow all company security policies,
    data protection requirements, and acceptable-use policies.

    Working from home does not change the employee''s normal working hours
    unless an alternative schedule has been approved by the manager.
    '
);
GO


--Vector Table
CREATE TABLE dbo.DocumentChunks
(
    ChunkId BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_DocumentChunks PRIMARY KEY,

    DocumentId BIGINT NOT NULL,

    ChunkText NVARCHAR(MAX) NOT NULL,

    Embedding VECTOR(384) NULL
);
GO


--convert documents into vector
INSERT INTO dbo.DocumentChunks
(
    DocumentId,
    ChunkText,
    Embedding
)
SELECT
    d.DocumentId,

    c.chunk,

    AI_GENERATE_EMBEDDINGS
    (
        c.chunk
          USE MODEL AllMiniLM
    )

FROM dbo.Documents AS d

CROSS APPLY AI_GENERATE_CHUNKS
(
    SOURCE = d.Content,

    CHUNK_TYPE = FIXED,

    CHUNK_SIZE = 500
) AS c;
GO

--verification
SELECT
    ChunkId,
    DocumentId,
    ChunkText,
    Embedding
FROM dbo.DocumentChunks
ORDER BY ChunkId;
GO

SELECT
    ChunkId,
     VECTORPROPERTY(Embedding, 'BaseType') as DataType,
       VECTORPROPERTY(Embedding, 'Dimensions') as numberofDimensions
FROM dbo.DocumentChunks
ORDER BY ChunkId;
GO

--Question

DECLARE @QuestionEmbedding VECTOR(384);

SET @QuestionEmbedding =
    AI_GENERATE_EMBEDDINGS
    (
        N'Can employees work from home?'
        USE MODEL AllMiniLM

    );
--Sematic search

SELECT TOP (5)

    ChunkId,

    DocumentId,

    ChunkText,

    VECTOR_DISTANCE
    (
        'cosine',
        Embedding,
        @QuestionEmbedding
    ) AS Distance

FROM dbo.DocumentChunks

ORDER BY Distance;