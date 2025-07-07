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

