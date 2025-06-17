## Data Query Language (DQL)

### Introdução

A Data Query Language (DQL) é responsável pelas instruções de consulta em SQL. Segundo Elmasri e Navathe, a DQL permite buscar e recuperar dados de tabelas para posterior análise, visualização ou processamento. Este documento organiza e descreve as principais queries utilizadas no sistema do jogo Munchkin, categorizadas por funcionalidade do jogo.

---

### DQL_01_consultas_cartas
<details><summary>Comandos</summary>

    ```sql
        -- Retorna o ID do poder da raça e o limite de cartas na mão da carta especificada
        SELECT pr.id_poder_raca, pl.limite_cartas_mao
        FROM poder_raca pr
        JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
        WHERE pr.id_carta = %s;

        -- Exibe tipo, slot e bônus de combate de um item
        SELECT tipo_item, slot, bonus_combate
        FROM carta_item
        WHERE id_carta = %s;

        -- Consulta restrições de uso de um item por classe ou raça
        SELECT tipo_alvo, valor_alvo, permitido
        FROM restricao_item
        WHERE id_carta_item = %s;

        -- Verifica se o jogador possui uma classe específica equipada
        SELECT 1
        FROM carta_partida cp
        JOIN carta_classe cc ON cc.id_carta = cp.id_carta
        WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND cc.nome_classe = %s;

        -- Verifica se o jogador possui uma raça específica equipada
        SELECT 1
        FROM carta_partida cp
        JOIN carta_raca cr ON cr.id_carta = cp.id_carta
        WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND cr.nome_raca = %s;

        -- Verifica se há item equipado no mesmo slot
        SELECT 1
        FROM carta_partida cp
        JOIN carta_item ci ON ci.id_carta = cp.id_carta
        WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND ci.slot = %s;

        -- Retorna ID do poder da raça associado a uma carta (ex: ao mover para a mão)
        SELECT pr.id_poder_raca
        FROM poder_raca pr
        JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
        WHERE pr.id_carta = %s;

        -- Verifica se ainda há uma carta equipada com poder de limite de mão
        SELECT 1
        FROM carta_partida cp
        JOIN poder_raca pr ON cp.id_carta = pr.id_carta
        JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
        WHERE cp.id_partida = %s AND cp.zona = 'equipado';

        -- Consulta o valor de ouro de um item
        SELECT valor_ouro
        FROM carta_item
        WHERE id_carta = %s;

        -- Retorna dados do estado da partida
        SELECT ouro_acumulado, nivel, turno_atual
        FROM partida
        WHERE id_partida = %s;

        -- Consulta poder de venda multiplicada equipado
        SELECT pr.id_carta, pvm.multiplicador, pvm.limite_vezes_por_turno
        FROM carta_partida cp
        JOIN poder_raca pr ON cp.id_carta = pr.id_carta
        JOIN poder_venda_multiplicada pvm ON pr.id_poder_raca = pvm.id_poder_raca
        WHERE cp.id_partida = %s AND cp.zona = 'equipado';

        -- Verifica quantas vezes o poder de venda foi usado no turno
        SELECT usos
        FROM uso_poder_venda
        WHERE id_partida = %s AND id_carta = %s AND turno = %s;

        -- Seleciona carta porta aleatória disponível
        SELECT id_carta, nome, subtipo FROM carta
        WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE
        ORDER BY RANDOM() LIMIT 1;

        -- Marca carta como indisponível
        UPDATE carta
        SET disponivel_para_virar = FALSE
        WHERE id_carta = %s;

        -- Registra início de combate
        INSERT INTO combate (id_partida, id_carta, monstro_vindo_do_baralho, data_ocorrido)
        VALUES (%s, %s, TRUE, NOW());

        -- Adiciona carta à mão do jogador
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (%s, %s, 'mao');

        -- Busca partida em andamento do jogador
        SELECT id_partida FROM partida
        WHERE id_jogador = %s AND estado_partida = 'em andamento'
        ORDER BY id_partida DESC LIMIT 1;

        -- Lista cartas na mão
        SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo
        FROM carta_partida cp
        JOIN carta c ON c.id_carta = cp.id_carta
        WHERE cp.id_partida = %s AND cp.zona = 'mao';

        -- Atualiza zona de uma carta
        UPDATE carta_partida
        SET zona = %s
        WHERE id_partida = %s AND id_carta = %s;

        -- Verifica se há partida em andamento
        SELECT id_partida FROM partida
        WHERE id_jogador = %s AND estado_partida = 'em andamento'
        LIMIT 1;

        -- Cria nova partida
        INSERT INTO partida (id_jogador, data_inicio, estado_partida, vida_restantes)
        VALUES (%s, %s, 'em andamento', 3)
        RETURNING id_partida;

        -- Seleciona 4 cartas aleatórias de um tipo
        SELECT id_carta FROM carta
        WHERE tipo_carta = %s AND disponivel_para_virar = TRUE
        ORDER BY RANDOM()
        LIMIT 4;

        -- Insere carta na mão
        INSERT INTO carta_partida (id_partida, id_carta, zona)
        VALUES (%s, %s, 'mao');

        -- Recupera dados da partida em andamento
        SELECT id_partida, limite_mao_atual, turno_atual
        FROM partida
        WHERE id_jogador = %s AND estado_partida = 'em andamento'
        ORDER BY id_partida DESC LIMIT 1;

        -- Conta cartas na mão
        SELECT COUNT(*) FROM carta_partida
        WHERE id_partida = %s AND zona = 'mao';

        -- Incrementa o turno
        UPDATE partida
        SET turno_atual = turno_atual + 1
        WHERE id_partida = %s;

        -- Lista jogadores existentes
        SELECT id_jogador, nome FROM jogador ORDER BY id_jogador;

        -- Consulta estado da partida mais recente
        SELECT nivel, vida_restantes, estado_partida, finalizada, vitoria, data_inicio, turno_atual, ouro_acumulado
        FROM partida
        WHERE id_jogador = %s
        ORDER BY id_partida DESC
        LIMIT 1;

        -- Detalhes de item
        SELECT bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla
        FROM carta_item WHERE id_carta = %s;

        -- Detalhes de monstro
        SELECT cm.nivel, cm.pode_fugir, cm.recompensa, cm.tipo_monstro, em.descricao
        FROM carta_monstro cm
        LEFT JOIN efeito_monstro em ON cm.id_carta_monstro = em.id_carta_monstro
        WHERE cm.id_carta = %s;

        -- Detalhes de raça
        SELECT cr.nome_raca, pr.descricao
        FROM carta_raca cr
        LEFT JOIN poder_raca pr ON cr.id_carta = pr.id_carta
        WHERE cr.id_carta = %s;

        -- Detalhes de classe
        SELECT cc.nome_classe, pc.descricao
        FROM carta_classe cc
        LEFT JOIN poder_classe pc ON cc.id_carta = pc.id_carta_classe
        WHERE cc.id_carta = %s;

        -- Recupera partida em andamento
        SELECT id_partida FROM partida
        WHERE id_jogador = %s AND estado_partida = 'em andamento'
        ORDER BY id_partida DESC LIMIT 1;

        -- Lista cartas em zona específica
        SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo
        FROM carta_partida cp
        JOIN carta c ON c.id_carta = cp.id_carta
        WHERE cp.id_partida = %s AND cp.zona = %s;
    ```

</details>

### Referência Bibliográfica

> [1] ELMASRI, Ramez; NAVATHE, Shamkant B. *Sistemas de banco de dados*. 6. ed. São Paulo: Pearson Addison Wesley, 2011.

---

### Versionamento

| Versão | Data       | Modificação           | Autor(es)                               |
|--------|------------|------------------------|------------------------------------------|
| 0.1    | 10/06/2025 | Criação do Documento   | Mylena Mendonça                          |
| 1.0    | 16/06/2025 | Atualizações Gerais    | Ana Luiza Komatsu e Mylena Mendonça     |
