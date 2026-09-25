DECLARE @Question NVARCHAR(MAX) =
    N'Can employees work from home?';

DECLARE @Context NVARCHAR(MAX);

------------------------------------------------------------
-- 1. Generate embedding for the question
------------------------------------------------------------
DECLARE @QuestionEmbedding VECTOR(384);

SET @QuestionEmbedding =
    AI_GENERATE_EMBEDDINGS(
        @Question USE MODEL AllMiniLM
    );


------------------------------------------------------------
-- 2. Retrieve the most relevant document chunks
------------------------------------------------------------
SELECT @Context =
    STRING_AGG(
        CAST(
            N'Document: ' + d.Title +
            NCHAR(13) + N'Content: ' + dc.ChunkText
            AS NVARCHAR(MAX)
        ),
        NCHAR(13) + NCHAR(13) +
        N'------------------------------' +
        NCHAR(13) + NCHAR(13)
    )
FROM
(
    SELECT TOP (5)
        dc.ChunkId,
        dc.DocumentId,
        dc.ChunkText,
        VECTOR_DISTANCE(
            'cosine',
            dc.Embedding,
            @QuestionEmbedding
        ) AS Distance
    FROM dbo.DocumentChunks AS dc
    WHERE dc.Embedding IS NOT NULL
    ORDER BY
        VECTOR_DISTANCE(
            'cosine',
            dc.Embedding,
            @QuestionEmbedding
        )
) AS dc
INNER JOIN dbo.Documents AS d
    ON d.DocumentId = dc.DocumentId;


------------------------------------------------------------
-- 3. Build user message
------------------------------------------------------------
DECLARE @UserContent NVARCHAR(MAX);

SET @UserContent =
    N'Context:' + NCHAR(13) + NCHAR(10) +
    ISNULL(@Context, N'No relevant documents found.') +
    NCHAR(13) + NCHAR(10) + NCHAR(13) + NCHAR(10) +
    N'Question: ' + @Question;


------------------------------------------------------------
-- 4. Build Ollama JSON payload
------------------------------------------------------------
DECLARE @Payload NVARCHAR(MAX);

SET @Payload =
(
    SELECT
        N'llama3.2' AS [model],

        JSON_QUERY
        (
            (
                SELECT
                    [role],
                    [content]
                FROM
                (
                    SELECT
                        1 AS SortOrder,
                        N'system' AS [role],
                        N'Answer the question using only the supplied document context. If the answer is not present in the context, say that the information is not available in the provided documents.' AS [content]

                    UNION ALL

                    SELECT
                        2 AS SortOrder,
                        N'user' AS [role],
                        @UserContent AS [content]
                ) AS Messages
                ORDER BY SortOrder
                FOR JSON PATH
            )
        ) AS [messages],

        CAST(0 AS BIT) AS [stream]

    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
);


------------------------------------------------------------
-- 5. Execute Ollama
------------------------------------------------------------
DECLARE @ReturnCode INT;
DECLARE @Response NVARCHAR(MAX);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'POST',
    @url = 'https://ollama.local:8443/api/chat',
    @headers = '{"Content-Type":"application/json"}',
    @payload = @Payload,
    @response = @Response OUTPUT;


------------------------------------------------------------
-- 6. Return answer
------------------------------------------------------------
SELECT
    ReturnCode = @ReturnCode,

    Answer = JSON_VALUE(
        @Response,
        '$.result.message.content'
    ),

    ContextUsed = @Context,

    FullResponse = @Response;