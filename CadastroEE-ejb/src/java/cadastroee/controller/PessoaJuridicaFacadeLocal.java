package cadastroee.controller;

import cadastroee.model.PessoaJuridica;
import java.util.List;
import jakarta.ejb.Local;

/**
 * Interface local do Session Bean PessoaJuridicaFacade.
 */
@Local
public interface PessoaJuridicaFacadeLocal {

    void create(PessoaJuridica pessoaJuridica);

    void edit(PessoaJuridica pessoaJuridica);

    void remove(PessoaJuridica pessoaJuridica);

    PessoaJuridica find(Object id);

    List<PessoaJuridica> findAll();

    List<PessoaJuridica> findRange(int[] range);

    int count();

}
