# test-checkpoint1.ps1
# Testa a aplicacao api-escola no profile "prd" via Docker, ponta a ponta.
# Uso: no PowerShell, na raiz do projeto (onde fica o Dockerfile), rode:
#   .\test-checkpoint1.ps1

$ErrorActionPreference = "Stop"
$ImageName = "gustavooda/api-escola:latest"

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

# 1. Build da imagem
Step "Build da imagem $ImageName"
docker build -t $ImageName .
if ($LASTEXITCODE -ne 0) { Fail "Build da imagem falhou. Veja o log de erro do Maven/Docker acima." }

# 2. Sobe a stack prd do zero (garante schema.sql rodando de novo)
Step "Derrubando ambiente anterior (se existir) e subindo mysql + app (docker-compose.prd.yml)"
$ErrorActionPreference = "Continue"
docker compose -f docker-compose.prd.yml down -v *> $null
$ErrorActionPreference = "Stop"
docker compose -f docker-compose.prd.yml up -d
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
    Fail "A aplicacao nao ficou pronta. Procure por ''Schema-validation'' ou erro de conexao com o banco no log acima."
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

# 6. Confere se o Swagger esta acessivel
Step "Conferindo Swagger UI"
$swagger = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing
if ($swagger.StatusCode -eq 200) { Write-Host "Swagger acessivel em http://localhost:8080" -ForegroundColor Green }

Step "TUDO OK. Containers rodando:"
docker ps --filter "name=escola"

Write-Host ""
Write-Host "Para publicar de verdade no Docker Hub, rode manualmente:" -ForegroundColor Cyan
Write-Host "  docker login"
Write-Host "  docker push $ImageName"
Write-Host ""
Write-Host "Para derrubar o ambiente de teste quando terminar:" -ForegroundColor Cyan
Write-Host "  docker compose -f docker-compose.prd.yml down -v"
