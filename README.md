# 🏫 API Escola — Spring Boot + SQL Server

API RESTful para gerenciamento de Alunos e Professores, desenvolvida com Spring Boot, Spring Data JPA e banco de dados **Microsoft SQL Server**.

> Check Point 2 — Microservices and Web Engineering (FIAP).
> A versão com MySQL (Check Point 1) está preservada na tag `checkpoint1`.

## 🛠️ Tecnologias Utilizadas

- Java 21
- Spring Boot 4.0.3
- Spring Data JPA / Hibernate
- Microsoft SQL Server 2025 (driver `mssql-jdbc`)
- Swagger / OpenAPI (SpringDoc)
- Docker
- Lombok

## 🌱 Profiles de execução

| Profile | Uso | Comportamento do schema |
|---|---|---|
| `default` | Desenvolvimento local | Hibernate cria/atualiza as **tabelas** automaticamente (`ddl-auto=update`) |
| `prd` | Produção / Docker | Idem (`ddl-auto=update`), sem log de SQL e com credenciais 100% via variáveis de ambiente |

> ⚠️ Em ambos os profiles o **banco** `api_escola` precisa existir antes de a API subir — o SQL Server não o cria sozinho. Veja o passo 2 abaixo (o `docker-compose` já faz isso automaticamente).

---

## 🗄️ Dados de conexão com o banco

| Configuração | Valor |
|---|---|
| Servidor (host) | `localhost` |
| Porta | `1433` |
| Banco | `api_escola` |
| Usuário | `sa` |
| Senha | `1q2w3e4R@` |
| Tabelas (criadas pelo JPA) | `alunos`, `professores` |

URL JDBC usada pela aplicação:

```
jdbc:sqlserver://localhost:1433;databaseName=api_escola;encrypt=true;trustServerCertificate=true
```

Para inspecionar o banco por uma ferramenta gráfica (Azure Data Studio, DBeaver, SSMS), conecte-se com os dados acima e marque **Trust server certificate**.

---

## 💻 Como executar (desenvolvimento — profile `default`)

### Pré-requisitos

- [Java 21](https://www.oracle.com/java/technologies/downloads/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Git](https://git-scm.com/)

### 1. Clone o repositório

```cmd
git clone https://github.com/Rafael-Scharlack/api-escola.git
cd api-escola
```

### 2. Suba o SQL Server e crie o banco

**Opção A — Docker Compose (automático, recomendado):** sobe o SQL Server e já executa o `CREATE DATABASE api_escola`.

```cmd
docker compose up -d
```

**Opção B — `docker run` manual (CMD, uma linha):**

```cmd
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=1q2w3e4R@" -p 1433:1433 --name sqlserver -v sqlserver_data:/var/opt/mssql -d mcr.microsoft.com/mssql/server:latest
```

Aguarde ~15 segundos o SQL Server iniciar e crie o banco (o container **não** cria o banco sozinho):

```cmd
docker exec sqlserver /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "1q2w3e4R@" -Q "CREATE DATABASE api_escola;"
```

Equivalente em T-SQL, caso prefira executar em uma ferramenta gráfica:

```sql
CREATE DATABASE api_escola;
```

> As tabelas `alunos` e `professores` **não** precisam ser criadas à mão: o Hibernate as cria na primeira execução da API.

### 3. Rode a aplicação

```cmd
mvnw.cmd spring-boot:run
```

A API estará disponível em `http://localhost:8080` (o Swagger UI está na mesma URL).

### Configuração da conexão (variáveis de ambiente)

A conexão é configurada em [`application.properties`](src/main/resources/application.properties) e pode ser sobrescrita por variáveis de ambiente, sem alterar o código:

| Variável | Padrão (`default`) | Descrição |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `default` | Profile ativo (`default` ou `prd`) |
| `DB_HOST` | `localhost` | Host do SQL Server |
| `DB_PORT` | `1433` | Porta do SQL Server |
| `DB_NAME` | `api_escola` | Nome do banco |
| `DB_USER` | `sa` | Usuário do banco |
| `DB_PASSWORD` | `1q2w3e4R@` | Senha do banco |

Exemplo (CMD) apontando para outro servidor:

```cmd
set DB_HOST=meu-servidor && set DB_PASSWORD=outraSenha && mvnw.cmd spring-boot:run
```

No profile `prd` as variáveis `DB_HOST`, `DB_NAME`, `DB_USER` e `DB_PASSWORD` são **obrigatórias** (não há valor padrão).

---

## 🐳 Rodando tudo com Docker (profile `prd`)

Sobe SQL Server + criação do banco + API de uma só vez. A imagem da API é **construída localmente** a partir do [`Dockerfile`](Dockerfile) (não é necessário baixar nada do Docker Hub):

```cmd
docker compose -f docker-compose.prd.yml up -d --build
```

Acesse `http://localhost:8080`. As portas `1433` e `8080` precisam estar livres.

Para derrubar tudo (inclusive os dados do banco):

```cmd
docker compose -f docker-compose.prd.yml down -v
```

Há também um script de teste ponta a ponta (PowerShell) que faz o build, sobe o ambiente, cria um aluno e lista os alunos:

```powershell
.\test-checkpoint2.ps1
```

---

## 📋 Endpoints

Base URL: `http://localhost:8080` — documentação interativa (Swagger UI) na mesma URL.

### 👨‍🎓 Alunos

| Método | Rota | Descrição |
|---|---|---|
| GET | /alunos | Lista todos os alunos |
| GET | /alunos/{id} | Busca aluno por ID |
| POST | /alunos | Cria um novo aluno |
| PUT | /alunos/{id} | Atualiza um aluno |
| DELETE | /alunos/{id} | Remove um aluno |

**Exemplo de body para POST/PUT:**
```json
{
  "nome": "João Silva",
  "email": "joao@email.com",
  "turma": "Turma A",
  "mediaFinal": 8.5,
  "observacao": "Aluno destaque"
}
```

### 👨‍🏫 Professores

| Método | Rota | Descrição |
|---|---|---|
| GET | /professores | Lista todos os professores |
| GET | /professores/{id} | Busca professor por ID |
| POST | /professores | Cria um novo professor |
| PUT | /professores/{id} | Atualiza um professor |
| DELETE | /professores/{id} | Remove um professor |

**Exemplo de body para POST/PUT:**
```json
{
  "nome": "Antonio Carlos",
  "email": "antonio@fiap.com",
  "disciplina": "Microservices",
  "titulacao": "Doutor",
  "sala": "B12"
}
```

### Testando via linha de comando (CMD)

```cmd
curl -X POST http://localhost:8080/alunos -H "Content-Type: application/json" -d "{\"nome\":\"Joao Silva\",\"email\":\"joao@email.com\",\"turma\":\"Turma A\",\"mediaFinal\":8.5,\"observacao\":\"Aluno destaque\"}"
curl http://localhost:8080/alunos
```

---

## 👥 Integrantes

| Nome | RM |
|---|---|
| Rafael Catapani Scharlack | 554633 |
| Gustavo Iudi Rosa Oda | 556754 |
