- 📄 DQL (Data Query Language) - Consultas do Projeto Munchkin
-- Autor: Mylena Trindade de Mendonça
-- Descrição: Este documento organiza e descreve as principais queries utilizadas no sistema do jogo Munchkin.

-- ===========================================================
-- 🔹 AÇÕES CARTAS
-- ===========================================================
-- Retorna o ID do poder da raça e o limite de cartas na mão da carta especificada
SELECT pr.id_poder_raca, pl.limite_cartas_mao
FROM poder_raca pr
JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
WHERE pr.id_carta = %s;

-- São exibidos: o tipo do item, o slot de equipamento correspondente e o bônus de combate fornecido
SELECT tipo_item, slot, bonus_combate
FROM carta_item
WHERE id_carta = %s;

-- São exibidos: o tipo de alvo (ex: raça, classe), o valor do alvo (ex: "elfo", "guerreiro") 
-- e se o uso do item é permitido para esse alvo
SELECT tipo_alvo, valor_alvo, permitido
FROM restricao_item
WHERE id_carta_item = %s;

-- Verifica se o jogador possui uma carta de classe específica equipada
SELECT 1
FROM carta_partida cp
JOIN carta_classe cc ON cc.id_carta = cp.id_carta
WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND cc.nome_classe = %s;

-- Verifica se o jogador possui uma carta de raça específica equipada
SELECT 1
FROM carta_partida cp
JOIN carta_raca cr ON cr.id_carta = cp.id_carta
WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND cr.nome_raca = %s;

-- Verifica se já existe um item equipado no mesmo slot
SELECT 1
FROM carta_partida cp
JOIN carta_item ci ON ci.id_carta = cp.id_carta
WHERE cp.id_partida = %s AND cp.zona = 'equipado' AND ci.slot = %s;

-- Retorna o ID do poder da raça associado a uma carta (usado ao voltar para a mão)
SELECT pr.id_poder_raca
FROM poder_raca pr
JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
WHERE pr.id_carta = %s;

-- Verifica se ainda há alguma carta equipada com o poder de limite de mão
SELECT 1
FROM carta_partida cp
JOIN poder_raca pr ON cp.id_carta = pr.id_carta
JOIN poder_limite_de_mao pl ON pr.id_poder_raca = pl.id_poder_raca
WHERE cp.id_partida = %s AND cp.zona = 'equipado';

-- Retorna o valor de ouro de uma carta item específica
SELECT valor_ouro
FROM carta_item
WHERE id_carta = %s;

-- Retorna o ouro acumulado, o nível e o turno atual de uma partida
SELECT ouro_acumulado, nivel, turno_atual
FROM partida
WHERE id_partida = %s;

-- Retorna os dados do poder de venda multiplicada (caso haja) e seu limite de usos
SELECT pr.id_carta, pvm.multiplicador, pvm.limite_vezes_por_turno
FROM carta_partida cp
JOIN poder_raca pr ON cp.id_carta = pr.id_carta
JOIN poder_venda_multiplicada pvm ON pr.id_poder_raca = pvm.id_poder_raca
WHERE cp.id_partida = %s AND cp.zona = 'equipado';

-- Retorna quantas vezes o poder de venda já foi usado neste turno
SELECT usos
FROM uso_poder_venda
WHERE id_partida = %s AND id_carta = %s AND turno = %s;


-- ===========================================================
-- 🔹 CHUTAR A PORTA
-- ===========================================================
-- Seleciona aleatoriamente uma carta do tipo porta que esteja disponível para virar.
SELECT id_carta, nome, subtipo FROM carta
WHERE tipo_carta = 'porta' AND disponivel_para_virar = TRUE
ORDER BY RANDOM() LIMIT 1;

-- Marca a carta sorteada como indisponível para não ser usada novamente.
UPDATE carta
SET disponivel_para_virar = FALSE
WHERE id_carta = %s;

-- Registra o início de um combate com um monstro vindo do baralho na partida atual.
INSERT INTO combate (id_partida, id_carta, monstro_vindo_do_baralho, data_ocorrido)
VALUES (%s, %s, TRUE, NOW());

-- Adiciona a carta à mão do jogador na partida atual.
INSERT INTO carta_partida (id_partida, id_carta, zona)
VALUES (%s, %s, 'mao');


-- ===========================================================
-- 🔹 CRIAR JOGADOR
-- ===========================================================
-- Cria um novo munchkin usando função armazenada
SELECT insert_munchkin_jogador(%s);


-- ===========================================================
-- 🔹 GERENCIAR CARTAS NA MÃO
-- ===========================================================

-- Busca a partida em andamento de um jogador
SELECT id_partida FROM partida
WHERE id_jogador = %s AND estado_partida = 'em andamento'
ORDER BY id_partida DESC LIMIT 1;

-- Lista as cartas na mão de um jogador na partida atual
SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo
FROM carta_partida cp
JOIN carta c ON c.id_carta = cp.id_carta
WHERE cp.id_partida = %s AND cp.zona = 'mao';

-- Atualiza a zona de uma carta específica na partida, movendo-a para a nova posição (ex: mão, mesa, descarte).
UPDATE carta_partida
SET zona = %s
WHERE id_partida = %s AND id_carta = %s;


-- ===========================================================
-- 🔹 INICIAR PARTIDA
-- ===========================================================

-- Busca uma partida em andamento de um jogador
SELECT id_partida FROM partida
WHERE id_jogador = %s AND estado_partida = 'em andamento'
LIMIT 1;

--  Cria uma nova partida com o jogador, data atual, estado "em andamento" e 3 vidas, retornando o ID gerado.
INSERT INTO partida (id_jogador, data_inicio, estado_partida, vida_restantes)
VALUES (%s, %s, 'em andamento', 3)
RETURNING id_partida;

-- Seleciona 4 cartas de tipo específico aleatórias disponíveis
SELECT id_carta FROM carta
WHERE tipo_carta = %s AND disponivel_para_virar = TRUE
ORDER BY RANDOM()
LIMIT 4;

-- Insere cada carta na nova partida, colocando-a na zona "mão" do jogador.
INSERT INTO carta_partida (id_partida, id_carta, zona)
VALUES (%s, %s, 'mao');


-- ===========================================================
-- 🔹 INICIAR TURNO
-- ===========================================================

-- Busca a partida mais recente em andamento do jogador, com ID, limite de mão e turno atual.
SELECT id_partida, limite_mao_atual, turno_atual
FROM partida
WHERE id_jogador = %s AND estado_partida = 'em andamento'
ORDER BY id_partida DESC LIMIT 1;

-- Conta quantas cartas estão na mão do jogador na partida informada.SELECT COUNT(*) FROM carta_partida
WHERE id_partida = %s AND zona = 'mao';

-- Atualiza a partida somando 1 ao turno atual para iniciar um novo turno.
UPDATE partida
SET turno_atual = turno_atual + 1
WHERE id_partida = %s


-- ===========================================================
-- 🔹 LISTAR JOGADORES
-- ===========================================================
-- Executa a consulta que busca todos os jogadores e armazena o resultado em resultados.
SELECT id_jogador, nome FROM Jogador ORDER BY id_jogador;


-- ===========================================================
-- 🔹 OBTER AÇÕES E ESTADO DA PARTIDA
-- ===========================================================

-- Obtém o estado atual da partida mais recente de um jogador
SELECT nivel, vida_restantes, estado_partida, finalizada, vitoria, data_inicio, turno_atual, ouro_acumulado
FROM partida
WHERE id_jogador = %s
ORDER BY id_partida DESC
LIMIT 1;


-- ===========================================================
-- 🔹 OBTER DETALHES DE CARTAS
-- ===========================================================

-- Detalhes de uma carta item específica
SELECT bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla
FROM carta_item WHERE id_carta = %s;

-- Detalhes de um monstro e seus efeitos
SELECT cm.nivel, cm.pode_fugir, cm.recompensa, cm.tipo_monstro,
       em.descricao
FROM carta_monstro cm
LEFT JOIN efeito_monstro em ON cm.id_carta_monstro = em.id_carta_monstro
WHERE cm.id_carta = %s;

-- Detalhes de raça e poderes
SELECT cr.nome_raca, pr.descricao
FROM carta_raca cr
LEFT JOIN poder_raca pr ON cr.id_carta = pr.id_carta
WHERE cr.id_carta = %s;

-- Detalhes de classe e poderes
SELECT cc.nome_classe, pc.descricao
FROM carta_classe cc
LEFT JOIN poder_classe pc ON cc.id_carta = pc.id_carta_classe
WHERE cc.id_carta = %s;


-- ===========================================================
-- 🔹 SELECIONAR JOGADOR
-- ===========================================================
-- Seleciona todos os jogadores com seus IDs e nomes, ordenados pelo ID.
SELECT id_jogador, nome FROM Jogador ORDER BY id_jogador;


-- ===========================================================
-- 🔹 VER CARTAS EM ZONAS ESPECÍFICAS
-- ===========================================================

-- Recupera a partida em andamento do jogador
SELECT id_partida FROM partida
WHERE id_jogador = %s AND estado_partida = 'em andamento'
ORDER BY id_partida DESC LIMIT 1;

-- Lista as cartas em uma zona específica da partida
SELECT c.id_carta, c.nome, c.tipo_carta, c.subtipo
FROM carta_partida cp
JOIN carta c ON c.id_carta = cp.id_carta
WHERE cp.id_partida = %s AND cp.zona = %s;


-- ===========================================================
-- 🔹 VERSIONAMENTO
-- ===========================================================

| Versão | Data | Modificação | Autor |
| --- | --- | --- | --- |
|  0.1 | 10/06/2025 | Criação do Documento | Mylena Mendonça |
|  1.0 | 16/06/2025 | Modificação | Ana Luiza Komatsu e Mylena Mendonça |