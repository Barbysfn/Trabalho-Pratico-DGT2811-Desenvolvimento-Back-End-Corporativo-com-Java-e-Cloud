package cadastroee.controller;

import cadastroee.model.PessoaFisica;
import java.util.List;
import jakarta.ejb.Local;

/**
 * Interface local do Session Bean PessoaFisicaFacade.
 */
@Local
public interface PessoaFisicaFacadeLocal {

    void create(PessoaFisica pessoaFisica);

    void edit(PessoaFisica pessoaFisica);

    void remove(PessoaFisica pessoaFisica);

    PessoaFisica find(Object id);

    List<PessoaFisica> findAll();

    List<PessoaFisica> findRange(int[] range);

    int count();

}
