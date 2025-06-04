CREATE TYPE enum_zona AS ENUM ('mao', 'equipado', 'mochila', 'descartada');

CREATE TABLE carta_partida (
    id_carta_partida SERIAL PRIMARY KEY,
    id_partida INT NOT NULL,
    id_carta INT NOT NULL,
    zona enum_zona NOT NULL,
    FOREIGN KEY (id_partida) REFERENCES partida(id_partida),
    FOREIGN KEY (id_carta) REFERENCES carta(id_carta));