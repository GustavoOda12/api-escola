-- Script de criacao do schema do banco "api_escola".
-- Executado automaticamente pelo container MySQL (docker-entrypoint-initdb.d)
-- na PRIMEIRA inicializacao do volume de dados.
--
-- Isso garante que, no profile prd, o schema/tabelas ja existam ANTES da
-- aplicacao subir - a aplicacao (Hibernate ddl-auto=validate) nunca cria
-- ou altera o banco automaticamente.

CREATE TABLE IF NOT EXISTS alunos (
    id            BIGINT NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    turma         VARCHAR(255) NOT NULL,
    media_final   DOUBLE NOT NULL,
    observacao    VARCHAR(255) NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS professores (
    id            BIGINT NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    disciplina    VARCHAR(255) NOT NULL,
    titulacao     VARCHAR(255) NOT NULL,
    sala          VARCHAR(255) NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
