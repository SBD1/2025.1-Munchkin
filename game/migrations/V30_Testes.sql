-- =====================================================
-- Migration V30: Teste de Validação de Slots de Itens
-- Projeto: Munchkin - Banco de Dados  
-- Objetivo: Simular cenário de teste para validar regras de slot único
-- Data: 2025-07-07
-- Autor: Sistema de Testes Automatizados
-- =====================================================
-- DEPENDÊNCIAS OBRIGATÓRIAS:
-- ✅ V1  - Tabelas principais (jogador, partida, carta)
-- ✅ V2  - Tabela carta_partida 
-- ✅ V3  - Tabela carta_item (slots, bônus)
-- ✅ V12 - Function insert_munchkin_jogador()
-- ✅ V24 - Function iniciar_partida_segura()
-- ✅ V25 - Triggers de validação de slots + mover_carta_zona_seguro()

DO $$
DECLARE
    v_id_jogador INTEGER;
    v_id_partida INTEGER;
    v_status TEXT;
    v_resultado RECORD;
BEGIN
    -- Etapa 1: Criar jogador
    INSERT INTO jogador (nome)
    VALUES ('TesteLimiteSlot')
    RETURNING id_jogador INTO v_id_jogador;

    RAISE NOTICE '🎮 Jogador criado: ID = %', v_id_jogador;

    -- Etapa 2: Iniciar partida segura (corrigido como em Python)
    SELECT p_id_partida, p_status 
    INTO v_id_partida, v_status
    FROM iniciar_partida_segura(v_id_jogador);

    RAISE NOTICE '🕹️ Partida iniciada. ID = %, Status = %', v_id_partida, v_status;

    -- Etapa 3: Inserir cartas com mesmo slot
    INSERT INTO carta (id_carta, nome, tipo_carta, subtipo, disponivel_para_virar)
    VALUES 
    (1001, 'Capacete do Caos', 'tesouro', 'item', TRUE),
    (1002, 'Touca do Troll', 'tesouro', 'item', TRUE),
    (1003, 'Capuz da Invisibilidade', 'tesouro', 'item', TRUE);

    INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
    VALUES 
    (1001, 2, 400, 'armadura', 'cabeca', FALSE),
    (1002, 3, 500, 'armadura', 'cabeca', FALSE),
    (1003, 4, 600, 'armadura', 'cabeca', FALSE);

    -- Etapa 4: Inserir cartas na mão
    PERFORM set_config('app.criacao_partida_autorizada', 'true', true);

    INSERT INTO carta_partida (id_partida, id_carta, zona)
    VALUES 
    (v_id_partida, 1001, 'mao'),
    (v_id_partida, 1002, 'mao'),
    (v_id_partida, 1003, 'mao');

    PERFORM set_config('app.criacao_partida_autorizada', '', true);

    -- Etapa 5: Tentar equipar itens (1 deve passar, 2 devem falhar)
    RAISE NOTICE '🔧 Equipando Capacete do Caos (ID: 1001)';
    BEGIN
        CALL mover_carta_zona_seguro(v_id_partida, 1001, 'equipado');
        RAISE NOTICE '✅ Sucesso: Capacete equipado!';
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE '❌ Erro inesperado: %', SQLERRM;
    END;

    RAISE NOTICE '🔧 Tentando Touca do Troll (ID: 1002)';
    BEGIN
        CALL mover_carta_zona_seguro(v_id_partida, 1002, 'equipado');
        RAISE NOTICE '❌ ERRO: Touca foi equipada (não deveria)';
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE '✅ Bloqueio correto: %', SQLERRM;
    END;

    RAISE NOTICE '🔧 Tentando Capuz da Invisibilidade (ID: 1003)';
    BEGIN
        CALL mover_carta_zona_seguro(v_id_partida, 1003, 'equipado');
        RAISE NOTICE '❌ ERRO: Capuz foi equipado (não deveria)';
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE '✅ Bloqueio correto: %', SQLERRM;
    END;

    -- Etapa 6: Validar quantidade de itens equipados
    SELECT COUNT(*) INTO v_resultado
    FROM carta_partida cp
    JOIN carta_item ci ON cp.id_carta = ci.id_carta
    WHERE cp.id_partida = v_id_partida
      AND cp.zona = 'equipado'
      AND ci.slot = 'cabeca';

    RAISE NOTICE '📊 Total de itens no slot cabeça: %', v_resultado.count;
    IF v_resultado.count = 1 THEN
        RAISE NOTICE '🎉 Teste passou!';
    ELSE
        RAISE NOTICE '💥 Teste falhou! Esperado 1, encontrado %', v_resultado.count;
    END IF;

    -- Etapa 7: Detalhar cartas
    RAISE NOTICE '📋 Cartas e zonas:';
    FOR v_resultado IN 
        SELECT c.nome, cp.zona, ci.slot, ci.bonus_combate
        FROM carta_partida cp
        JOIN carta c ON cp.id_carta = c.id_carta
        LEFT JOIN carta_item ci ON c.id_carta = ci.id_carta
        WHERE cp.id_partida = v_id_partida
          AND c.id_carta IN (1001, 1002, 1003)
        ORDER BY cp.zona, c.nome
    LOOP
        RAISE NOTICE '   - % | Zona=% | Slot=% | Bônus=%', 
            v_resultado.nome, v_resultado.zona, v_resultado.slot, v_resultado.bonus_combate;
    END LOOP;

    -- Etapa 8: (Opcional) Limpar
    /*
    DELETE FROM carta_partida WHERE id_partida = v_id_partida;
    DELETE FROM partida WHERE id_partida = v_id_partida;
    DELETE FROM jogador WHERE id_jogador = v_id_jogador;
    DELETE FROM carta_item WHERE id_carta IN (1001, 1002, 1003);
    DELETE FROM carta WHERE id_carta IN (1001, 1002, 1003);
    RAISE NOTICE '🧹 Dados de teste removidos';
    */

    RAISE NOTICE '✅ Fim do teste de slot de itens.';
END $$;