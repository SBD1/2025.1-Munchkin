CREATE TABLE combate (
    id_combate SERIAL PRIMARY KEY,
    id_partida INT NOT NULL,
    id_carta_monstro INT NOT NULL,
    monstro_vindo_do_baralho BOOLEAN,
    vitoria BOOLEAN,
    coisa_ruim_aplicada BOOLEAN,
    nivel_ganho INT,
    data_ocorrido TIMESTAMP,
    FOREIGN KEY (id_partida) REFERENCES partida(id_partida),
    FOREIGN KEY (id_carta_monstro) REFERENCES carta_monstro(id_carta_monstro)
);
