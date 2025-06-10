-- poder_recompensa_condicional

-- Elfo: Ganha 1 tesouro extra por monstro morto
INSERT INTO poder_recompensa_condicional (id_poder_raca, bonus_tipo, bonus_quantidade, condicao_tipo)
VALUES (2, 'tesouro_extra', 1, 'matar_monstro');

-- Orc: Sobe 1 nível ao derrotar monstro com nível > 10
INSERT INTO poder_recompensa_condicional (id_poder_raca, bonus_tipo, bonus_quantidade, condicao_tipo)
VALUES (4, 'nivel', 1, 'nivel_monstro_maior_10');

-- poder_limite_de_mao

-- Anão: Pode ter até 6 cartas na mão no fim do turno
INSERT INTO poder_limite_de_mao (id_poder_raca, limite_cartas_mao)
VALUES (1, 6);

-- poder_venda_multiplicada

-- Halfling: Pode vender um item por o dobro do preço uma vez por turno
INSERT INTO poder_venda_multiplicada (id_poder_raca, multiplicador, limite_vezes_por_turno)
VALUES (3, 2, 1);
