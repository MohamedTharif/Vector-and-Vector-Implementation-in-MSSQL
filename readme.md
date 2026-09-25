# SQL Server 2025 + AI + Full-Text Search + Ollama + Caddy HTTPS Setup

This guide prepares a Windows lab environment for **SQL Server 2025 AI/vector features**, **Full-Text Search**, **Ollama embeddings**, and **Caddy HTTPS**.
The setup is divided into two parts:

1. **SQL Server 2025 installation and database preparation**
2. **Ollama + Caddy HTTPS configuration and SQL Server integration**

> **Important:** SQL Server Setup does **not** have a separate checkbox called "AI Features". The SQL Server 2025 AI/vector capabilities are part of the Database Engine. During Feature Selection, select **Database Engine Services** and **Full-Text and Semantic Extractions for Search** for this lab. Microsoft documents Full-Text/Semantic Search as a selectable setup feature, while SQL Server 2025 provides vector and AI functionality through the Database Engine.

---

# 1. Install SQL Server 2025

## 1.1 Download SQL Server 2025

Download the SQL Server 2025 Evaluation media from Microsoft:
[https://www.microsoft.com/en-in/evalcenter/evaluate-sql-server-2025](https://www.microsoft.com/en-in/evalcenter/evaluate-sql-server-2025)
For a lab or proof-of-concept environment, the Evaluation edition can be used according to Microsoft's evaluation terms.

---

## 1.2 Start SQL Server Setup

1. Mount the SQL Server 2025 ISO or extract the installation media.
2. Open the installation folder.
3. Right-click `setup.exe`.
4. Select **Run as administrator**.
5. In SQL Server Installation Center, select:

```
Installation
    → New SQL Server stand-alone installation or add features to an existing installation
```

6. Continue through the setup rules and prerequisite checks.

Microsoft's installation wizard uses the **Feature Selection** page to choose the SQL Server components to install.

---

## 1.3 Select SQL Server 2025 Edition

On the Edition page, select the edition required for your environment.
For this lab:

```
Evaluation
```

Continue to the Feature Selection page.

---

# 2. SQL Server 2025 Feature Selection

This is the important setup step for the AI/vector and Full-Text Search lab.
On **Feature Selection**, select:

```
[x] Database Engine Services
[x] Full-Text and Semantic Extractions for Search
```

### Database Engine Services

Select:

```
Database Engine Services
```

This is the core SQL Server Database Engine and is required for the SQL Server 2025 vector and AI T-SQL functionality used later in this guide.

### Full-Text and Semantic Extractions for Search

Select:

```
Full-Text and Semantic Extractions for Search
```

This installs the Full-Text Search and Semantic Search components. Microsoft specifically documents this option on the SQL Server Setup Feature Selection page.

### What about an "AI" feature?

There is **no separate SQL Server Setup feature named "AI" that must be selected** for:

- `VECTOR`
- `VECTOR_SEARCH`
- `VECTOR_DISTANCE`
- `AI_GENERATE_CHUNKS`
- `AI_GENERATE_EMBEDDINGS`
- `CREATE EXTERNAL MODEL`

These are SQL Server 2025 Database Engine capabilities. The external model configuration is performed after SQL Server installation.

### Recommended Feature Selection

For this lab, the Feature Selection page should look conceptually like:

```
Database Engine Services
    [x] Database Engine Services

Full-Text and Semantic Extractions for Search
    [x] Full-Text and Semantic Extractions for Search
```

Do not select unrelated SQL Server features unless they are required for your environment.

---

# 3. Instance Configuration

For a simple single-server lab, select:

```
Default instance
```

The default instance name is:

```
MSSQLSERVER
```

You can later connect from SSMS using:

```
localhost
```

or:

```
localhost,1433
```

if TCP/IP is configured to use port 1433.

---

# 4. Database Engine Configuration

## 4.1 Server Configuration

Leave the SQL Server service configuration at the recommended defaults unless your environment requires different service accounts.
For a lab environment, the default SQL Server service account configuration is normally sufficient.

---

## 4.2 Database Engine Configuration

Choose the authentication mode required by your environment.
For this lab, **Mixed Mode** can be used if both Windows Authentication and SQL Server Authentication are required.
If Mixed Mode is selected:

1. Set a strong password for the `sa` account.
2. Add the required Windows account(s) as SQL Server administrators.
3. Continue with the installation.

---

# 5. Complete SQL Server 2025 Installation

Continue through the remaining setup pages and select:

```
Install
```

Wait for SQL Server Setup to complete.
After installation, restart the server if Setup requests it.

---

# 6. Install SQL Server Management Studio

SQL Server Management Studio (SSMS) is installed separately from the SQL Server Database Engine.
Install a current version of SSMS from Microsoft:
[https://learn.microsoft.com/en-us/ssms/install/install](https://learn.microsoft.com/en-us/ssms/install/install)
Open SSMS and connect to the SQL Server 2025 instance.

---

# 7. Verify SQL Server 2025 and Full-Text Search

Run:

```
SELECT
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductMajorVersion') AS ProductMajorVersion,
    SERVERPROPERTY('Edition') AS Edition,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;
GO
```

For SQL Server 2025, the major version should be:

```
17
```

For Full-Text Search/Semantic Search, the expected value is:

```
IsFullTextInstalled = 1
```

Microsoft documents that `SERVERPROPERTY('IsFullTextInstalled')` returns `1` when Full-Text Search and Semantic Search are installed.

---

# 8. Restore AdventureWorks2025

Download the AdventureWorks sample database from Microsoft:
[https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver17&tabs=ssms)
Download the SQL Server 2025 backup:

```
AdventureWorks2025.bak
```

Place the `.bak` file in a folder accessible to the SQL Server service.
For example:

```
C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\
```

## 8.1 Check the Backup

Before restoring, you can inspect the backup:

```
RESTORE FILELISTONLY
FROM DISK =
N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorks2025.bak';
GO
```

## 8.2 Restore AdventureWorks2025

Use:

```
USE [master];
GO

RESTORE DATABASE [AdventureWorks2025]
FROM DISK =
N'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\AdventureWorks2025.bak'
WITH
    FILE = 1,
    NOUNLOAD,
    STATS = 5;
GO
```

This follows Microsoft's documented `AdventureWorks2025` Windows restore example. Adjust the backup path for your environment.
Verify:

```
SELECT
    name,
    state_desc,
    compatibility_level
FROM sys.databases
WHERE name = N'AdventureWorks2025';
GO
```

---

# 9. Set AdventureWorks2025 Compatibility Level to 170

SQL Server 2025 AI functions such as `AI_GENERATE_CHUNKS` require database compatibility level **170 or higher**.
Set the compatibility level:

```
ALTER DATABASE [AdventureWorks2025]
SET COMPATIBILITY_LEVEL = 170;
GO
```

Verify:

```
SELECT
    name,
    compatibility_level
FROM sys.databases
WHERE name = N'AdventureWorks2025';
GO
```

Expected:

```
AdventureWorks2025    170
```

---

# 10. Verify SQL Server 2025 VECTOR Support

Connect to `AdventureWorks2025` and run:

```
USE AdventureWorks2025;
GO

CREATE TABLE dbo.VectorTest
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Content NVARCHAR(1000),
    Embedding VECTOR(3)
);
GO
```

Insert a test vector:

```
INSERT INTO dbo.VectorTest
(
    Content,
    Embedding
)
VALUES
(
    N'SQL Server 2025 vector test',
    '[0.1, 0.2, 0.3]'
);
GO
```

Verify:

```
SELECT *
FROM dbo.VectorTest;
GO
```

Clean up:

```
DROP TABLE dbo.VectorTest;
GO
```

SQL Server 2025 provides the `VECTOR` data type for storing vector data used by similarity search and machine-learning applications. The documented maximum is 1998 dimensions.

---

# 11. Verify Full-Text Search

Run:

```
SELECT SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;
GO
```

Expected:

```
1
```

You can also check the database's Full-Text catalogs:

```
USE AdventureWorks2025;
GO

SELECT *
FROM sys.fulltext_catalogs;
GO
```

At this point, the SQL Server installation portion of the lab is complete.

---

# 12. Test AI_GENERATE_CHUNKS

`AI_GENERATE_CHUNKS` creates chunks of text and requires compatibility level 170 or higher.
Run:

```
USE AdventureWorks2025;
GO

SELECT *
FROM AI_GENERATE_CHUNKS
(
    SOURCE = N'SQL Server 2025 provides native vector capabilities and AI functions for intelligent applications.',
    CHUNK_TYPE = FIXED,
    CHUNK_SIZE = 50,
    OVERLAP = 10
);
GO
```

The documented syntax is:

```
AI_GENERATE_CHUNKS
(
    SOURCE = text_expression,
    CHUNK_TYPE = FIXED,
    CHUNK_SIZE = numeric_expression,
    OVERLAP = numeric_expression
)
```

`OVERLAP` is a percentage from `0` through `50`.

---

# 13. Configure SQL Server for an External Embedding Model

After the Ollama + Caddy configuration later in this README is working, SQL Server 2025 can register the Ollama embedding endpoint with `CREATE EXTERNAL MODEL`.
Microsoft documents `Ollama` as a supported `API_FORMAT` and uses an `/api/embed` endpoint for Ollama embeddings.
Example:

```
USE AdventureWorks2025;
GO

CREATE EXTERNAL MODEL MyOllamaModel
WITH
(
    LOCATION = 'https://ollama.local:8443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'all-minilm'
);
GO
```

Verify:

```
SELECT
    name,
    location,
    api_format,
    model_type,
    model
FROM sys.external_models;
GO
```

The database principal creating the external model requires `CREATE EXTERNAL MODEL` or `ALTER ANY EXTERNAL MODEL` permission.
If necessary:

```
GRANT CREATE EXTERNAL MODEL TO [YourUser];
GO
```

To allow a user to execute the external model:

```
GRANT EXECUTE
ON EXTERNAL MODEL::MyOllamaModel
TO [YourUser];
GO
```

---

# 14. Test AI_GENERATE_EMBEDDINGS

Once `MyOllamaModel` is successfully created:

```
USE AdventureWorks2025;
GO

SELECT
    AI_GENERATE_EMBEDDINGS
    (
        N'SQL Server is a relational database system.'
        USE MODEL MyOllamaModel
    ) AS Embedding;
GO
```

The documented syntax is:

```
AI_GENERATE_EMBEDDINGS
(
    source
    USE MODEL model_identifier
)
```

The function generates an embedding using the external model definition stored in the database.

> **Important:** Do not assume the vector dimension. The dimension of the `VECTOR(n)` column must match the dimension produced by the selected embedding model.

---

# 15. Store Embeddings in a VECTOR Column

After confirming the actual embedding dimension produced by the selected model, create a table using that dimension.
Example:

```
CREATE TABLE dbo.DocumentEmbeddings
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    DocumentText NVARCHAR(MAX),
    Embedding VECTOR(384)
);
GO
```

`384` is only an example. Replace it with the actual dimension produced by your embedding model.
For example:

```
INSERT INTO dbo.DocumentEmbeddings
(
    DocumentText,
    Embedding
)
SELECT
    N'SQL Server 2025 supports vector search.',
    AI_GENERATE_EMBEDDINGS
    (
        N'SQL Server 2025 supports vector search.'
        USE MODEL MyOllamaModel
    );
GO
```

---

# 16. SQL Server 2025 AI Lab Flow

At this point the complete lab flow is:

```
SQL Server 2025 Installation
        │
        ├── Database Engine Services
        │
        └── Full-Text and Semantic Extractions
        │
        ▼
AdventureWorks2025
        │
        ├── Compatibility Level 170
        │
        ├── Full-Text Search
        │
        ├── VECTOR
        │
        ├── AI_GENERATE_CHUNKS
        │
        └── AI_GENERATE_EMBEDDINGS
        │
        ▼
CREATE EXTERNAL MODEL
        │
        ▼
Ollama
        │
        ▼
Caddy HTTPS
        │
        ▼
Ollama Embedding Model
```

The remaining sections of this README configure Ollama, Caddy HTTPS, and the SQL Server external REST connectivity.

---

---

# 2. Ollama + Caddy HTTPS Configuration

## Architecture

```text
SQL Server
    │
    │ HTTPS :8443
    ▼
https://ollama.local:8443
    │
    │ Caddy reverse proxy
    ▼
http://127.0.0.1:11434
    │
    ▼
Ollama
```

---

## 2.1 Install Ollama

Download and install Ollama for Windows:

https://ollama.com/download

After installation, verify the installation:

```cmd
ollama --version
```

---

## 2.2 Check Ollama Installation

Check the available Ollama commands:

```cmd
ollama help
```

Check the installed models:

```cmd
ollama list
```

---

## 2.3 Start Ollama

If Ollama is not already running, start the Ollama server:

```cmd
ollama serve
```

By default, Ollama listens on:

```text
http://127.0.0.1:11434
```

Verify the API directly:

```cmd
curl.exe http://127.0.0.1:11434/api/tags
```

---

## 2.4 Install Embedding Models

Pull the embedding models required for the SQL Server vector/RAG lab.

### all-MiniLM

```cmd
ollama pull all-minilm
```

### nomic-embed-text

```cmd
ollama pull nomic-embed-text
```

Verify the models:

```cmd
ollama list
```

Example:

```text
NAME                    ID              SIZE
all-minilm:latest       ...             ...
nomic-embed-text:latest ...             ...
```

---

## 2.5 Download Caddy

Download the Windows AMD64 Caddy binary:

https://caddyserver.com/download

For example:

```text
caddy_windows_amd64.exe
```

Place the executable in a directory such as:

```text
D:\Setups\Caddy
```

Open Command Prompt:

```cmd
cd /d D:\Setups\Caddy
```

Verify Caddy:

```cmd
caddy_windows_amd64.exe version
```

---

## 2.6 Configure `ollama.local`

Open the Windows hosts file as Administrator:

```text
C:\Windows\System32\drivers\etc\hosts
```

Add:

```text
127.0.0.1    ollama.local
```

Save the file.

### Verify hostname resolution

Run:

```cmd
ping ollama.local
```

Expected:

```text
Pinging ollama.local [127.0.0.1]
```

You can also check DNS resolution:

```cmd
nslookup ollama.local
```

> **Note:** `nslookup` queries the configured DNS server and may report that `ollama.local` does not exist even when the Windows `hosts` file contains the entry. For this local configuration, `ping`, Windows name resolution, or an actual HTTPS connection are more useful validation methods.

PowerShell:

```powershell
[System.Net.Dns]::GetHostAddresses("ollama.local") |
    Select-Object -ExpandProperty IPAddressToString
```

Expected:

```text
127.0.0.1
```

---

## 2.7 Create the Caddyfile

Create a file named:

```text
Caddyfile
```

inside:

```text
D:\Setups\Caddy
```

Use the following configuration:

```caddy
{
    auto_https disable_redirects
}

https://ollama.local:8443 {
    tls internal
    respond /test "Caddy HTTPS working" 200
    reverse_proxy 127.0.0.1:11434
}
```

The configuration does the following:

- Enables Caddy's internal CA.
- Provides HTTPS on port `8443`.
- Provides `/test` as a simple health endpoint.
- Proxies requests to Ollama on `127.0.0.1:11434`.

---

## 2.8 Format the Caddyfile

Run:

```cmd
caddy_windows_amd64.exe fmt --overwrite Caddyfile
```

---

## 2.9 Trust the Caddy Root Certificate

Run Command Prompt as Administrator and execute:

```cmd
caddy_windows_amd64.exe trust
```

Caddy uses its local CA to generate certificates for the internal HTTPS endpoint.

> **Important:** SQL Server may run under a Windows service account that does not use the same certificate store as your interactive user. If SQL Server cannot validate the Caddy certificate, install the Caddy root CA into the **Local Computer → Trusted Root Certification Authorities** store and restart the SQL Server service.

---

## 2.10 Start Caddy

Run:

```cmd
caddy_windows_amd64.exe run --config Caddyfile
```

Keep this Command Prompt window running.

---

## 2.11 Test Caddy HTTPS

First test the Caddy health endpoint:

```cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/test
```

Expected response:

```text
Caddy HTTPS working
```

You can also test the Ollama API through Caddy:

```cmd
curl.exe --ssl-no-revoke https://ollama.local:8443/api/tags
```

The response should contain the installed Ollama models.

---

## 2.12 Test Network Connectivity

Check whether port `8443` is reachable:

```powershell
Test-NetConnection ollama.local -Port 8443
```

Expected:

```text
TcpTestSucceeded : True
```

---

## 2.13 Test the Ollama Embedding API Through Caddy

Use the following command from Command Prompt:

```cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/api/embed ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"all-minilm:latest\",\"input\":\"SQL Server is a relational database system.\"}"
```

A successful response should contain an embedding vector.

The vector length depends on the embedding model that is installed. Do not assume that every model produces the same number of dimensions.

---

## 2.14 Enable SQL Server External REST Endpoint

SQL Server 2025 provides:

```sql
sys.sp_invoke_external_rest_endpoint
```

The external REST endpoint feature is disabled by default on SQL Server 2025. Enable it before testing connectivity.

Run as a login with `ALTER SETTINGS` permission:

```sql
EXECUTE sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO
```

You can verify the setting:

```sql
EXECUTE sp_configure 'external rest endpoint enabled';
GO
```

The `run_value` should be:

```text
1
```

The caller also needs the database permission required to execute the external REST endpoint procedure. For a dedicated lab user:

```sql
GRANT EXECUTE ANY EXTERNAL ENDPOINT TO [YourUser];
GO
```

---

## 2.15 Test SQL Server External REST Endpoint

Before connecting SQL Server to Ollama, verify that SQL Server can access an external HTTPS endpoint.

Run:

```sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = N'https://www.microsoft.com',
    @headers = N'{"Accept":"text/html"}',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
GO
```

A return code of `0` indicates a successful HTTPS request with a 2xx response.

---

## 2.16 Test SQL Server → Caddy → Ollama

Once the external REST endpoint test works, test the Ollama endpoint through Caddy.

```sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = N'https://ollama.local:8443/api/tags',
    @headers = N'{"Accept":"application/json"}',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
GO
```

The response should contain the Ollama model list.

If SQL Server returns error `31608` and Caddy does not show an incoming request, check TLS, certificate trust, hostname resolution, and Windows firewall configuration.

---

## 2.17 Test Ollama Embeddings from SQL Server

After `/api/tags` works, test the embedding API:

```sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'POST',
    @url = N'https://ollama.local:8443/api/embed',
    @headers = N'{"Content-Type":"application/json"}',
    @payload = N'{
        "model": "all-minilm:latest",
        "input": "SQL Server is a relational database system."
    }',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
GO
```

If successful, the response contains the generated embedding vector.

---

## 2.18 Configure SQL Server for an External Embedding Model

After the Ollama + Caddy configuration is working, SQL Server 2025 can register the Ollama embedding endpoint with `CREATE EXTERNAL MODEL`.

Use:

```sql
USE AdventureWorks2025;
GO

CREATE EXTERNAL MODEL MyOllamaModel
WITH
(
    LOCATION = 'https://ollama.local:8443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'all-minilm'
);
GO
```

Verify:

```sql
SELECT
    name,
    location,
    api_format,
    model_type,
    model
FROM sys.external_models;
GO
```

The database principal creating the external model requires `CREATE EXTERNAL MODEL` or `ALTER ANY EXTERNAL MODEL` permission.

For example:

```sql
GRANT CREATE EXTERNAL MODEL TO [YourUser];
GO
```

To allow a user to execute the external model:

```sql
GRANT EXECUTE
ON EXTERNAL MODEL::MyOllamaModel
TO [YourUser];
GO
```

---

## 2.19 Test `AI_GENERATE_EMBEDDINGS`

Once `MyOllamaModel` is successfully created:

```sql
USE AdventureWorks2025;
GO

SELECT AI_GENERATE_EMBEDDINGS
(
    N'SQL Server is a relational database system.'
    USE MODEL MyOllamaModel
) AS Embedding;
GO
```

The syntax requires a space between the source expression and `USE MODEL`.

The function generates an embedding using the external model definition stored in the database.

> **Important:** Do not assume the vector dimension. The dimension of the `VECTOR(n)` column must match the dimension produced by the selected embedding model.

---

## 2.20 Store Embeddings in a VECTOR Column

After confirming the actual embedding dimension produced by the selected model, create a table using that dimension.

Example:

```sql
USE AdventureWorks2025;
GO

CREATE TABLE dbo.DocumentEmbeddings
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    DocumentText NVARCHAR(MAX),
    Embedding VECTOR(384)
);
GO
```

`384` is only an example. Replace it with the actual dimension produced by your embedding model.

For example:

```sql
INSERT INTO dbo.DocumentEmbeddings
(
    DocumentText,
    Embedding
)
SELECT
    N'SQL Server 2025 supports vector search.',
    AI_GENERATE_EMBEDDINGS
    (
        N'SQL Server 2025 supports vector search.'
        USE MODEL MyOllamaModel
    );
GO
```

---

## 2.21 Troubleshooting SQL Server Error 31608

If SQL Server returns:

```text
Msg 31608
An error occurred, failed to communicate with the external rest endpoint.
HRESULT: 0x80070008
```

and Caddy does not show an incoming request, investigate the TLS/certificate path first.

### Check Caddy environment

```cmd
caddy_windows_amd64.exe environ
```

### Search for the Caddy root certificate

```powershell
Get-ChildItem C:\Users -Recurse -Filter root.crt -ErrorAction SilentlyContinue
```

You can also check service profiles:

```powershell
Get-ChildItem C:\Windows\ServiceProfiles -Recurse -Filter root.crt -ErrorAction SilentlyContinue
```

For a typical Administrator installation, check:

```powershell
Get-ChildItem "C:\Users\Administrator\AppData\Roaming\Caddy" -Recurse -Filter root.crt
```

A typical path is:

```text
C:\Users\Administrator\AppData\Roaming\Caddy\pki\authorities\local\root.crt
```

### Install the Caddy Root CA into Windows Trusted Root

If the certificate is located at:

```text
C:\Users\Administrator\AppData\Roaming\Caddy\pki\authorities\local\root.crt
```

run Command Prompt or PowerShell as Administrator:

```cmd
certutil -addstore -f Root "C:\Users\Administrator\AppData\Roaming\Caddy\pki\authorities\local\root.crt"
```

Restart the SQL Server service after installing the certificate.

### Test Caddy certificate validation

First test with the revocation check bypass:

```cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/test
```

Then test normal validation:

```cmd
curl.exe -v https://ollama.local:8443/test
```

If the normal request fails but `--ssl-no-revoke` succeeds, investigate certificate revocation validation.

---

## 2.22 Troubleshooting Checklist

Use the following order when troubleshooting.

### Check Ollama

```cmd
ollama --version
ollama list
```

### Check Ollama directly

```cmd
curl.exe http://127.0.0.1:11434/api/tags
```

### Check hostname

```cmd
ping ollama.local
```

### Check port

```powershell
Test-NetConnection ollama.local -Port 8443
```

### Check Caddy

```cmd
caddy_windows_amd64.exe run --config Caddyfile
```

### Check Caddy HTTPS

```cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/test
```

### Check Ollama through Caddy

```cmd
curl.exe --ssl-no-revoke https://ollama.local:8443/api/tags
```

### Check embedding API

```cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/api/embed ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"all-minilm:latest\",\"input\":\"SQL Server is a relational database system.\"}"
```

### Check SQL Server external REST configuration

```sql
EXECUTE sp_configure 'external rest endpoint enabled';
GO
```

### Check SQL Server external REST

```sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = N'https://www.microsoft.com',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
GO
```

### Check SQL Server → Caddy

```sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = N'https://ollama.local:8443/api/tags',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
GO
```

### Check SQL Server → Ollama embedding

```sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'POST',
    @url = N'https://ollama.local:8443/api/embed',
    @headers = N'{"Content-Type":"application/json"}',
    @payload = N'{
        "model": "all-minilm:latest",
        "input": "SQL Server is a relational database system."
    }',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
GO
```

---

## 2.23 Final Architecture

After successful configuration, the communication path is:

```text
┌──────────────────────────────┐
│          SQL Server          │
│                              │
│ sp_invoke_external_rest_     │
│ endpoint / AI functions      │
└──────────────┬───────────────┘
               │
               │ HTTPS :8443
               ▼
┌──────────────────────────────┐
│      ollama.local:8443       │
│            Caddy             │
│                              │
│       TLS termination        │
│       Reverse proxy          │
└──────────────┬───────────────┘
               │
               │ HTTP :11434
               ▼
┌──────────────────────────────┐
│           Ollama             │
│                              │
│       all-minilm             │
│       nomic-embed-text       │
└──────────────────────────────┘
```

This setup allows SQL Server 2025 to call Ollama's REST API through an HTTPS endpoint and provides the foundation for generating embeddings and storing them in SQL Server `VECTOR` columns for vector search and RAG experiments.
