ALTER DATABASE SCOPED CONFIGURATION
SET PREVIEW_FEATURES = ON;
GO

--all-minilm
--output -384 dimensional embeddings
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'POST',
    @url = 'https://ollama.local:8443/api/embed',
    @headers = '{"Content-Type":"application/json"}',
    @payload = N'{
        "model": "all-minilm:latest",
        "input": "SQL Server is a relational database system."
    }',
    @response = @Response OUTPUT;

SELECT
    HttpStatus = JSON_VALUE(@Response, '$.response.status.http.code'),
    Errors = JSON_VALUE(@Response, '$.result.message'),
    GeneratedEmbeddings = JSON_QUERY(@Response, '$.result.embeddings[0]'),
    FullResult = @Response;

-----nomic-embed-text
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);
DECLARE @Embedding nvarchar(max);

DECLARE @Payload nvarchar(max) =
N'{
    "model": "nomic-embed-text",
    "input": "How many products are in stock?"
}';

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method  = 'POST',
    @url     = 'https://ollama.local:8443/api/embed',
    @payload = @Payload,
    @headers = '{"Content-Type":"application/json"}',
    @response = @Response OUTPUT;

SET @Embedding =
    JSON_QUERY(@Response, '$.result.embeddings[0]');

SELECT
    ReturnCode = @ReturnCode,
    HttpStatus = JSON_VALUE(@Response, '$.response.status.http.code'),
    Embedding = @Embedding;



