-- =====================================================
-- Migration V24: Functions Seguras para Criação de Partidas
-- Projeto: Munchkin - Banco de Dados
-- Objetivo: Garantir integridade na criação de partidas e distribuição de cartas
-- Data: 2025-01-06
-- =====================================================

-- =====================================================
-- STORED FUNCTIONS PARA CRIAÇÃO SEGURA DE PARTIDAS
-- =====================================================

-- Function para iniciar partida de forma segura
-- Garante que partida seja criada com exatamente 8 cartas (4 porta + 4 tesouro)
-- Retorna: (id_partida, status)
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
    -- Verificar se jogador existe
    IF NOT EXISTS (SELECT 1 FROM jogador WHERE id_jogador = p_id_jogador) THEN
        RAISE EXCEPTION 'Jogador com ID % não encontrado!', p_id_jogador;
    END IF;

    -- Verificar se já tem partida em andamento
    SELECT id_partida INTO partida_existente 
    FROM partida 
    WHERE id_jogador = p_id_jogador AND estado_partida = 'em andamento';

    IF partida_existente IS NOT NULL THEN
        nova_partida_id := partida_existente;
        resultado_status := 'PARTIDA_EXISTENTE';
        RAISE NOTICE 'Jogador % já possui partida em andamento (ID: %)', p_id_jogador, partida_existente;
        
        -- Retornar resultado
        p_id_partida := nova_partida_id;
        p_status := resultado_status;
        RETURN NEXT;
        RETURN;
    END IF;

    -- Verificar se há cartas suficientes disponíveis
    SELECT COUNT(*) INTO cartas_porta 
    FROM carta 
    WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE;
    
    SELECT COUNT(*) INTO cartas_tesouro 
    FROM carta 
    WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE;

    IF cartas_porta < 7 OR cartas_tesouro < 7 THEN
        RAISE EXCEPTION 'Cartas insuficientes! Disponível: % porta, % tesouro (mínimo: 7 de cada)', 
                        cartas_porta, cartas_tesouro;
    END IF;

    -- Autorizar operações de criação
    PERFORM set_config('app.criacao_partida_autorizada', 'true', true);

    -- Criar nova partida
    INSERT INTO partida (id_jogador, data_inicio, estado_partida, vida_restantes)
    VALUES (p_id_jogador, NOW(), 'em andamento', 3)
    RETURNING id_partida INTO nova_partida_id;

    RAISE NOTICE 'Criando partida % para jogador %...', nova_partida_id, p_id_jogador;

    -- Distribuir exatamente 4 cartas de cada tipo
    -- 1. Distribuir 4 cartas PORTA
    FOR carta_record IN (
        SELECT id_carta FROM carta
        WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM()
        LIMIT 7
    ) LOOP
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (nova_partida_id, carta_record.id_carta, 'mao');
        
        contador_cartas := contador_cartas + 1;
        RAISE NOTICE 'Carta PORTA % adicionada à mão (total: %)', carta_record.id_carta, contador_cartas;
    END LOOP;

    -- 2. Distribuir 4 cartas TESOURO
    FOR carta_record IN (
        SELECT id_carta FROM carta
        WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM()
        LIMIT 7
    ) LOOP
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (nova_partida_id, carta_record.id_carta, 'mao');
        
        contador_cartas := contador_cartas + 1;
        RAISE NOTICE 'Carta TESOURO % adicionada à mão (total: %)', carta_record.id_carta, contador_cartas;
    END LOOP;

    -- Verificar se distribuiu exatamente 8 cartas
    IF contador_cartas != 14 THEN
        RAISE EXCEPTION 'Erro crítico na distribuição: esperado 8 cartas, distribuído %', contador_cartas;
    END IF;

    -- Limpar autorização
    PERFORM set_config('app.criacao_partida_autorizada', '', true);
    
    resultado_status := 'NOVA_PARTIDA_CRIADA';
    RAISE NOTICE 'Partida % criada com sucesso! % cartas distribuídas na mão do jogador %', 
                 nova_partida_id, contador_cartas, p_id_jogador;

    -- Retornar resultado
    p_id_partida := nova_partida_id;
    p_status := resultado_status;
    RETURN NEXT;

EXCEPTION
    WHEN OTHERS THEN
        -- Limpar autorização em caso de erro
        PERFORM set_config('app.criacao_partida_autorizada', '', true);
        RAISE EXCEPTION 'Erro ao iniciar partida para jogador %: %', p_id_jogador, SQLERRM;
END;
$$;

-- =====================================================
-- FUNCTIONS PARA TRIGGERS DE PROTEÇÃO DE CRIAÇÃO
-- =====================================================

-- Function para bloquear inserção direta na tabela partida
CREATE OR REPLACE FUNCTION bloquear_insert_partida() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se é operação autorizada pela function
    IF current_setting('app.criacao_partida_autorizada', true) = 'true' THEN
        RETURN NEW; -- Permitir inserção
    END IF;
    
    -- Bloquear inserção direta
    RAISE EXCEPTION 'Inserção direta na tabela partida não permitida! Use: SELECT * FROM iniciar_partida_segura(%)', NEW.id_jogador;
END;
$$ LANGUAGE plpgsql;

-- Function para bloquear inserção direta na tabela carta_partida
CREATE OR REPLACE FUNCTION bloquear_insert_carta_partida() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se é operação autorizada
    IF current_setting('app.criacao_partida_autorizada', true) = 'true' THEN
        RETURN NEW; -- Permitir inserção
    END IF;
    
    -- Verificar se é operação durante o jogo (outras functions podem autorizar)
    IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN NEW; -- Permitir (para functions de exclusão)
    END IF;
    
    -- Bloquear inserção direta
    RAISE EXCEPTION 'Inserção direta na tabela carta_partida não permitida! Use functions seguras.';
END;
$$ LANGUAGE plpgsql;

-- Function para validar integridade de partida recém-criada
CREATE OR REPLACE FUNCTION validar_integridade_partida() 
RETURNS TRIGGER AS $$
DECLARE
    qtd_cartas INTEGER;
    qtd_porta INTEGER;
    qtd_tesouro INTEGER;
BEGIN
    -- Só validar se não estiver em processo de criação autorizada
    IF current_setting('app.criacao_partida_autorizada', true) = 'true' THEN
        RETURN NEW;
    END IF;

    -- Aguardar um momento para permitir inserções em lote
    PERFORM pg_sleep(0.05);
    
    -- Verificar quantidade total de cartas na mão
    SELECT COUNT(*) INTO qtd_cartas 
    FROM carta_partida cp
    WHERE cp.id_partida = NEW.id_partida AND cp.zona = 'mao';
    
    -- Verificar distribuição por tipo
    SELECT COUNT(*) INTO qtd_porta
    FROM carta_partida cp
    JOIN carta c ON cp.id_carta = c.id_carta
    WHERE cp.id_partida = NEW.id_partida 
      AND cp.zona = 'mao' 
      AND c.tipo_carta = 'porta';
      
    SELECT COUNT(*) INTO qtd_tesouro
    FROM carta_partida cp
    JOIN carta c ON cp.id_carta = c.id_carta
    WHERE cp.id_partida = NEW.id_partida 
      AND cp.zona = 'mao' 
      AND c.tipo_carta = 'tesouro';
    
    -- Validar regras de distribuição inicial
    IF qtd_cartas < 14 THEN
        RAISE EXCEPTION 'Partida % possui apenas % cartas na mão (mínimo: 14)!', NEW.id_partida, qtd_cartas;
    END IF;
    
    IF qtd_porta < 7 OR qtd_tesouro < 7 THEN
        RAISE EXCEPTION 'Partida % possui distribuição inválida: % porta, % tesouro (mínimo: 7 de cada)!', 
                        NEW.id_partida, qtd_porta, qtd_tesouro;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS DE PROTEÇÃO CONTRA OPERAÇÕES DIRETAS
-- =====================================================

-- Trigger para impedir inserção direta na tabela partida
CREATE TRIGGER trigger_bloquear_insert_partida
    BEFORE INSERT ON partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_insert_partida();

-- Trigger para impedir inserção direta na tabela carta_partida
CREATE TRIGGER trigger_bloquear_insert_carta_partida
    BEFORE INSERT ON carta_partida
    FOR EACH ROW
    EXECUTE FUNCTION bloquear_insert_carta_partida();

-- Trigger para validar integridade de partida (com delay)
CREATE CONSTRAINT TRIGGER trigger_validar_integridade_partida
    AFTER INSERT ON partida
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE FUNCTION validar_integridade_partida();

-- =====================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

COMMENT ON FUNCTION iniciar_partida_segura(INTEGER) IS 
'Function segura para iniciar partida. Retorna (id_partida, status). Distribui exatamente 14 cartas (7 porta + 7 tesouro) e garante integridade completa.';

COMMENT ON FUNCTION bloquear_insert_partida() IS 
'Function de trigger que impede inserção direta na tabela partida, exceto quando chamada pela function autorizada';

COMMENT ON FUNCTION bloquear_insert_carta_partida() IS 
'Function de trigger que impede inserção direta na tabela carta_partida, exceto quando chamada por functions autorizadas';

COMMENT ON FUNCTION validar_integridade_partida() IS 
'Function de trigger que valida se partidas possuem distribuição correta de cartas após criação';



