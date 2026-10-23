<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="cadastroee.model.Produto"%>
<%@page import="cadastroee.servlets.Html"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Listagem de Produtos</title>
    </head>
    <body>
        <h1>Listagem de Produtos</h1>
        <a href="ServletProdutoFC?acao=formIncluir">Novo Produto</a>
        <% String erro = (String) request.getAttribute("erro");
           if (erro != null) { %>
        <p style="color: red;"><%= Html.esc(erro) %></p>
        <% } %>
        <table border="1">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Nome</th>
                    <th>Quantidade</th>
                    <th>Preço de Venda</th>
                    <th>Opções</th>
                </tr>
            </thead>
            <tbody>
                <%
                    List<Produto> lista = (List<Produto>) request.getAttribute("lista");
                    if (lista != null) {
                        for (Produto produto : lista) {
                %>
                <tr>
                    <td><%= produto.getIdProduto() %></td>
                    <td><%= Html.esc(produto.getNome()) %></td>
                    <td><%= produto.getQuantidade() %></td>
                    <td><%= String.format("%.2f", produto.getPrecoVenda()) %></td>
                    <td>
                        <a href="ServletProdutoFC?acao=formAlterar&id=<%= produto.getIdProduto() %>">Alterar</a>
                        <a href="ServletProdutoFC?acao=excluir&id=<%= produto.getIdProduto() %>">Excluir</a>
                    </td>
                </tr>
                <%
                        }
                    }
                %>
            </tbody>
        </table>
    </body>
</html>
