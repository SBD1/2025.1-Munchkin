CREATE TABLE combate (
    id_combate SERIAL PRIMARY KEY,
    id_partida INT NOT NULL,
    id_carta INT NOT NULL, 
    monstro_vindo_do_baralho BOOLEAN,
    vitoria BOOLEAN,
    coisa_ruim_aplicada BOOLEAN,
    nivel_ganho INT,
    data_ocorrido TIMESTAMP,
    FOREIGN KEY (id_partida) REFERENCES partida(id_partida),
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta) 
);
