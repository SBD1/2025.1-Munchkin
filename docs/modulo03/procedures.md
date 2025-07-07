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
```

### Versionamento

| Versão | Data | Modificação | Autor |
| --- | --- | --- | --- |
| 0.1 | 06/07/2025 | Criação do Documento | X |