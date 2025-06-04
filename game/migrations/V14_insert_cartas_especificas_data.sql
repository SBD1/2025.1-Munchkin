-- Carta Item
INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (1, 1, 200, 'arma', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (2, 3, 0, 'acessório', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (3, 1, 200, 'armadura', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (4, 2, 400, 'armadura', 'pe', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (5, 2, 400, 'arma', '1_mao', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (6, 1, 200, 'armadura', 'cabeca', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (7, 2, 400, 'armadura', 'corpo', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (8, 3, 600, 'arma', '2_maos', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (9, 4, 600, 'armadura', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (10, 3, 400, 'acessório', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (11, 3, 400, 'armadura', 'armadura', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (12, 4, 800, 'arma', '2_maos', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (13, 3, 400, 'arma', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (14, 3, 600, 'armadura', 'nenhum', FALSE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (15, 4, 600, 'arma', '1_mao', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (16, 4, 600, 'arma', '1_mao', TRUE);

INSERT INTO carta_item (id_carta, bonus_combate, valor_ouro, tipo_item, slot, ocupacao_dupla)
VALUES (17, 3, 400, 'cabeca', TRUE);

-- Carta Classe
INSERT INTO carta_classe (id_carta, nome_classe, descricao)
VALUES (22, 'clérigo', NULL);

INSERT INTO carta_classe (id_carta, nome_classe, descricao)
VALUES (23, 'guerreiro', NULL);

INSERT INTO carta_classe (id_carta, nome_classe, descricao)
VALUES (24, 'mago', NULL);

-- Carta Raça
INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (18, 'anao', NULL);

INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (19, 'elfo', NULL);

INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (20, 'halfling', NULL);

INSERT INTO carta_raca (id_carta, nome_raca, descricao)
VALUES (21, 'orc', NULL);

-- Carta Monstro
INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (1, 25, 2, FALSE, 1, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (2, 26, 4, TRUE, 2, 'morto_vivo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (3, 27, 6, TRUE, 2, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (4, 28, 8, TRUE, 2, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (5, 29, 10, TRUE, 3, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (6, 30, 12, TRUE, 3, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (7, 31, 14, TRUE, 4, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (8, 32, 16, TRUE, 4, 'morto_vivo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (9, 33, 18, TRUE, 5, 'sem_tipo');

INSERT INTO carta_monstro (id_carta_monstro, id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (10, 34, 20, TRUE, 5, 'sem_tipo');