CREATE TABLE restricao_item (
    id_restricao SERIAL PRIMARY KEY,
    id_carta_item INT REFERENCES carta_item(id_carta),
    tipo_alvo VARCHAR(20) CHECK (tipo_alvo IN ('raca', 'classe')),
    valor_alvo VARCHAR(50) CHECK (valor_alvo IN ('mago', 'anao', 'guerreiro', 'orc')),
    permitido BOOLEAN
);