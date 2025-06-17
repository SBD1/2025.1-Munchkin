CREATE TABLE efeito_monstro (
    id_efeito_monstro SERIAL PRIMARY KEY,
    id_carta_monstro INT REFERENCES carta_monstro(id_carta),
    descricao TEXT
);