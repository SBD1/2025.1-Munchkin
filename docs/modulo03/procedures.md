## Stored Procedures

### Introdução

As Stored Procedures são blocos de código SQL armazenados no banco de dados que permitem automatizar tarefas e centralizar regras de negócio, promovendo segurança, reutilização e desempenho. Segundo Elmasri e Navathe, elas são úteis para encapsular operações complexas, controlar o acesso aos dados e reduzir a duplicação de lógica no sistema. Este documento apresenta o uso de stored procedures no sistema de gerenciamento de partidas com cartas, com o objetivo de garantir a integridade das operações e aplicar regras de segurança de forma consistente e controlada.

-- =====================================================
-- SECTION: PROCEDURES E FUNCTIONS DE CRIAÇÃO
-- =====================================================

```sql
-- Function para iniciar uma partida de forma segura.
-- Garante que a partida seja criada com exatamente 8 cartas (4 de porta e 4 de tesouro).
-- Retorna uma tabela com o ID da partida e um status sobre a operação.
CREATE OR REPLACE FUNCTION iniciar_partida_segura(p_id_jogador INTEGER)
RETURNS TABLE(p_id_partida INTEGER, p_status VARCHAR(50))
LANGUAGE plpgsql AS $$
DECLARE
    partida_existente INTEGER;
    carta_record RECORD;
    contador_cartas INTEGER := 0;
    cartas_porta_disponiveis INTEGER := 0;
    cartas_tesouro_disponiveis INTEGER := 0;
    nova_partida_id INTEGER;
    resultado_status VARCHAR(50);
BEGIN
    -- 1. Verificar se o jogador existe no banco de dados
    IF NOT EXISTS (SELECT 1 FROM jogador WHERE id_jogador = p_id_jogador) THEN
        RAISE EXCEPTION 'Jogador com ID % não encontrado!', p_id_jogador;
    END IF;

    -- 2. Verificar se o jogador já possui uma partida em andamento para evitar duplicatas
    SELECT id_partida INTO partida_existente 
    FROM partida 
    WHERE id_jogador = p_id_jogador AND estado_partida = 'em andamento';

    IF partida_existente IS NOT NULL THEN
        -- Se já existe, retorna o ID da partida existente
        RAISE NOTICE 'Jogador % já possui partida em andamento (ID: %)', p_id_jogador, partida_existente;
        p_id_partida := partida_existente;
        p_status := 'PARTIDA_EXISTENTE';
        RETURN NEXT;
        RETURN;
    END IF;

    -- 3. Verificar se há cartas suficientes no baralho para iniciar uma nova partida
    SELECT COUNT(*) INTO cartas_porta_disponiveis 
    FROM carta 
    WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE;
    
    SELECT COUNT(*) INTO cartas_tesouro_disponiveis 
    FROM carta 
    WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE;

    IF cartas_porta_disponiveis < 4 OR cartas_tesouro_disponiveis < 4 THEN
        RAISE EXCEPTION 'Cartas insuficientes para iniciar! Disponível: % porta, % tesouro (mínimo: 4 de cada)', 
                        cartas_porta_disponiveis, cartas_tesouro_disponiveis;
    END IF;

    -- 4. Autorizar a criação da partida e distribuição de cartas (para os triggers)
    PERFORM set_config('app.criacao_partida_autorizada', 'true', true);

    -- 5. Criar a nova partida
    INSERT INTO partida (id_jogador, data_inicio, estado_partida, vida_restantes)
    VALUES (p_id_jogador, NOW(), 'em andamento', 3)
    RETURNING id_partida INTO nova_partida_id;

    RAISE NOTICE 'Criando partida % para jogador %...', nova_partida_id, p_id_jogador;

    -- 6. Distribuir 4 cartas de PORTA aleatoriamente
    FOR carta_record IN (
        SELECT id_carta FROM carta
        WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM()
        LIMIT 4
    ) LOOP
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (nova_partida_id, carta_record.id_carta, 'mao');
        contador_cartas := contador_cartas + 1;
    END LOOP;

    -- 7. Distribuir 4 cartas de TESOURO aleatoriamente
    FOR carta_record IN (
        SELECT id_carta FROM carta
        WHERE tipo_carta = 'tesouro' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM()
        LIMIT 4
    ) LOOP
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (nova_partida_id, carta_record.id_carta, 'mao');
        contador_cartas := contador_cartas + 1;
    END LOOP;

    -- 8. Verificação final de segurança
    IF contador_cartas != 8 THEN
        RAISE EXCEPTION 'Erro crítico na distribuição: esperado 8 cartas, mas % foram distribuídas.', contador_cartas;
    END IF;

    -- 9. Limpar a autorização e retornar o resultado
    PERFORM set_config('app.criacao_partida_autorizada', '', true);
    
    RAISE NOTICE 'Partida % criada com sucesso! % cartas distribuídas para o jogador %.', 
                 nova_partida_id, contador_cartas, p_id_jogador;

    p_id_partida := nova_partida_id;
    p_status := 'NOVA_PARTIDA_CRIADA';
    RETURN NEXT;

EXCEPTION
    WHEN OTHERS THEN
        PERFORM set_config('app.criacao_partida_autorizada', '', true);
        RAISE EXCEPTION 'Erro ao iniciar partida para jogador %: %', p_id_jogador, SQLERRM;
END;
$$;

COMMENT ON FUNCTION iniciar_partida_segura(INTEGER) IS 
'Function segura para iniciar partida. Retorna (id_partida, status). Distribui 8 cartas (4 porta + 4 tesouro).';
```

-- =====================================================
-- SECTION: PROCEDURES DE EXCLUSÃO
-- =====================================================

```sql
-- Procedure para exclusão segura e completa de um jogador.
-- Remove o jogador e todos os seus dados associados (partidas, combates, etc.).
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

    -- Definir variável de sessão para autorizar exclusões em cascata nos triggers
    PERFORM set_config('app.exclusao_autorizada', 'true', true);

    -- Para cada partida associada ao jogador, excluir dados dependentes
    FOR partida_record IN 
        SELECT id_partida FROM partida WHERE id_jogador = p_id_jogador
    LOOP
        RAISE NOTICE 'Excluindo dados da partida %...', partida_record.id_partida;
        DELETE FROM uso_poder_venda WHERE id_partida = partida_record.id_partida;
        DELETE FROM combate WHERE id_partida = partida_record.id_partida;
        DELETE FROM carta_partida WHERE id_partida = partida_record.id_partida;
        DELETE FROM partida WHERE id_partida = partida_record.id_partida;
    END LOOP;
    
    -- Por último, excluir o Jogador
    DELETE FROM jogador WHERE id_jogador = p_id_jogador;
    
    -- Limpar a variável de sessão
    PERFORM set_config('app.exclusao_autorizada', '', true);
    
    RAISE NOTICE 'Jogador % e todos os seus dados foram excluídos com segurança!', p_id_jogador;
    
EXCEPTION
    WHEN OTHERS THEN
        PERFORM set_config('app.exclusao_autorizada', '', true);
        RAISE EXCEPTION 'Erro ao excluir jogador %: %', p_id_jogador, SQLERRM;
END;
$$;

-- Procedure para exclusão segura de todas as partidas de um jogador.
-- Mantém o registro do jogador, mas remove todo o seu histórico de partidas.
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

    -- Verificar se o jogador possui partidas
    SELECT COUNT(*) INTO contador_partidas 
    FROM partida WHERE id_jogador = p_id_jogador;
    
    IF contador_partidas = 0 THEN
        RAISE NOTICE 'Jogador % não possui partidas para excluir.', p_id_jogador;
        RETURN;
    END IF;

    -- Autorizar exclusões nos triggers
    PERFORM set_config('app.exclusao_autorizada', 'true', true);

    -- Loop para excluir cada partida e seus dados
    FOR partida_record IN 
        SELECT id_partida FROM partida WHERE id_jogador = p_id_jogador
    LOOP
        RAISE NOTICE 'Excluindo dados da partida %...', partida_record.id_partida;
        DELETE FROM uso_poder_venda WHERE id_partida = partida_record.id_partida;
        DELETE FROM combate WHERE id_partida = partida_record.id_partida;
        DELETE FROM carta_partida WHERE id_partida = partida_record.id_partida;
        DELETE FROM partida WHERE id_partida = partida_record.id_partida;
    END LOOP;
    
    -- Limpar a variável de autorização
    PERFORM set_config('app.exclusao_autorizada', '', true);
    
    RAISE NOTICE 'Todas as % partidas do jogador % foram excluídas! O jogador foi mantido.', contador_partidas, p_id_jogador;
    
EXCEPTION
    WHEN OTHERS THEN
        PERFORM set_config('app.exclusao_autorizada', '', true);
        RAISE EXCEPTION 'Erro ao excluir partidas do jogador %: %', p_id_jogador, SQLERRM;
END;
$$;

COMMENT ON PROCEDURE excluir_jogador_completo(INTEGER) IS
'Exclui um jogador e todos os seus dados associados, como partidas, combates e cartas. Usa autorização por variável de sessão.';

COMMENT ON PROCEDURE excluir_partidas_jogador(INTEGER) IS
'Remove com segurança todas as partidas de um jogador, mantendo o cadastro do jogador. Usa variável de autorização para permitir a operação.';

```

-- =====================================================
-- SECTION: MOVER CARTAS COM SEGURANÇA
-- =====================================================
```sql

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

COMMENT ON FUNCTION mover_carta_segura(INTEGER, INTEGER, VARCHAR) IS
'Move uma carta entre zonas ("mao", "equipado", "descartada") de forma segura e validada. Retorna sucesso, mensagem e zonas envolvidas.';

```

-- =====================================================
-- SECTION: PROTEÇÃO DA TABELA PARTIDA
-- =====================================================
```sql
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

COMMENT ON FUNCTION atualizar_limite_mao_seguro(INTEGER, INTEGER) IS
'Atualiza o limite de cartas na mão da partida, geralmente aplicado ao equipar ou desequipar uma raça. Valida limites e evita redundância.';

COMMENT ON FUNCTION aplicar_bonus_combate_seguro(INTEGER, INTEGER) IS
'Aplica bônus ou penalidade de combate à partida (ex: ao equipar um item). Valida limites e protege a integridade dos dados.';

COMMENT ON FUNCTION processar_venda_segura(INTEGER, INTEGER) IS
'Processa venda de cartas para ouro. Acumula ouro e converte em níveis a cada 1000. Limita nível entre 1 e 20. Retorna estado antes/depois.';

```

-- =====================================================
-- SECTION: VALIDAÇÃO DE RAÇA/CLASSE ÚNICA
-- =====================================================
```sql

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

COMMENT ON FUNCTION validar_equipamento_seguro(INTEGER, INTEGER, VARCHAR) IS
'Valida se uma carta pode ser equipada, com regras específicas para raça, classe e itens proibidos como monstros.';

COMMENT ON FUNCTION equipar_carta_segura(INTEGER, INTEGER) IS
'Realiza o equipamento completo de uma carta com segurança. Inclui validação de regras, movimentação de zona e aplicação de efeitos.';

```


### Versionamento

| Versão | Data | Modificação | Autor |
| --- | --- | --- | --- |
| 06/07/2025 | Criação do Documento e Organização inicial| [Mylena Mendonça](https://github.com/MylenaTrindade) |
| 06/07/2025 | Continuação do desenvolvimento | [Maria Clara Sena](https://github.com/mclarasenaa) |