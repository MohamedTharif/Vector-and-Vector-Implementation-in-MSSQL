
--Enable AI runtimes
EXECUTE sp_configure 'external AI runtimes enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

use dbadb

--External Embeeding Model
       CREATE EXTERNAL MODEL AllMiniLM
AUTHORIZATION dbo
WITH 
(
      LOCATION = 'https://ollama.local:8443/api/embed',
      API_FORMAT = 'Ollama',
      MODEL_TYPE = EMBEDDINGS,
      MODEL = 'all-minilm'
);

--External LLM 
CREATE EXTERNAL MODEL OllamaLLM
AUTHORIZATION dbo
WITH
(
    LOCATION = 'https://ollama.local:8443/api/chat',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = CHAT,
    MODEL = 'llama3.2'
);


--Chunking
AI_GENERATE_CHUNKS


--Embedding
SELECT AI_GENERATE_EMBEDDINGS(N'SQL Server meets AI' 
       USE MODEL AllMiniLM)
