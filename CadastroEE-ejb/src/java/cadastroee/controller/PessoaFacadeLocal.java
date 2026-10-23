package cadastroee.controller;

import cadastroee.model.Pessoa;
import java.util.List;
import jakarta.ejb.Local;

/**
 * Interface local do Session Bean PessoaFacade.
 */
@Local
public interface PessoaFacadeLocal {

    void create(Pessoa pessoa);

    void edit(Pessoa pessoa);

    void remove(Pessoa pessoa);

    Pessoa find(Object id);

    List<Pessoa> findAll();

    List<Pessoa> findRange(int[] range);

    int count();

}
