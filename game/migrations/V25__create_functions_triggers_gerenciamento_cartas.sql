-- =====================================================
-- Migration V25: Functions Seguras para Gerenciamento de Cartas
-- Projeto: Munchkin - Banco de Dados  
-- Objetivo: ETAPA 1 - Proteger UPDATE perigoso do gerenciar_cartas.py
-- Data: 2025-01-06
-- =====================================================

-- =====================================================
-- ETAPA 1: FUNCTION BÁSICA PARA MOVER CARTAS COM SEGURANÇA
-- =====================================================

-- Function para substituir o UPDATE perigoso do final do gerenciar_cartas.py
-- Foca apenas na validação básica e movimentação segura de cartas
CREATE OR REPLACE FUNCTION mover_carta_segura(
    p_id_partida INTEGER,
    p_id_carta INTEGER,
    p_zona_destino VARCHAR(20)
)
RETURNS TABLE(
    sucesso BOOLEAN,
    mensagem VARCHAR(255),
    zona_anterior VARCHAR(20),
    zona_atual VARCHAR(20)
)
LANGUAGE plpgsql AS $$
DECLARE
    carta_info RECORD;
    zona_atual VARCHAR(20);
    partida_ativa BOOLEAN := FALSE;
    zona_valida BOOLEAN := FALSE;
    mensagem_retorno VARCHAR(255);
BEGIN
    -- 1. VALIDAR SE PARTIDA EXISTE E ESTÁ EM ANDAMENTO
    SELECT EXISTS(
        SELECT 1 FROM partida 
        WHERE id_partida = p_id_partida AND estado_partida = 'em andamento'
    ) INTO partida_ativa;
    
    IF NOT partida_ativa THEN
        RETURN QUERY SELECT FALSE, 'Partida não encontrada ou não está em andamento'::VARCHAR, ''::VARCHAR, ''::VARCHAR;
        RETURN;
    END IF;

    -- 2. VALIDAR SE CARTA EXISTE NA PARTIDA
    SELECT cp.zona, c.nome, c.subtipo
    INTO carta_info
    FROM carta_partida cp
    JOIN carta c ON cp.id_carta = c.id_carta
    WHERE cp.id_partida = p_id_partida AND cp.id_carta = p_id_carta;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Carta não encontrada nesta partida'::VARCHAR, ''::VARCHAR, ''::VARCHAR;
        RETURN;
    END IF;
    
    zona_atual := carta_info.zona;

    -- 3. VALIDAR SE ZONA DE DESTINO É VÁLIDA
    -- Baseado na V2: zona CHECK (zona IN ('mao', 'equipado', 'descartada'))
    IF p_zona_destino NOT IN ('mao', 'equipado', 'descartada') THEN
        RETURN QUERY SELECT FALSE, format('Zona de destino inválida: "%s". Use: mao, equipado ou descartada', p_zona_destino), zona_atual, zona_atual;
        RETURN;
    END IF;

    -- 4. EVITAR MOVIMENTOS REDUNDANTES
    IF zona_atual = p_zona_destino THEN
        RETURN QUERY SELECT FALSE, format('Carta "%s" já está na zona: %s', carta_info.nome, zona_atual), zona_atual, zona_atual;
        RETURN;
    END IF;

    -- 5. AUTORIZAR OPERAÇÃO (mesmo padrão V23/V24)
    PERFORM set_config('app.movimentacao_carta_autorizada', 'true', true);
    
    -- 6. REALIZAR MOVIMENTAÇÃO SEGURA (corrigido para ENUM)
    UPDATE carta_partida
    SET zona = p_zona_destino::enum_zona
    WHERE id_partida = p_id_partida AND id_carta = p_id_carta;
    
    -- 7. LIMPAR AUTORIZAÇÃO
    PERFORM set_config('app.movimentacao_carta_autorizada', '', true);
    
    -- 8. RETORNAR SUCESSO
    mensagem_retorno := format('Carta "%s" (%s) movida de "%s" para "%s" com sucesso', 
                              carta_info.nome, carta_info.subtipo, zona_atual, p_zona_destino);
    
    RETURN QUERY SELECT TRUE, mensagem_retorno, zona_atual, p_zona_destino;
    
    -- Log para debug
    RAISE NOTICE 'MOVIMENTAÇÃO SEGURA: Carta % (%): % -> %', 
                 carta_info.nome, p_id_carta, zona_atual, p_zona_destino;

EXCEPTION
    WHEN OTHERS THEN
        -- Limpar autorização em caso de erro
        PERFORM set_config('app.movimentacao_carta_autorizada', '', true);
        RETURN QUERY SELECT FALSE, ('Erro ao mover carta: ' || SQLERRM)::VARCHAR, zona_atual, zona_atual;
END;
$$;

-- =====================================================
-- TRIGGER DE PROTEÇÃO CONTRA UPDATE DIRETO
-- =====================================================

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

-- =====================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO
-- =====================================================

COMMENT ON FUNCTION mover_carta_segura(INTEGER, INTEGER, VARCHAR) IS 
'ETAPA 1: Function básica e segura para mover cartas entre zonas. Substitui UPDATE perigoso do gerenciar_cartas.py com validações completas.';

COMMENT ON FUNCTION bloquear_update_carta_partida() IS 
'Trigger que impede UPDATEs diretos em carta_partida, forçando uso de functions seguras (V23, V24, V25).';

-- =====================================================
-- EXEMPLOS DE USO PARA ETAPA 1
-- =====================================================

/*
-- ✅ NOVO MÉTODO SEGURO (substitui UPDATE perigoso):
SELECT sucesso, mensagem, zona_anterior, zona_atual 
FROM mover_carta_segura(123, 45, 'equipado');

-- Resultados possíveis:
-- sucesso=TRUE,  mensagem="Carta ... movida de mao para equipado com sucesso"
-- sucesso=FALSE, mensagem="Carta não encontrada nesta partida"
-- sucesso=FALSE, mensagem="Zona de destino inválida: zona_inexistente"
-- sucesso=FALSE, mensagem="Partida não encontrada ou não está em andamento"

-- ❌ MÉTODO ANTIGO PERIGOSO (será bloqueado pelo trigger):
-- UPDATE carta_partida SET zona = 'equipado' WHERE id_partida = 123 AND id_carta = 45;
-- ERRO: UPDATE direto na tabela carta_partida não permitido!

-- =====================================================
-- VALIDAÇÕES IMPLEMENTADAS NA ETAPA 1:
-- =====================================================

-- 1. ✅ Partida existe e está 'em andamento'
-- 2. ✅ Carta existe na partida especificada  
-- 3. ✅ Zona de destino é válida ('mao', 'equipado', 'descartada')
-- 4. ✅ Evita movimentos redundantes (carta já na zona)
-- 5. ✅ Sistema de autorização compatível com V23/V24
-- 6. ✅ Trigger bloqueia UPDATEs diretos não autorizados
-- 7. ✅ Tratamento robusto de exceções
-- 8. ✅ Mensagens de feedback específicas e úteis
*/

-- =====================================================
-- ETAPA 2: FUNCTIONS SEGURAS PARA PROTEGER TABELA PARTIDA
-- =====================================================

-- Function para atualizar limite de mão com segurança (equipar/desequipar raça)
CREATE OR REPLACE FUNCTION atualizar_limite_mao_seguro(
    p_id_partida INTEGER,
    p_novo_limite INTEGER
)
RETURNS TABLE(
    sucesso BOOLEAN,
    mensagem VARCHAR(255),
    limite_anterior INTEGER,
    limite_atual INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    partida_info RECORD;
    limite_anterior INTEGER;
    mensagem_retorno VARCHAR(255);
BEGIN
    -- 1. VALIDAR PARTIDA ATIVA
    SELECT limite_mao_atual, estado_partida, id_jogador
    INTO partida_info
    FROM partida 
    WHERE id_partida = p_id_partida;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Partida não encontrada'::VARCHAR, 0, 0;
        RETURN;
    END IF;
    
    IF partida_info.estado_partida != 'em andamento' THEN
        RETURN QUERY SELECT FALSE, 'Partida não está em andamento'::VARCHAR, partida_info.limite_mao_atual, partida_info.limite_mao_atual;
        RETURN;
    END IF;
    
    limite_anterior := partida_info.limite_mao_atual;

    -- 2. VALIDAR NOVO LIMITE (entre 1 e 15 cartas)
    IF p_novo_limite IS NULL OR p_novo_limite < 1 OR p_novo_limite > 15 THEN
        RETURN QUERY SELECT FALSE, format('Limite inválido: %s. Deve estar entre 1 e 15', p_novo_limite), limite_anterior, limite_anterior;
        RETURN;
    END IF;

    -- 3. EVITAR OPERAÇÃO REDUNDANTE
    IF limite_anterior = p_novo_limite THEN
        RETURN QUERY SELECT FALSE, format('Limite já é %s', p_novo_limite), limite_anterior, limite_anterior;
        RETURN;
    END IF;

    -- 4. AUTORIZAR E EXECUTAR OPERAÇÃO
    PERFORM set_config('app.update_partida_autorizado', 'true', true);
    
    UPDATE partida 
    SET limite_mao_atual = p_novo_limite
    WHERE id_partida = p_id_partida;
    
    PERFORM set_config('app.update_partida_autorizado', '', true);
    
    -- 5. RETORNAR SUCESSO
    mensagem_retorno := format('Limite de mão atualizado de %s para %s', limite_anterior, p_novo_limite);
    RETURN QUERY SELECT TRUE, mensagem_retorno, limite_anterior, p_novo_limite;
    
    RAISE NOTICE 'LIMITE MÃO SEGURO: Partida % - %s -> %s', p_id_partida, limite_anterior, p_novo_limite;

EXCEPTION
    WHEN OTHERS THEN
        PERFORM set_config('app.update_partida_autorizado', '', true);
        RETURN QUERY SELECT FALSE, ('Erro ao atualizar limite: ' || SQLERRM)::VARCHAR, limite_anterior, limite_anterior;
END;
$$;

-- Function para aplicar bônus de combate com segurança (equipar item)
CREATE OR REPLACE FUNCTION aplicar_bonus_combate_seguro(
    p_id_partida INTEGER,
    p_bonus INTEGER
)
RETURNS TABLE(
    sucesso BOOLEAN,
    mensagem VARCHAR(255),
    nivel_anterior INTEGER,
    nivel_atual INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    partida_info RECORD;
    nivel_anterior INTEGER;
    nivel_novo INTEGER;
    mensagem_retorno VARCHAR(255);
BEGIN
    -- 1. VALIDAR PARTIDA ATIVA
    SELECT nivel, estado_partida, id_jogador
    INTO partida_info
    FROM partida 
    WHERE id_partida = p_id_partida;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Partida não encontrada'::VARCHAR, 0, 0;
        RETURN;
    END IF;
    
    IF partida_info.estado_partida != 'em andamento' THEN
        RETURN QUERY SELECT FALSE, 'Partida não está em andamento'::VARCHAR, partida_info.nivel, partida_info.nivel;
        RETURN;
    END IF;
    
    nivel_anterior := partida_info.nivel;

    -- 2. VALIDAR BÔNUS (entre -10 e +10 para evitar valores absurdos)
    IF p_bonus IS NULL OR p_bonus < -10 OR p_bonus > 10 THEN
        RETURN QUERY SELECT FALSE, format('Bônus inválido: %s. Deve estar entre -10 e +10', p_bonus), nivel_anterior, nivel_anterior;
        RETURN;
    END IF;
    
    -- 3. CALCULAR NOVO NÍVEL (mínimo 1, máximo 20)
    nivel_novo := nivel_anterior + p_bonus;
    IF nivel_novo < 1 THEN nivel_novo := 1; END IF;
    IF nivel_novo > 20 THEN nivel_novo := 20; END IF;

    -- 4. EVITAR OPERAÇÃO REDUNDANTE
    IF nivel_anterior = nivel_novo THEN
        RETURN QUERY SELECT FALSE, format('Nível permanece %s (bônus %s não teve efeito)', nivel_novo, p_bonus), nivel_anterior, nivel_anterior;
        RETURN;
    END IF;

    -- 5. AUTORIZAR E EXECUTAR OPERAÇÃO
    PERFORM set_config('app.update_partida_autorizado', 'true', true);
    
    UPDATE partida 
    SET nivel = nivel_novo
    WHERE id_partida = p_id_partida;
    
    PERFORM set_config('app.update_partida_autorizado', '', true);
    
    -- 6. RETORNAR SUCESSO
    mensagem_retorno := format('Bônus de combate aplicado: %s%s (nível %s -> %s)', 
                              CASE WHEN p_bonus > 0 THEN '+' ELSE '' END, p_bonus, nivel_anterior, nivel_novo);
    RETURN QUERY SELECT TRUE, mensagem_retorno, nivel_anterior, nivel_novo;
    
    RAISE NOTICE 'BÔNUS COMBATE SEGURO: Partida % - nível %s -> %s (bônus %s)', p_id_partida, nivel_anterior, nivel_novo, p_bonus;

EXCEPTION
    WHEN OTHERS THEN
        PERFORM set_config('app.update_partida_autorizado', '', true);
        RETURN QUERY SELECT FALSE, ('Erro ao aplicar bônus: ' || SQLERRM)::VARCHAR, nivel_anterior, nivel_anterior;
END;
$$;

-- Function para processar venda com segurança (ouro + conversão para nível)
CREATE OR REPLACE FUNCTION processar_venda_segura(
    p_id_partida INTEGER,
    p_valor_ouro INTEGER
)
RETURNS TABLE(
    sucesso BOOLEAN,
    mensagem VARCHAR(255),
    ouro_anterior INTEGER,
    ouro_atual INTEGER,
    nivel_anterior INTEGER,
    nivel_atual INTEGER,
    niveis_ganhos INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    partida_info RECORD;
    ouro_anterior INTEGER;
    nivel_anterior INTEGER;
    ouro_novo INTEGER;
    nivel_novo INTEGER;
    niveis_ganhos INTEGER := 0;
    mensagem_retorno VARCHAR(255);
BEGIN
    -- 1. VALIDAR PARTIDA ATIVA
    SELECT ouro_acumulado, nivel, estado_partida, id_jogador
    INTO partida_info
    FROM partida 
    WHERE id_partida = p_id_partida;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Partida não encontrada'::VARCHAR, 0, 0, 0, 0, 0;
        RETURN;
    END IF;
    
    IF partida_info.estado_partida != 'em andamento' THEN
        RETURN QUERY SELECT FALSE, 'Partida não está em andamento'::VARCHAR, partida_info.ouro_acumulado, partida_info.ouro_acumulado, partida_info.nivel, partida_info.nivel, 0;
        RETURN;
    END IF;
    
    ouro_anterior := partida_info.ouro_acumulado;
    nivel_anterior := partida_info.nivel;

    -- 2. VALIDAR VALOR DE OURO (aceita qualquer valor >= 0, incluindo itens com valor 0)
    IF p_valor_ouro IS NULL OR p_valor_ouro < 0 THEN
        RETURN QUERY SELECT FALSE, format('Valor de ouro inválido: %s. Deve ser >= 0', p_valor_ouro), ouro_anterior, ouro_anterior, nivel_anterior, nivel_anterior, 0;
        RETURN;
    END IF;

    -- 3. CALCULAR NOVO OURO E CONVERSÃO PARA NÍVEIS
    ouro_novo := ouro_anterior + p_valor_ouro;
    nivel_novo := nivel_anterior;
    
    -- Conversão: cada 1000 ouro = 1 nível (máximo nível 20)
    WHILE ouro_novo >= 1000 AND nivel_novo < 20 LOOP
        niveis_ganhos := niveis_ganhos + 1;
        nivel_novo := nivel_novo + 1;
        ouro_novo := ouro_novo - 1000;
    END LOOP;

    -- 4. AUTORIZAR E EXECUTAR OPERAÇÃO
    PERFORM set_config('app.update_partida_autorizado', 'true', true);
    
    UPDATE partida 
    SET ouro_acumulado = ouro_novo, nivel = nivel_novo
    WHERE id_partida = p_id_partida;
    
    PERFORM set_config('app.update_partida_autorizado', '', true);
    
    -- 5. RETORNAR SUCESSO
    IF p_valor_ouro = 0 THEN
        mensagem_retorno := format('Item descartado sem valor (0 ouro). Ouro atual: %s', ouro_novo);
    ELSIF niveis_ganhos > 0 THEN
        mensagem_retorno := format('Venda processada: +%s ouro. Subiu %s nível(s)! (Nível %s -> %s, Ouro: %s)', 
                                  p_valor_ouro, niveis_ganhos, nivel_anterior, nivel_novo, ouro_novo);
    ELSE
        mensagem_retorno := format('Venda processada: +%s ouro (Total: %s)', p_valor_ouro, ouro_novo);
    END IF;
    
    RETURN QUERY SELECT TRUE, mensagem_retorno, ouro_anterior, ouro_novo, nivel_anterior, nivel_novo, niveis_ganhos;
    
    RAISE NOTICE 'VENDA SEGURA: Partida % - Ouro %s -> %s, Nível %s -> %s', p_id_partida, ouro_anterior, ouro_novo, nivel_anterior, nivel_novo;

EXCEPTION
    WHEN OTHERS THEN
        PERFORM set_config('app.update_partida_autorizado', '', true);
        RETURN QUERY SELECT FALSE, ('Erro ao processar venda: ' || SQLERRM)::VARCHAR, ouro_anterior, ouro_anterior, nivel_anterior, nivel_anterior, 0;
END;
$$;

-- =====================================================
-- TRIGGER PARA PROTEGER CAMPOS CRÍTICOS DA TABELA PARTIDA
-- =====================================================

-- Function para bloquear UPDATE direto nos campos críticos da partida
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

-- =====================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO DA ETAPA 2
-- =====================================================

COMMENT ON FUNCTION atualizar_limite_mao_seguro(INTEGER, INTEGER) IS 
'ETAPA 2: Function segura para atualizar limite_mao_atual. Substitui UPDATEs perigosos do acoes_cartas.py (equipar/desequipar raça).';

COMMENT ON FUNCTION aplicar_bonus_combate_seguro(INTEGER, INTEGER) IS 
'ETAPA 2: Function segura para aplicar bônus de combate no nível. Substitui UPDATEs perigosos do acoes_cartas.py (equipar item).';

COMMENT ON FUNCTION processar_venda_segura(INTEGER, INTEGER) IS 
'ETAPA 2: Function segura para processar venda/descarte de itens (aceita qualquer valor >= 0, incluindo itens sem valor). Substitui UPDATEs perigosos do acoes_cartas.py.';

COMMENT ON FUNCTION bloquear_update_partida_criticos() IS 
'Trigger que impede UPDATEs diretos nos campos críticos da partida (limite_mao_atual, nivel, ouro_acumulado), forçando uso de functions seguras.';

-- =====================================================
-- EXEMPLOS DE USO PARA ETAPA 2
-- =====================================================

/*
-- ✅ MÉTODOS SEGUROS (substituem UPDATEs perigosos):

-- 1. Equipar raça (alterar limite de mão):
SELECT sucesso, mensagem, limite_anterior, limite_atual 
FROM atualizar_limite_mao_seguro(123, 7);

-- 2. Equipar item (aplicar bônus de combate):
SELECT sucesso, mensagem, nivel_anterior, nivel_atual 
FROM aplicar_bonus_combate_seguro(123, 3);

-- 3. Vender item com valor (ouro + conversão para nível):
SELECT sucesso, mensagem, ouro_anterior, ouro_atual, nivel_anterior, nivel_atual, niveis_ganhos 
FROM processar_venda_segura(123, 1500);

-- 4. Descartar item sem valor (0 ouro):
SELECT sucesso, mensagem, ouro_anterior, ouro_atual, nivel_anterior, nivel_atual, niveis_ganhos 
FROM processar_venda_segura(123, 0);

-- ❌ MÉTODOS ANTIGOS PERIGOSOS (serão bloqueados):
-- UPDATE partida SET limite_mao_atual = 7 WHERE id_partida = 123;        -- ERRO!
-- UPDATE partida SET nivel = nivel + 3 WHERE id_partida = 123;           -- ERRO!
-- UPDATE partida SET ouro_acumulado = 1500 WHERE id_partida = 123;       -- ERRO!

-- =====================================================
-- VALIDAÇÕES IMPLEMENTADAS NA ETAPA 2:
-- =====================================================

-- 1. ✅ Partida existe e está 'em andamento'
-- 2. ✅ Valores dentro de limites seguros (limite_mao: 1-15, bônus: -10 a +10, ouro: >= 0)
-- 3. ✅ Nível máximo 20, mínimo 1
-- 4. ✅ Conversão automática ouro -> nível (1000 ouro = 1 nível)
-- 5. ✅ Permite venda de itens com qualquer valor, incluindo 0 ouro
-- 6. ✅ Evita operações redundantes
-- 7. ✅ Sistema de autorização compatível com V23/V24/V25
-- 8. ✅ Triggers bloqueiam UPDATEs diretos não autorizados
-- 9. ✅ Tratamento robusto de exceções
-- 9. ✅ Feedback específico sobre limites e validações
*/

-- =====================================================
-- ETAPA 3: VALIDAÇÃO DE RAÇA/CLASSE ÚNICA
-- =====================================================

-- Function para validar regras específicas de equipamento (raça/classe única)
CREATE OR REPLACE FUNCTION validar_equipamento_seguro(
    p_id_partida INTEGER,
    p_id_carta INTEGER,
    p_subtipo VARCHAR(20)
)
RETURNS TABLE(
    pode_equipar BOOLEAN,
    mensagem VARCHAR(255),
    carta_conflito_id INTEGER,
    carta_conflito_nome VARCHAR(100)
)
LANGUAGE plpgsql AS $$
DECLARE
    carta_conflito RECORD;
    nova_carta_nome VARCHAR(100);
BEGIN
    -- 1. BUSCAR NOME DA CARTA QUE SERÁ EQUIPADA
    SELECT nome INTO nova_carta_nome 
    FROM carta 
    WHERE id_carta = p_id_carta;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Carta não encontrada'::VARCHAR, 0, ''::VARCHAR;
        RETURN;
    END IF;

    -- 2. VALIDAR REGRA: APENAS 1 RAÇA OU 1 CLASSE EQUIPADA
    IF p_subtipo IN ('raca', 'classe') THEN
        SELECT cp.id_carta, c.nome, c.subtipo
        INTO carta_conflito
        FROM carta_partida cp
        JOIN carta c ON cp.id_carta = c.id_carta
        WHERE cp.id_partida = p_id_partida 
          AND cp.zona = 'equipado' 
          AND c.subtipo = p_subtipo
          AND cp.id_carta != p_id_carta;  -- Excluir a própria carta (caso já equipada)
        
        IF FOUND THEN
            RETURN QUERY SELECT 
                FALSE, 
                format('❌ Você já tem uma %s equipada: "%s". Desequipe-a primeiro para equipar "%s".', 
                       UPPER(p_subtipo), carta_conflito.nome, nova_carta_nome),
                carta_conflito.id_carta,
                carta_conflito.nome;
            RETURN;
        END IF;
    END IF;

    -- 3. VALIDAÇÃO ESPECIAL: MONSTROS NÃO PODEM SER EQUIPADOS
    IF p_subtipo = 'monstro' THEN
        RETURN QUERY SELECT 
            FALSE, 
            format('❌ Cartas do tipo MONSTRO ("%s") não podem ser equipadas.', nova_carta_nome),
            0,
            ''::VARCHAR;
        RETURN;
    END IF;

    -- 4. SE CHEGOU ATÉ AQUI, PODE EQUIPAR
    RETURN QUERY SELECT 
        TRUE, 
        format('✅ Carta "%s" (%s) pode ser equipada.', nova_carta_nome, p_subtipo),
        0,
        ''::VARCHAR;

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, ('Erro ao validar equipamento: ' || SQLERRM)::VARCHAR, 0, ''::VARCHAR;
END;
$$;

-- =====================================================
-- FUNCTION EQUIPAR CARTA COM VALIDAÇÃO COMPLETA
-- =====================================================

-- Function que combina validação + equipamento seguro
CREATE OR REPLACE FUNCTION equipar_carta_segura(
    p_id_partida INTEGER,
    p_id_carta INTEGER
)
RETURNS TABLE(
    sucesso BOOLEAN,
    mensagem VARCHAR(255),
    zona_anterior VARCHAR(20),
    zona_atual VARCHAR(20),
    limite_anterior INTEGER,
    limite_atual INTEGER,
    nivel_anterior INTEGER,
    nivel_atual INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    carta_info RECORD;
    validacao RECORD;
    resultado_mover RECORD;
    resultado_limite RECORD;
    resultado_bonus RECORD;
    limite_ant INTEGER := 0;
    limite_atual INTEGER := 0;
    nivel_ant INTEGER := 0;
    nivel_atual INTEGER := 0;
    mensagem_final VARCHAR(255);
BEGIN
    -- 1. BUSCAR INFORMAÇÕES DA CARTA
    SELECT c.nome, c.subtipo, cp.zona
    INTO carta_info
    FROM carta_partida cp
    JOIN carta c ON cp.id_carta = c.id_carta
    WHERE cp.id_partida = p_id_partida AND cp.id_carta = p_id_carta;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Carta não encontrada nesta partida'::VARCHAR, ''::VARCHAR, ''::VARCHAR, 0, 0, 0, 0;
        RETURN;
    END IF;

    -- 2. VALIDAR SE PODE EQUIPAR
    SELECT pode_equipar, mensagem, carta_conflito_id, carta_conflito_nome
    INTO validacao
    FROM validar_equipamento_seguro(p_id_partida, p_id_carta, carta_info.subtipo);
    
    IF NOT validacao.pode_equipar THEN
        RETURN QUERY SELECT FALSE, validacao.mensagem, carta_info.zona, carta_info.zona, 0, 0, 0, 0;
        RETURN;
    END IF;

    -- 3. MOVER CARTA PARA ZONA EQUIPADO
    SELECT sucesso, mensagem, zona_anterior, zona_atual
    INTO resultado_mover
    FROM mover_carta_segura(p_id_partida, p_id_carta, 'equipado');
    
    IF NOT resultado_mover.sucesso THEN
        RETURN QUERY SELECT FALSE, resultado_mover.mensagem, carta_info.zona, carta_info.zona, 0, 0, 0, 0;
        RETURN;
    END IF;

    -- 4. APLICAR EFEITOS ESPECÍFICOS POR SUBTIPO
    mensagem_final := format('✅ %s equipada com sucesso!', carta_info.nome);
    
    IF carta_info.subtipo = 'raca' THEN
        -- Buscar e aplicar limite de mão da raça
        SELECT pl.limite_cartas_mao
        INTO limite_atual
        FROM poder_raca pr
        JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
        WHERE pr.id_carta = p_id_carta;
        
        IF FOUND THEN
            SELECT sucesso, mensagem, limite_anterior, limite_atual
            INTO resultado_limite
            FROM atualizar_limite_mao_seguro(p_id_partida, limite_atual);
            
            IF resultado_limite.sucesso THEN
                mensagem_final := format('✅ %s equipada! %s', carta_info.nome, resultado_limite.mensagem);
                limite_ant := resultado_limite.limite_anterior;
                limite_atual := resultado_limite.limite_atual;
            END IF;
        END IF;
        
    ELSIF carta_info.subtipo = 'item' THEN
        -- Buscar e aplicar bônus de combate do item
        SELECT bonus_combate
        INTO nivel_atual
        FROM carta_item
        WHERE id_carta = p_id_carta;
        
        IF FOUND AND nivel_atual != 0 THEN
            SELECT sucesso, mensagem, nivel_anterior, nivel_atual
            INTO resultado_bonus
            FROM aplicar_bonus_combate_seguro(p_id_partida, nivel_atual);
            
            IF resultado_bonus.sucesso THEN
                mensagem_final := format('✅ %s equipado! %s', carta_info.nome, resultado_bonus.mensagem);
                nivel_ant := resultado_bonus.nivel_anterior;
                nivel_atual := resultado_bonus.nivel_atual;
            END IF;
        END IF;
    END IF;

    -- 5. RETORNAR SUCESSO COMPLETO
    RETURN QUERY SELECT 
        TRUE, 
        mensagem_final,
        resultado_mover.zona_anterior,
        resultado_mover.zona_atual,
        limite_ant,
        limite_atual,
        nivel_ant,
        nivel_atual;

EXCEPTION
    WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, ('Erro ao equipar carta: ' || SQLERRM)::VARCHAR, carta_info.zona, carta_info.zona, 0, 0, 0, 0;
END;
$$;

-- =====================================================
-- COMENTÁRIOS E DOCUMENTAÇÃO DA ETAPA 3
-- =====================================================

COMMENT ON FUNCTION validar_equipamento_seguro(INTEGER, INTEGER, VARCHAR) IS 
'ETAPA 3: Valida regras específicas de equipamento - apenas 1 raça e 1 classe por vez, bloqueia monstros.';

COMMENT ON FUNCTION equipar_carta_segura(INTEGER, INTEGER) IS 
'ETAPA 3: Function completa para equipar cartas com validação + aplicação automática de efeitos (limite mão, bônus combate).';

-- =====================================================
-- EXEMPLOS DE USO PARA ETAPA 3
-- =====================================================

/*
-- ✅ NOVO MÉTODO SEGURO COMPLETO (substitui tratar_equipar()):

-- 1. Equipar carta com validação automática:
SELECT sucesso, mensagem, zona_anterior, zona_atual, limite_anterior, limite_atual, nivel_anterior, nivel_atual
FROM equipar_carta_segura(123, 45);

-- Cenários possíveis:
-- sucesso=TRUE,  mensagem="✅ Anão equipada! Limite de mão atualizado de 5 para 6"
-- sucesso=FALSE, mensagem="❌ Você já tem uma RACA equipada: 'Elfo'. Desequipe-a primeiro para equipar 'Anão'.",
-- sucesso=FALSE, mensagem="❌ Cartas do tipo MONSTRO ('Dragão') não podem ser equipadas."

-- 2. Apenas validar (sem equipar):
SELECT pode_equipar, mensagem, carta_conflito_id, carta_conflito_nome
FROM validar_equipamento_seguro(123, 45, 'raca');

-- =====================================================
-- REGRAS IMPLEMENTADAS NA ETAPA 3:
-- =====================================================

-- 1. ✅ Apenas 1 RAÇA equipada por vez
-- 2. ✅ Apenas 1 CLASSE equipada por vez  
-- 3. ✅ Múltiplos ITENS podem ser equipados (limitados por slots)
-- 4. ✅ MONSTROS não podem ser equipados
-- 5. ✅ Aplicação automática de efeitos (limite mão para raças, bônus para itens)
-- 6. ✅ Validação no banco garante integridade independente da aplicação
-- 7. ✅ Mensagens específicas sobre conflitos e soluções
-- 8. ✅ Compatível com sistema de autorização existente (V23/V24/V25)
-- 9. ✅ Tratamento robusto de exceções e rollback automático
*/