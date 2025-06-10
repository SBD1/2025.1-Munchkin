CREATE TABLE poder_raca (
    id_poder_raca SERIAL PRIMARY KEY,
    id_carta INT NOT NULL,
    descricao VARCHAR(200),
    FOREIGN KEY (id_carta) REFERENCES carta_raca(id_carta));