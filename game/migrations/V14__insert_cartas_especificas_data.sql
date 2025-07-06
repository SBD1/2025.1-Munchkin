-- Dados da tabela slot_equipamento
INSERT INTO slot_equipamento (nome, capacidade, grupo_exclusao, descricao) VALUES
('cabeca', 1, NULL, 'Equipamentos de cabeça'),
('corpo', 1, NULL, 'Armaduras corporais'),
('pe', 1, NULL, 'Botas ou calçados'),
('1_mao', 2, 'mao', 'Armas de uma mão'),
('2_maos', 1, 'mao', 'Armas que ocupam as duas mãos'),
('nenhum', 0, NULL, 'Itens que não ocupam espaço específico');

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
VALUES (11, 3, 400, 'armadura', 'corpo', TRUE);

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
VALUES (17, 3, 400, 'armadura', 'cabeca', TRUE);

-- Carta Classe
INSERT INTO carta_classe (id_carta, nome_classe)
VALUES (22, 'clérigo');

INSERT INTO carta_classe (id_carta, nome_classe)
VALUES (23, 'guerreiro');

INSERT INTO carta_classe (id_carta, nome_classe)
VALUES (24, 'mago');

-- Carta Raça
INSERT INTO carta_raca (id_carta, nome_raca)
VALUES (18, 'anao');

INSERT INTO carta_raca (id_carta, nome_raca)
VALUES (19, 'elfo');

INSERT INTO carta_raca (id_carta, nome_raca)
VALUES (20, 'halfling');

INSERT INTO carta_raca (id_carta, nome_raca)
VALUES (21, 'orc');

-- Carta Monstro
INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (25, 2, FALSE, 1, 'sem_tipo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (26, 4, TRUE, 2, 'morto_vivo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (27, 6, TRUE, 2, 'sem_tipo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (28, 8, TRUE, 2, 'sem_tipo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (29, 10, TRUE, 3, 'sem_tipo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (30, 12, TRUE, 3, 'sem_tipo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (31, 14, TRUE, 4, 'sem_tipo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (32, 16, TRUE, 4, 'morto_vivo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (33, 18, TRUE, 5, 'sem_tipo');

INSERT INTO carta_monstro (id_carta, nivel, pode_fugir, recompensa, tipo_monstro)
VALUES (34, 20, TRUE, 5, 'sem_tipo');

