-- Função para bloquear update direto da zona
CREATE OR REPLACE FUNCTION bloquear_update_zona()
RETURNS TRIGGER AS $$
BEGIN
  -- Se a zona foi alterada manualmente
  IF NEW.zona IS DISTINCT FROM OLD.zona THEN
    -- Permitir apenas se estiver dentro de uma function segura
    IF current_setting('app.mudanca_zona_autorizada', true) = 'true' THEN
      RETURN NEW;
    END IF;

    -- Bloquear operação não autorizada
    RAISE EXCEPTION 'Atualização da zona não permitida diretamente! Use a procedure segura para movimentar cartas.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para proteger update na zona
CREATE TRIGGER trigger_bloquear_update_zona
BEFORE UPDATE ON carta_partida
FOR EACH ROW
EXECUTE FUNCTION bloquear_update_zona();

-- =====================================================
-- Procedure segura para movimentar cartas entre zonas
-- Projeto: Munchkin - Banco de Dados
-- Objetivo: Permitir alteração da zona apenas via procedimento controlado
-- Data: 2025-07-07
-- =====================================================

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

-- ===============================================
-- Function: validar_limite_slot_equipado()
-- Projeto: Munchkin - Banco de Dados
-- Objetivo: Impedir múltiplos itens equipados no mesmo slot
-- ===============================================
CREATE OR REPLACE FUNCTION validar_limite_slot_equipado()
RETURNS TRIGGER AS $$
DECLARE
    v_id_partida INTEGER := NEW.id_partida;
    v_id_carta INTEGER := NEW.id_carta;
    v_slot VARCHAR(20);
    v_ocupacao_dupla BOOLEAN;
    v_subtipo carta.subtipo%TYPE;
    v_conflito INTEGER;
BEGIN
    -- Só valida se estiver sendo equipado
    IF NEW.zona != 'equipado' THEN
        RETURN NEW;
    END IF;

    -- Obter slot e ocupação da carta
    SELECT ci.slot, ci.ocupacao_dupla, c.subtipo
    INTO v_slot, v_ocupacao_dupla, v_subtipo
    FROM carta_item ci
    JOIN carta c ON c.id_carta = ci.id_carta
    WHERE ci.id_carta = v_id_carta;

    -- Só aplica a regra para cartas de subtipo item
    IF v_subtipo != 'item' THEN
        RETURN NEW;
    END IF;

    -- Contar quantas outras cartas já equipadas usam o mesmo slot
    SELECT COUNT(*) INTO v_conflito
    FROM carta_partida cp
    JOIN carta_item ci ON ci.id_carta = cp.id_carta
    JOIN carta c ON c.id_carta = cp.id_carta
    WHERE cp.id_partida = v_id_partida
      AND cp.zona = 'equipado'
      AND ci.slot = v_slot
      AND cp.id_carta != v_id_carta;

    -- Se já houver outra carta no mesmo slot, e não for permitido ocupar duplamente
    IF v_conflito > 0 AND NOT v_ocupacao_dupla THEN
        RAISE EXCEPTION '❌ Não é permitido equipar múltiplos itens no slot "%"! Já existe outro item equipado neste slot.', v_slot;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ===============================================
-- Trigger: trigger_validar_limites_equipados
-- ===============================================
CREATE TRIGGER trigger_validar_limites_equipados
AFTER UPDATE ON carta_partida
FOR EACH ROW
WHEN (OLD.zona IS DISTINCT FROM NEW.zona AND NEW.zona = 'equipado')
EXECUTE FUNCTION validar_limite_slot_equipado();

-- ===============================================
-- Procedure: equipar_carta_segura
-- Projeto: Munchkin - Banco de Dados
-- Objetivo: Equipar uma carta de forma segura, aplicando regras e poderes
-- Data: 2025-07-07 (atualizado)
-- ===============================================

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

-- ===============================================
-- Procedure: desequipar_carta_segura
-- Projeto: Munchkin - Banco de Dados
-- Objetivo: Desequipar uma carta com segurança
-- Data: 2025-07-08
-- ===============================================

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
            RAISE NOTICE '⚠️ O item "%" depende de sua % "%". Será automaticamente desequipado.', v_dependentes.nome, v_subtipo, v_nome;

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