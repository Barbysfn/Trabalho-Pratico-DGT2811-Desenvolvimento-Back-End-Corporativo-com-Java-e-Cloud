package cadastroee.controller;

import cadastroee.model.Movimento;
import java.util.List;
import jakarta.ejb.Local;

/**
 * Interface local do Session Bean MovimentoFacade.
 */
@Local
public interface MovimentoFacadeLocal {

    void create(Movimento movimento);

    void edit(Movimento movimento);

    void remove(Movimento movimento);

    Movimento find(Object id);

    List<Movimento> findAll();

    List<Movimento> findRange(int[] range);

    int count();

}
