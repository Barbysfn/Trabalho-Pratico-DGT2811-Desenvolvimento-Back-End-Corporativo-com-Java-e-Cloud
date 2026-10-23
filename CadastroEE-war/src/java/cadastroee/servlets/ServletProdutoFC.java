package cadastroee.servlets;

import cadastroee.controller.ProdutoFacadeLocal;
import cadastroee.model.Produto;
import java.io.IOException;
import jakarta.ejb.EJB;
import jakarta.ejb.EJBException;
import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Front Controller do cadastro de produtos.
 *
 * Toda requisição passa por este Servlet, que lê o parâmetro "acao",
 * executa a regra de negócio através do EJB (ProdutoFacadeLocal) e
 * encaminha (forward) para a JSP de apresentação adequada:
 *   - formIncluir / formAlterar -> ProdutoDados.jsp
 *   - listar / incluir / alterar / excluir -> ProdutoLista.jsp
 */
@WebServlet(name = "ServletProdutoFC", urlPatterns = {"/ServletProdutoFC"})
public class ServletProdutoFC extends HttpServlet {

    @EJB
    ProdutoFacadeLocal facade;

    protected void processRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String acao = request.getParameter("acao");
        if (acao == null || acao.isEmpty()) {
            acao = "listar";
        }

        String destino = ("formAlterar".equals(acao) || "formIncluir".equals(acao))
                ? "ProdutoDados.jsp"
                : "ProdutoLista.jsp";

        try {
            switch (acao) {
                case "listar":
                    request.setAttribute("lista", facade.findAll());
                    break;

                case "formAlterar": {
                    Integer id = Integer.valueOf(request.getParameter("id"));
                    request.setAttribute("produto", facade.find(id));
                    break;
                }

                case "formIncluir":
                    // formulário vazio: nenhuma entidade é enviada
                    break;

                case "excluir": {
                    Integer id = Integer.valueOf(request.getParameter("id"));
                    Produto produto = facade.find(id);
                    if (produto != null) {
                        facade.remove(produto);
                    }
                    request.setAttribute("lista", facade.findAll());
                    break;
                }

                case "alterar": {
                    Integer id = Integer.valueOf(request.getParameter("id"));
                    Produto produto = facade.find(id);
                    preencher(produto, request);
                    facade.edit(produto);
                    request.setAttribute("lista", facade.findAll());
                    break;
                }

                case "incluir": {
                    Produto produto = new Produto();
                    preencher(produto, request);
                    facade.create(produto);
                    request.setAttribute("lista", facade.findAll());
                    break;
                }

                default:
                    request.setAttribute("lista", facade.findAll());
            }
        } catch (EJBException e) {
            // ex.: excluir um produto que possui movimentos (chave estrangeira)
            request.setAttribute("erro", "Não foi possível concluir a operação \"" + acao
                    + "\". Verifique se o produto não possui movimentos associados.");
            request.setAttribute("lista", facade.findAll());
            destino = "ProdutoLista.jsp";
        } catch (NumberFormatException e) {
            request.setAttribute("erro", "Valor numérico inválido: " + e.getMessage());
            request.setAttribute("lista", facade.findAll());
            destino = "ProdutoLista.jsp";
        }

        RequestDispatcher rd = request.getRequestDispatcher(destino);
        rd.forward(request, response);
    }

    /** Copia nome, quantidade e preço de venda do request para a entidade. */
    private void preencher(Produto produto, HttpServletRequest request) {
        produto.setNome(request.getParameter("nome").trim());
        produto.setQuantidade(Integer.parseInt(request.getParameter("quantidade").trim()));
        produto.setPrecoVenda(Float.valueOf(request.getParameter("precoVenda").trim().replace(",", ".")));
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        processRequest(request, response);
    }

    @Override
    public String getServletInfo() {
        return "Front Controller do cadastro de produtos";
    }

}
