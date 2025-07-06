-- =====================================================
-- Migration V23: Procedures para Exclusão de Jogador e Partidas
-- Projeto: Munchkin - Banco de Dados
-- Objetivo: Garantir exclusão segura de jogadores e partidas com integridade referencial
-- Data: 2025-01-06
-- =====================================================

-- =====================================================
-- STORED PROCEDURES PARA OPERAÇÕES SEGURAS
-- =====================================================

-- Procedure para exclusão segura de jogador
-- Remove todas as dependências hierárquicas antes de excluir o jogador
CREATE OR REPLACE PROCEDURE excluir_jogador_completo(p_id_jogador INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    partida_record RECORD;
    contador_registros INTEGER;
BEGIN
    -- Verificar se o jogador existe
    SELECT COUNT(*) INTO contador_registros 
    FROM jogador WHERE id_jogador = p_id_jogador;
    
    IF contador_registros = 0 THEN
        RAISE EXCEPTION 'Jogador com ID % não encontrado!', p_id_jogador;
    END IF;

    -- Definir variável de sessão para autorizar exclusões
    PERFORM set_config('app.exclusao_autorizada', 'true', true);

    -- Para cada partida do jogador
    FOR partida_record IN 
        SELECT id_partida FROM partida WHERE id_jogador = p_id_jogador
    LOOP
        RAISE NOTICE 'Excluindo dados da partida %...', partida_record.id_partida;
        
        -- 1. Excluir UsoPoderVenda (mais profundo na hierarquia)
        DELETE FROM uso_poder_venda 
        WHERE id_partida = partida_record.id_partida;
        
        -- 2. Excluir Combates
        DELETE FROM combate 
        WHERE id_partida = partida_record.id_partida;
        
        -- 3. Excluir CartaPartida (cartas associadas à partida)
        DELETE FROM carta_partida 
        WHERE id_partida = partida_record.id_partida;
        
        -- 4. Excluir a Partida
        DELETE FROM partida 
        WHERE id_partida = partida_record.id_partida;
    END LOOP;
    
    -- 5. Por último, excluir o Jogador
    DELETE FROM jogador WHERE id_jogador = p_id_jogador;
    
    -- Limpar variável de autorização
    PERFORM set_config('app.exclusao_autorizada', '', true);
    
    RAISE NOTICE 'Jogador % e todos os seus dados foram excluídos com segurança!', p_id_jogador;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Limpar variável de autorização em caso de erro
        PERFORM set_config('app.exclusao_autorizada', '', true);
        RAISE EXCEPTION 'Erro ao excluir jogador %: %', p_id_jogador, SQLERRM;
END;
$$;

-- Procedure para exclusão segura de partidas de um jogador específico
-- Remove apenas as partidas e dados relacionados, mantendo o jogador
CREATE OR REPLACE PROCEDURE excluir_partidas_jogador(p_id_jogador INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    partida_record RECORD;
    contador_registros INTEGER;
    contador_partidas INTEGER;
BEGIN
    -- Verificar se o jogador existe
    SELECT COUNT(*) INTO contador_registros 
    FROM jogador WHERE id_jogador = p_id_jogador;
    
    IF contador_registros = 0 THEN
        RAISE EXCEPTION 'Jogador com ID % não encontrado!', p_id_jogador;
    END IF;

    -- Verificar quantas partidas o jogador possui
    SELECT COUNT(*) INTO contador_partidas 
    FROM partida WHERE id_jogador = p_id_jogador;
    
    IF contador_partidas = 0 THEN
        RAISE NOTICE 'Jogador % não possui partidas para excluir.', p_id_jogador;
        RETURN;
    END IF;

    -- Definir variável de sessão para autorizar exclusões
    PERFORM set_config('app.exclusao_autorizada', 'true', true);

    -- Para cada partida do jogador
    FOR partida_record IN 
        SELECT id_partida FROM partida WHERE id_jogador = p_id_jogador
    LOOP
        RAISE NOTICE 'Excluindo dados da partida %...', partida_record.id_partida;
        
        -- 1. Excluir UsoPoderVenda (mais profundo na hierarquia)
        DELETE FROM uso_poder_venda 
        WHERE id_partida = partida_record.id_partida;
        
        -- 2. Excluir Combates
        DELETE FROM combate 
        WHERE id_partida = partida_record.id_partida;
        
        -- 3. Excluir CartaPartida (cartas associadas à partida)
        DELETE FROM carta_partida 
        WHERE id_partida = partida_record.id_partida;
        
        -- 4. Excluir a Partida
        DELETE FROM partida 
        WHERE id_partida = partida_record.id_partida;
    END LOOP;
    
    -- Limpar variável de autorização
    PERFORM set_config('app.exclusao_autorizada', '', true);
    
    RAISE NOTICE 'Todas as % partidas do jogador % foram excluídas com segurança! Jogador mantido.', contador_partidas, p_id_jogador;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Limpar variável de autorização em caso de erro
        PERFORM set_config('app.exclusao_autorizada', '', true);
        RAISE EXCEPTION 'Erro ao excluir partidas do jogador %: %', p_id_jogador, SQLERRM;
END;
$$;

-- =====================================================
-- FUNCTIONS PARA TRIGGERS DE PROTEÇÃO INTELIGENTES
-- =====================================================

-- Function para bloquear exclusão direta do jogador (com exceção para procedure)
CREATE OR REPLACE FUNCTION bloquear_delete_jogador() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se a exclusão está sendo feita pela procedure autorizada
    IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN OLD; -- Permitir exclusão
    END IF;
    
    -- Bloquear exclusão direta
    RAISE EXCEPTION 'Exclusão direta de jogador não permitida! Use: CALL excluir_jogador_completo(%)', OLD.id_jogador;
END;
$$ LANGUAGE plpgsql;

-- Function para bloquear exclusão direta de partida (com exceção para procedure)
CREATE OR REPLACE FUNCTION bloquear_delete_partida() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se a exclusão está sendo feita pela procedure autorizada
    IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN OLD; -- Permitir exclusão
    END IF;
    
    -- Bloquear exclusão direta
    RAISE EXCEPTION 'Exclusão direta de partida não permitida! Use a procedure de exclusão do jogador.';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS DE PROTEÇÃO CONTRA OPERAÇÕES DIRETAS
-- =====================================================

-- Trigger para impedir exclusão direta de jogador
CREATE TRIGGER trigger_bloquear_delete_jogador
    BEFORE DELETE ON jogador
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_delete_jogador();

-- Trigger para impedir exclusão direta de partida
CREATE TRIGGER trigger_bloquear_delete_partida
    BEFORE DELETE ON partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_delete_partida();

