# SQL Server 2025 + Ollama + Caddy HTTPS Setup

This guide configures **Ollama** on Windows and exposes the Ollama API
through **Caddy HTTPS** so that SQL Server 2025 can access the Ollama
REST API using `sys.sp_invoke_external_rest_endpoint`.

## Architecture

``` text
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

------------------------------------------------------------------------

# 1. Install Ollama

Download and install Ollama for Windows:

https://ollama.com/download

After installation, verify the installation:

``` cmd
ollama --version
```

------------------------------------------------------------------------

# 2. Check Ollama Installation

Check the available Ollama commands:

``` cmd
ollama help
```

Check the installed models:

``` cmd
ollama list
```

------------------------------------------------------------------------

# 3. Start Ollama

If Ollama is not already running, start the Ollama server:

``` cmd
ollama serve
```

By default, Ollama listens on:

``` text
http://127.0.0.1:11434
```

You can verify the API directly:

``` cmd
curl http://127.0.0.1:11434/api/tags
```

------------------------------------------------------------------------

# 4. Install Embedding Models

Pull the embedding models required for the SQL Server vector/RAG lab.

### all-MiniLM

``` cmd
ollama pull all-minilm
```

### nomic-embed-text

``` cmd
ollama pull nomic-embed-text
```

Verify the models:

``` cmd
ollama list
```

Example:

``` text
NAME                    ID              SIZE
all-minilm:latest       ...             ...
nomic-embed-text:latest ...             ...
```

------------------------------------------------------------------------

# 5. Download Caddy

Download the Windows AMD64 Caddy binary:

https://caddyserver.com/download

For example:

``` text
caddy_windows_amd64.exe
```

Place the executable in a directory such as:

``` text
D:\Setups\Caddy
```

Open Command Prompt:

``` cmd
cd /d D:\Setups\Caddy
```

Verify Caddy:

``` cmd
caddy_windows_amd64.exe version
```

------------------------------------------------------------------------

# 6. Configure `ollama.local`

Open the Windows hosts file as Administrator:

``` text
C:\Windows\System32\drivers\etc\hosts
```

Add:

``` text
127.0.0.1    ollama.local
```

Save the file.

## Verify hostname resolution

``` cmd
ping ollama.local
```

Expected:

``` text
Pinging ollama.local [127.0.0.1]
```

You can also check DNS resolution:

``` cmd
nslookup ollama.local
```

> **Note:** `nslookup` queries the configured DNS server and may report
> that `ollama.local` does not exist even when the Windows `hosts` file
> contains the entry. For this local configuration, `ping`, PowerShell
> DNS resolution, or an actual HTTPS connection are more useful
> validation methods.

PowerShell:

``` powershell
[System.Net.Dns]::GetHostAddresses("ollama.local")
```

Expected:

``` text
127.0.0.1
```

------------------------------------------------------------------------

# 7. Create the Caddyfile

Create a file named:

``` text
Caddyfile
```

inside:

``` text
D:\Setups\Caddy
```

Use the following configuration:

``` caddy
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

-   Enables an internal Caddy CA.
-   Provides HTTPS on port `8443`.
-   Provides `/test` as a simple Caddy health endpoint.
-   Proxies requests to Ollama on `127.0.0.1:11434`.

------------------------------------------------------------------------

# 8. Format the Caddyfile

Run:

``` cmd
caddy_windows_amd64.exe fmt --overwrite Caddyfile
```

------------------------------------------------------------------------

# 9. Trust the Caddy Root Certificate

Run:

``` cmd
caddy_windows_amd64.exe trust
```

Caddy uses its local CA to generate certificates for the internal HTTPS
endpoint.

------------------------------------------------------------------------

# 10. Start Caddy

Run:

``` cmd
caddy_windows_amd64.exe run --config Caddyfile
```

Keep this Command Prompt window running.

------------------------------------------------------------------------

# 11. Test Caddy HTTPS

First test the Caddy health endpoint:

``` cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/test
```

Expected response:

``` text
Caddy HTTPS working
```

You can also test the Ollama API through Caddy:

``` cmd
curl.exe --ssl-no-revoke https://ollama.local:8443/api/tags
```

The response should contain the installed Ollama models.

------------------------------------------------------------------------

# 12. Test Network Connectivity

Check whether port `8443` is reachable:

``` powershell
Test-NetConnection ollama.local -Port 8443
```

Expected:

``` text
TcpTestSucceeded : True
```

------------------------------------------------------------------------

# 13. Test the Ollama Embedding API Through Caddy

Use the following command:

``` cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/api/embed ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"all-minilm:latest\",\"input\":\"SQL Server is a relational database system.\"}"
```

A successful response should contain an embedding vector.

For `all-minilm`, the embedding length is expected to match the model's
embedding dimension.

------------------------------------------------------------------------

# 14. Test SQL Server External REST Endpoint

SQL Server 2025 provides:

``` sql
sys.sp_invoke_external_rest_endpoint
```

Before connecting SQL Server to Ollama, verify that SQL Server can
access an external HTTPS endpoint.

Run:

``` sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = 'https://www.microsoft.com',
    @headers = N'{"Accept":"text/html"}',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
```

A successful HTTPS request confirms that the SQL Server external REST
endpoint functionality is working.

------------------------------------------------------------------------

# 15. Test SQL Server → Caddy → Ollama

Once the external REST endpoint test works, test the Ollama endpoint
through Caddy.

``` sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = 'https://ollama.local:8443/api/tags',
    @headers = N'{"Accept":"application/json"}',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
```

The response should contain the Ollama model list.

------------------------------------------------------------------------

# 16. Test Ollama Embeddings from SQL Server

After `/api/tags` works, test the embedding API:

``` sql
DECLARE @ReturnCode int;
DECLARE @Response nvarchar(max);

EXEC @ReturnCode = sys.sp_invoke_external_rest_endpoint
    @method = 'POST',
    @url = 'https://ollama.local:8443/api/embed',
    @headers = N'{"Content-Type":"application/json"}',
    @payload = N'{
        "model": "all-minilm:latest",
        "input": "SQL Server is a relational database system."
    }',
    @response = @Response OUTPUT;

SELECT
    @ReturnCode AS ReturnCode,
    @Response AS Response;
```

If successful, the response contains the generated embedding vector.

------------------------------------------------------------------------

# 17. Troubleshooting SQL Server Error 31608

If SQL Server returns:

``` text
Msg 31608
An error occurred, failed to communicate with the external rest endpoint.
HRESULT: 0x80070008
```

and Caddy does not show an incoming request, investigate the
TLS/certificate path.

The first step is to locate Caddy's root certificate.

## Check Caddy environment

``` cmd
caddy_windows_amd64.exe environ
```

You can also search for the certificate:

``` powershell
Get-ChildItem C:\Users -Recurse -Filter root.crt -ErrorAction SilentlyContinue
```

And:

``` powershell
Get-ChildItem C:\Windows\ServiceProfiles -Recurse -Filter root.crt -ErrorAction SilentlyContinue
```

For a typical Administrator installation, check:

``` powershell
Get-ChildItem "C:\Users\Administrator\AppData\Roaming\Caddy" -Recurse -Filter root.crt
```

A typical path is:

``` text
C:\Users\Administrator\AppData\Roaming\Caddy\pki\authorities\local\root.crt
```

------------------------------------------------------------------------

# 18. Install the Caddy Root CA into Windows Trusted Root

If the certificate is located at:

``` text
C:\Users\Administrator\AppData\Roaming\Caddy\pki\authorities\local\root.crt
```

run Command Prompt or PowerShell as Administrator:

``` cmd
certutil -addstore -f Root "C:\Users\Administrator\AppData\Roaming\Caddy\pki\authorities\local\root.crt"
```

You should see a successful certificate-store import.

After installing the CA, restart the applications involved and test
again.

------------------------------------------------------------------------

# 19. Test Caddy Certificate Validation

Test the local HTTPS endpoint:

``` cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/test
```

You can also test without the revocation bypass:

``` cmd
curl.exe -v https://ollama.local:8443/test
```

If the normal request fails with a certificate revocation-related error
while `--ssl-no-revoke` succeeds, the remaining issue is related to
certificate revocation validation rather than the Ollama API itself.

------------------------------------------------------------------------

# 20. Troubleshooting Checklist

Use the following order when troubleshooting.

### Check Ollama

``` cmd
ollama --version
ollama list
```

### Check Ollama directly

``` cmd
curl http://127.0.0.1:11434/api/tags
```

### Check hostname

``` cmd
ping ollama.local
```

### Check port

``` powershell
Test-NetConnection ollama.local -Port 8443
```

### Check Caddy

``` cmd
caddy_windows_amd64.exe run --config Caddyfile
```

### Check Caddy HTTPS

``` cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/test
```

### Check Ollama through Caddy

``` cmd
curl.exe --ssl-no-revoke https://ollama.local:8443/api/tags
```

### Check embedding API

``` cmd
curl.exe --ssl-no-revoke -v https://ollama.local:8443/api/embed ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"all-minilm:latest\",\"input\":\"SQL Server is a relational database system.\"}"
```

### Check SQL Server external REST

``` sql
EXEC sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = 'https://www.microsoft.com';
```

### Check SQL Server → Caddy

``` sql
EXEC sys.sp_invoke_external_rest_endpoint
    @method = 'GET',
    @url = 'https://ollama.local:8443/api/tags';
```

### Check SQL Server → Ollama embedding

``` sql
EXEC sys.sp_invoke_external_rest_endpoint
    @method = 'POST',
    @url = 'https://ollama.local:8443/api/embed',
    @headers = N'{"Content-Type":"application/json"}',
    @payload = N'{
        "model": "all-minilm:latest",
        "input": "SQL Server is a relational database system."
    }';
```

------------------------------------------------------------------------

# 21. Final Architecture

After successful configuration, the communication path is:

``` text
┌──────────────────────┐
│      SQL Server      │
│                      │
│ sp_invoke_external_  │
│ rest_endpoint        │
└──────────┬───────────┘
           │
           │ HTTPS :8443
           ▼
┌──────────────────────┐
│   ollama.local:8443  │
│        Caddy         │
│                      │
│   TLS termination    │
│   Reverse proxy      │
└──────────┬───────────┘
           │
           │ HTTP :11434
           ▼
┌──────────────────────┐
│       Ollama         │
│                      │
│ all-minilm           │
│ nomic-embed-text     │
└──────────────────────┘
```

This setup allows SQL Server 2025 to call Ollama's REST API through an
HTTPS endpoint and can be used as the foundation for generating
embeddings and storing them in SQL Server `VECTOR` columns for vector
search and RAG experiments.
