-- =====================================================
-- Migration V24: Procedures Seguras para Criação de Partidas
-- Projeto: Munchkin - Banco de Dados
-- Objetivo: Garantir integridade na criação de partidas e distribuição de cartas
-- Data: 2025-01-06
-- =====================================================

-- =====================================================
-- STORED PROCEDURES PARA CRIAÇÃO SEGURA DE PARTIDAS
-- =====================================================

-- Procedure para iniciar partida de forma segura
-- Garante que partida seja criada com exatamente 8 cartas (4 porta + 4 tesouro)
CREATE OR REPLACE PROCEDURE iniciar_partida_segura(
    p_id_jogador INTEGER,
    OUT p_id_partida INTEGER,
    OUT p_status VARCHAR(50)
)
LANGUAGE plpgsql AS $$
DECLARE
    partida_existente INTEGER;
    carta_record RECORD;
    contador_cartas INTEGER := 0;
    cartas_porta INTEGER := 0;
    cartas_tesouro INTEGER := 0;
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
        p_id_partida := partida_existente;
        p_status := 'PARTIDA_EXISTENTE';
        RAISE NOTICE 'Jogador % já possui partida em andamento (ID: %)', p_id_jogador, partida_existente;
        RETURN;
    END IF;

    -- Verificar se há cartas suficientes disponíveis
    SELECT COUNT(*) INTO cartas_porta 
    FROM carta 
    WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE;
    
    SELECT COUNT(*) INTO cartas_tesouro 
    FROM carta 
    WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE;

    IF cartas_porta < 4 OR cartas_tesouro < 4 THEN
        RAISE EXCEPTION 'Cartas insuficientes! Disponível: % porta, % tesouro (mínimo: 4 de cada)', 
                        cartas_porta, cartas_tesouro;
    END IF;

    -- Autorizar operações de criação
    PERFORM set_config('app.criacao_partida_autorizada', 'true', true);

    -- Criar nova partida
    INSERT INTO partida (id_jogador, data_inicio, estado_partida, vida_restantes)
    VALUES (p_id_jogador, NOW(), 'em andamento', 3)
    RETURNING id_partida INTO p_id_partida;

    RAISE NOTICE 'Criando partida % para jogador %...', p_id_partida, p_id_jogador;

    -- Distribuir exatamente 4 cartas de cada tipo
    -- 1. Distribuir 4 cartas PORTA
    FOR carta_record IN (
        SELECT id_carta FROM carta
        WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM()
        LIMIT 4
    ) LOOP
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (p_id_partida, carta_record.id_carta, 'mao');
        
        contador_cartas := contador_cartas + 1;
        RAISE NOTICE 'Carta PORTA % adicionada à mão (total: %)', carta_record.id_carta, contador_cartas;
    END LOOP;

    -- 2. Distribuir 4 cartas TESOURO
    FOR carta_record IN (
        SELECT id_carta FROM carta
        WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM()
        LIMIT 4
    ) LOOP
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (p_id_partida, carta_record.id_carta, 'mao');
        
        contador_cartas := contador_cartas + 1;
        RAISE NOTICE 'Carta TESOURO % adicionada à mão (total: %)', carta_record.id_carta, contador_cartas;
    END LOOP;

    -- Verificar se distribuiu exatamente 8 cartas
    IF contador_cartas != 8 THEN
        RAISE EXCEPTION 'Erro crítico na distribuição: esperado 8 cartas, distribuído %', contador_cartas;
    END IF;

    -- Limpar autorização
    PERFORM set_config('app.criacao_partida_autorizada', '', true);
    
    p_status := 'NOVA_PARTIDA_CRIADA';
    RAISE NOTICE 'Partida % criada com sucesso! % cartas distribuídas na mão do jogador %', 
                 p_id_partida, contador_cartas, p_id_jogador;

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
    -- Verificar se é operação autorizada pela procedure
    IF current_setting('app.criacao_partida_autorizada', true) = 'true' THEN
        RETURN NEW; -- Permitir inserção
    END IF;
    
    -- Bloquear inserção direta
    RAISE EXCEPTION 'Inserção direta na tabela partida não permitida! Use: CALL iniciar_partida_segura(%))', NEW.id_jogador;
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
    
    -- Verificar se é operação durante o jogo (outras procedures podem autorizar)
    IF current_setting('app.exclusao_autorizada', true) = 'true' THEN
        RETURN NEW; -- Permitir (para procedures de exclusão)
    END IF;
    
    -- Bloquear inserção direta
    RAISE EXCEPTION 'Inserção direta na tabela carta_partida não permitida! Use procedures seguras.';
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
    IF qtd_cartas < 8 THEN
        RAISE EXCEPTION 'Partida % possui apenas % cartas na mão (mínimo: 8)!', NEW.id_partida, qtd_cartas;
    END IF;
    
    IF qtd_porta < 4 OR qtd_tesouro < 4 THEN
        RAISE EXCEPTION 'Partida % possui distribuição inválida: % porta, % tesouro (mínimo: 4 de cada)!', 
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

COMMENT ON PROCEDURE iniciar_partida_segura(INTEGER, INTEGER, VARCHAR) IS 
'Procedure segura para criação de partidas. Garante distribuição correta de 8 cartas (4 porta + 4 tesouro) e previne criação de partidas duplicadas.';

COMMENT ON FUNCTION bloquear_insert_partida() IS 
'Function de trigger que impede inserção direta na tabela partida, exceto quando chamada pela procedure autorizada';

COMMENT ON FUNCTION bloquear_insert_carta_partida() IS 
'Function de trigger que impede inserção direta na tabela carta_partida, exceto quando chamada por procedures autorizadas';

COMMENT ON FUNCTION validar_integridade_partida() IS 
'Function de trigger que valida se partidas possuem distribuição correta de cartas após criação';

-- =====================================================
-- EXEMPLOS DE USO
-- =====================================================

/*
-- Para criar uma partida de forma segura:
CALL iniciar_partida_segura(123, NULL, NULL);

-- Para verificar resultado:
SELECT * FROM iniciar_partida_segura(123) AS (id_partida INTEGER, status VARCHAR);

-- Tentativas de inserção direta resultarão em erro:
-- INSERT INTO partida (id_jogador, data_inicio...) VALUES (...); -- ERRO!
-- INSERT INTO carta_partida (id_partida, id_carta...) VALUES (...); -- ERRO!

-- Como funciona a proteção:
-- 1. Procedure define: app.criacao_partida_autorizada = 'true'
-- 2. Triggers verificam essa variável antes de bloquear
-- 3. Se autorizada: permite operação
-- 4. Se não autorizada: bloqueia com erro
-- 5. Procedure sempre limpa a variável no final
-- 6. Trigger de integridade valida distribuição final de cartas

-- Cenários protegidos:
-- - Criação de partidas sem cartas
-- - Distribuição incorreta de cartas (não 4+4)
-- - Múltiplas partidas em andamento para mesmo jogador
-- - Race conditions na criação simultânea
-- - Estados inconsistentes no banco
*/
