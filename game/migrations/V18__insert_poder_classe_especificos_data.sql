-- Tabela: descarta_para_efeito
INSERT INTO descarta_para_efeito (id_poder_classe, bonus, max_cartas)
VALUES (3, 3, 2);

INSERT INTO descarta_para_efeito (id_poder_classe, bonus, max_cartas)
VALUES (5, 1, 3);

-- Tabela: empata_vence
INSERT INTO empata_vence (id_poder_classe, vence_empata)
VALUES (4, TRUE);

-- Tabela: poder_compensacao_derrota
INSERT INTO poder_compensacao_derrota (id_poder_classe, cartas_tesouro)
VALUES (6, 2);

INSERT INTO poder_compensacao_derrota (id_poder_classe, cartas_tesouro)
VALUES (7, 1);

INSERT INTO poder_ressurreicao (id_poder_classe, vidas_recuperadas)
VALUES (8, 1);
