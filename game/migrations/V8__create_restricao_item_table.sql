CREATE TABLE restricao_item (
    id_restricao SERIAL PRIMARY KEY,
    id_carta_item INT REFERENCES carta_item(id_carta),
    tipo_alvo VARCHAR(20) CHECK (tipo_alvo IN ('raca', 'classe')),
    valor_alvo VARCHAR(50),
    permitido BOOLEAN,
    CHECK (
        (tipo_alvo = 'classe' AND valor_alvo IN ('mago', 'guerreiro', 'clérigo')) OR
        (tipo_alvo = 'raca' AND valor_alvo IN ('anao', 'elfo', 'halfling', 'orc'))
    )
);