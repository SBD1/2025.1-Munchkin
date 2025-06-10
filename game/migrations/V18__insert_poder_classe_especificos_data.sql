-- descarta_para_efeito
INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (1, 'compra carta', 1);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (2, '+3 de bônus em combate contra mortos-vivos', 3);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (3, '+1 de bônus em combate', 3);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (5, '+1 de fuga em combate', 3);

INSERT INTO descarta_para_efeito (id_poder_classe, efeito, max_cartas)
VALUES (6, 'enfeitiçar um único monstro em vez de lutar contra ele', 0);

-- empata_vence
INSERT INTO empata_vence (id_poder_classe, vence_empata)
VALUES (4, TRUE);
