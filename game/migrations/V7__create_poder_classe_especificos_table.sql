CREATE TABLE descarta_para_efeito (
    id_poder_classe INT PRIMARY KEY,
    bonus INT NOT NULL,
    max_cartas INT NOT NULL,
    FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
);

CREATE TABLE empata_vence (
        id_poder_classe INT PRIMARY KEY,
        vence_empata BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
);

CREATE TABLE poder_compensacao_derrota (
    id_poder_classe INT PRIMARY KEY,
    cartas_tesouro INT NOT NULL,
    FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
);

CREATE TABLE poder_ressurreicao (
    id_poder_classe INT PRIMARY KEY,
    vidas_recuperadas INT NOT NULL DEFAULT 1,
    FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
);