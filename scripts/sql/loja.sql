-- =====================================================================
--  Banco de dados "loja" (Prática 2 - Vamos manter as informações)
--  Usado pelo trabalho prático DGT2811 - CadastroEE
--  Login / senha / banco: loja
-- =====================================================================

IF DB_ID('loja') IS NULL
    CREATE DATABASE loja;
GO

USE loja;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'loja')
    CREATE LOGIN loja WITH PASSWORD = 'loja', DEFAULT_DATABASE = loja,
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'loja')
    CREATE USER loja FOR LOGIN loja;
GO

ALTER ROLE db_owner ADD MEMBER loja;
GO

-- ---------------------------------------------------------------------
--  Tabelas
-- ---------------------------------------------------------------------
IF OBJECT_ID('dbo.Usuario') IS NULL
CREATE TABLE Usuario (
    idUsuario   INT IDENTITY(1,1) NOT NULL,
    login       VARCHAR(50)  NOT NULL,
    senha       VARCHAR(50)  NOT NULL,
    CONSTRAINT PK_Usuario PRIMARY KEY (idUsuario)
);
GO

IF OBJECT_ID('dbo.orderPessoa') IS NULL
    CREATE SEQUENCE orderPessoa AS INT START WITH 1 INCREMENT BY 1;
GO

IF OBJECT_ID('dbo.Pessoa') IS NULL
CREATE TABLE Pessoa (
    idPessoa    INT          NOT NULL,
    nome        VARCHAR(255) NOT NULL,
    logradouro  VARCHAR(255),
    cidade      VARCHAR(255),
    estado      CHAR(2),
    telefone    VARCHAR(11),
    email       VARCHAR(255),
    CONSTRAINT PK_Pessoa PRIMARY KEY (idPessoa)
);
GO

IF OBJECT_ID('dbo.PessoaFisica') IS NULL
CREATE TABLE PessoaFisica (
    idPessoa    INT         NOT NULL,
    cpf         VARCHAR(11) NOT NULL,
    CONSTRAINT PK_PessoaFisica PRIMARY KEY (idPessoa),
    CONSTRAINT FK_PessoaFisica_Pessoa FOREIGN KEY (idPessoa) REFERENCES Pessoa (idPessoa)
);
GO

IF OBJECT_ID('dbo.PessoaJuridica') IS NULL
CREATE TABLE PessoaJuridica (
    idPessoa    INT         NOT NULL,
    cnpj        VARCHAR(14) NOT NULL,
    CONSTRAINT PK_PessoaJuridica PRIMARY KEY (idPessoa),
    CONSTRAINT FK_PessoaJuridica_Pessoa FOREIGN KEY (idPessoa) REFERENCES Pessoa (idPessoa)
);
GO

IF OBJECT_ID('dbo.Produto') IS NULL
CREATE TABLE Produto (
    idProduto   INT IDENTITY(1,1) NOT NULL,
    nome        VARCHAR(255)  NOT NULL,
    quantidade  INT           NOT NULL,
    precoVenda  NUMERIC(10,2) NOT NULL,
    CONSTRAINT PK_Produto PRIMARY KEY (idProduto)
);
GO

IF OBJECT_ID('dbo.Movimento') IS NULL
CREATE TABLE Movimento (
    idMovimento   INT IDENTITY(1,1) NOT NULL,
    idUsuario     INT           NOT NULL,
    idPessoa      INT           NOT NULL,
    idProduto     INT           NOT NULL,
    quantidade    INT           NOT NULL,
    tipo          CHAR(1)       NOT NULL,
    valorUnitario NUMERIC(10,2) NOT NULL,
    CONSTRAINT PK_Movimento PRIMARY KEY (idMovimento),
    CONSTRAINT FK_Movimento_Usuario FOREIGN KEY (idUsuario) REFERENCES Usuario (idUsuario),
    CONSTRAINT FK_Movimento_Pessoa  FOREIGN KEY (idPessoa)  REFERENCES Pessoa (idPessoa),
    CONSTRAINT FK_Movimento_Produto FOREIGN KEY (idProduto) REFERENCES Produto (idProduto),
    CONSTRAINT CK_Movimento_Tipo CHECK (tipo IN ('E', 'S'))
);
GO

-- ---------------------------------------------------------------------
--  Dados de exemplo (só insere se as tabelas estiverem vazias)
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Usuario)
    INSERT INTO Usuario (login, senha) VALUES ('op1', 'op1'), ('op2', 'op2');
GO

IF NOT EXISTS (SELECT 1 FROM Produto)
    INSERT INTO Produto (nome, quantidade, precoVenda) VALUES
        ('Banana',  100,  5.00),
        ('Laranja', 500,  2.00),
        ('Manga',   800,  4.00);
GO

IF NOT EXISTS (SELECT 1 FROM Pessoa)
BEGIN
    DECLARE @pf INT = NEXT VALUE FOR orderPessoa;
    INSERT INTO Pessoa (idPessoa, nome, logradouro, cidade, estado, telefone, email)
        VALUES (@pf, 'Joao', 'Rua 12, casa 3, Quitanda', 'Riacho do Sul', 'PA', '1111-1111', 'joao@riacho.com');
    INSERT INTO PessoaFisica (idPessoa, cpf) VALUES (@pf, '11111111111');

    DECLARE @pj INT = NEXT VALUE FOR orderPessoa;
    INSERT INTO Pessoa (idPessoa, nome, logradouro, cidade, estado, telefone, email)
        VALUES (@pj, 'JJC', 'Rua 11, Centro', 'Riacho do Norte', 'PA', '1212-1212', 'jjc@riacho.com');
    INSERT INTO PessoaJuridica (idPessoa, cnpj) VALUES (@pj, '22222222222222');

    INSERT INTO Movimento (idUsuario, idPessoa, idProduto, quantidade, tipo, valorUnitario) VALUES
        (1, @pf, 1, 20, 'S', 4.00),
        (1, @pf, 3, 15, 'S', 2.00),
        (2, @pf, 3, 10, 'S', 3.00),
        (1, @pj, 3, 15, 'E', 5.00),
        (1, @pj, 2, 20, 'E', 4.00);
END
GO
