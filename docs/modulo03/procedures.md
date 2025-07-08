## Stored Procedures (DML & DCL)

### Introdução

As Stored Procedures são blocos de código SQL armazenados no banco de dados que encapsulam lógicas complexas e promovem segurança, reutilização e desempenho. Segundo Elmasri e Navathe, elas são fundamentais para padronizar o acesso aos dados, aplicar regras de negócio de forma centralizada e reduzir a duplicação de comandos SQL.

Este documento apresenta as principais procedures e functions do sistema Munchkin, organizadas por categoria funcional. Cada bloco de código está documentado com comentários explicativos, e as operações são protegidas por variáveis de sessão que garantem a integridade das transações.

---

### 1. Criar partida segura

#### Este stored procedure serve para iniciar uma nova partida distribuindo automaticamente 14 cartas (7 porta + 7 tesouro) para a mão do jogador.

<details><summary>Comandos</summary>

    ```sql
        -- Function segura para iniciar uma partida.
        -- Distribui exatamente 14 cartas (7 porta + 7 tesouro) para a mão do jogador.
        -- Retorna: (id_partida, status da operação)
        CREATE OR REPLACE FUNCTION iniciar_partida_segura(p_id_jogador INTEGER)
        RETURNS TABLE(p_id_partida INTEGER, p_status VARCHAR(50))
        LANGUAGE plpgsql AS $$
        DECLARE
            partida_existente INTEGER;
            carta_record RECORD;
            contador_cartas INTEGER := 0;
            cartas_porta INTEGER := 0;
            cartas_tesouro INTEGER := 0;
            nova_partida_id INTEGER;
            resultado_status VARCHAR(50);
        BEGIN
            -- Verifica se o jogador existe
            IF NOT EXISTS (SELECT 1 FROM jogador WHERE id_jogador = p_id_jogador) THEN
                RAISE EXCEPTION 'Jogador com ID % não encontrado!', p_id_jogador;
            END IF;

            -- Verifica se já há partida em andamento
            SELECT id_partida INTO partida_existente
            FROM partida
            WHERE id_jogador = p_id_jogador AND estado_partida = 'em andamento';

            IF partida_existente IS NOT NULL THEN
                nova_partida_id := partida_existente;
                resultado_status := 'PARTIDA_EXISTENTE';
                p_id_partida := nova_partida_id;
                p_status := resultado_status;
                RETURN NEXT;
                RETURN;
            END IF;

            -- Verifica disponibilidade de cartas
            SELECT COUNT(*) INTO cartas_porta
            FROM carta WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE;

            SELECT COUNT(*) INTO cartas_tesouro
            FROM carta WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE;

            IF cartas_porta < 7 OR cartas_tesouro < 7 THEN
                RAISE EXCEPTION 'Cartas insuficientes! Disponível: % porta, % tesouro (mínimo: 7 de cada)',
                                cartas_porta, cartas_tesouro;
            END IF;

            -- Autoriza criação controlada
            PERFORM set_config('app.criacao_partida_autorizada', 'true', true);

            -- Cria nova partida
            INSERT INTO partida (id_jogador, data_inicio, estado_partida, vida_restantes)
            VALUES (p_id_jogador, NOW(), 'em andamento', 3)
            RETURNING id_partida INTO nova_partida_id;

            -- Distribui 7 cartas do tipo porta
            FOR carta_record IN (
                SELECT id_carta FROM carta
                WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE
                ORDER BY RANDOM() LIMIT 7
            ) LOOP
                INSERT INTO carta_partida (id_partida, id_carta, zona)
                VALUES (nova_partida_id, carta_record.id_carta, 'mao');
                contador_cartas := contador_cartas + 1;
            END LOOP;

            -- Distribui 7 cartas do tipo tesouro
            FOR carta_record IN (
                SELECT id_carta FROM carta
                WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE
                ORDER BY RANDOM() LIMIT 7
            ) LOOP
                INSERT INTO carta_partida (id_partida, id_carta, zona)
                VALUES (nova_partida_id, carta_record.id_carta, 'mao');
                contador_cartas := contador_cartas + 1;
            END LOOP;

            -- Verificação de segurança
            IF contador_cartas != 14 THEN
                RAISE EXCEPTION 'Erro crítico na distribuição: esperado 14 cartas, recebido %', contador_cartas;
            END IF;

            -- Limpa variável de controle
            PERFORM set_config('app.criacao_partida_autorizada', '', true);

            -- Retorna resultado
            p_id_partida := nova_partida_id;
            p_status := 'NOVA_PARTIDA_CRIADA';
            RETURN NEXT;
        END;
        $$;

        COMMENT ON FUNCTION iniciar_partida_segura(INTEGER) IS
        'Inicia partida com 14 cartas (7 porta + 7 tesouro), verificando integridade e protegendo via variável de sessão.';
    ```

</details>

### 2. Excluir jogador completo

#### Este stored procedure serve para remover um jogador e todos os seus dados vinculados (partidas, cartas, combates) do sistema.

<details><summary>Comandos</summary>

    ```sql
        -- Procedure para exclusão total de um jogador e seus dados vinculados.
        CREATE OR REPLACE PROCEDURE excluir_jogador_completo(p_id_jogador INTEGER)
        LANGUAGE plpgsql AS $$
        DECLARE
            partida_record RECORD;
        BEGIN
            -- Verifica existência
            IF NOT EXISTS (SELECT 1 FROM jogador WHERE id_jogador = p_id_jogador) THEN
                RAISE EXCEPTION 'Jogador com ID % não encontrado!', p_id_jogador;
            END IF;

            -- Autoriza exclusão
            PERFORM set_config('app.exclusao_autorizada', 'true', true);

            FOR partida_record IN SELECT id_partida FROM partida WHERE id_jogador = p_id_jogador LOOP
                DELETE FROM uso_poder_venda WHERE id_partida = partida_record.id_partida;
                DELETE FROM combate WHERE id_partida = partida_record.id_partida;
                DELETE FROM carta_partida WHERE id_partida = partida_record.id_partida;
                DELETE FROM partida WHERE id_partida = partida_record.id_partida;
            END LOOP;

            DELETE FROM jogador WHERE id_jogador = p_id_jogador;

            PERFORM set_config('app.exclusao_autorizada', '', true);
        END;
        $$;

        COMMENT ON PROCEDURE excluir_jogador_completo(INTEGER) IS
        'Remove um jogador e todas as suas partidas, cartas e combates associados.';
    ```

</details>

### 3. Excluir partidas do jogador

#### Este stored procedure serve para remover apenas as partidas de um jogador específico, mantendo o cadastro do jogador no sistema.

<details><summary>Comandos</summary>

    ```sql
        -- Procedure que remove apenas as partidas do jogador, preservando seu cadastro.
        CREATE OR REPLACE PROCEDURE excluir_partidas_jogador(p_id_jogador INTEGER)
        LANGUAGE plpgsql AS $$
        DECLARE
            partida_record RECORD;
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM jogador WHERE id_jogador = p_id_jogador) THEN
                RAISE EXCEPTION 'Jogador com ID % não encontrado!', p_id_jogador;
            END IF;

            PERFORM set_config('app.exclusao_autorizada', 'true', true);

            FOR partida_record IN SELECT id_partida FROM partida WHERE id_jogador = p_id_jogador LOOP
                DELETE FROM uso_poder_venda WHERE id_partida = partida_record.id_partida;
                DELETE FROM combate WHERE id_partida = partida_record.id_partida;
                DELETE FROM carta_partida WHERE id_partida = partida_record.id_partida;
                DELETE FROM partida WHERE id_partida = partida_record.id_partida;
            END LOOP;

            PERFORM set_config('app.exclusao_autorizada', '', true);
        END;
        $$;

        COMMENT ON PROCEDURE excluir_partidas_jogador(INTEGER) IS
        'Remove com segurança todas as partidas de um jogador, sem apagar o jogador.';
    ```

</details>

### 4. Movimentar cartas entre zonas

#### Este stored procedure serve para mover uma carta de uma zona para outra (mão, equipado, descartado) de forma segura e controlada.

<details><summary>Comandos</summary>

    ```sql
        -- Procedure segura para movimentar cartas entre zonas
        CREATE OR REPLACE PROCEDURE mover_carta_zona_seguro(
            p_id_partida INTEGER,
            p_id_carta INTEGER,
            p_nova_zona enum_zona
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            existe_carta INTEGER;
        BEGIN
            -- Verificar se a carta pertence à partida fornecida
            SELECT COUNT(*) INTO existe_carta
            FROM carta_partida
            WHERE id_partida = p_id_partida AND id_carta = p_id_carta;

            IF existe_carta = 0 THEN
                RAISE EXCEPTION 'A carta % não pertence à partida %!', p_id_carta, p_id_partida;
            END IF;

            -- Autorizar temporariamente a alteração da zona
            PERFORM set_config('app.mudanca_zona_autorizada', 'true', true);

            -- Alterar a zona com permissão
            UPDATE carta_partida
            SET zona = p_nova_zona
            WHERE id_partida = p_id_partida AND id_carta = p_id_carta;

            -- Limpar a autorização ao final
            PERFORM set_config('app.mudanca_zona_autorizada', '', true);

            RAISE NOTICE '✅ Carta % movida para a zona % com sucesso.', p_id_carta, p_nova_zona;

        EXCEPTION
            WHEN OTHERS THEN
                -- Limpar a permissão em caso de erro
                PERFORM set_config('app.mudanca_zona_autorizada', '', true);
                RAISE EXCEPTION 'Erro ao mover carta %: %', p_id_carta, SQLERRM;
        END;
        $$;

        COMMENT ON PROCEDURE mover_carta_zona_seguro(INTEGER, INTEGER, enum_zona) IS
        'Move uma carta entre zonas dentro de uma partida de forma controlada e segura, validando autorização via variável de sessão.';
    ```

</details>

---

### 5. Equipar carta segura

#### Este stored procedure serve para equipar uma carta aplicando todas as regras do jogo (validação de slots, restrições de raça/classe, bônus automáticos).

<details><summary>Comandos</summary>

    ```sql
        -- Procedure segura para equipar uma carta aplicando regras e poderes
        CREATE OR REPLACE PROCEDURE equipar_carta_segura(
            p_id_partida INTEGER,
            p_id_carta INTEGER
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_subtipo TEXT;
            v_slot TEXT;
            v_bonus_combate INTEGER;
            v_limite_mao INTEGER;
            v_ocupacao_dupla BOOLEAN;
            v_tipo_alvo TEXT;
            v_valor_alvo TEXT;
            v_permitido BOOLEAN;
            v_possui_alvo BOOLEAN;
            v_conflito INTEGER;
            restr RECORD;
        BEGIN
            -- Obter subtipo da carta
            SELECT subtipo INTO v_subtipo
            FROM carta
            WHERE id_carta = p_id_carta;

            -- Impedir equipar monstro
            IF v_subtipo = 'monstro' THEN
                RAISE EXCEPTION '❌ Você não pode equipar cartas do tipo MONSTRO.';
            END IF;

            -- Impedir múltiplas raças
            IF v_subtipo = 'raca' THEN
                IF EXISTS (
                    SELECT 1
                    FROM carta_partida cp
                    JOIN carta c ON c.id_carta = cp.id_carta
                    WHERE cp.id_partida = p_id_partida
                      AND cp.zona = 'equipado'
                      AND c.subtipo = 'raca'
                ) THEN
                    RAISE EXCEPTION '❌ Você já tem uma raça equipada. Desequipe-a antes de equipar outra.';
                END IF;
            END IF;

            -- Impedir múltiplas classes
            IF v_subtipo = 'classe' THEN
                IF EXISTS (
                    SELECT 1
                    FROM carta_partida cp
                    JOIN carta c ON c.id_carta = cp.id_carta
                    WHERE cp.id_partida = p_id_partida
                      AND cp.zona = 'equipado'
                      AND c.subtipo = 'classe'
                ) THEN
                    RAISE EXCEPTION '❌ Você já tem uma classe equipada. Desequipe-a antes de equipar outra.';
                END IF;
            END IF;

            -- Caso a carta seja uma raça com poder de limite de mão
            IF v_subtipo = 'raca' THEN
                SELECT pl.limite_cartas_mao INTO v_limite_mao
                FROM poder_raca pr
                JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
                WHERE pr.id_carta = p_id_carta;

                -- Se existir poder, atualiza o limite
                IF v_limite_mao IS NOT NULL THEN
                    UPDATE partida
                    SET limite_mao_atual = v_limite_mao
                    WHERE id_partida = p_id_partida;

                    RAISE NOTICE '🧬 Limite de cartas na mão atualizado para % devido ao poder da raça.', v_limite_mao;
                END IF;
            END IF;

            -- Caso item: verificar restrições e aplicar bônus
            IF v_subtipo = 'item' THEN
                -- Aplicar verificações de restrição
                FOR restr IN
                    SELECT tipo_alvo, valor_alvo, permitido
                    FROM restricao_item
                    WHERE id_carta_item = p_id_carta
                LOOP
                    v_tipo_alvo := restr.tipo_alvo;
                    v_valor_alvo := restr.valor_alvo;
                    v_permitido := restr.permitido;

                    IF v_tipo_alvo = 'classe' THEN
                        SELECT EXISTS (
                            SELECT 1
                            FROM carta_partida cp
                            JOIN carta_classe cc ON cc.id_carta = cp.id_carta
                            WHERE cp.id_partida = p_id_partida AND cp.zona = 'equipado' AND cc.nome_classe = v_valor_alvo
                        ) INTO v_possui_alvo;

                    ELSIF v_tipo_alvo = 'raca' THEN
                        SELECT EXISTS (
                            SELECT 1
                            FROM carta_partida cp
                            JOIN carta_raca cr ON cr.id_carta = cp.id_carta
                            WHERE cp.id_partida = p_id_partida AND cp.zona = 'equipado' AND cr.nome_raca = v_valor_alvo
                        ) INTO v_possui_alvo;
                    END IF;

                    IF v_permitido AND NOT v_possui_alvo THEN
                        RAISE EXCEPTION '❌ Este item só pode ser usado por %: %, e você não está com isso equipado.', v_tipo_alvo, v_valor_alvo;
                    ELSIF NOT v_permitido AND v_possui_alvo THEN
                        RAISE EXCEPTION '❌ Este item não pode ser usado por %: %, e você está com isso equipado.', v_tipo_alvo, v_valor_alvo;
                    END IF;
                END LOOP;

                -- Obter dados do item
                SELECT slot, bonus_combate, ocupacao_dupla INTO v_slot, v_bonus_combate, v_ocupacao_dupla
                FROM carta_item
                WHERE id_carta = p_id_carta;

                -- Validação de slot ocupado
                IF v_slot != 'nenhum' THEN
                    IF v_slot = '2_maos' THEN
                        -- Verifica se já tem qualquer item nas mãos
                        SELECT COUNT(*) INTO v_conflito
                        FROM carta_partida cp
                        JOIN carta_item ci ON ci.id_carta = cp.id_carta
                        WHERE cp.id_partida = p_id_partida AND cp.zona = 'equipado'
                        AND ci.slot IN ('1_mao', '2_maos');

                        IF v_conflito > 0 THEN
                            RAISE EXCEPTION '❌ Você já está usando as mãos. Remova os itens antes de equipar um que ocupa 2 mãos.';
                        END IF;

                    ELSIF v_slot = '1_mao' THEN
                        -- Verifica se já tem um item de 2_maos
                        SELECT COUNT(*) INTO v_conflito
                        FROM carta_partida cp
                        JOIN carta_item ci ON ci.id_carta = cp.id_carta
                        WHERE cp.id_partida = p_id_partida AND cp.zona = 'equipado'
                        AND ci.slot = '2_maos';

                        IF v_conflito > 0 THEN
                            RAISE EXCEPTION '❌ Você já está usando um item que ocupa 2 mãos. Não pode equipar outro nas mãos.';
                        END IF;
                    ELSE
                        -- Verifica se já existe outro item no mesmo slot
                        SELECT COUNT(*) INTO v_conflito
                        FROM carta_partida cp
                        JOIN carta_item ci ON ci.id_carta = cp.id_carta
                        WHERE cp.id_partida = p_id_partida AND cp.zona = 'equipado'
                        AND ci.slot = v_slot;

                        IF v_conflito > 0 AND NOT v_ocupacao_dupla THEN
                            RAISE EXCEPTION '❌ Você já tem um item equipado no slot "%".', v_slot;
                        END IF;
                    END IF;
                END IF;

                -- Aplica bônus de combate
                UPDATE partida
                SET nivel = nivel + v_bonus_combate
                WHERE id_partida = p_id_partida;

                RAISE NOTICE '🪖 Item equipado no slot "%". Bônus de combate +% aplicado.', v_slot, v_bonus_combate;
            END IF;

            -- Mover para a zona "equipado" com segurança
            CALL mover_carta_zona_seguro(p_id_partida, p_id_carta, 'equipado');

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION '❌ Erro ao equipar carta %: %', p_id_carta, SQLERRM;
        END;
        $$;

        COMMENT ON PROCEDURE equipar_carta_segura(INTEGER, INTEGER) IS
        'Equipa uma carta validando todas as regras do jogo (raça/classe única, restrições de item, slots) e aplicando efeitos automaticamente.';
    ```

</details>

---

### 6. Desequipar carta segura

#### Este stored procedure serve para desequipar uma carta removendo seus efeitos e gerenciando itens dependentes automaticamente.

<details><summary>Comandos</summary>

    ```sql
        -- Procedure segura para desequipar uma carta removendo efeitos
        CREATE OR REPLACE PROCEDURE desequipar_carta_segura(
            p_id_partida INTEGER,
            p_id_carta INTEGER
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_subtipo TEXT;
            v_nome TEXT;
            v_bonus_combate INTEGER;
            v_dependentes RECORD;
        BEGIN
            -- Verificar se a carta está realmente equipada
            IF NOT EXISTS (
                SELECT 1
                FROM carta_partida
                WHERE id_partida = p_id_partida AND id_carta = p_id_carta AND zona = 'equipado'
            ) THEN
                RAISE EXCEPTION '❌ Esta carta não está equipada.';
            END IF;

            -- Obter subtipo e nome para mensagens
            SELECT subtipo, nome INTO v_subtipo, v_nome
            FROM carta
            WHERE id_carta = p_id_carta;

            -- Se for raça ou classe, verificar dependência de itens
            IF v_subtipo IN ('raca', 'classe') THEN
                FOR v_dependentes IN
                    SELECT ci.id_carta AS id_item, c.nome
                    FROM carta_partida cp
                    JOIN carta_item ci ON ci.id_carta = cp.id_carta
                    JOIN restricao_item ri ON ri.id_carta_item = ci.id_carta
                    JOIN carta c ON c.id_carta = ci.id_carta
                    WHERE cp.id_partida = p_id_partida
                      AND cp.zona = 'equipado'
                      AND ri.tipo_alvo = v_subtipo
                      AND ri.valor_alvo = v_nome
                      AND ri.permitido = true
                LOOP
                    RAISE NOTICE '🧤 O item "%" foi automaticamente desequipado pois depende da sua % "%".', v_dependentes.nome, v_subtipo, v_nome;

                    -- Mover o item dependente para a mão
                    CALL mover_carta_zona_seguro(p_id_partida, v_dependentes.id_item, 'mao');
                END LOOP;
            END IF;

            -- Se for item, remover bônus de combate
            IF v_subtipo = 'item' THEN
                SELECT bonus_combate INTO v_bonus_combate
                FROM carta_item
                WHERE id_carta = p_id_carta;

                UPDATE partida
                SET nivel = nivel - v_bonus_combate
                WHERE id_partida = p_id_partida;

                RAISE NOTICE '🪖 Item "%": bônus de combate -% removido.', v_nome, v_bonus_combate;
            END IF;

            -- Mover a carta para a mão
            CALL mover_carta_zona_seguro(p_id_partida, p_id_carta, 'mao');

            RAISE NOTICE '✅ Carta "%" foi movida de EQUIPADO para MÃO.', v_nome;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION '❌ Erro ao desequipar carta %: %', p_id_carta, SQLERRM;
        END;
        $$;

        COMMENT ON PROCEDURE desequipar_carta_segura(INTEGER, INTEGER) IS
        'Desequipa uma carta removendo seus efeitos e gerenciando dependências de itens que requerem raça/classe específica.';
    ```

</details>

### Referência Bibliográfica

> [1] ELMASRI, Ramez; NAVATHE, Shamkant B. _Sistemas de banco de dados_. 6. ed. São Paulo: Pearson Addison Wesley, 2011.

---

### Versionamento

| Versão | Data       | Modificação                       | Autor(es)              |
| ------ | ---------- | --------------------------------- | ---------------------- |
| 0.1    | 06/07/2025 | Criação do Documento e Procedures | Mylena Mendonça        |
| 1.0    | 06/07/2025 | Organização e adaptação final     | Maria Clara Sena       |
| 1.1    | 07/07/2025 | Ajustes na formatação geral       | Breno Soares Fernandes |
