CREATE TABLE poder_classe (
    id_poder_classe INT PRIMARY KEY,
    id_carta_classe INT,
    descricao VARCHAR(200),

    FOREIGN KEY (id_carta_classe) REFERENCES carta_classe(id_carta)