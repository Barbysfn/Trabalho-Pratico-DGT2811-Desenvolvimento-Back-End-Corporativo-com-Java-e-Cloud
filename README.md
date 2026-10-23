<h1 align="center">🏪 CadastroEE</h1>

<p align="center">
  Trabalho Prático | <strong>DGT2811 – Desenvolvimento Back-End Corporativo com Java e Cloud</strong><br>
  Sistema cadastral Web com <strong>JPA</strong>, <strong>EJB</strong>, <strong>Servlets</strong>, <strong>JSP</strong> e
  <strong>Bootstrap</strong>, rodando no <strong>GlassFish 6</strong> com banco <strong>SQL Server</strong>.
</p>

<p align="center">
  <img alt="Java" src="https://img.shields.io/badge/Java-17-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white">
  <img alt="Jakarta EE" src="https://img.shields.io/badge/Jakarta%20EE-JPA%20%7C%20EJB%20%7C%20Servlet-1A4F8B?style=for-the-badge">
  <img alt="GlassFish" src="https://img.shields.io/badge/GlassFish-6.2.5-0A6FB5?style=for-the-badge">
  <img alt="SQL Server" src="https://img.shields.io/badge/SQL%20Server-2022-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white">
  <img alt="Bootstrap" src="https://img.shields.io/badge/Bootstrap-5.3-7952B3?style=for-the-badge&logo=bootstrap&logoColor=white">
  <img alt="NetBeans" src="https://img.shields.io/badge/NetBeans-Ant-1B6AC6?style=for-the-badge&logo=apachenetbeanside&logoColor=white">
</p>

---

## 💡 Sobre o projeto

Aplicativo corporativo (EAR) criado no NetBeans com três projetos:

| Projeto | Conteúdo |
|---------|----------|
| **CadastroEE** | Projeto principal — empacota o arquivo `CadastroEE.ear` |
| **CadastroEE-ejb** | Camadas de **persistência** (entidades JPA em `cadastroee.model`) e **controle** (Session Beans `*Facade` e interfaces `*FacadeLocal` em `cadastroee.controller`) |
| **CadastroEE-war** | Camada **Web**: `ServletProduto` (teste), `ServletProdutoFC` (Front Controller) e as páginas `ProdutoLista.jsp` / `ProdutoDados.jsp` com Bootstrap |

## 🏛️ Arquitetura

```
 Navegador
    │  GET/POST  /CadastroEE-war/ServletProdutoFC?acao=...
    ▼
┌──────────────────────────── CadastroEE.ear ────────────────────────────┐
│  CadastroEE-war                                                         │
│   ServletProdutoFC (Front Controller) ──forward──► ProdutoLista.jsp     │
│          │ @EJB                                    ProdutoDados.jsp     │
│          ▼                                                              │
│  CadastroEE-ejb                                                         │
│   ProdutoFacadeLocal ◄── ProdutoFacade (@Stateless)                     │
│                               │ @PersistenceContext(CadastroEE-ejbPU)   │
│                               ▼                                         │
│                    Entidades JPA (Produto, Pessoa, Movimento, ...)      │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │ JNDI jdbc/loja → pool SQLServerPool
                                ▼
                      SQL Server  (banco loja, porta 1433)
```

## 📁 Estrutura

```
CadastroEE/
├── CadastroEE-ejb/
│   └── src/
│       ├── conf/persistence.xml
│       └── java/cadastroee/
│           ├── model/        Movimento, Pessoa, PessoaFisica, PessoaJuridica, Produto, Usuario
│           └── controller/   AbstractFacade + <Entidade>Facade + <Entidade>FacadeLocal
├── CadastroEE-war/
│   ├── src/java/cadastroee/servlets/   ServletProduto, ServletProdutoFC, Html
│   └── web/                             ProdutoLista.jsp, ProdutoDados.jsp, WEB-INF/web.xml
├── nbproject/ , build.xml               projeto Ant do NetBeans (Enterprise Application)
├── scripts/
│   ├── sql/loja.sql                     cria o banco loja, o login loja e dados de exemplo
│   ├── 01-instalar-ambiente.ps1         instala JDK 17, NetBeans, SQL Server, GlassFish e cria o pool
│   └── 02-compilar-implantar.ps1        compila, implanta o EAR e testa as URLs
└── docs/                                relatório (PDF) e capturas de tela
```

## 📋 Pré-requisitos

- JDK 17 e Apache NetBeans (projeto Ant – *Java Enterprise › Enterprise Application*)
- GlassFish **6.2.5** (Jakarta EE 9.1 — por isso os imports usam `jakarta.*`)
- SQL Server com o banco `loja` (login/senha `loja`) — script em [`scripts/sql/loja.sql`](scripts/sql/loja.sql)
- Driver `mssql-jdbc-12.2.0.jre8.jar` copiado para `glassfish6/glassfish/lib`

## ⚙️ Configuração do GlassFish (asadmin)

```text
create-jdbc-connection-pool
  --datasourceclassname com.microsoft.sqlserver.jdbc.SQLServerDataSource
  --restype javax.sql.DataSource
  --property driverClass=com.microsoft.sqlserver.jdbc.SQLServerDriver:portNumber=1433:password=loja:user=loja:serverName=localhost:databaseName=loja:trustServerCertificate=true:URL="jdbc\\:sqlserver\\://localhost\\:1433\\;databaseName\\=loja\\;encrypt\\=true\\;trustServerCertificate\\=true\\;"
  SQLServerPool

ping-connection-pool SQLServerPool
create-jdbc-resource --connectionpoolid SQLServerPool jdbc/loja
```

## 🚀 Como executar

1. Abra os três projetos no NetBeans (`File › Open Project`, marcando *Open Required Projects*).
2. Clique em **Run** (▶) no projeto **CadastroEE**.
3. Acesse:
   - Teste do EJB: <http://localhost:8080/CadastroEE-war/ServletProduto>
   - Cadastro: <http://localhost:8080/CadastroEE-war/ServletProdutoFC?acao=listar>

> Alternativa sem IDE: `scripts\02-compilar-implantar.bat` compila os módulos, gera o EAR e faz o deploy com `asadmin`.

## 🔀 Ações do Front Controller (`ServletProdutoFC`)

| `acao` | O que faz | Destino |
|--------|-----------|---------|
| `listar` | consulta todos os produtos | `ProdutoLista.jsp` |
| `formIncluir` | abre o formulário vazio | `ProdutoDados.jsp` |
| `formAlterar` | busca o produto pelo `id` | `ProdutoDados.jsp` |
| `incluir` | cria um `Produto` com os dados do formulário | `ProdutoLista.jsp` |
| `alterar` | atualiza o produto `id` | `ProdutoLista.jsp` |
| `excluir` | remove o produto `id` | `ProdutoLista.jsp` |

## 📝 Ajustes em relação ao código gerado pelo NetBeans

- Todos os imports `javax.*` → `jakarta.*` (GlassFish 6).
- `Produto.precoVenda`: `BigDecimal` → `Float`.
- `@GeneratedValue(strategy = IDENTITY)` nas entidades cujas chaves são `IDENTITY` no SQL Server (`Produto`, `Usuario`, `Movimento`), para a inclusão funcionar.
- `Produto.movimentoCollection` sem `cascade`, para que excluir um produto nunca apague o histórico de movimentos (se houver movimentos, a tela mostra uma mensagem de erro).
- Pacote dos Session Beans: `cadastroee.controller` (o roteiro traz o erro de digitação `cadatroee`).

## 📄 Relatório

O relatório da prática está em [`docs/`](docs/).

---

## 👩‍💻 Autora

**Bárbara Floripes** — Trabalho Prático da disciplina **DGT2811 – Desenvolvimento Back-End Corporativo com Java e Cloud**.

**GitHub:** [@barbysfn](https://github.com/barbysfn)
