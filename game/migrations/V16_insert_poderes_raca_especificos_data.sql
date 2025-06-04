-- poder_fuga_condicional
INSERT INTO poder_fuga_condicional (id_poder_raca, nova_tentativa, quantidade, condicao_tipo)
VALUES (3, TRUE, 1, 'sem_condicao');

INSERT INTO poder_fuga_condicional (id_poder_raca, nova_tentativa, quantidade, condicao_tipo)
VALUES (6, TRUE, 1, 'descartar_carta');

-- poder_maldicao
INSERT INTO poder_maldicao (id_poder_raca, ignora_maldicao, penalidade_substituta, nivel_minimo)
VALUES (7, TRUE, 'Perde 1 nível em vez de descartar', 1);

-- poder_recompensa_condicional
INSERT INTO poder_recompensa_condicional (id_poder_raca, bonus_tipo, bonus_quantidade, condicao_tipo)
VALUES (4, 'tesouro_extra', 1, 'matar_monstro');

INSERT INTO poder_recompensa_condicional (id_poder_raca, bonus_tipo, bonus_quantidade, condicao_tipo)
VALUES (8, 'nivel', 1, 'nivel_menor_que_monstro');

-- poder_limite_de_mao
INSERT INTO poder_limite_de_mao (id_poder_raca, limite_carta_mao)
VALUES (2, 6);

-- poder_pecas_ouro
INSERT INTO poder_pecas_ouro (id_poder_raca, quantidade)
VALUES (1, 50);

INSERT INTO poder_pecas_ouro (id_poder_raca, quantidade)
VALUES (5, 20);