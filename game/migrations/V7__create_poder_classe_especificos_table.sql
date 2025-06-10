CREATE TABLE descarta_para_efeito (
        id_poder_classe INT PRIMARY KEY,
        efeito VARCHAR(100),
        max_cartas INT,

        FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
);

    CREATE TABLE empata_vence (
        id_poder_classe INT PRIMARY KEY,
        vence_empata BOOLEAN DEFAULT FALSE,

        FOREIGN KEY (id_poder_classe) REFERENCES poder_classe(id_poder_classe)
);