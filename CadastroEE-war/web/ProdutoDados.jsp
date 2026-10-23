<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="cadastroee.model.Produto"%>
<%@page import="cadastroee.servlets.Html"%>
<%
    Produto produto = (Produto) request.getAttribute("produto");
    String acao = (produto == null) ? "incluir" : "alterar";
%>
<!DOCTYPE html>
<html lang="pt-BR">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Dados do Produto</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
    </head>
    <body class="container">
        <h1 class="mt-3"><%= produto == null ? "Incluir Produto" : "Alterar Produto" %></h1>
        <form class="form" action="ServletProdutoFC" method="post">
            <input type="hidden" name="acao" value="<%= acao %>">
            <% if ("alterar".equals(acao)) { %>
            <input type="hidden" name="id" value="<%= produto.getIdProduto() %>">
            <% } %>
            <div class="mb-3">
                <label class="form-label" for="nome">Nome</label>
                <input class="form-control" type="text" id="nome" name="nome" required
                       value="<%= produto == null ? "" : Html.esc(produto.getNome()) %>">
            </div>
            <div class="mb-3">
                <label class="form-label" for="quantidade">Quantidade</label>
                <input class="form-control" type="number" id="quantidade" name="quantidade" min="0" required
                       value="<%= produto == null ? "" : produto.getQuantidade() %>">
            </div>
            <div class="mb-3">
                <label class="form-label" for="precoVenda">Preço de Venda</label>
                <input class="form-control" type="number" id="precoVenda" name="precoVenda" min="0" step="0.01" required
                       value="<%= produto == null ? "" : String.format(java.util.Locale.US, "%.2f", produto.getPrecoVenda()) %>">
            </div>
            <input class="btn btn-primary" type="submit" value="<%= produto == null ? "Incluir" : "Alterar" %>">
        </form>
    </body>
</html>
