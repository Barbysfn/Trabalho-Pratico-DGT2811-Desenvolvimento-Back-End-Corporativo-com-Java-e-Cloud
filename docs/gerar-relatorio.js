// Gera docs/Relatorio-CadastroEE.docx (depois convertido para PDF com o LibreOffice)
// Uso: node docs/gerar-relatorio.js  (a partir da raiz do repositório)
const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, ImageRun,
  PageBreak, ShadingType, BorderStyle, Footer, PageNumber, TableOfContents,
  Table, TableRow, TableCell, WidthType, LevelFormat,
} = require('docx');

const RAIZ = path.resolve(__dirname, '..');
const IMG = path.join(__dirname, 'img');
const PROC2_JSP = process.env.PROC2_JSP_DIR || path.join(__dirname, 'jsp-procedimento2'); // versões das JSPs antes do Bootstrap
const REPO = 'https://github.com/Barbysfn/Trabalho-Pratico-DGT2811-Desenvolvimento-Back-End-Corporativo-com-Java-e-Cloud';
const analise = JSON.parse(fs.readFileSync(path.join(__dirname, 'analise.json'), 'utf8'));

const LARGURA = 9638; // A4 com margens de 2 cm (DXA)
const COR = '1F4E79';

// ---------- helpers ----------
const p = (text, opts = {}) => new Paragraph({
  spacing: { after: 120, line: 300 }, alignment: opts.align || AlignmentType.JUSTIFIED,
  children: [new TextRun({ text, size: 22, bold: opts.bold, italics: opts.italics, color: opts.color })],
  ...opts.para,
});
const rich = (runs, opts = {}) => new Paragraph({
  spacing: { after: 120, line: 300 }, alignment: AlignmentType.JUSTIFIED,
  children: runs.map(r => typeof r === 'string' ? new TextRun({ text: r, size: 22 }) : new TextRun({ size: 22, ...r })),
  ...opts,
});
const h1 = t => new Paragraph({ heading: HeadingLevel.HEADING_1, spacing: { before: 240, after: 160 }, children: [new TextRun({ text: t })] });
const h2 = t => new Paragraph({ heading: HeadingLevel.HEADING_2, spacing: { before: 200, after: 120 }, children: [new TextRun({ text: t })] });
const h3 = t => new Paragraph({ heading: HeadingLevel.HEADING_3, spacing: { before: 160, after: 100 }, children: [new TextRun({ text: t })] });
const bullet = (t) => new Paragraph({ numbering: { reference: 'bul', level: 0 }, spacing: { after: 60 },
  children: (Array.isArray(t) ? t : [t]).map(r => typeof r === 'string' ? new TextRun({ text: r, size: 22 }) : new TextRun({ size: 22, ...r })) });
const quebra = () => new Paragraph({ children: [new PageBreak()] });

function codigo(texto, titulo) {
  const out = [];
  if (titulo) out.push(new Paragraph({ spacing: { before: 160, after: 40 }, keepNext: true,
    children: [new TextRun({ text: titulo, bold: true, size: 20, color: COR, font: 'Consolas' })] }));
  const linhas = texto.replace(/\r/g, '').replace(/\t/g, '    ').replace(/\n+$/, '').split('\n');
  linhas.forEach((l, i) => out.push(new Paragraph({
    spacing: { after: 0, line: 240 },
    shading: { type: ShadingType.CLEAR, color: 'auto', fill: 'F3F5F8' },
    border: {
      left: { style: BorderStyle.SINGLE, size: 12, color: '9DB4CF', space: 6 },
      ...(i === 0 ? { top: { style: BorderStyle.SINGLE, size: 4, color: 'D9E1EA', space: 2 } } : {}),
      ...(i === linhas.length - 1 ? { bottom: { style: BorderStyle.SINGLE, size: 4, color: 'D9E1EA', space: 2 } } : {}),
    },
    children: [new TextRun({ text: l.length ? l : ' ', font: 'Consolas', size: 16 })],
  })));
  out.push(new Paragraph({ spacing: { after: 120 }, children: [] }));
  return out;
}
const arq = (rel, base = RAIZ) => fs.readFileSync(path.join(base, rel), 'utf8');
const cod = (rel, base) => codigo(arq(rel, base), rel.replace(/\\/g, '/'));

let nFig = 0;
function figura(nome, legenda, larguraMax = 600) {
  const buf = fs.readFileSync(path.join(IMG, nome));
  // dimensões do PNG
  const w = buf.readUInt32BE(16), h = buf.readUInt32BE(20);
  const largura = Math.min(larguraMax, w), altura = Math.round(h * largura / w);
  nFig++;
  return [
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 120, after: 40 }, keepNext: true,
      children: [new ImageRun({ type: 'png', data: buf, transformation: { width: largura, height: altura },
        altText: { title: legenda, description: legenda, name: nome } })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new TextRun({ text: `Figura ${nFig} – ${legenda}`, italics: true, size: 18, color: '555555' })] }),
  ];
}
function perguntas(lista) {
  const out = [];
  lista.forEach(([q, r]) => { out.push(h3(q)); out.push(p(r)); });
  return out;
}

// ---------- capa ----------
const campo = (rotulo, valor, destaque) => new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 },
  children: [new TextRun({ text: rotulo + ': ', bold: true, size: 24 }),
    new TextRun({ text: valor, size: 24, highlight: destaque ? 'yellow' : undefined })] });

const capa = [
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 600, after: 200 },
    border: { top: { style: BorderStyle.DASHED, size: 6, color: '999999', space: 8 }, bottom: { style: BorderStyle.DASHED, size: 6, color: '999999', space: 8 },
      left: { style: BorderStyle.DASHED, size: 6, color: '999999', space: 8 }, right: { style: BorderStyle.DASHED, size: 6, color: '999999', space: 8 } },
    indent: { left: 3200, right: 3200 },
    children: [new TextRun({ text: '[ inserir aqui a logo da universidade ]', color: '888888', size: 20, highlight: 'yellow' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 400, after: 80 }, children: [new TextRun({ text: 'UNIVERSIDADE ESTÁCIO DE SÁ', bold: true, size: 30, color: COR })] }),
  campo('Campus', 'Polo Alexandrino'),
  campo('Curso', 'Desenvolvimento Full Stack'),
  campo('Disciplina', 'DGT2811 – Desenvolvimento Back-End Corporativo com Java e Cloud'),
  campo('Turma', '[preencher]', true),
  campo('Semestre letivo', '[preencher]', true),
  campo('Integrante', 'Bárbara Floripes'),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 700, after: 120 }, children: [new TextRun({ text: 'Trabalho Prático', size: 28, color: '555555' })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: 'CadastroEE – Sistema cadastral Web com Servlets, JPA e JEE', bold: true, size: 40, color: COR })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 600 }, children: [
    new TextRun({ text: 'Repositório: ', bold: true, size: 20 }), new TextRun({ text: REPO, size: 20, color: '0563C1', underline: {} })] }),
  quebra(),
];

// ---------- corpo ----------
const corpo = [
  new Paragraph({ spacing: { after: 200 }, children: [new TextRun({ text: 'Sumário', bold: true, size: 32, color: COR })] }),
  new TableOfContents('Sumário', { hyperlink: true, headingStyleRange: '1-2' }),
  quebra(),

  h1('Título da Prática'),
  p('Implementação de sistema cadastral com interface Web, baseado nas tecnologias de Servlets, JPA e JEE (projeto CadastroEE).'),

  h1('Objetivo da Prática'),
  bullet('Implementar persistência com base em JPA.'),
  bullet('Implementar regras de negócio na plataforma JEE, através de EJBs.'),
  bullet('Implementar sistema cadastral Web com base em Servlets e JSPs.'),
  bullet('Utilizar a biblioteca Bootstrap para melhoria do design.'),
  p('Ao final, a aplicação permite listar, incluir, alterar e excluir produtos do banco loja (SQL Server) por meio de uma interface Web, passando pelas camadas Web (Servlets e JSPs), de controle (Session Beans) e de persistência (entidades JPA).'),

  h1('Ambiente utilizado'),
  bullet('Windows 11, JDK 17 (Eclipse Temurin 17.0.20) e Apache NetBeans IDE 25 (projeto Ant – Java Enterprise › Enterprise Application).'),
  bullet('GlassFish Server 6.2.5 (Jakarta EE 9.1 – por isso os pacotes javax foram trocados por jakarta).'),
  bullet('Microsoft SQL Server 2022 Express, instância padrão na porta 1433, banco loja com o login loja/loja.'),
  bullet('Driver JDBC mssql-jdbc-12.2.0.jre8.jar, copiado para glassfish6/glassfish/lib.'),
  bullet('Bootstrap 5.3.3 via CDN (jsDelivr).'),
  rich(['Repositório Git com todo o código, scripts e este relatório: ', { text: REPO, color: '0563C1', underline: {} }, '.']),

  // ================= PROCEDIMENTO 1 =================
  quebra(),
  h1('1º Procedimento – Camadas de Persistência e Controle'),
  h2('1.1 Conexão com o SQL Server e pool de conexões no GlassFish'),
  p('O driver do SQL Server foi registrado no NetBeans (Serviços › Banco de Dados › Drivers) e foi criada a conexão loja com a URL jdbc:sqlserver://localhost:1433;databaseName=loja;encrypt=true;trustServerCertificate=true;. O arquivo mssql-jdbc-12.2.0.jre8.jar foi copiado para o diretório lib do GlassFish e, com o servidor iniciado, foram executados no asadmin os comandos abaixo, exatamente como no roteiro (o identificador do pool, SQLServerPool, foi informado ao final do comando):', { align: AlignmentType.LEFT }),
  ...codigo(`create-jdbc-connection-pool
  --datasourceclassname com.microsoft.sqlserver.jdbc.SQLServerDataSource
  --restype javax.sql.DataSource
  --property driverClass=com.microsoft.sqlserver.jdbc.SQLServerDriver:portNumber=1433:password=loja:user=loja:serverName=localhost:databaseName=loja:trustServerCertificate=true:URL="jdbc\\\\:sqlserver\\\\://localhost\\\\:1433\\\\;databaseName\\\\=loja\\\\;encrypt\\\\=true\\\\;trustServerCertificate\\\\=true\\\\;"
  SQLServerPool

ping-connection-pool SQLServerPool

create-jdbc-resource --connectionpoolid SQLServerPool jdbc/loja`, 'Comandos asadmin'),
  ...codigo(`JDBC connection pool SQLServerPool created successfully.
Command create-jdbc-connection-pool executed successfully.
Command ping-connection-pool executed successfully.
JDBC resource jdbc/loja created successfully.
Command create-jdbc-resource executed successfully.`, 'Resultado da execução'),
  ...figura('nb-03-services.png', 'Aba Serviços do NetBeans: driver Microsoft SQL Server, conexão loja, GlassFish 6.2.5 com o recurso jdbc/loja, o pool SQLServerPool e a aplicação CadastroEE implantada', 380),

  h2('1.2 Aplicativo corporativo CadastroEE'),
  p('Foi criado o projeto Ant › Java Enterprise › Enterprise Application CadastroEE, com o servidor GlassFish e a plataforma Jakarta EE 8, que gerou os projetos dependentes CadastroEE-ejb (JPA e EJB) e CadastroEE-war (Web). No CadastroEE-ejb foram geradas as entidades com New Entity Classes from Database (Data Source jdbc/loja, todas as tabelas, pacote cadastroee.model e persistence.xml) e, em seguida, os Session Beans com New Session Beans for Entity Classes (todas as entidades, interface local, pacote cadastroee.controller — o roteiro traz o erro de digitação "cadatroee").'),
  h2('1.3 Ajustes para o Jakarta'),
  bullet('Biblioteca Jakarta EE 8 API adicionada ao CadastroEE-ejb e Jakarta EE Web 8 API ao CadastroEE-war.'),
  bullet('Todas as importações javax.* trocadas por jakarta.* nos dois projetos.'),
  bullet('Produto.precoVenda alterado de BigDecimal para Float.'),
  bullet('persistence.xml substituído pelo do roteiro e web.xml do CadastroEE-war substituído pelo do roteiro.'),
  bullet('Ajuste adicional: @GeneratedValue(strategy = GenerationType.IDENTITY) nas entidades cujas chaves são IDENTITY no SQL Server (Produto, Usuario, Movimento), necessário para a inclusão de novos produtos.'),
  ...figura('nb-01-ejb.png', 'Projeto CadastroEE-ejb no NetBeans: entidades, Session Beans, bibliotecas e persistence.xml', 380),

  h2('1.4 Códigos – CadastroEE-ejb'),
  ...cod('CadastroEE-ejb/src/conf/persistence.xml'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/model/Produto.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/model/Pessoa.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/model/PessoaFisica.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/model/PessoaJuridica.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/model/Usuario.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/model/Movimento.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/controller/AbstractFacade.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/controller/ProdutoFacade.java'),
  ...cod('CadastroEE-ejb/src/java/cadastroee/controller/ProdutoFacadeLocal.java'),
  p('As demais classes MovimentoFacade, PessoaFacade, PessoaFisicaFacade, PessoaJuridicaFacade e UsuarioFacade (e suas interfaces …FacadeLocal) seguem exatamente o mesmo modelo, mudando apenas a entidade, e estão no repositório.', { italics: true }),

  h2('1.5 Códigos – CadastroEE-war (Servlet de teste)'),
  ...cod('CadastroEE-war/web/WEB-INF/web.xml'),
  ...cod('CadastroEE-war/src/java/cadastroee/servlets/ServletProduto.java'),
  ...cod('CadastroEE-war/src/java/cadastroee/servlets/Html.java'),

  h2('1.6 Execução'),
  p('O projeto principal CadastroEE foi executado com Run, que compilou os três módulos, gerou o EAR e o implantou no GlassFish. Com o banco alimentado pelo script de dados, o ServletProduto apresentou a lista de produtos obtida pelo EJB:'),
  ...figura('nb-04-run.png', 'Saída do Run no NetBeans: build dos três módulos, implantação no GlassFish e BUILD SUCCESSFUL', 560),
  ...figura('p1-01-servletproduto.png', 'http://localhost:8080/CadastroEE-war/ServletProduto', 420),

  h2('1.7 Análise e Conclusão'),
  ...perguntas(analise.proc1),

  // ================= PROCEDIMENTO 2 =================
  quebra(),
  h1('2º Procedimento – Interface Cadastral com Servlet e JSPs'),
  p('Foi criado o Servlet ServletProdutoFC no padrão Front Controller: ele captura o parâmetro acao, executa a operação correspondente pelo ProdutoFacadeLocal e encaminha (forward via RequestDispatcher) para ProdutoDados.jsp (formIncluir e formAlterar) ou ProdutoLista.jsp (demais ações). Também foram criadas as páginas de consulta e de cadastro. O tratamento de erro (try/catch) mostra uma mensagem na listagem quando uma operação falha, por exemplo ao excluir um produto que possui movimentos (chave estrangeira).'),
  h2('2.1 Códigos'),
  ...cod('CadastroEE-war/src/java/cadastroee/servlets/ServletProdutoFC.java'),
  ...cod('ProdutoLista.jsp', PROC2_JSP),
  ...cod('ProdutoDados.jsp', PROC2_JSP),

  h2('2.2 Resultados dos testes'),
  h3('Listagem'),
  ...figura('p2-01-listar.png', 'http://localhost:8080/CadastroEE-war/ServletProdutoFC?acao=listar', 360),
  h3('Inclusão (a partir do link "Novo Produto")'),
  p('Foi incluído o produto "Maçã" (para testar a acentuação, tratada com request.setCharacterEncoding("UTF-8")):'),
  ...figura('p2-05-lista-com-maca.png', 'Listagem após a inclusão do produto Maçã', 360),
  h3('Alteração (a partir do link dinâmico "Alterar")'),
  ...figura('p2-06-form-alterar.png', 'Formulário de alteração aberto com os dados do produto 4', 360),
  ...figura('p2-07-form-alterar-editado.png', 'Quantidade alterada para 150 e preço para 7,25', 360),
  ...figura('p2-08-lista-apos-alterar.png', 'Listagem após a alteração', 360),
  h3('Exclusão (a partir do link dinâmico "Excluir")'),
  ...figura('p2-09-lista-apos-excluir.png', 'Listagem após excluir o produto Maçã', 360),
  ...figura('p2-10-excluir-com-movimentos.png', 'Tentativa de excluir Banana, que possui movimentos: a operação é recusada e a mensagem é exibida', 460),
  h3('Nova inclusão'),
  ...figura('p2-02-form-incluir-vazio.png', 'Formulário de inclusão (acao=formIncluir)', 360),
  ...figura('p2-03-form-incluir-preenchido.png', 'Formulário preenchido com o produto Abacaxi', 360),
  ...figura('p2-04-lista-apos-incluir.png', 'Listagem após a inclusão do Abacaxi', 360),

  h2('2.3 Análise e Conclusão'),
  ...perguntas(analise.proc2),

  // ================= PROCEDIMENTO 3 =================
  quebra(),
  h1('3º Procedimento – Melhorando o Design da Interface'),
  p('As bibliotecas do Bootstrap foram incluídas por CDN (link do CSS e script do JavaScript copiados de getbootstrap.com) na divisão head de ProdutoLista.jsp e ProdutoDados.jsp, e foram aplicadas as classes pedidas: container no body; btn btn-primary m-2 no link de inclusão; table table-striped na tabela e table-dark no thead; btn btn-primary btn-sm e btn btn-danger btn-sm nos links de alteração e exclusão; form no formulário, div mb-3 envolvendo cada par label/input, form-label nos labels, form-control nos inputs e btn btn-primary no botão.'),
  h2('3.1 Códigos'),
  ...cod('CadastroEE-war/web/ProdutoLista.jsp'),
  ...cod('CadastroEE-war/web/ProdutoDados.jsp'),
  h2('3.2 Resultados'),
  ...figura('p3-01-listar.png', 'Listagem com Bootstrap', 560),
  ...figura('p3-02-form-incluir-vazio.png', 'Formulário de inclusão com Bootstrap', 560),
  ...figura('p3-03-form-incluir-preenchido.png', 'Inclusão do produto Uva', 560),
  ...figura('p3-04-lista-apos-incluir.png', 'Listagem após a inclusão', 560),
  ...figura('p3-06-form-alterar-editado.png', 'Alteração do produto Uva (quantidade 180, preço 10,50)', 560),
  ...figura('p3-07-lista-apos-alterar.png', 'Listagem após a alteração', 560),
  ...figura('p3-08-lista-apos-excluir.png', 'Listagem após excluir o Abacaxi', 560),
  ...figura('p3-09-excluir-com-movimentos.png', 'Mensagem de erro com o componente alert do Bootstrap', 560),
  h2('3.3 Análise e Conclusão'),
  ...perguntas(analise.proc3),

  h1('Conclusão geral'),
  p('O trabalho percorreu as camadas de uma aplicação corporativa Java: as entidades JPA mapeiam o banco loja, os Session Beans concentram as operações e as transações, o Servlet Front Controller organiza o fluxo da interface e as JSPs, estilizadas com Bootstrap, apresentam os dados. Os assistentes do NetBeans geraram boa parte do código repetitivo, e os ajustes para o GlassFish 6 (troca de javax por jakarta, chave IDENTITY e tipo Float) mostraram na prática como versões de plataforma e mapeamento objeto-relacional influenciam o projeto.'),
];

const doc = new Document({
  creator: 'Bárbara Floripes',
  title: 'CadastroEE – Relatório do Trabalho Prático DGT2811',
  features: { updateFields: true },
  styles: {
    default: { document: { run: { font: 'Calibri', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 32, bold: true, color: COR }, paragraph: { spacing: { before: 240, after: 160 }, outlineLevel: 0, keepNext: true } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 26, bold: true, color: '2E74B5' }, paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 1, keepNext: true } },
      { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 23, bold: true, color: '404040' }, paragraph: { spacing: { before: 160, after: 80 }, outlineLevel: 2, keepNext: true } },
    ],
  },
  numbering: { config: [{ reference: 'bul', levels: [{ level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT,
    style: { paragraph: { indent: { left: 540, hanging: 270 } } } }] }] },
  sections: [
    { properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
      children: capa },
    { properties: { page: { size: { width: 11906, height: 16838 }, margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
      footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
        children: [new TextRun({ text: 'CadastroEE – DGT2811   |   ', size: 16, color: '888888' }), new TextRun({ children: [PageNumber.CURRENT], size: 16, color: '888888' })] })] }) },
      children: corpo },
  ],
});

Packer.toBuffer(doc).then(b => {
  const out = path.join(__dirname, 'Relatorio-CadastroEE.docx');
  fs.writeFileSync(out, b);
  console.log('gerado:', out, b.length, 'bytes; figuras:', nFig);
});
