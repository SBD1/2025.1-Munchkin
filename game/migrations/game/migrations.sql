-- penalidade_perda_nivel
INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (1, 2);

INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (2, 2);

INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (4, 1);

INSERT INTO penalidade_perda_nivel (id_efeito_monstro, niveis)
VALUES (5, 4);

-- penalidade_item
INSERT INTO penalidade_item (id_efeito_monstro, local_item, remove_tudo)
VALUES (4, 'cabeca', FALSE);

INSERT INTO penalidade_item (id_efeito_monstro, local_item, remove_tudo)
VALUES (6, 'cabeca', FALSE);

INSERT INTO penalidade_item (id_efeito_monstro, local_item, remove_tudo)
VALUES (8, 'todos', TRUE);

-- penalidade_transformacao
INSERT INTO penalidade_transformacao (id_efeito_monstro, perde_classe, perde_raca, vira_humano)
VALUES (3, TRUE, TRUE, TRUE);

-- penalidade_morte
INSERT INTO penalidade_morte (id_efeito_monstro, morte)
VALUES (7, TRUE);

INSERT INTO penalidade_morte (id_efeito_monstro, morte)
VALUES (9, TRUE);

INSERT INTO penalidade_morte (id_efeito_monstro, morte)
VALUES (10, TRUE);