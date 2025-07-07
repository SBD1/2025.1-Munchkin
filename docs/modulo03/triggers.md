## Triggers e Integridade

### Introdução

A utilização de triggers em bancos de dados relacionais representa uma abordagem avançada para automatizar ações e reforçar regras de negócio diretamente no nível do banco. Segundo Elmasri e Navathe, triggers são procedimentos armazenados que são automaticamente executados em resposta a determinados eventos, como inserções, atualizações ou exclusões de dados em tabelas específicas. Este documento apresenta a aplicação de triggers no sistema de gerenciamento de partidas com cartas, demonstrando como elas contribuem para a manutenção da integridade, automação de processos e resposta a eventos críticos, garantindo que o sistema opere de acordo com os padrões e restrições previamente definidos.


-- =====================================================
-- SECTION: PROTEÇÃO DE CRIAÇÃO (INSERT)
-- =====================================================

```sql
-- Função de trigger que impede a inserção direta na tabela 'partida'.
CREATE OR REPLACE FUNCTION bloquear_insert_partida() 
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('app.criacao_partida_autorizada', true) = 'true' THEN
        RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Inserção direta em "partida" não permitida! Use: SELECT * FROM iniciar_partida_segura(id_jogador)';
END;
$$ LANGUAGE plpgsql;

-- Trigger que impede a inserção direta na tabela 'partida'
CREATE TRIGGER trigger_bloquear_insert_partida
    BEFORE INSERT ON partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_insert_partida();

-- Função de trigger para bloquear inserções diretas na tabela 'carta_partida'.
CREATE OR REPLACE FUNCTION bloquear_insert_carta_partida() 
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('app.criacao_partida_autorizada', true) = 'true' OR
       current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Inserção direta em "carta_partida" não permitida! Use functions seguras.';
END;
$$ LANGUAGE plpgsql;

-- Trigger que impede a inserção direta na tabela 'carta_partida'
CREATE TRIGGER trigger_bloquear_insert_carta_partida
    BEFORE INSERT ON carta_partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_insert_carta_partida();

-- Função de trigger para validar a integridade de uma partida recém-criada.
CREATE OR REPLACE FUNCTION validar_integridade_partida() 
RETURNS TRIGGER AS $$
DECLARE
    qtd_cartas INTEGER;
    qtd_porta INTEGER;
    qtd_tesouro INTEGER;
BEGIN
    IF current_setting('app.criacao_partida_autorizada', true) = 'true' THEN
        RETURN NEW;
    END IF;
    
    PERFORM pg_sleep(0.05);
    
    SELECT COUNT(*) INTO qtd_cartas FROM carta_partida cp WHERE cp.id_partida = NEW.id_partida AND cp.zona = 'mao';
    SELECT COUNT(*) INTO qtd_porta FROM carta_partida cp JOIN carta c ON cp.id_carta = c.id_carta WHERE cp.id_partida = NEW.id_partida AND cp.zona = 'mao' AND c.tipo_carta = 'porta';
    SELECT COUNT(*) INTO qtd_tesouro FROM carta_partida cp JOIN carta c ON cp.id_carta = c.id_carta WHERE cp.id_partida = NEW.id_partida AND cp.zona = 'mao' AND c.tipo_carta = 'tesouro';
    
    IF qtd_cartas < 8 THEN
        RAISE EXCEPTION 'Partida % tem apenas % cartas na mão (mínimo: 8)!', NEW.id_partida, qtd_cartas;
    END IF;
    IF qtd_porta < 4 OR qtd_tesouro < 4 THEN
        RAISE EXCEPTION 'Partida % tem distribuição inválida: % porta, % tesouro (mínimo: 4 de cada)!', NEW.id_partida, qtd_porta, qtd_tesouro;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger de constraint para validar a integridade da partida no final da transação.
CREATE CONSTRAINT TRIGGER trigger_validar_integridade_partida
    AFTER INSERT ON partida
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION validar_integridade_partida();
```

-- =====================================================
-- SECTION: PROTEÇÃO DE EXCLUSÃO (DELETE)
-- =====================================================
```sql
-- Função de trigger que bloqueia a exclusão direta de um jogador.
CREATE OR REPLACE FUNCTION bloquear_delete_jogador() 
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'Exclusão direta de jogador não permitida! Use: CALL excluir_jogador_completo(%)', OLD.id_jogador;
END;
$$ LANGUAGE plpgsql;

-- Trigger que impede a exclusão direta de registros da tabela 'jogador'
CREATE TRIGGER trigger_bloquear_delete_jogador
    BEFORE DELETE ON jogador
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_delete_jogador();

-- Função de trigger que bloqueia a exclusão direta de uma partida.
CREATE OR REPLACE FUNCTION bloquear_delete_partida() 
RETURNS TRIGGER AS $$
BEGIN
    IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'Exclusão direta de partida não permitida! Use a procedure de exclusão apropriada.';
END;
$$ LANGUAGE plpgsql;

-- Trigger que impede a exclusão direta de registros da tabela 'partida'
CREATE TRIGGER trigger_bloquear_delete_partida
    BEFORE DELETE ON partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_delete_partida();
```

-- =====================================================
-- SECTION: PROTEÇÃO DE UPDATE DIRETO
-- =====================================================
```sql
-- Function para bloquear UPDATE direto em carta_partida
CREATE OR REPLACE FUNCTION bloquear_update_carta_partida() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se é operação autorizada por functions seguras (V23, V24, V25)
    IF current_setting('app.movimentacao_carta_autorizada', true) = 'true' OR
       current_setting('app.criacao_partida_autorizada', true) = 'true' OR
       current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN NEW; -- Permitir operação autorizada
    END IF;
    
    -- Bloquear UPDATE direto não autorizado
    RAISE EXCEPTION 'UPDATE direto na tabela carta_partida não permitido! Use: SELECT * FROM mover_carta_segura(%, %, ''%'')', 
                   NEW.id_partida, NEW.id_carta, NEW.zona;
END;
$$ LANGUAGE plpgsql;

-- Trigger para impedir UPDATE direto na tabela carta_partida
CREATE TRIGGER trigger_bloquear_update_carta_partida
    BEFORE UPDATE ON carta_partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_update_carta_partida();
```

-- =======================================================
-- SECTION: PROTEÇÃO DE CAMPOS CRÍTICOS DA TABELA PARTIDA
-- =======================================================
```sql
CREATE OR REPLACE FUNCTION bloquear_update_partida_criticos() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se é operação autorizada por functions seguras
    IF current_setting('app.update_partida_autorizado', true) = 'true' OR
       current_setting('app.criacao_partida_autorizada', true) = 'true' OR
       current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN NEW; -- Permitir operação autorizada
    END IF;
    
    -- Verificar quais campos críticos estão sendo alterados
    IF OLD.limite_mao_atual IS DISTINCT FROM NEW.limite_mao_atual THEN
        RAISE EXCEPTION 'UPDATE direto no campo limite_mao_atual não permitido! Use: SELECT * FROM atualizar_limite_mao_seguro(%, %)', NEW.id_partida, NEW.limite_mao_atual;
    END IF;
    
    IF OLD.nivel IS DISTINCT FROM NEW.nivel THEN
        RAISE EXCEPTION 'UPDATE direto no campo nivel não permitido! Use: SELECT * FROM aplicar_bonus_combate_seguro(%, %)', NEW.id_partida, (NEW.nivel - OLD.nivel);
    END IF;
    
    IF OLD.ouro_acumulado IS DISTINCT FROM NEW.ouro_acumulado THEN
        RAISE EXCEPTION 'UPDATE direto no campo ouro_acumulado não permitido! Use: SELECT * FROM processar_venda_segura(%, %)', NEW.id_partida, (NEW.ouro_acumulado - OLD.ouro_acumulado);
    END IF;
    
    -- Se chegou aqui, é um UPDATE em campo não crítico (permitir)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para campos críticos da tabela partida
CREATE TRIGGER trigger_bloquear_update_partida_criticos
    BEFORE UPDATE ON partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_update_partida_criticos();
```

-- =====================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

```sql
COMMENT ON FUNCTION bloquear_insert_partida() IS 'Trigger Function: Impede inserção direta em "partida".';
COMMENT ON FUNCTION bloquear_insert_carta_partida() IS 'Trigger Function: Impede inserção direta em "carta_partida".';
COMMENT ON FUNCTION validar_integridade_partida() IS 'Trigger Function: Valida distribuição de cartas após criação da partida.';
COMMENT ON FUNCTION bloquear_delete_jogador() IS 'Trigger Function: Impede exclusão direta de "jogador".';
COMMENT ON FUNCTION bloquear_delete_partida() IS 'Trigger Function: Impede exclusão direta de "partida".';
COMMENT ON FUNCTION bloquear_update_carta_partida() IS 'Trigger Function: Impede UPDATE direto em "carta_partida"; exige uso de função segura como mover_carta_segura.';
COMMENT ON FUNCTION bloquear_update_partida_criticos() IS 'Trigger Function: Bloqueia alteração direta em campos críticos de "partida" (nível, ouro, limite de mão), recomendando o uso das funções seguras correspondentes.';


```

### Versionamento

| Versão | Data | Modificação | Autor |
| --- | --- | --- | --- |
| 06/07/2025 | Criação do Documento e Organização inicial| [Mylena Mendonça](https://github.com/MylenaTrindade) |
| 06/07/2025 | Continuação do desenvolvimento | [Maria Clara Sena](https://github.com/mclarasenaa) |