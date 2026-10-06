# test-checkpoint2.ps1
# Testa a aplicacao api-escola (profile "prd") com SQL Server via Docker, ponta a ponta:
# build da API a partir do Dockerfile, SQL Server + criacao do banco + API, e um
# POST/GET em /alunos.
# Uso: no PowerShell, na raiz do projeto (onde fica o Dockerfile), rode:
#   .\test-checkpoint2.ps1
# Requer as portas 1433 e 8080 livres (pare outros containers que as usem).

$ErrorActionPreference = "Stop"
$ComposeFile = "docker-compose.prd.yml"

function Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Fail($msg) {
    Write-Host "ERRO: $msg" -ForegroundColor Red
    exit 1
}

# 0. Docker rodando?
Step "Verificando se o Docker esta rodando"
$ErrorActionPreference = "Continue"
docker info *> $null
$ErrorActionPreference = "Stop"
if ($LASTEXITCODE -ne 0) { Fail "Docker Desktop nao esta rodando. Abra o Docker Desktop e tente novamente." }
Write-Host "Docker OK" -ForegroundColor Green

# 1. Build da imagem da API (definida em "build: ." no compose)
Step "Build da imagem da API a partir do Dockerfile"
docker compose -f $ComposeFile build
if ($LASTEXITCODE -ne 0) { Fail "Build da imagem falhou. Veja o log de erro do Maven/Docker acima." }

# 2. Sobe a stack prd do zero (volume zerado: banco recriado pelo servico db-init)
Step "Derrubando ambiente anterior (se existir) e subindo sqlserver + db-init + app ($ComposeFile)"
$ErrorActionPreference = "Continue"
docker compose -f $ComposeFile down -v *> $null
$ErrorActionPreference = "Stop"
docker compose -f $ComposeFile up -d
if ($LASTEXITCODE -ne 0) { Fail "Falha ao subir os containers com docker compose." }

# 3. Espera a aplicacao responder (ate 60s)
Step "Aguardando a aplicacao subir (ate 60s)"
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:8080/alunos" -UseBasicParsing -TimeoutSec 3
        if ($resp.StatusCode -eq 200) { $ready = $true; break }
    } catch {
        Write-Host "." -NoNewline
    }
}
Write-Host ""
if (-not $ready) {
    Write-Host "Aplicacao nao respondeu a tempo. Ultimas linhas do log:" -ForegroundColor Yellow
    docker logs api-escola-prd --tail 80
    Fail "A aplicacao nao ficou pronta. Procure por erro de conexao/login com o SQL Server no log acima."
}
Write-Host "Aplicacao respondendo em http://localhost:8080" -ForegroundColor Green

# 4. Confere o profile ativo diretamente na variavel de ambiente do container
Step "Conferindo profile ativo"
docker exec api-escola-prd env | Select-String "SPRING_PROFILES_ACTIVE"

# 5. Teste funcional: cria e lista um aluno
Step "Testando POST /alunos"
$body = @{
    nome       = "Teste Automatizado"
    email      = "teste@fiap.com"
    turma      = "Turma Script"
    mediaFinal = 9.0
    observacao = "criado pelo script de teste"
} | ConvertTo-Json

$post = Invoke-RestMethod -Uri "http://localhost:8080/alunos" -Method Post -Body $body -ContentType "application/json"
Write-Host "Aluno criado com id $($post.id)" -ForegroundColor Green

Step "Testando GET /alunos"
$list = Invoke-RestMethod -Uri "http://localhost:8080/alunos" -Method Get
Write-Host "Total de alunos retornados: $($list.Count)" -ForegroundColor Green

# 5b. Confere no proprio SQL Server que o banco e as tabelas foram criados
Step "Conferindo banco api_escola e tabelas no SQL Server"
docker exec sqlserver-escola-prd /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "1q2w3e4R@" -d api_escola -Q "SELECT name AS tabela FROM sys.tables ORDER BY name"
if ($LASTEXITCODE -ne 0) { Fail "Nao foi possivel consultar o banco api_escola no SQL Server." }

# 6. Confere se o Swagger esta acessivel
Step "Conferindo Swagger UI"
$swagger = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing
if ($swagger.StatusCode -eq 200) { Write-Host "Swagger acessivel em http://localhost:8080" -ForegroundColor Green }

Step "TUDO OK. Containers rodando:"
docker ps --filter "name=escola"

Write-Host ""
Write-Host "Para derrubar o ambiente de teste quando terminar:" -ForegroundColor Cyan
Write-Host "  docker compose -f $ComposeFile down -v"
