## Triggers e Integridade

### Introdução

A utilização de _triggers_ em bancos de dados relacionais representa uma abordagem avançada para automatizar ações e reforçar regras de negócio diretamente no nível do banco. Segundo Elmasri e Navathe, _triggers_ são procedimentos armazenados que são automaticamente executados em resposta a determinados eventos, como inserções, atualizações ou exclusões de dados em tabelas específicas.

Este documento apresenta a aplicação de _triggers_ no sistema de gerenciamento de partidas com cartas, demonstrando como elas contribuem para a manutenção da integridade, automação de processos e resposta a eventos críticos, garantindo que o sistema opere de acordo com os padrões e restrições previamente definidos.

---

### 1. Proteção de inserção em partidas e cartas

#### Este trigger serve para impedir inserções diretas nas tabelas partida e carta_partida, garantindo que apenas procedures seguras sejam utilizadas.

<details><summary>Comandos</summary>

    ```sql
        -- Impede inserção direta na tabela 'partida'
        CREATE OR REPLACE FUNCTION bloquear_insert_partida()
        RETURNS TRIGGER AS $$
        BEGIN
            IF current_setting('app.criacao_partida_autorizada', true) = 'true' THEN
                RETURN NEW;
            END IF;
            RAISE EXCEPTION 'Inserção direta em "partida" não permitida! Use: SELECT * FROM iniciar_partida_segura(id_jogador)';
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_bloquear_insert_partida
            BEFORE INSERT ON partida
            FOR EACH ROW
            EXECUTE FUNCTION bloquear_insert_partida();

        -- Impede inserção direta na tabela 'carta_partida'
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

        CREATE TRIGGER trigger_bloquear_insert_carta_partida
            BEFORE INSERT ON carta_partida
            FOR EACH ROW
            EXECUTE FUNCTION bloquear_insert_carta_partida();
    ```

</details>

### 2. Validação de integridade da partida

#### Este trigger serve para verificar se uma partida foi criada corretamente com 14 cartas (7 porta + 7 tesouro) na mão do jogador.

<details><summary>Comandos</summary>

    ```sql
        -- Valida quantidade e tipo de cartas na mão ao criar uma partida
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

            SELECT COUNT(*) INTO qtd_cartas
            FROM carta_partida WHERE id_partida = NEW.id_partida AND zona = 'mao';

            SELECT COUNT(*) INTO qtd_porta
            FROM carta_partida cp
            JOIN carta c ON c.id_carta = cp.id_carta
            WHERE cp.id_partida = NEW.id_partida AND cp.zona = 'mao' AND c.tipo_carta = 'porta';

            SELECT COUNT(*) INTO qtd_tesouro
            FROM carta_partida cp
            JOIN carta c ON c.id_carta = cp.id_carta
            WHERE cp.id_partida = NEW.id_partida AND cp.zona = 'mao' AND c.tipo_carta = 'tesouro';

            IF qtd_cartas < 14 THEN
                RAISE EXCEPTION 'Partida % tem apenas % cartas na mão (mínimo: 14)!', NEW.id_partida, qtd_cartas;
            END IF;

            IF qtd_porta < 7 OR qtd_tesouro < 7 THEN
                RAISE EXCEPTION 'Distribuição inválida: % porta, % tesouro (mínimo: 7 de cada)', NEW.id_partida, qtd_porta, qtd_tesouro;
            END IF;

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE CONSTRAINT TRIGGER trigger_validar_integridade_partida
            AFTER INSERT ON partida
            DEFERRABLE INITIALLY DEFERRED
            FOR EACH ROW
            EXECUTE FUNCTION validar_integridade_partida();
    ```

</details>

### 3. Bloqueio de exclusões diretas

#### Este trigger serve para impedir exclusões diretas de jogadores e partidas, garantindo que apenas procedures seguras sejam utilizadas.

<details><summary>Comandos</summary>

    ```sql
        -- Impede exclusão direta de jogador
        CREATE OR REPLACE FUNCTION bloquear_delete_jogador()
        RETURNS TRIGGER AS $$
        BEGIN
            IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
                RETURN OLD;
            END IF;
            RAISE EXCEPTION 'Exclusão direta de jogador não permitida! Use: CALL excluir_jogador_completo(%)', OLD.id_jogador;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_bloquear_delete_jogador
            BEFORE DELETE ON jogador
            FOR EACH ROW
            EXECUTE FUNCTION bloquear_delete_jogador();

        -- Impede exclusão direta de partida
        CREATE OR REPLACE FUNCTION bloquear_delete_partida()
        RETURNS TRIGGER AS $$
        BEGIN
            IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
                RETURN OLD;
            END IF;
            RAISE EXCEPTION 'Exclusão direta de partida não permitida!';
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_bloquear_delete_partida
            BEFORE DELETE ON partida
            FOR EACH ROW
            EXECUTE FUNCTION bloquear_delete_partida();
    ```

</details>

### 4. Bloqueio de atualização direta de zona

#### Este trigger serve para impedir alterações diretas na zona das cartas, garantindo que movimentações sejam feitas apenas via procedures seguras.

<details><summary>Comandos</summary>

    ```sql
        -- Impede alteração direta da zona de uma carta
        CREATE OR REPLACE FUNCTION bloquear_update_zona()
        RETURNS TRIGGER AS $$
        BEGIN
            IF NEW.zona IS DISTINCT FROM OLD.zona THEN
                IF current_setting('app.mudanca_zona_autorizada', true) = 'true' THEN
                    RETURN NEW;
                END IF;
                RAISE EXCEPTION 'Atualização da zona não permitida diretamente! Use procedure segura.';
            END IF;
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_bloquear_update_zona
            BEFORE UPDATE ON carta_partida
            FOR EACH ROW
            EXECUTE FUNCTION bloquear_update_zona();
    ```

</details>

### 5. Validação de slots equipados

#### Este trigger serve para validar se múltiplos itens podem ser equipados no mesmo slot, impedindo conflitos de equipamento.

<details><summary>Comandos</summary>

    ```sql
        -- Impede múltiplos itens equipados no mesmo slot
        CREATE OR REPLACE FUNCTION validar_limite_slot_equipado()
        RETURNS TRIGGER AS $$
        DECLARE
            v_slot VARCHAR(20);
            v_ocupacao_dupla BOOLEAN;
            v_subtipo carta.subtipo%TYPE;
            v_conflito INTEGER;
        BEGIN
            IF NEW.zona != 'equipado' THEN
                RETURN NEW;
            END IF;

            SELECT ci.slot, ci.ocupacao_dupla, c.subtipo
            INTO v_slot, v_ocupacao_dupla, v_subtipo
            FROM carta_item ci
            JOIN carta c ON c.id_carta = ci.id_carta
            WHERE ci.id_carta = NEW.id_carta;

            IF v_subtipo != 'item' THEN
                RETURN NEW;
            END IF;

            SELECT COUNT(*) INTO v_conflito
            FROM carta_partida cp
            JOIN carta_item ci ON ci.id_carta = cp.id_carta
            JOIN carta c ON c.id_carta = cp.id_carta
            WHERE cp.id_partida = NEW.id_partida
              AND cp.zona = 'equipado'
              AND ci.slot = v_slot
              AND cp.id_carta != NEW.id_carta;

            IF v_conflito > 0 AND NOT v_ocupacao_dupla THEN
                RAISE EXCEPTION '❌ Slot "%": já existe item equipado.', v_slot;
            END IF;

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trigger_validar_limites_equipados
        AFTER UPDATE ON carta_partida
        FOR EACH ROW
        WHEN (OLD.zona IS DISTINCT FROM NEW.zona AND NEW.zona = 'equipado')
        EXECUTE FUNCTION validar_limite_slot_equipado();
    ```

</details>

### Referência Bibliográfica

> [1] ELMASRI, Ramez; NAVATHE, Shamkant B. _Sistemas de banco de dados_. 6. ed. São Paulo: Pearson Addison Wesley, 2011.

---

### Versionamento

| Versão | Data       | Modificação                          | Autor(es)              |
| ------ | ---------- | ------------------------------------ | ---------------------- |
| 0.1    | 06/07/2025 | Criação do Documento e triggers      | Mylena Mendonça        |
| 1.0    | 06/07/2025 | Continuação do desenvolvimento       | Maria Clara Sena       |
| 1.1    | 07/07/2025 | Padronização e ajustes de formatação | Breno Soares Fernandes |
