# 🏫 API Escola — Spring Boot + MySQL

API RESTful para gerenciamento de Alunos e Professores, desenvolvida com Spring Boot e banco de dados MySQL.

## 🛠️ Tecnologias Utilizadas

- Java 21
- Spring Boot 4.0.3
- Spring Data JPA / Hibernate
- MySQL 8.0
- Swagger / OpenAPI (SpringDoc)
- Docker
- Lombok

## 🌱 Profiles de execução

A aplicação possui dois profiles:

| Profile | Uso | Comportamento do schema |
|---|---|---|
| `default` | Desenvolvimento local | Hibernate cria/atualiza as tabelas automaticamente (`ddl-auto=update`) |
| `prd` | Produção | A aplicação **nunca** cria ou altera o schema (`ddl-auto=validate`). As tabelas são criadas pelo próprio container MySQL a partir de [`docker/mysql/init/schema.sql`](docker/mysql/init/schema.sql) |

---

## ▶️ Rodando a partir da imagem publicada no Docker Hub (profile `prd`)

Esta é a forma recomendada para avaliação/correção.

### 1. Baixe a imagem

```bash
docker pull gustavooda/api-escola:latest
```

### 2. Suba um banco MySQL com o schema já criado

```bash
docker run -d \
  --name mysql-escola \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=api_escola \
  -p 3306:3306 \
  -v "$(pwd)/docker/mysql/init:/docker-entrypoint-initdb.d" \
  mysql:8.0
```

> Aguarde alguns segundos até o MySQL finalizar a inicialização e criar as tabelas (`alunos`, `professores`) a partir do script montado.

### 3. Rode a aplicação (profile `prd`)

```bash
docker run -d \
  --name api-escola \
  --link mysql-escola:mysql \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prd \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_NAME=api_escola \
  -e DB_USER=root \
  -e DB_PASSWORD=root \
  gustavooda/api-escola:latest
```

> Alternativa equivalente usando Docker Compose:
> ```bash
> docker compose -f docker-compose.prd.yml up -d
> ```

### Variáveis de ambiente da aplicação

| Variável | Obrigatória | Padrão | Descrição |
|---|---|---|---|
| `SPRING_PROFILES_ACTIVE` | Não | `default` | Profile ativo (`default` ou `prd`) |
| `DB_HOST` | Sim (em `prd`) | `localhost` | Host do MySQL |
| `DB_PORT` | Não | `3306` | Porta do MySQL |
| `DB_NAME` | Sim (em `prd`) | `api_escola` | Nome do banco |
| `DB_USER` | Sim (em `prd`) | `root` | Usuário do banco |
| `DB_PASSWORD` | Sim (em `prd`) | `root` | Senha do banco |

### 4. Acesse o Swagger / OpenAPI

Com o container rodando, abra:

```
http://localhost:8080
```

O Swagger UI está configurado na raiz (`springdoc.swagger-ui.path=/`) e expõe automaticamente todos os endpoints REST documentados abaixo.

---

## 💻 Rodando em modo desenvolvimento (profile `default`)

### Pré-requisitos

- [Java 21](https://www.oracle.com/java/technologies/downloads/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Git](https://git-scm.com/)

### 1. Clone o repositório

```bash
git clone https://github.com/GustavoOda12/api-escola.git
cd api-escola
```

### 2. Suba o banco de dados com Docker

```bash
docker-compose up -d
```

| Configuração | Valor |
|---|---|
| Host | localhost |
| Porta | 3306 |
| Banco | api_escola |
| Usuário | root |
| Senha | root |

### 3. Rode a aplicação

```bash
./mvnw spring-boot:run
```

A API estará disponível em `http://localhost:8080` (Swagger na mesma URL).

---

## 🐳 Build e publicação da imagem Docker

```bash
# build local da imagem
docker build -t gustavooda/api-escola:latest .

# testar localmente antes de publicar
docker run -p 8080:8080 -e SPRING_PROFILES_ACTIVE=default gustavooda/api-escola:latest

# publicar no Docker Hub
docker login
docker push gustavooda/api-escola:latest
```

---

## 📋 Endpoints

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

---

## 👥 Integrantes

| Nome | RM |
|---|---|
| Rafael Catapani Scharlack | 554633 |
| _(preencher segundo integrante)_ | _(preencher)_ |
