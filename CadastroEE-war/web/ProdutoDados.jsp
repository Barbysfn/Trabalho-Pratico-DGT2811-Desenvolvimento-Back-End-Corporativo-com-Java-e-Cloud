<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="cadastroee.model.Produto"%>
<%@page import="cadastroee.servlets.Html"%>
<%
    Produto produto = (Produto) request.getAttribute("produto");
    String acao = (produto == null) ? "incluir" : "alterar";
%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Dados do Produto</title>
    </head>
    <body>
        <h1><%= produto == null ? "Incluir Produto" : "Alterar Produto" %></h1>
        <form action="ServletProdutoFC" method="post">
            <input type="hidden" name="acao" value="<%= acao %>">
            <% if ("alterar".equals(acao)) { %>
            <input type="hidden" name="id" value="<%= produto.getIdProduto() %>">
            <% } %>
            <p>
                <label for="nome">Nome:</label>
                <input type="text" id="nome" name="nome" required
                       value="<%= produto == null ? "" : Html.esc(produto.getNome()) %>">
            </p>
            <p>
                <label for="quantidade">Quantidade:</label>
                <input type="number" id="quantidade" name="quantidade" min="0" required
                       value="<%= produto == null ? "" : produto.getQuantidade() %>">
            </p>
            <p>
                <label for="precoVenda">Preço de Venda:</label>
                <input type="number" id="precoVenda" name="precoVenda" min="0" step="0.01" required
                       value="<%= produto == null ? "" : String.format(java.util.Locale.US, "%.2f", produto.getPrecoVenda()) %>">
            </p>
            <input type="submit" value="<%= produto == null ? "Incluir" : "Alterar" %>">
        </form>
    </body>
</html>
